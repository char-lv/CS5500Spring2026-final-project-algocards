//
//  NetworkManager.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation
import Alamofire

protocol NetworkServiceProtocol {
    func fetchProblems(category: APIConfigs.Category,
                       completion: @escaping (Result<[ProblemListItem], NetworkError>) -> Void)
    func fetchProblemDetail(titleSlug: String,
                            completion: @escaping (Result<Problem, NetworkError>) -> Void)
}

// Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case premiumQuestion
    case decodingFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "Invalid URL."
        case .premiumQuestion:   return "This is a premium problem and cannot be loaded."
        case .decodingFailed:    return "Failed to decode server response."
        case .serverError(let msg): return msg
        }
    }
}

// NetworkManager
class NetworkManager: NetworkServiceProtocol {

    static let shared = NetworkManager()
    private init() {}

    // Fetch Problem List by Category
    func fetchProblems(
        category: APIConfigs.Category,
        completion: @escaping (Result<[ProblemListItem], NetworkError>) -> Void
    ) {
        guard let url = category.url else {
            completion(.failure(.invalidURL))
            return
        }

        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: ProblemsAPIResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    completion(.success(apiResponse.problemsetQuestionList))
                case .failure:
                    completion(.failure(.decodingFailed))
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
                    // check if it is a premium q（description is empty）
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
}

private struct ProblemsAPIResponse: Codable {
    let problemsetQuestionList: [ProblemListItem]
}

private struct ProblemAPIResponse: Codable {
    let questionId: String
    let questionTitle: String
    let titleSlug: String
    let question: String        // HTML description
    let difficulty: String
    let exampleTestcases: String
}
