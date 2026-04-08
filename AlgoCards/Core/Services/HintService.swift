//
//  HintService.swift
//  AlgoCards
//

import Foundation

/// Manages hint retrieval with a two-level cache: in-memory then Firestore.
///
/// V1 behavior: if no cached hints exist in Firestore, returns static placeholder hints
/// without writing anything to the database.
///
/// V2 behavior (not yet implemented): if no cache exists, call Claude to generate 3 hints,
/// save them via FirestoreService.saveHints(_:for:), then return the result.
final class HintService {

    static let shared = HintService()
    private init() {}

    /// In-memory cache keyed by questionFrontendId.
    /// Avoids repeated Firestore reads for the same problem within a single session.
    private var memoryCache: [String: [String]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.algocards.hintservice.cache")

    /// Returns 3 hints for the given problem ID.
    /// Resolution order: in-memory cache → Firestore → placeholder fallback.
    /// Always calls completion on the main thread.
    func getHints(for problemId: String, completion: @escaping ([String]) -> Void) {
        // 1. In-memory cache hit — no Firestore round-trip needed.
        if let cached = cacheQueue.sync(execute: { memoryCache[problemId] }) {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // 2. Try Firestore.
        FirestoreService.shared.fetchHints(problemId: problemId) { [weak self] result in
            guard let self else { return }

            if case .success(let hints) = result, let hints, hints.count == 3 {
                // Valid cache found — store in memory and return.
                self.cacheQueue.async { self.memoryCache[problemId] = hints }
                DispatchQueue.main.async { completion(hints) }
            } else {
                // No valid cache (missing document, wrong count, or network error).
                // V2: replace this branch with Claude API call + saveHints().
                DispatchQueue.main.async { completion(HintService.placeholderHints) }
            }
        }
    }

    /// V1 placeholder hints shown when no cached hints exist.
    /// Replaced with Claude-generated content once V2 is implemented.
    private static let placeholderHints = [
        "Think about which data structure best supports the operations this problem requires.",
        "Consider the time and space trade-offs. Can you reduce the problem to a known pattern?",
        "Try mapping this to sliding window, two pointers, or a recursive sub-problem structure."
    ]
}
