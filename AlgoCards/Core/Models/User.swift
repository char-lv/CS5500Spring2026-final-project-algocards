//
//  User.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var userName: String
    var email: String
    var profilePicURL: String?
    var score: Int
    var solvedProblemIds: [String]
    var commentIds: [String]

    init(id: String? = nil, userName: String, email: String) {
        self.id = id
        self.userName = userName
        self.email = email
        self.profilePicURL = nil
        self.score = 0
        self.solvedProblemIds = []
        self.commentIds = []
    }


    var solvedCount: Int { solvedProblemIds.count }
    var hasProfilePic: Bool {
        guard let url = profilePicURL else { return false }
        return !url.isEmpty
    }

    enum CodingKeys: String, CodingKey {
        case id, userName, email, profilePicURL
        case score, solvedProblemIds, commentIds
    }
}
