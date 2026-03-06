//
//  AuthService.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation

// TODO: Implement in feature/auth branch
class AuthService {
    static let shared = AuthService()
    private init() {}

    var currentUserId: String? { return nil }
    var isLoggedIn: Bool { return false }
}
