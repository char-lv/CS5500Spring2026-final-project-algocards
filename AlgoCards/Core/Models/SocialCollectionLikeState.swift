//
//  SocialCollectionLikeState.swift
//  AlgoCards
//

import Foundation

struct SocialCollectionLikeState {
    let ownerUserId: String
    let viewerUserId: String?
    let likeCount: Int
    let isLikedByViewer: Bool
}
