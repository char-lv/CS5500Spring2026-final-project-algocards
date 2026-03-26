//
//  RecommendationService.swift
//  AlgoCards
//
//  Created by Cici Zhao on 3/24/26.
//

import Foundation

enum RecommendationSource {
    case heuristic
    case ai
}

struct PersonalizedRecommendation {
    let problem: ProblemListItem
    let headline: String
    let reason: String
    let focusArea: String
    let source: RecommendationSource

    var sourceBadgeText: String {
        switch source {
        case .heuristic:
            return "Personalized Pick"
        case .ai:
            return "AI Generated"
        }
    }
}

struct ProblemCatalogItem {
    let problem: ProblemListItem
    let listTags: [String]

    var categoryTags: [ProblemDeckConfig.Category] {
        listTags.compactMap(ProblemDeckConfig.Category.init(rawValue:))
    }
}

struct AIRecommendationUsageState {
    let dateKey: String?
    let count: Int
}

enum RecommendationError: LocalizedError {
    case unauthenticated
    case noProblemsAvailable
    case noUnsolvedProblems

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Please log in to load personalized recommendations."
        case .noProblemsAvailable:
            return "We couldn't find any practice problems right now."
        case .noUnsolvedProblems:
            return "You've completed every available problem. Nice work."
        }
    }
}

private struct ScoredProblem {
    let item: ProblemCatalogItem
    let score: Double
}

private struct RecommendationContext {
    let submissions: [Answer]
    let solvedIds: Set<String>
    let attemptedIds: Set<String>
    let solvedCategoryCounts: [String: Int]
    let recentCategoryCounts: [String: Int]
    let targetDifficulty: Difficulty
    let ranked: [ScoredProblem]
    let topPool: [ScoredProblem]
    let phaseOneSelection: ScoredProblem
    let rotationIndex: Int
}

final class RecommendationService {

    static let shared = RecommendationService()

    private let aiDailyLimit = 10

    private init() {}

