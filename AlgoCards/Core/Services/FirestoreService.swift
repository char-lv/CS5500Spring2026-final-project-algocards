//
//  FirestoreService.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

// TODO: Implement in feature/auth branch

import Foundation
import FirebaseFirestore

struct ProblemListTagStat {
    let tag: String
    let count: Int
}

class FirestoreService {
    
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // Collection References
    private var usersRef: CollectionReference { db.collection("users") }
    private var problemsRef: CollectionReference { db.collection("problems") }
    private var submissionsRef: CollectionReference { db.collection("submissions") }
    private var commentsRef: CollectionReference { db.collection("comments") }

    // Problems
    func fetchProblems(
        listTag: String,
        completion: @escaping (Result<[ProblemListItem], Error>) -> Void
    ) {
        problemsRef
            .whereField("listTags", arrayContains: listTag)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let problems = snapshot?.documents.compactMap { doc -> ProblemListItem? in
                    self.makeProblemCatalogItem(from: doc.data())?.problem
                } ?? []

                let sorted = problems.sorted {
                    (Int($0.id) ?? 0) < (Int($1.id) ?? 0)
                }
                completion(.success(sorted))
            }
    }

    func fetchAllProblemCatalogItems(
        completion: @escaping (Result<[ProblemCatalogItem], Error>) -> Void
    ) {
        problemsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let items = snapshot?.documents.compactMap { doc -> ProblemCatalogItem? in
                self.makeProblemCatalogItem(from: doc.data())
            } ?? []

            let sorted = items.sorted {
                (Int($0.problem.id) ?? 0) < (Int($1.problem.id) ?? 0)
            }
            completion(.success(sorted))
        }
    }

    func fetchAvailableListTags(
        completion: @escaping (Result<[ProblemListTagStat], Error>) -> Void
    ) {
        problemsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var counts: [String: Int] = [:]

            snapshot?.documents.forEach { document in
                let tags = document.data()["listTags"] as? [String] ?? []
                tags.forEach { tag in
                    let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    guard !normalizedTag.isEmpty else { return }
                    counts[normalizedTag, default: 0] += 1
                }
            }

            let stats = counts.map { ProblemListTagStat(tag: $0.key, count: $0.value) }
                .sorted { lhs, rhs in
                    if lhs.count == rhs.count {
                        return lhs.tag < rhs.tag
                    }
                    return lhs.count > rhs.count
                }

            completion(.success(stats))
        }
    }
    
    // Practice
    func saveAnswer(_ answer: Answer, userId: String, completion: @escaping (Error?) -> Void) {
        // document ID = userId_problemId，one answer for one problem
        let docId = "\(userId)_\(answer.problemId)"
        do {
            try submissionsRef.document(docId).setData(from: answer, merge: true) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func fetchAnswer(userId: String, problemId: String, completion: @escaping (Result<Answer, Error>) -> Void) {
        let docId = "\(userId)_\(problemId)"
        submissionsRef.document(docId).getDocument(as: Answer.self) { result in
            completion(result)
        }
    }

    // User
    func createUser(_ user: User, completion: @escaping (Error?) -> Void) {
        guard let uid = user.id else { return }
        do {
            try usersRef.document(uid).setData(from: user) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        usersRef.document(userId).getDocument(as: User.self) { result in
            completion(result)
        }
    }

    func updateUserName(userId: String, newName: String, completion: @escaping (Error?) -> Void) {
        usersRef.document(userId).updateData(["userName": newName]) { error in
            completion(error)
        }
    }

    func fetchAIRecommendationUsage(
        userId: String,
        completion: @escaping (Result<AIRecommendationUsageState, Error>) -> Void
    ) {
        usersRef.document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let data = snapshot?.data() ?? [:]
            let usageState = AIRecommendationUsageState(
                dateKey: data["aiRecommendationUsageDate"] as? String,
                count: data["aiRecommendationUsageCount"] as? Int ?? 0
            )
            completion(.success(usageState))
        }
    }

    func recordAIRecommendationUsage(
        userId: String,
        dateKey: String,
        completion: @escaping (Error?) -> Void
    ) {
        let userDoc = usersRef.document(userId)

        db.runTransaction({ transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(userDoc)
                let data = snapshot.data() ?? [:]
                let previousDate = data["aiRecommendationUsageDate"] as? String
                let previousCount = data["aiRecommendationUsageCount"] as? Int ?? 0
                let nextCount = previousDate == dateKey ? previousCount + 1 : 1

                transaction.setData([
                    "aiRecommendationUsageDate": dateKey,
                    "aiRecommendationUsageCount": nextCount
                ], forDocument: userDoc, merge: true)
            } catch {
                errorPointer?.pointee = error as NSError
            }

            return nil
        }) { _, error in
            completion(error)
        }
    }

    // Solved Problems
    func markProblemSolved(
        userId: String,
        problemId: String,
        completion: @escaping (Error?) -> Void
    ) {
        let userDoc = usersRef.document(userId)
        userDoc.getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            let solvedIds = snapshot?.data()?["solvedProblemIds"] as? [String] ?? []
            guard !solvedIds.contains(problemId) else {
                // Already solved — no score change, treat as success.
                completion(nil)
                return
            }
            userDoc.updateData([
                "solvedProblemIds": FieldValue.arrayUnion([problemId]),
                "score": FieldValue.increment(Int64(10))
            ]) { error in
                completion(error)
            }
        }
    }

    // Liked Problems
    func fetchLikedProblemIds(userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        usersRef.document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let ids = snapshot?.data()?["likedProblemIds"] as? [String] ?? []
            completion(.success(ids))
        }
    }

    func setLikeProblem(userId: String, problemId: String, liked: Bool, completion: @escaping (Error?) -> Void) {
        usersRef.document(userId).updateData([
            "likedProblemIds": liked
                ? FieldValue.arrayUnion([problemId])
                : FieldValue.arrayRemove([problemId])
        ]) { error in
            completion(error)
        }
    }

    // Submissions
    func saveSubmission(_ answer: Answer, completion: @escaping (Error?) -> Void) {
        do {
            _ = try submissionsRef.addDocument(from: answer) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func fetchSubmissions(
        userId: String,
        completion: @escaping (Result<[Answer], Error>) -> Void
    ) {
        submissionsRef
            .whereField("userId", isEqualTo: userId)
            .order(by: "submittedAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let answers = snapshot?.documents.compactMap {
                    try? $0.data(as: Answer.self)
                } ?? []
                completion(.success(answers))
            }
    }

    // Leaderboard
    func fetchLeaderboard(completion: @escaping (Result<[User], Error>) -> Void) {
        usersRef
            .order(by: "score", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let users = snapshot?.documents.compactMap {
                    try? $0.data(as: User.self)
                } ?? []
                completion(.success(users))
            }
    }

    // Comments
    func fetchComments(
        problemId: String,
        completion: @escaping (Result<[Comment], Error>) -> Void
    ) {
        commentsRef
            .whereField("problemId", isEqualTo: problemId)
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let comments = snapshot?.documents.compactMap {
                    try? $0.data(as: Comment.self)
                } ?? []
                completion(.success(comments))
            }
    }

    func postComment(_ comment: Comment, completion: @escaping (Error?) -> Void) {
        do {
            _ = try commentsRef.addDocument(from: comment) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    private func makeProblemCatalogItem(from data: [String: Any]) -> ProblemCatalogItem? {
        guard
            let id = data["questionFrontendId"] as? String,
            let title = data["title"] as? String,
            let titleSlug = data["titleSlug"] as? String,
            let diffStr = data["difficulty"] as? String,
            let difficulty = Difficulty(rawValue: diffStr),
            let acRate = data["acRate"] as? Double,
            let isPaidOnly = data["isPaidOnly"] as? Bool,
            let hasSolution = data["hasSolution"] as? Bool
        else { return nil }

        let listTags = data["listTags"] as? [String] ?? []
        let problem = ProblemListItem(
            id: id,
            title: title,
            titleSlug: titleSlug,
            difficulty: difficulty,
            acRate: acRate,
            isPaidOnly: isPaidOnly,
            hasSolution: hasSolution,
            topicTags: []
        )

        return ProblemCatalogItem(problem: problem, listTags: listTags)
    }
}
