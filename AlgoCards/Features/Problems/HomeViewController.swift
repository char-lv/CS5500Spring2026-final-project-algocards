//
//  HomeViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/5/26.
//

import Foundation
import UIKit

class HomeViewController: UIViewController {

    private struct DeckCardItem {
        let title: String
        let tag: String
        let icon: String
        let color: UIColor
    }

    private let defaultCuratedDecks: [DeckCardItem] = [
        DeckCardItem(title: "Favorites", tag: ProblemDeckConfig.favoritesTag, icon: "❤️", color: .systemPink),
        DeckCardItem(title: "Blind 75", tag: "blind75", icon: "🎯", color: .systemPurple),
        DeckCardItem(title: "Hot 100", tag: "hot100", icon: "🔥", color: .systemRed),
        DeckCardItem(title: "Interview 150", tag: "interview150", icon: "💼", color: .systemBlue)
    ]
    private let recommendationService = RecommendationService.shared

    private lazy var curatedDecks: [DeckCardItem] = defaultCuratedDecks
    private lazy var categoryDecks: [DeckCardItem] = makeFallbackCategoryDecks()

    private var currentRecommendation: PersonalizedRecommendation?
    private var isRecommendationLoading = false
    private var shownRecommendationIds = Set<String>()

    private var isDailyLoading = false
    private weak var dailyCardButton: UIButton?

