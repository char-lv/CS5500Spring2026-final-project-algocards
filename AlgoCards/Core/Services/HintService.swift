//
//  HintService.swift
//  AlgoCards
//

import Foundation

/// Manages hint retrieval with cache-first resolution: in-memory, then Firestore, then Claude.
///
/// getHints(for problemId:)  — cache lookup only (in-memory → Firestore → placeholder).
/// getHints(for problem:)    — full V2 path: adds Claude generation and Firestore persistence
///                             when no valid cache exists.
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
            guard let self else { DispatchQueue.main.async { completion(HintService.placeholderHints) }; return }

            if case .success(let hints) = result, let hints, hints.count == 3 {
                // Valid cache found — store in memory and return.
                self.cacheQueue.async { self.memoryCache[problemId] = hints }
                DispatchQueue.main.async { completion(hints) }
            } else {
                // No valid cache. This overload does not generate hints.
                // Use getHints(for problem:) with ProblemListItem for Claude generation.
                DispatchQueue.main.async { completion(HintService.placeholderHints) }
            }
        }
    }

    /// Returns 3 hints for the given problem, with Claude generation as fallback.
    ///
    /// Resolution order:
    ///   1. In-memory cache
    ///   2. Firestore (first read)
    ///   3. Firestore (second read — double-check before generating, reduces duplicate Claude calls)
    ///   4. Claude generation via HintGenerator
    ///   5. Placeholder fallback if generation fails
    ///
    /// On successful generation: saves to Firestore and updates memory cache.
    /// On failed generation: returns placeholders without touching Firestore.
    /// Always calls completion on the main thread.
    func getHints(for problem: ProblemListItem, completion: @escaping ([String]) -> Void) {
        let problemId = problem.id

        // 1. Memory cache hit — fastest path, no network.
        if let cached = cacheQueue.sync(execute: { memoryCache[problemId] }) {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // 2. Firestore first read.
        FirestoreService.shared.fetchHints(problemId: problemId) { [weak self] result in
            guard let self else { DispatchQueue.main.async { completion(HintService.placeholderHints) }; return }

            if case .success(let hints) = result, let hints, hints.count == 3 {
                self.cacheQueue.async { self.memoryCache[problemId] = hints }
                DispatchQueue.main.async { completion(hints) }
                return
            }

            // 3. Double-check Firestore before generating.
            //    Captures the case where another device just finished writing
            //    between our first read and now.
            FirestoreService.shared.fetchHints(problemId: problemId) { [weak self] secondResult in
                guard let self else { DispatchQueue.main.async { completion(HintService.placeholderHints) }; return }

                if case .success(let hints) = secondResult, let hints, hints.count == 3 {
                    self.cacheQueue.async { self.memoryCache[problemId] = hints }
                    DispatchQueue.main.async { completion(hints) }
                    return
                }

                // 4. No cache found — generate with Claude.
                HintGenerator.shared.generateHints(for: problem) { [weak self] genResult in
                    guard let self else { DispatchQueue.main.async { completion(HintService.placeholderHints) }; return }

                    switch genResult {
                    case .success(let generatedHints):
                        // Persist to Firestore so future requests skip generation.
                        FirestoreService.shared.saveHints(generatedHints, for: problemId)
                        self.cacheQueue.async { self.memoryCache[problemId] = generatedHints }
                        DispatchQueue.main.async { completion(generatedHints) }

                    case .failure:
                        // Generation failed — return placeholders.
                        // Do NOT write to Firestore: invalid/missing data must not pollute the cache.
                        DispatchQueue.main.async { completion(HintService.placeholderHints) }
                    }
                }
            }
        }
    }

    /// Fallback hints returned when Claude generation fails or is unavailable.
    /// Never written to Firestore — only used as a temporary in-session fallback.
    private static let placeholderHints = [
        "Think about which data structure best supports the operations this problem requires.",
        "Consider the time and space trade-offs. Can you reduce the problem to a known pattern?",
        "Try mapping this to sliding window, two pointers, or a recursive sub-problem structure."
    ]
}
