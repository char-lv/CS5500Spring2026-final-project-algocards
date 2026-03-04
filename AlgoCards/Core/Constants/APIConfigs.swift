//
//  APIConfigs.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation

enum APIConfigs {

    // Base
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

        var url: URL? {
            URL(string: "\(APIConfigs.baseURL)/problems?tags=\(rawValue)&limit=50")
        }
    }

    // Problem Detail
    static func problemDetailURL(titleSlug: String) -> URL? {
        URL(string: "\(baseURL)/select?titleSlug=\(titleSlug)")
    }

    // MARK: - AI
    // static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"
}
