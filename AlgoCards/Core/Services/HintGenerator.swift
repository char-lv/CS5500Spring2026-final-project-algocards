//
//  HintGenerator.swift
//  AlgoCards
//

import Foundation

// TODO: Move Claude API call to Firebase Cloud Function in production.
//       Client-side invocation exposes ANTHROPIC_API_KEY in the app bundle.
//       Current approach matches the existing OpenAI integration pattern and is
//       acceptable for the current development phase.

/// Generates 3 progressive hints for a LeetCode problem using the Claude API.
///
/// Responsibilities (only):
///   - Fetch the problem description via NetworkManager (usually a memory cache hit)
///   - Build a structured Claude prompt
///   - Call the Anthropic Messages API via URLSession
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
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return key
    }

    private var model: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_HINT_MODEL") as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "claude-haiku-4-5-20251001" : trimmed
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
                self.callClaudeAPI(
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

    // MARK: - Claude API

    private func callClaudeAPI(
        problem: ProblemListItem,
        description: String,
        apiKey: String,
        completion: @escaping (Result<[String], GenerationError>) -> Void
    ) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(.failure(.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ClaudeRequest(
            model: model,
            max_tokens: 256,
            messages: [ClaudeMessage(role: "user", content: buildPrompt(problem: problem, description: description))]
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
                let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
                guard let textBlock = response.content.first(where: { $0.type == "text" }) else {
                    completion(.failure(.invalidResponse))
                    return
                }
                let hints = try self.parseAndValidate(textBlock.text)
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
        - Hint 1: Name the general category of approach or data structure to consider. Do NOT name the specific algorithm.
        - Hint 2: Name the specific technique or pattern. Still no implementation details.
        - Hint 3: Describe the key insight or observation that unlocks the solution. No code.
        - Each hint must be 1–2 sentences only.
        - Hints must be strictly progressive: each reveals more than the one before.

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

private struct ClaudeRequest: Encodable {
    let model: String
    let max_tokens: Int
    let messages: [ClaudeMessage]
}

private struct ClaudeMessage: Encodable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Decodable {
    let content: [ClaudeContent]
}

private struct ClaudeContent: Decodable {
    let type: String
    let text: String
}

private struct HintGenerationResponse: Decodable {
    let hints: [String]
}
