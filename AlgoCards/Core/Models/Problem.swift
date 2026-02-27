//
//  Problem.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
//

import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"

    var starCount: Int {
        switch self {
        case .easy:   return 1
        case .medium: return 2
        case .hard:   return 3
        }
    }

    var estimatedTime: String {
        switch self {
        case .easy:   return "30 min"
        case .medium: return "40 min"
        case .hard:   return "50 min"
        }
    }

    var colorName: String {
        switch self {
        case .easy:   return "DifficultyEasy"
        case .medium: return "DifficultyMedium"
        case .hard:   return "DifficultyHard"
        }
    }
}

struct ProblemListItem: Codable, Identifiable {
    let id: String
    let title: String
    let titleSlug: String
    let difficulty: Difficulty

    enum CodingKeys: String, CodingKey {
        case id = "questionFrontendId"
        case title, titleSlug, difficulty
    }
}

struct Problem: Codable, Identifiable {
    let id: String
    let title: String
    let titleSlug: String
    let difficulty: Difficulty
    let description: String
    let exampleTestcases: String
    var hint: String?
    var aiExplanation: String?

    var leetcodeURL: URL? {
        URL(string: "https://leetcode.com/problems/\(titleSlug)/")
    }

    enum CodingKeys: String, CodingKey {
        case id = "questionFrontendId"
        case title, titleSlug, difficulty, description
        case exampleTestcases, hint, aiExplanation
    }
}
