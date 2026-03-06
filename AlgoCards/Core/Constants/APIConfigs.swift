//
//  APIConfigs.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation

// Difficulty Filter
enum DifficultyFilter: String {
    case easy   = "EASY"
    case medium = "MEDIUM"
    case hard   = "HARD"
}

enum APIConfigs {

    static let baseURL = "https://alfa-leetcode-api.onrender.com"

    // Problem Categories
    enum Category: String, CaseIterable {
        case array         = "array"
        case string        = "string"
        case slidingWindow = "sliding-window"
        case twoPointers   = "two-pointers"
        case tree          = "tree"
        case graph         = "graph"
        case stack         = "stack"
        case queue         = "queue"

        var displayName: String {
            switch self {
            case .array:         return "Array"
            case .string:        return "String"
            case .slidingWindow: return "Sliding Window"
            case .twoPointers:   return "Two Pointers"
            case .tree:          return "Tree"
            case .graph:         return "Graph"
            case .stack:         return "Stack"
            case .queue:         return "Queue"
            }
        }
        var icon: String {
            switch self {
            case .array:         return "🔢"
            case .string:        return "🔤"
            case .slidingWindow: return "🪟"
            case .twoPointers:   return "2️⃣"
            case .tree:          return "🌲"
            case .graph:         return "🕸️"
            case .stack:         return "📚"
            case .queue:         return "🚶"
            }
        }
    }
    
    static func problemListURL(
            tags: [Category] = [],
            difficulty: DifficultyFilter? = nil,
            limit: Int = 50,
            skip: Int = 0
        ) -> URL? {
            var components = URLComponents(string: "\(baseURL)/problems")
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "skip",  value: "\(skip)")
            ]
            if !tags.isEmpty {
                let tagString = tags.map { $0.rawValue }.joined(separator: "+")
                queryItems.append(URLQueryItem(name: "tags", value: tagString))
            }
            if let difficulty = difficulty {
                queryItems.append(URLQueryItem(name: "difficulty", value: difficulty.rawValue))
            }
            components?.queryItems = queryItems
            return components?.url
        }

        static func problemDetailURL(titleSlug: String) -> URL? {
            URL(string: "\(baseURL)/select?titleSlug=\(titleSlug)")
        }

        static func officialSolutionURL(titleSlug: String) -> URL? {
            URL(string: "\(baseURL)/officialSolution?titleSlug=\(titleSlug)")
        }

        static var dailyProblemURL: URL? {
            URL(string: "\(baseURL)/daily")
        }

        // MARK: - AI
        // static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"
    }
