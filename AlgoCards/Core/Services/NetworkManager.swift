//
//  NetworkManager.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation
import Alamofire

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case premiumQuestion
    case decodingFailed
    case noSolutionAvailable
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL."
        case .premiumQuestion:      return "This is a premium problem and cannot be loaded."
        case .decodingFailed:       return "Failed to decode server response."
        case .noSolutionAvailable:  return "No official solution available for this problem."
        case .serverError(let msg): return msg
        }
    }
}

class NetworkManager {

    static let shared = NetworkManager()
    private init() {}

    private var problemCache: [String: Problem] = [:]
    private let cacheQueue = DispatchQueue(label: "com.algocards.network.problem-cache")

    // Fetch Problem List
    func fetchProblems(
        url: URL,
        completion: @escaping (Result<[ProblemListItem], NetworkError>) -> Void
    ) {
        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: ProblemsAPIResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    completion(.success(apiResponse.problemsetQuestionList))
                case .failure(let err):
                    completion(.failure(.serverError(err.localizedDescription)))
                }
            }
    }

    // Fetch Single Problem Detail
    func fetchProblemDetail(
        titleSlug: String,
        completion: @escaping (Result<Problem, NetworkError>) -> Void
    ) {
        if let cachedProblem = cachedProblem(for: titleSlug) {
            completion(.success(cachedProblem))
            return
        }

        fetchProblemDetailFromLeetCode(titleSlug: titleSlug) { [weak self] result in
            switch result {
            case .success(let problem):
                self?.cache(problem: problem, for: titleSlug)
                completion(.success(problem))
            case .failure:
                self?.fetchProblemDetailFromMirror(titleSlug: titleSlug, completion: completion)
            }
        }
    }

    // Fetch Daily Problem
    func fetchDailyProblem(
        completion: @escaping (Result<Problem, NetworkError>) -> Void
    ) {
        guard let url = LegacyMirrorConfig.dailyProblemURL else {
            completion(.failure(.invalidURL))
            return
        }
        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: ProblemAPIResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    let problem = Problem(
                        id: apiResponse.questionId,
                        title: apiResponse.questionTitle,
                        titleSlug: apiResponse.titleSlug,
                        difficulty: Difficulty(rawValue: apiResponse.difficulty) ?? .medium,
                        description: apiResponse.question,
                        exampleTestcases: apiResponse.exampleTestcases
                    )
                    completion(.success(problem))
                case .failure:
                    completion(.failure(.decodingFailed))
                }
            }
    }

    // Fetch Official Solution
    func fetchOfficialSolution(
        titleSlug: String,
        completion: @escaping (Result<String, NetworkError>) -> Void
    ) {
        guard let url = LegacyMirrorConfig.officialSolutionURL(titleSlug: titleSlug) else {
            completion(.failure(.invalidURL))
            return
        }
        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: OfficialSolutionAPIResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    guard let content = apiResponse.content, !content.isEmpty else {
                        completion(.failure(.noSolutionAvailable))
                        return
                    }
                    completion(.success(content))
                case .failure:
                    completion(.failure(.noSolutionAvailable))
                }
            }
    }

    private func fetchProblemDetailFromLeetCode(
        titleSlug: String,
        completion: @escaping (Result<Problem, NetworkError>) -> Void
    ) {
        guard let url = LeetCodeConfig.graphqlURL else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = LeetCodeGraphQLRequest(
            operationName: "questionData",
            variables: ["titleSlug": titleSlug],
            query: """
            query questionData($titleSlug: String!) {
              question(titleSlug: $titleSlug) {
                questionFrontendId
                title
                titleSlug
                content
                difficulty
                sampleTestCase
                isPaidOnly
              }
            }
            """
        )

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(.serverError(error.localizedDescription)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.serverError(error.localizedDescription)))
                return
            }

            guard
                let httpResponse = response as? HTTPURLResponse,
                let data
            else {
                completion(.failure(.decodingFailed))
                return
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError("LeetCode returned HTTP \(httpResponse.statusCode).")))
                return
            }

            do {
                let apiResponse = try JSONDecoder().decode(LeetCodeGraphQLResponse.self, from: data)
                guard let question = apiResponse.data.question else {
                    if let graphQLError = apiResponse.errors?.first?.message, !graphQLError.isEmpty {
                        completion(.failure(.serverError(graphQLError)))
                    } else {
                        completion(.failure(.decodingFailed))
                    }
                    return
                }

                if question.isPaidOnly || question.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    completion(.failure(.premiumQuestion))
                    return
                }

                let problem = Problem(
                    id: question.questionFrontendId,
                    title: question.title,
                    titleSlug: question.titleSlug,
                    difficulty: Difficulty(rawValue: question.difficulty) ?? .medium,
                    description: question.content,
                    exampleTestcases: question.sampleTestCase
                )
                completion(.success(problem))
            } catch {
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }

    private func fetchProblemDetailFromMirror(
        titleSlug: String,
        completion: @escaping (Result<Problem, NetworkError>) -> Void
    ) {
        guard let url = LegacyMirrorConfig.problemDetailURL(titleSlug: titleSlug) else {
            completion(.failure(.invalidURL))
            return
        }

        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: ProblemAPIResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    guard !apiResponse.question.isEmpty else {
                        completion(.failure(.premiumQuestion))
                        return
                    }
                    let problem = Problem(
                        id: apiResponse.questionId,
                        title: apiResponse.questionTitle,
                        titleSlug: apiResponse.titleSlug,
                        difficulty: Difficulty(rawValue: apiResponse.difficulty) ?? .medium,
                        description: apiResponse.question,
                        exampleTestcases: apiResponse.exampleTestcases
                    )
                    self.cache(problem: problem, for: titleSlug)
                    completion(.success(problem))
                case .failure(let error):
                    completion(.failure(.serverError(error.localizedDescription)))
                }
            }
    }

    private func cachedProblem(for titleSlug: String) -> Problem? {
        cacheQueue.sync {
            problemCache[titleSlug]
        }
    }

    private func cache(problem: Problem, for titleSlug: String) {
        cacheQueue.async {
            self.problemCache[titleSlug] = problem
        }
    }
}

// Private Response Models
private struct ProblemsAPIResponse: Codable {
    let problemsetQuestionList: [ProblemListItem]
}

private struct ProblemAPIResponse: Codable {
    let questionId: String
    let questionTitle: String
    let titleSlug: String
    let question: String
    let difficulty: String
    let exampleTestcases: String
}

private struct OfficialSolutionAPIResponse: Codable {
    let content: String?
}

private struct LeetCodeGraphQLRequest: Encodable {
    let operationName: String
    let variables: [String: String]
    let query: String
}

private struct LeetCodeGraphQLResponse: Decodable {
    let data: LeetCodeQuestionData
    let errors: [LeetCodeGraphQLError]?
}

private struct LeetCodeQuestionData: Decodable {
    let question: LeetCodeQuestion?
}

private struct LeetCodeQuestion: Decodable {
    let questionFrontendId: String
    let title: String
    let titleSlug: String
    let content: String
    let difficulty: String
    let sampleTestCase: String
    let isPaidOnly: Bool
}

private struct LeetCodeGraphQLError: Decodable {
    let message: String
}
