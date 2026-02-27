//
//  Answer.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
//

import Foundation

struct Answer: Codable {
    let problemId: String
    var code: String
    var isCompleted: Bool
    var submittedAt: Date

    init(problemId: String, code: String, isCompleted: Bool = false) {
        self.problemId = problemId
        self.code = code
        self.isCompleted = isCompleted
        self.submittedAt = Date()
    }
}