    func generateRecommendation(
        excludingProblemIds: Set<String> = [],
        poolSize: Int = 5,
        completion: @escaping (Result<PersonalizedRecommendation, Error>) -> Void
    ) {
        guard let userId = AuthService.shared.currentUserId else {
            completion(.failure(RecommendationError.unauthenticated))
            return
        }

        let group = DispatchGroup()

        var loadedUser = User(id: userId, userName: "Learner", email: "")
        var submissions: [Answer] = []
        var catalog: [ProblemCatalogItem] = []
        var catalogError: Error?
        var aiUsageState: AIRecommendationUsageState?

        group.enter()
        FirestoreService.shared.fetchUser(userId: userId) { result in
            if case .success(let user) = result {
                loadedUser = user
            }
            group.leave()
        }

        group.enter()
        FirestoreService.shared.fetchSubmissions(userId: userId) { result in
            if case .success(let answers) = result {
                submissions = answers
            }
            group.leave()
        }

        group.enter()
        FirestoreService.shared.fetchAllProblemCatalogItems { result in
            switch result {
            case .success(let items):
                catalog = items
            case .failure(let error):
                catalogError = error
            }
            group.leave()
        }

        group.enter()
        FirestoreService.shared.fetchAIRecommendationUsage(userId: userId) { result in
            if case .success(let usageState) = result {
                aiUsageState = usageState
            }
            group.leave()
        }

        group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
            guard let self else { return }

            if let error = catalogError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            do {
                let context = try self.buildRecommendationContext(
                    user: loadedUser,
                    submissions: submissions,
                    catalog: catalog,
                    excludingProblemIds: excludingProblemIds,
                    poolSize: poolSize
                )

                let phaseOneRecommendation = self.makeRecommendation(
                    for: context.phaseOneSelection.item,
                    context: context,
                    source: .heuristic
                )

                guard
                    let config = AIRecommendationConfig.current,
                    let usageState = aiUsageState,
                    self.isAIUsageAvailable(usageState)
                else {
                    DispatchQueue.main.async {
                        completion(.success(phaseOneRecommendation))
                    }
                    return
                }

                let anchor = context.topPool[context.rotationIndex % context.topPool.count].item
                let aiOptions = self.aiCandidateOptions(
                    anchor: anchor,
                    context: context,
                    excludingProblemIds: excludingProblemIds,
                    limit: 8
                )

                guard !aiOptions.isEmpty else {
                    DispatchQueue.main.async {
                        completion(.success(phaseOneRecommendation))
                    }
                    return
                }

                let prompt = self.aiRecommendationPrompt(
                    anchor: anchor,
                    options: aiOptions,
                    context: context
                )

                AIRecommendationClient(config: config).generateRelatedRecommendation(prompt: prompt) { result in
                    switch result {
                    case .success(let aiResponse):
                        guard
                            let selectedItem = aiOptions.first(where: { $0.problem.id == aiResponse.problemId })
                        else {
                            DispatchQueue.main.async {
                                completion(.success(phaseOneRecommendation))
                            }
                            return
                        }

                        let aiRecommendation = self.makeRecommendation(
                            for: selectedItem,
                            context: context,
                            source: .ai,
                            headlineOverride: aiResponse.headline,
                            reasonOverride: aiResponse.reason
                        )

                        FirestoreService.shared.recordAIRecommendationUsage(
                            userId: userId,
                            dateKey: self.currentDateKey()
                        ) { _ in }

                        DispatchQueue.main.async {
                            completion(.success(aiRecommendation))
                        }
                    case .failure:
                        DispatchQueue.main.async {
                            completion(.success(phaseOneRecommendation))
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func buildRecommendationContext(
        user: User,
        submissions: [Answer],
        catalog: [ProblemCatalogItem],
        excludingProblemIds: Set<String>,
        poolSize: Int
    ) throws -> RecommendationContext {
        guard !catalog.isEmpty else {
            throw RecommendationError.noProblemsAvailable
        }

        let solvedIds = Set(user.solvedProblemIds)
        let attemptedIds = Set(uniqueProblemIds(from: submissions))
        let unsolved = catalog.filter { !solvedIds.contains($0.problem.id) && !$0.problem.isPaidOnly }

        guard !unsolved.isEmpty else {
            throw RecommendationError.noUnsolvedProblems
        }

        let catalogById = Dictionary(uniqueKeysWithValues: catalog.map { ($0.problem.id, $0) })
        let recentAttemptIds = uniqueProblemIds(from: submissions).prefix(6)

        let solvedItems = solvedIds.compactMap { catalogById[$0] }
        let recentItems = recentAttemptIds.compactMap { catalogById[$0] }

        let solvedCategoryCounts = countCategories(in: solvedItems)
        let recentCategoryCounts = countCategories(in: recentItems)
        let solvedDifficultyCounts = countDifficulties(in: solvedItems)
        let targetDifficulty = determineTargetDifficulty(
            solvedCount: solvedItems.count,
            difficultyCounts: solvedDifficultyCounts
        )

        let ranked = unsolved
            .map { item in
                ScoredProblem(
                    item: item,
                    score: score(
                        item: item,
                        targetDifficulty: targetDifficulty,
                        solvedCategoryCounts: solvedCategoryCounts,
                        recentCategoryCounts: recentCategoryCounts,
                        recentAttemptIds: Set(recentAttemptIds)
                    )
                )
            }
            .sorted(by: rankedHigherThan)

        let topPool = Array(ranked.prefix(max(1, poolSize)))

        guard
            let phaseOneSelection = topPool.first(where: { !excludingProblemIds.contains($0.item.problem.id) })
                ?? topPool.first
        else {
            throw RecommendationError.noProblemsAvailable
        }

        return RecommendationContext(
            submissions: submissions,
            solvedIds: solvedIds,
            attemptedIds: attemptedIds,
            solvedCategoryCounts: solvedCategoryCounts,
            recentCategoryCounts: recentCategoryCounts,
            targetDifficulty: targetDifficulty,
            ranked: ranked,
            topPool: topPool,
            phaseOneSelection: phaseOneSelection,
            rotationIndex: excludingProblemIds.count
        )
    }

    private func makeRecommendation(
        for item: ProblemCatalogItem,
        context: RecommendationContext,
        source: RecommendationSource,
        headlineOverride: String? = nil,
        reasonOverride: String? = nil
    ) -> PersonalizedRecommendation {
        let focusArea = focusAreaText(
            for: item,
            solvedCategoryCounts: context.solvedCategoryCounts,
            recentCategoryCounts: context.recentCategoryCounts
        )
        let headline = sanitizedAIText(headlineOverride)
            ?? headlineText(
                for: item.problem,
                targetDifficulty: context.targetDifficulty,
                recentCategoryCounts: context.recentCategoryCounts
            )
        let reason = sanitizedAIText(reasonOverride)
            ?? reasonText(
                for: item,
                focusArea: focusArea,
                solvedCount: context.solvedIds.count,
                recentCategoryCounts: context.recentCategoryCounts
            )

        return PersonalizedRecommendation(
            problem: item.problem,
            headline: headline,
            reason: reason,
            focusArea: focusArea,
            source: source
        )
    }

    private func aiCandidateOptions(
        anchor: ProblemCatalogItem,
        context: RecommendationContext,
        excludingProblemIds: Set<String>,
        limit: Int
    ) -> [ProblemCatalogItem] {
        let related = context.ranked
            .filter { scored in
                let id = scored.item.problem.id
                return id != anchor.problem.id
                    && !context.solvedIds.contains(id)
                    && !context.attemptedIds.contains(id)
                    && !excludingProblemIds.contains(id)
            }
            .map { scored in
                (
                    item: scored.item,
                    score: relatednessScore(anchor: anchor, candidate: scored.item) + (scored.score * 0.15)
                )
            }
            .filter { $0.score > 0.0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return (Int(lhs.item.problem.id) ?? 0) < (Int(rhs.item.problem.id) ?? 0)
                }
                return lhs.score > rhs.score
            }

        return Array(related.prefix(limit).map(\.item))
    }

    private func relatednessScore(
        anchor: ProblemCatalogItem,
        candidate: ProblemCatalogItem
    ) -> Double {
        let anchorTags = Set(anchor.listTags)
        let candidateTags = Set(candidate.listTags)
        let sharedTags = anchorTags.intersection(candidateTags)

        let anchorTitleTokens = Set(tokenize(anchor.problem.title))
        let candidateTitleTokens = Set(tokenize(candidate.problem.title))
        let sharedTitleTokens = anchorTitleTokens.intersection(candidateTitleTokens)

        var score = Double(sharedTags.count) * 2.0
        score += Double(sharedTitleTokens.count) * 1.4

        if anchor.problem.difficulty == candidate.problem.difficulty {
            score += 1.2
        } else if difficultyDistance(anchor.problem.difficulty, candidate.problem.difficulty) == 1 {
            score += 0.6
        }

        return score
    }

    private func score(
        item: ProblemCatalogItem,
        targetDifficulty: Difficulty,
        solvedCategoryCounts: [String: Int],
        recentCategoryCounts: [String: Int],
        recentAttemptIds: Set<String>
    ) -> Double {
        var total = 0.0
        let categoryTags = item.categoryTags.map(\.rawValue)
        let solvedAverage = solvedCategoryCounts.values.isEmpty
            ? 0.0
            : Double(solvedCategoryCounts.values.reduce(0, +)) / Double(solvedCategoryCounts.count)

        total += difficultyScore(for: item.problem.difficulty, targetDifficulty: targetDifficulty)

        for tag in categoryTags {
            total += Double(recentCategoryCounts[tag, default: 0]) * 2.4

            let solvedCount = Double(solvedCategoryCounts[tag, default: 0])
            if solvedAverage > 0 {
                total += max(0, solvedAverage - solvedCount) * 0.7
            } else {
                total += 0.8
            }
        }

        if item.listTags.contains("blind75") {
            total += 0.8
        }
        if item.listTags.contains("hot100") {
            total += 0.5
        }
        if item.problem.hasSolution {
            total += 0.2
        }

        if recentAttemptIds.contains(item.problem.id) {
            total -= 1.0
        }

        let acceptance = item.problem.acRate / 100.0
        switch targetDifficulty {
        case .easy:
            total += acceptance * 1.2
        case .medium:
            total += acceptance
        case .hard:
            total += acceptance * 0.6
        }

        if categoryTags.isEmpty && !recentCategoryCounts.isEmpty {
            total -= 0.4
        }

        return total
    }

    private func difficultyScore(
        for difficulty: Difficulty,
        targetDifficulty: Difficulty
    ) -> Double {
        switch (difficulty, targetDifficulty) {
        case let (lhs, rhs) where lhs == rhs:
            return 3.0
        case (.easy, .medium), (.medium, .easy), (.medium, .hard), (.hard, .medium):
            return 1.1
        default:
            return 0.1
        }
    }

    private func determineTargetDifficulty(
        solvedCount: Int,
        difficultyCounts: [Difficulty: Int]
    ) -> Difficulty {
        if solvedCount < 3 {
            return .easy
        }

        let easySolved = difficultyCounts[.easy, default: 0]
        let mediumSolved = difficultyCounts[.medium, default: 0]

        if mediumSolved >= 5 && solvedCount >= 10 {
            return .hard
        }

        if easySolved >= 3 || solvedCount >= 5 {
            return .medium
        }

        return .easy
    }

    private func focusAreaText(
        for item: ProblemCatalogItem,
        solvedCategoryCounts: [String: Int],
        recentCategoryCounts: [String: Int]
    ) -> String {
        let categories = item.categoryTags.map(\.rawValue)

        if let recentTag = categories.max(by: {
            recentCategoryCounts[$0, default: 0] < recentCategoryCounts[$1, default: 0]
        }), recentCategoryCounts[recentTag, default: 0] > 0 {
            return displayName(for: recentTag)
        }

        if let weakestTag = categories.min(by: {
            solvedCategoryCounts[$0, default: 0] < solvedCategoryCounts[$1, default: 0]
        }) {
            return displayName(for: weakestTag)
        }

        if item.listTags.contains("blind75") {
            return "Blind 75"
        }
        if item.listTags.contains("hot100") {
            return "Hot 100"
        }

        return item.problem.difficulty.rawValue
    }

    private func headlineText(
        for problem: ProblemListItem,
        targetDifficulty: Difficulty,
        recentCategoryCounts: [String: Int]
    ) -> String {
        if recentCategoryCounts.isEmpty {
            return "Start with \(problem.title)"
        }

        switch targetDifficulty {
        case .easy:
            return "Warm up with \(problem.title)"
        case .medium:
            return "Your next step: \(problem.title)"
        case .hard:
            return "Stretch yourself with \(problem.title)"
        }
    }

    private func reasonText(
        for item: ProblemCatalogItem,
        focusArea: String,
        solvedCount: Int,
        recentCategoryCounts: [String: Int]
    ) -> String {
        let difficultyText = item.problem.difficulty.rawValue.lowercased()

        if solvedCount == 0 {
            return "\(item.problem.title) is a strong first pick: it is a \(difficultyText) problem with a solid success rate and gives you a clean entry point into \(focusArea)."
        }

        if recentCategoryCounts.isEmpty {
            return "Based on what you've already solved, this \(difficultyText) question is a sensible next step to keep building momentum in \(focusArea)."
        }

        return "You recently practiced \(focusArea), and this \(difficultyText) question keeps that pattern fresh while nudging you toward the right next difficulty."
    }

    private func aiRecommendationPrompt(
        anchor: ProblemCatalogItem,
        options: [ProblemCatalogItem],
        context: RecommendationContext
    ) -> String {
        let optionLines = options.map { option in
            let tags = option.listTags.map(displayName(for:)).joined(separator: ", ")
            return "- id: \(option.problem.id), title: \(option.problem.title), difficulty: \(option.problem.difficulty.rawValue), tags: \(tags)"
        }.joined(separator: "\n")

        let anchorTags = anchor.listTags.map(displayName(for:)).joined(separator: ", ")

        return """
        You are choosing a new interview-practice recommendation for a learner.

        Rules:
        - Pick exactly one problem from the candidate options.
        - The chosen problem must feel like a natural follow-up to the anchor problem.
        - The chosen problem must be unseen by the learner.
        - Prefer a recommendation that is clearly related in technique, pattern, or progression.
        - Do not invent a new problem title. Use one option exactly as given.

        Anchor problem:
        - id: \(anchor.problem.id)
        - title: \(anchor.problem.title)
        - difficulty: \(anchor.problem.difficulty.rawValue)
        - tags: \(anchorTags)

        Learner context:
        - solved count: \(context.solvedIds.count)
        - recent submissions: \(context.submissions.count)

        Candidate options:
        \(optionLines)

        Return strict JSON with exactly these keys:
        {
          "problemId": "one id from the candidate list",
          "headline": "short recommendation headline",
          "reason": "1-2 short sentences explaining why this new problem is a good follow-up"
        }
        """
    }

    private func isAIUsageAvailable(_ usageState: AIRecommendationUsageState) -> Bool {
        let today = currentDateKey()
        if usageState.dateKey != today {
            return true
        }
        return usageState.count < aiDailyLimit
    }

    private func currentDateKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func countCategories(in items: [ProblemCatalogItem]) -> [String: Int] {
        var counts: [String: Int] = [:]
        items.forEach { item in
            item.categoryTags.map(\.rawValue).forEach { tag in
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    private func countDifficulties(in items: [ProblemCatalogItem]) -> [Difficulty: Int] {
        var counts: [Difficulty: Int] = [:]
        items.forEach { item in
            counts[item.problem.difficulty, default: 0] += 1
        }
        return counts
    }

    private func uniqueProblemIds(from submissions: [Answer]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for answer in submissions {
            if seen.insert(answer.problemId).inserted {
                ordered.append(answer.problemId)
            }
        }

        return ordered
    }

    private func displayName(for tag: String) -> String {
        ProblemDeckConfig.displayName(forListTag: tag)
    }

    private func difficultyDistance(_ lhs: Difficulty, _ rhs: Difficulty) -> Int {
        let values: [Difficulty: Int] = [.easy: 0, .medium: 1, .hard: 2]
        return abs(values[lhs, default: 0] - values[rhs, default: 0])
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    private func sanitizedAIText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func rankedHigherThan(_ lhs: ScoredProblem, _ rhs: ScoredProblem) -> Bool {
        if lhs.score == rhs.score {
            return (Int(lhs.item.problem.id) ?? 0) < (Int(rhs.item.problem.id) ?? 0)
        }
        return lhs.score > rhs.score
    }
}

private struct AIRecommendationConfig {
    let apiKey: String
    let model: String

    static var current: AIRecommendationConfig? {
        guard
            let rawKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
            !rawKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let rawModel = (Bundle.main.object(forInfoDictionaryKey: "OPENAI_RECOMMENDATION_MODEL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return AIRecommendationConfig(
            apiKey: rawKey,
            model: (rawModel?.isEmpty == false) ? rawModel! : "gpt-4.1-mini"
        )
    }
}

private final class AIRecommendationClient {

    private let config: AIRecommendationConfig

    init(config: AIRecommendationConfig) {
        self.config = config
    }

    func generateRelatedRecommendation(
        prompt: String,
        completion: @escaping (Result<AIRelatedRecommendationResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(RecommendationError.noProblemsAvailable))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatCompletionRequest(
            model: config.model,
            messages: [
                ChatMessage(
                    role: "system",
                    content: "You choose one related practice problem from a provided list and return valid JSON only."
                ),
                ChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.4
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(RecommendationError.noProblemsAvailable))
                return
            }

            do {
                let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                guard
                    let content = response.choices.first?.message.content,
                    let jsonString = Self.extractJSONObject(from: content),
                    let jsonData = jsonString.data(using: .utf8)
                else {
                    throw RecommendationError.noProblemsAvailable
                }

                let recommendation = try JSONDecoder().decode(
                    AIRelatedRecommendationResponse.self,
                    from: jsonData
                )
                completion(.success(recommendation))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private static func extractJSONObject(from content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("{"), trimmed.hasSuffix("}") {
            return trimmed
        }

        if let start = trimmed.range(of: "{"),
           let end = trimmed.range(of: "}", options: .backwards),
           start.lowerBound < end.upperBound {
            return String(trimmed[start.lowerBound..<end.upperBound])
        }

        return nil
    }
}

private struct AIRelatedRecommendationResponse: Decodable {
    let problemId: String
    let headline: String
    let reason: String
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [ChatChoice]
}

private struct ChatChoice: Decodable {
    let message: ChatMessage
}
