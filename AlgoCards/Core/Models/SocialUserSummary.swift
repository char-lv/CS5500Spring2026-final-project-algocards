//
//  SocialUserSummary.swift
//  AlgoCards
//

import Foundation

struct SocialUserSummary: Identifiable {
    let id: String
    let userName: String
    let score: Int
    let solvedCount: Int
    let likedCount: Int
    let likedCollectionLikeCount: Int
    let profilePicURL: String?

    var initials: String {
        let words = userName.split(separator: " ").prefix(2)
        let value = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        return value.isEmpty ? "?" : value
    }
}
