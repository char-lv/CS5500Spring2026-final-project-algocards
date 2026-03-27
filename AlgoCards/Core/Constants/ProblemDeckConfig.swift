//
//  ProblemDeckConfig.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation
import UIKit

enum DifficultyFilter: String {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"
}

enum ProblemDeckConfig {

    static let favoritesTag = "favorites"
    static let curatedHomeTags = [favoritesTag, "blind75", "hot100", "interview150"]
    static let featuredHomeCategoryTags = [
        "array",
        "string",
        "linked-list",
        "dynamic-programming",
        "tree",
        "graph",
        "binary-search",
        "sliding-window",
        "two-pointers",
        "stack",
        "queue"
    ]

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

    static func displayName(forListTag tag: String) -> String {
        if let category = Category(rawValue: tag) {
            return category.displayName
        }

        switch tag {
        case favoritesTag:
            return "Favorites"
        case "blind75":
            return "Blind 75"
        case "hot100":
            return "Hot 100"
        case "interview150":
            return "Interview 150"
        default:
            return tag
                .split(separator: "-")
                .map { $0.capitalized }
                .joined(separator: " ")
        }
    }

    static func icon(forListTag tag: String) -> String {
        switch tag {
        case favoritesTag:          return "❤️"
        case "blind75":             return "🎯"
        case "hot100":              return "🔥"
        case "interview150":        return "💼"
        case "array":               return "🔢"
        case "string":              return "🔤"
        case "sliding-window":      return "🪟"
        case "two-pointers":        return "2️⃣"
        case "tree":                return "🌲"
        case "graph":               return "🕸️"
        case "stack":               return "📚"
        case "queue":               return "🚶"
        case "linked-list":         return "🔗"
        case "dynamic-programming": return "🧠"
        case "binary-search":       return "🧭"
        case "hash-table":          return "#️⃣"
        case "heap-priority-queue": return "⛰️"
        case "backtracking":        return "🧩"
        case "math":                return "➗"
        case "recursion":           return "🔁"
        default:                    return "🏷️"
        }
    }

    static func color(forListTag tag: String) -> UIColor {
        switch tag {
        case favoritesTag:          return .systemPink
        case "blind75":             return .systemPurple
        case "hot100":              return .systemRed
        case "interview150":        return .systemBlue
        case "array":               return .systemBlue
        case "string":              return .systemIndigo
        case "sliding-window":      return .systemTeal
        case "two-pointers":        return .systemMint
        case "tree":                return .systemGreen
        case "graph":               return .systemCyan
        case "stack":               return .systemOrange
        case "queue":               return .systemBrown
        case "linked-list":         return .systemPink
        case "dynamic-programming": return .systemPurple
        case "binary-search":       return .systemBlue
        case "hash-table":          return .systemYellow
        case "heap-priority-queue": return .systemOrange
        case "backtracking":        return .systemIndigo
        case "math":                return .systemTeal
        case "recursion":           return .systemPink
        default:                    return .systemGray
        }
    }
}
