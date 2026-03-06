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
        guard let url = APIConfigs.problemDetailURL(titleSlug: titleSlug) else {
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
                    completion(.success(problem))
                case .failure:
                    completion(.failure(.decodingFailed))
                }
            }
    }

    // Fetch Daily Problem
    func fetchDailyProblem(
        completion: @escaping (Result<Problem, NetworkError>) -> Void
    ) {
        guard let url = APIConfigs.dailyProblemURL else {
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
        guard let url = APIConfigs.officialSolutionURL(titleSlug: titleSlug) else {
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
