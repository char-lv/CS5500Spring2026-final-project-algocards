//
//  HintGenerator.swift
//  AlgoCards
//

import Foundation

// TODO: Move OpenAI API call to Firebase Cloud Function in production.
//       Client-side invocation exposes OPENAI_API_KEY in the app bundle.
//       Current approach matches the existing OpenAI recommendation integration pattern and is
//       acceptable for the current development phase.

/// Generates 3 progressive hints for a LeetCode problem using the OpenAI Chat Completions API.
///
/// Responsibilities (only):
///   - Fetch the problem description via NetworkManager (usually a memory cache hit)
///   - Build a structured prompt
///   - Call the OpenAI Chat Completions API via URLSession
///   - Parse and strictly validate the response
///
/// Does NOT access Firestore. Does NOT manage any cache.
/// HintService is responsible for cache coordination and Firestore persistence.
final class HintGenerator {

    static let shared = HintGenerator()
    private init() {}

    /// Dedicated session with a 5-second request timeout (NFR-10).
    /// Using a private session instead of URLSession.shared ensures the timeout
    /// applies only to AI calls and does not affect other URLSession users.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 5.0   // NFR-10: 3-5 s max
        config.timeoutIntervalForResource = 5.0
        return URLSession(configuration: config)
    }()

    enum GenerationError: Error {
        case missingAPIKey
        case descriptionUnavailable
        case networkError(Error)
        case invalidResponse
        case validationFailed
    }

    // MARK: - Configuration

    private var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return key
    }

    private var model: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "OPENAI_RECOMMENDATION_MODEL") as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "gpt-4.1-mini" : trimmed
    }

    // MARK: - Public API

    /// Generates exactly 3 progressive hints for the given problem.
    /// Calls completion on a background thread. HintService is responsible for
    /// dispatching to the main thread before updating the UI.
    func generateHints(
        for problem: ProblemListItem,
        completion: @escaping (Result<[String], GenerationError>) -> Void
    ) {
        guard let apiKey else {
            completion(.failure(.missingAPIKey))
            return
        }

        // Fetch problem description. NetworkManager caches by titleSlug, so this is
        // usually a memory hit if FlashCardViewController already loaded the card content.
        NetworkManager.shared.fetchProblemDetail(titleSlug: problem.titleSlug) { [weak self] result in
            guard let self else { completion(.failure(.descriptionUnavailable)); return }

            switch result {
            case .success(let fullProblem):
                self.callOpenAIAPI(
                    problem: problem,
                    description: fullProblem.description,
                    apiKey: apiKey,
                    completion: completion
                )
            case .failure:
                // Without a description Claude cannot generate meaningful hints.
                completion(.failure(.descriptionUnavailable))
            }
        }
    }

    // MARK: - OpenAI API

    private func callOpenAIAPI(
        problem: ProblemListItem,
        description: String,
        apiKey: String,
        completion: @escaping (Result<[String], GenerationError>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: "You are a coding interview coach that returns only valid JSON."),
                ChatMessage(role: "user", content: buildPrompt(problem: problem, description: description))
            ],
            temperature: 0.2
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(.invalidResponse))
            return
        }

        Self.session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { completion(.failure(.invalidResponse)); return }

            if let error {
                completion(.failure(.networkError(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                completion(.failure(.invalidResponse))
                return
            }

            guard let data else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    completion(.failure(.invalidResponse))
                    return
                }
                let hints = try self.parseAndValidate(content)
                completion(.success(hints))
            } catch {
                completion(.failure(.validationFailed))
            }
        }.resume()
    }

    // MARK: - Prompt

    private func buildPrompt(problem: ProblemListItem, description: String) -> String {
        let tags = problem.topicTags.map(\.name).joined(separator: ", ")
        let tagsLine = tags.isEmpty ? "None" : tags

        return """
        You are a coding interview coach. Generate exactly 3 progressive hints for the following LeetCode problem.

        Problem: \(problem.title)
        Difficulty: \(problem.difficulty.rawValue)
        Topic Tags: \(tagsLine)

        Problem Description:
        \(description)

        Hint progression rules:
        - Hint 1: Point out one specific observation about this problem's structure, constraints, or
          input properties that suggests a direction. Do NOT name any algorithm or data structure yet.
          The observation must be grounded in the problem description above — not generic advice.
        - Hint 2: Name the specific technique or data structure and give one concrete reason why it
          fits this particular problem's structure. One to two sentences.
        - Hint 3: Describe the key implementation detail or edge case the solution must handle,
          tied to a specific element of this problem. No code, no pseudocode.
        - Each hint must be 1–2 sentences only.
        - Hints must be strictly progressive: each reveals a little more than the one before.
        - Do NOT write a hint that could apply word-for-word to a different LeetCode problem.
        - Do NOT reveal the full solution approach in a single hint.

        Return ONLY valid JSON with no explanation, no markdown, no extra text:
        {"hints": ["hint one", "hint two", "hint three"]}
        """
    }

    // MARK: - Parsing and Validation

    private func parseAndValidate(_ content: String) throws -> [String] {
        guard let jsonString = extractJSON(from: content),
              let data = jsonString.data(using: .utf8) else {
            throw GenerationError.validationFailed
        }

        let decoded = try JSONDecoder().decode(HintGenerationResponse.self, from: data)

        // Strict validation: exactly 3 hints, each non-empty and of reasonable length.
        // Any failure returns an error — invalid data is never written to Firestore.
        guard decoded.hints.count == 3,
              decoded.hints.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              decoded.hints.allSatisfy({ $0.count < 300 }) else {
            throw GenerationError.validationFailed
        }

        return decoded.hints
    }

    /// Extracts the first `{...}` block from content to tolerate markdown fences
    /// or surrounding explanation text that Claude occasionally emits.
    private func extractJSON(from content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fast path: content is already a clean JSON object.
        if trimmed.hasPrefix("{"), trimmed.hasSuffix("}") {
            return trimmed
        }

        // Slow path: extract the outermost { ... } block.
        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start < end else { return nil }

        return String(trimmed[start...end])
    }
}

// MARK: - Private Request / Response Models

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

private struct HintGenerationResponse: Decodable {
    let hints: [String]
}
