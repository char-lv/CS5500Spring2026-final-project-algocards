//
//  LegacyMirrorConfig.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/25/26.
//

import Foundation

enum LegacyMirrorConfig {
    static let baseURL = "https://alfa-leetcode-api.onrender.com"

    static func problemDetailURL(titleSlug: String) -> URL? {
        URL(string: "\(baseURL)/select?titleSlug=\(titleSlug)")
    }

    static func officialSolutionURL(titleSlug: String) -> URL? {
        URL(string: "\(baseURL)/officialSolution?titleSlug=\(titleSlug)")
    }

    static var dailyProblemURL: URL? {
        URL(string: "\(baseURL)/daily")
    }
}
