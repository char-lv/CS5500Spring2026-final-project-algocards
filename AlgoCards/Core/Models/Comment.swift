//
//  Comment.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
//

import Foundation
import FirebaseFirestore

struct Comment: Codable, Identifiable {
    @DocumentID var id: String?
    let problemId: String
    let text: String
    let userId: String
    let userName: String
    let createdAt: Date

    init(problemId: String, text: String, userId: String, userName: String) {
        self.problemId = problemId
        self.text = text
        self.userId = userId
        self.userName = userName
        self.createdAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, problemId, text, userId, userName, createdAt
    }
}
