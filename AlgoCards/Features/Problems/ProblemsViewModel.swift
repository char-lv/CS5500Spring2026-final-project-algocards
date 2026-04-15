//
//  ProblemsViewModel.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation

class ProblemsViewModel {

    private var allProblems: [ProblemListItem] = []
    var filteredProblems: [ProblemListItem] = []
    var solvedProblemIds: [String] = []
    var selectedDifficulty: DifficultyFilter? = nil
    var isLoading = false


    var onProblemsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    // Inject pre-fetched problems (used by Profile review lists)
    func setPreloadedProblems(_ problems: [ProblemListItem]) {
        isLoading = false
        allProblems = problems
        applyDifficultyFilter(nil)
    }

    // Fetch from database
    func loadProblems(listTag: String, difficulty: DifficultyFilter? = nil) {
        selectedDifficulty = difficulty
        isLoading = true
        onProblemsUpdated?()

        if listTag == ProblemDeckConfig.favoritesTag {
            loadFavoriteProblems(difficulty: difficulty)
            return
        }

        FirestoreService.shared.fetchProblems(listTag: listTag) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let problems):
                    self?.allProblems = problems
                    self?.applyDifficultyFilter(difficulty)
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    private func loadFavoriteProblems(difficulty: DifficultyFilter?) {
        guard let userId = AuthService.shared.currentUserId else {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.allProblems = []
                self?.applyDifficultyFilter(difficulty)
            }
            return
        }

        FirestoreService.shared.fetchLikedProblemIds(userId: userId) { [weak self] result in
            switch result {
            case .success(let ids):
                FirestoreService.shared.fetchProblems(frontendIds: ids) { nestedResult in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        switch nestedResult {
                        case .success(let problems):
                            self?.allProblems = problems
                            self?.applyDifficultyFilter(difficulty)
                        case .failure(let error):
                            self?.onError?(error.localizedDescription)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    // Difficulty filter
    func applyDifficultyFilter(_ difficulty: DifficultyFilter?) {
        selectedDifficulty = difficulty
        if let difficulty = difficulty {
            filteredProblems = allProblems.filter {
                $0.difficulty.rawValue == difficulty.rawValue
            }
        } else {
            filteredProblems = allProblems
        }
        onProblemsUpdated?()
    }

    // Load solved problems
    func loadSolvedProblems() {
        guard let userId = AuthService.shared.currentUserId else { return }
        FirestoreService.shared.fetchUser(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    self?.solvedProblemIds = user.solvedProblemIds
                    self?.onProblemsUpdated?()
                }
            }
        }
    }

    // Search
    func search(query: String) {
        let base = selectedDifficulty == nil ? allProblems : allProblems.filter {
            $0.difficulty.rawValue == selectedDifficulty!.rawValue
        }
        if query.isEmpty {
            filteredProblems = base
        } else {
            filteredProblems = base.filter {
                $0.title.lowercased().contains(query.lowercased()) ||
                $0.id.contains(query)
            }
        }
        onProblemsUpdated?()
    }

    func isSolved(_ problemId: String) -> Bool {
        solvedProblemIds.contains(problemId)
    }

    var solvedCount: Int {
        let solvedSet = Set(solvedProblemIds)
        return allProblems.filter { solvedSet.contains($0.id) }.count
    }
    var totalCount: Int { allProblems.count }
}