    private let curatedGridContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let categoryGridContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 24
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "AlgoCards"
        l.font = UIFont.boldSystemFont(ofSize: 32)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Pick a deck or jump into your next personalized question"
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0)
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.15).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let recommendationBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 11)
        l.textColor = .systemBlue
        l.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationHeadlineLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 20)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationProblemLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 16)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationMetaLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationReasonLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationActionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let recommendationRetryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Refresh Recommendation", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let recommendationSpinner: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = ""
        print("[HomeViewController] Loaded — current UID: \(AuthService.shared.currentUserId ?? "nil")")
        setupUI()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Sign Out",
            style: .plain,
            target: self,
            action: #selector(signOutTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trophy"),
            style: .plain,
            target: self,
            action: #selector(leaderboardTapped)
        )

        recommendationActionButton.addTarget(
            self,
            action: #selector(openRecommendationTapped),
            for: .touchUpInside
        )
        recommendationRetryButton.addTarget(
            self,
            action: #selector(refreshRecommendationTapped),
            for: .touchUpInside
        )
        loadAvailableDecks()
        loadRecommendation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @objc private func leaderboardTapped() {
        navigationController?.pushViewController(LeaderboardViewController(), animated: true)
    }

    @objc private func signOutTapped() {
        AuthService.shared.signOut()
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.showAuth()
    }

    @objc private func refreshRecommendationTapped() {
        loadRecommendation(force: true)
    }

    @objc private func openRecommendationTapped() {
        guard let recommendation = currentRecommendation else { return }
        let flashCardVC = FlashCardViewController(problems: [recommendation.problem], currentIndex: 0)
        navigationController?.pushViewController(flashCardVC, animated: true)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        buildHeader()

        // Daily Challenge
        buildSection(title: "⚡ Daily Challenge") {
            self.makeDailyChallengeCard()
        }

        // Curated Lists
        buildSection(title: "📚 Curated Lists") {
            self.buildCuratedSectionContent()
        }

        // Category
        buildSection(title: "🗂 By Category") {
            self.buildCategorySectionContent()
        }
        // AI Recommendation
        buildSection(title: "✨ AI Recommendation") { self.buildRecommendationCard() }
    }

    private func buildHeader() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        contentStack.addArrangedSubview(stack)
    }

    private func buildSection(title: String, content: () -> UIView) {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 12

        let label = UILabel()
        label.text = title
        label.font = UIFont.boldSystemFont(ofSize: 18)
        sectionStack.addArrangedSubview(label)
        sectionStack.addArrangedSubview(content())
        contentStack.addArrangedSubview(sectionStack)
    }

    private func buildRecommendationCard() -> UIView {
        recommendationCard.addSubview(recommendationBadgeLabel)
        recommendationCard.addSubview(recommendationHeadlineLabel)
        recommendationCard.addSubview(recommendationProblemLabel)
        recommendationCard.addSubview(recommendationMetaLabel)
        recommendationCard.addSubview(recommendationReasonLabel)
        recommendationCard.addSubview(recommendationActionButton)
        recommendationCard.addSubview(recommendationRetryButton)
        recommendationCard.addSubview(recommendationSpinner)

        NSLayoutConstraint.activate([
            recommendationBadgeLabel.topAnchor.constraint(equalTo: recommendationCard.topAnchor, constant: 18),
            recommendationBadgeLabel.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            recommendationBadgeLabel.heightAnchor.constraint(equalToConstant: 24),
            recommendationBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 118),

            recommendationSpinner.centerYAnchor.constraint(equalTo: recommendationBadgeLabel.centerYAnchor),
            recommendationSpinner.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),

            recommendationHeadlineLabel.topAnchor.constraint(equalTo: recommendationBadgeLabel.bottomAnchor, constant: 14),
            recommendationHeadlineLabel.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            recommendationHeadlineLabel.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),

            recommendationProblemLabel.topAnchor.constraint(equalTo: recommendationHeadlineLabel.bottomAnchor, constant: 10),
            recommendationProblemLabel.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            recommendationProblemLabel.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),

            recommendationMetaLabel.topAnchor.constraint(equalTo: recommendationProblemLabel.bottomAnchor, constant: 6),
            recommendationMetaLabel.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            recommendationMetaLabel.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),

            recommendationReasonLabel.topAnchor.constraint(equalTo: recommendationMetaLabel.bottomAnchor, constant: 10),
            recommendationReasonLabel.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            recommendationReasonLabel.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),

            recommendationActionButton.topAnchor.constraint(equalTo: recommendationReasonLabel.bottomAnchor, constant: 18),
            recommendationActionButton.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            recommendationActionButton.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),
            recommendationActionButton.heightAnchor.constraint(equalToConstant: 46),

            recommendationRetryButton.topAnchor.constraint(equalTo: recommendationActionButton.bottomAnchor, constant: 10),
            recommendationRetryButton.centerXAnchor.constraint(equalTo: recommendationCard.centerXAnchor),
            recommendationRetryButton.bottomAnchor.constraint(equalTo: recommendationCard.bottomAnchor, constant: -16),
        ])

        renderRecommendationLoadingState()
        return recommendationCard
    }

    private func buildCuratedSectionContent() -> UIView {
        renderCuratedGrid()
        return curatedGridContainer
    }

    private func renderCuratedGrid() {
        clearArrangedSubviews(in: curatedGridContainer)

        curatedDecks.chunked(into: 2).enumerated().forEach { rowIndex, row in
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually

            row.enumerated().forEach { offset, item in
                let absoluteIndex = (rowIndex * 2) + offset
                let card = makeCuratedCard(item, index: absoluteIndex)
                rowStack.addArrangedSubview(card)
            }

            if row.count == 1 {
                rowStack.addArrangedSubview(UIView())
            }

            curatedGridContainer.addArrangedSubview(rowStack)
        }
    }

    private func makeCuratedCard(
        _ item: DeckCardItem,
        index: Int
    ) -> UIView {
        let card = UIButton(type: .system)
        card.backgroundColor = item.color.withAlphaComponent(0.12)
        card.layer.cornerRadius = 16
        card.tag = index
        card.addTarget(self, action: #selector(curatedTapped(_:)), for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = UIFont.systemFont(ofSize: 32)

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = item.color
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        stack.addArrangedSubview(iconLabel)
        stack.addArrangedSubview(titleLabel)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        return card
    }

    private func buildCategorySectionContent() -> UIView {
        renderCategoryGrid()
        return categoryGridContainer
    }

    private func renderCategoryGrid() {
        clearArrangedSubviews(in: categoryGridContainer)

        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 12

        categoryDecks.chunked(into: 2).enumerated().forEach { rowIndex, row in
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually

            row.enumerated().forEach { offset, item in
                let absoluteIndex = (rowIndex * 2) + offset
                let card = makeCategoryCard(item, index: absoluteIndex)
                rowStack.addArrangedSubview(card)
            }

            if row.count == 1 {
                rowStack.addArrangedSubview(UIView())
            }

            outerStack.addArrangedSubview(rowStack)
        }

        categoryGridContainer.addArrangedSubview(outerStack)
    }

    private func makeCategoryCard(_ item: DeckCardItem, index: Int) -> UIView {
        let card = UIButton(type: .system)
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.tag = index
        card.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = UIFont.systemFont(ofSize: 28)

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        stack.addArrangedSubview(iconLabel)
        stack.addArrangedSubview(titleLabel)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 90),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        return card
    }

    // MARK: - Daily Challenge

    private func makeDailyChallengeCard() -> UIView {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.12)
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(dailyTapped), for: .touchUpInside)

        let iconLabel = UILabel()
        iconLabel.text = "⚡"
        iconLabel.font = UIFont.systemFont(ofSize: 28)
        iconLabel.isUserInteractionEnabled = false

        let titleLabel = UILabel()
        titleLabel.text = "Today's Challenge"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap to solve today's problem"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.tag = 42

        let row = UIStackView(arrangedSubviews: [iconLabel, textStack, UIView(), spinner])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        btn.addSubview(row)
        NSLayoutConstraint.activate([
            btn.heightAnchor.constraint(equalToConstant: 80),
            row.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
        ])

        dailyCardButton = btn
        return btn
    }

    @objc private func dailyTapped() {
        guard !isDailyLoading else { return }
        isDailyLoading = true
        dailyCardButton?.isEnabled = false
        (dailyCardButton?.viewWithTag(42) as? UIActivityIndicatorView)?.startAnimating()

        NetworkManager.shared.fetchDailyProblem { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isDailyLoading = false
                self.dailyCardButton?.isEnabled = true
                (self.dailyCardButton?.viewWithTag(42) as? UIActivityIndicatorView)?.stopAnimating()

                switch result {
                case .success(let problem):
                    let listItem = ProblemListItem(
                        id: problem.id,
                        title: problem.title,
                        titleSlug: problem.titleSlug,
                        difficulty: problem.difficulty,
                        acRate: 0.0,
                        isPaidOnly: false,
                        hasSolution: true,
                        topicTags: []
                    )
                    let vc = FlashCardViewController(problems: [listItem], currentIndex: 0)
                    self.navigationController?.pushViewController(vc, animated: true)
                case .failure:
                    self.showAlert(title: "Could not load daily problem",
                                   message: "Please check your connection and try again.")
                }
            }
        }
    }

    @objc private func curatedTapped(_ sender: UIButton) {
        guard curatedDecks.indices.contains(sender.tag) else { return }
        let item = curatedDecks[sender.tag]

        if item.tag == ProblemDeckConfig.favoritesTag,
           AuthService.shared.currentUserId == nil {
            showAlert(title: "Login Required",
                      message: "Log in to save favorite problems and review them here.")
            return
        }

        let vc = ProblemsViewController(listTag: item.tag, title: item.title)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        guard categoryDecks.indices.contains(sender.tag) else { return }
        let item = categoryDecks[sender.tag]
        let vc = ProblemsViewController(listTag: item.tag, title: item.title)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadAvailableDecks() {
        FirestoreService.shared.fetchAvailableListTags { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let stats):
                    let refreshedCuratedDecks = self.makeCuratedDecks(from: stats)
                    let refreshedCategoryDecks = self.makeAutoCategoryDecks(from: stats)

                    self.curatedDecks = refreshedCuratedDecks.isEmpty
                        ? self.defaultCuratedDecks
                        : refreshedCuratedDecks
                    self.categoryDecks = refreshedCategoryDecks.isEmpty
                        ? self.makeFallbackCategoryDecks()
                        : refreshedCategoryDecks

                    self.renderCuratedGrid()
                    self.renderCategoryGrid()
                case .failure(let error):
                    print("[HomeViewController] Failed to load available list tags: \(error.localizedDescription)")
                }
            }
        }
    }

    private func makeCuratedDecks(from stats: [ProblemListTagStat]) -> [DeckCardItem] {
        let countsByTag = Dictionary(uniqueKeysWithValues: stats.map { ($0.tag, $0.count) })

        return ProblemDeckConfig.curatedHomeTags.compactMap { tag in
            if tag == ProblemDeckConfig.favoritesTag {
                return makeDeckCardItem(for: tag)
            }
            guard countsByTag[tag, default: 0] > 0 else { return nil }
            return makeDeckCardItem(for: tag)
        }
    }

    private func makeAutoCategoryDecks(from stats: [ProblemListTagStat]) -> [DeckCardItem] {
        let excludedTags = Set(ProblemDeckConfig.curatedHomeTags)
        let eligibleStats = stats.filter { !excludedTags.contains($0.tag) && $0.count > 0 }
        let countsByTag = Dictionary(uniqueKeysWithValues: eligibleStats.map { ($0.tag, $0.count) })

        var orderedTags: [String] = []
        var seenTags = Set<String>()

        for tag in ProblemDeckConfig.featuredHomeCategoryTags where countsByTag[tag, default: 0] > 0 {
            if seenTags.insert(tag).inserted {
                orderedTags.append(tag)
            }
        }

        let trendingTags = eligibleStats
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return ProblemDeckConfig.displayName(forListTag: lhs.tag) < ProblemDeckConfig.displayName(forListTag: rhs.tag)
                }
                return lhs.count > rhs.count
            }
            .map(\.tag)

        for tag in trendingTags where seenTags.insert(tag).inserted {
            orderedTags.append(tag)
        }

        return Array(orderedTags.prefix(12)).map(makeDeckCardItem(for:))
    }

    private func makeFallbackCategoryDecks() -> [DeckCardItem] {
        ProblemDeckConfig.Category.allCases.map { makeDeckCardItem(for: $0.rawValue) }
    }

    private func makeDeckCardItem(for tag: String) -> DeckCardItem {
        DeckCardItem(
            title: ProblemDeckConfig.displayName(forListTag: tag),
            tag: tag,
            icon: icon(for: tag),
            color: color(for: tag)
        )
    }

    private func icon(for tag: String) -> String {
        switch tag {
        case ProblemDeckConfig.favoritesTag: return "❤️"
        case "blind75": return "🎯"
        case "hot100": return "🔥"
        case "interview150": return "💼"
        case "array": return "🔢"
        case "string": return "🔤"
        case "sliding-window": return "🪟"
        case "two-pointers": return "2️⃣"
        case "tree": return "🌲"
        case "graph": return "🕸️"
        case "stack": return "📚"
        case "queue": return "🚶"
        case "linked-list": return "🔗"
        case "dynamic-programming": return "🧠"
        case "binary-search": return "🧭"
        case "hash-table": return "#️⃣"
        case "heap-priority-queue": return "⛰️"
        case "backtracking": return "🧩"
        default: return "🏷️"
        }
    }

    private func color(for tag: String) -> UIColor {
        switch tag {
        case ProblemDeckConfig.favoritesTag: return .systemPink
        case "blind75": return .systemPurple
        case "hot100": return .systemRed
        case "interview150": return .systemBlue
        case "array": return .systemBlue
        case "string": return .systemIndigo
        case "sliding-window": return .systemTeal
        case "two-pointers": return .systemMint
        case "tree": return .systemGreen
        case "graph": return .systemCyan
        case "stack": return .systemOrange
        case "queue": return .systemBrown
        case "linked-list": return .systemPink
        case "dynamic-programming": return .systemPurple
        case "binary-search": return .systemBlue
        case "hash-table": return .systemYellow
        case "heap-priority-queue": return .systemOrange
        case "backtracking": return .systemIndigo
        default: return .systemGray
        }
    }

    private func clearArrangedSubviews(in stackView: UIStackView) {
        stackView.arrangedSubviews.forEach { subview in
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }

    private func loadRecommendation(force: Bool = false) {
        guard !isRecommendationLoading else { return }
        if currentRecommendation != nil && !force { return }

        isRecommendationLoading = true
        renderRecommendationLoadingState()

        recommendationService.generateRecommendation(
            excludingProblemIds: shownRecommendationIds
        ) { [weak self] result in
            guard let self else { return }
            self.isRecommendationLoading = false

            switch result {
            case .success(let recommendation):
                self.currentRecommendation = recommendation
                self.shownRecommendationIds.insert(recommendation.problem.id)
                self.renderRecommendation(recommendation)
            case .failure(let error):
                self.currentRecommendation = nil
                self.renderRecommendationError(error.localizedDescription)
            }
        }
    }

    private func renderRecommendationLoadingState() {
        recommendationSpinner.startAnimating()
        recommendationBadgeLabel.text = "ANALYZING"
        recommendationHeadlineLabel.text = "Finding your next best question"
        recommendationProblemLabel.text = "We’re ranking your top candidates and looking for a related unseen follow-up."
        recommendationMetaLabel.text = "Refresh manually when you want a new suggestion."
        recommendationReasonLabel.text = "Phase 2 uses AI to suggest a related unseen problem when available. After 10 AI recommendations in one day, the card automatically falls back to the Phase 1 personalized pick."
        recommendationActionButton.isHidden = true
        recommendationRetryButton.isHidden = true
    }

    private func renderRecommendation(_ recommendation: PersonalizedRecommendation) {
        recommendationSpinner.stopAnimating()
        recommendationBadgeLabel.text = recommendation.sourceBadgeText.uppercased()
        recommendationHeadlineLabel.text = recommendation.headline
        recommendationProblemLabel.text = "#\(recommendation.problem.id) \(recommendation.problem.title)"
        recommendationMetaLabel.text = "\(recommendation.problem.difficulty.rawValue) • Focus: \(recommendation.focusArea)"
        recommendationReasonLabel.text = recommendation.reason
        recommendationActionButton.isHidden = false
        recommendationRetryButton.isHidden = false
        recommendationActionButton.setTitle("Start \(recommendation.problem.title)", for: .normal)
    }

    private func renderRecommendationError(_ message: String) {
        recommendationSpinner.stopAnimating()
        recommendationBadgeLabel.text = "RECOMMENDATION"
        recommendationHeadlineLabel.text = "We couldn't load your next question"
        recommendationProblemLabel.text = "Your practice decks are still ready to use."
        recommendationMetaLabel.text = nil
        recommendationReasonLabel.text = message
        recommendationActionButton.isHidden = true
        recommendationRetryButton.isHidden = false
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
