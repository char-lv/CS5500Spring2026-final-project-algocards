//
//  Answer.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
//

import Foundation

struct Answer: Codable {
    let problemId: String
    let userId: String
    var notes: String
    var isCompleted: Bool
    var submittedAt: Date

    init(problemId: String, userId: String, notes: String, isCompleted: Bool = false) {
        self.problemId = problemId
        self.userId = userId
        self.notes = notes
        self.isCompleted = isCompleted
        self.submittedAt = Date()
    }
}
