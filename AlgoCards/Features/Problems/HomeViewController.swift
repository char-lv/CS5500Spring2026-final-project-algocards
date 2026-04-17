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

    private var currentRecommendations: [PersonalizedRecommendation] = []
    private var isRecommendationLoading = false
    private var shownRecommendationIds = Set<String>()

    private var isDailyLoading = false
    private weak var dailyCardButton: UIButton?
    private var hasAnimatedIn = false

    private let curatedGridContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let categoryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
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
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 12
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

    private let questionListStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let startAllButton: UIButton = {
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trophy"),
            style: .plain,
            target: self,
            action: #selector(leaderboardTapped)
        )

        startAllButton.addTarget(
            self,
            action: #selector(startAllRecommendationsTapped),
            for: .touchUpInside
        )
        recommendationRetryButton.addTarget(
            self,
            action: #selector(refreshRecommendationTapped),
            for: .touchUpInside
        )
        loadAvailableDecks()
        loadRecommendation()
        subtitleLabel.text = makeGreeting()
        contentStack.arrangedSubviews.forEach { $0.alpha = 0 }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true
        animateSectionsIn()
    }

    // MARK: - Press Animations

    @objc private func cardPressDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }

    @objc private func cardPressUp(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.28, delay: 0,
            usingSpringWithDamping: 0.68, initialSpringVelocity: 0.6,
            options: .allowUserInteraction
        ) {
            sender.transform = .identity
        }
    }

    @objc private func chipPressDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.10) {
            sender.superview?.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }
    }

    @objc private func chipPressUp(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.25, delay: 0,
            usingSpringWithDamping: 0.70, initialSpringVelocity: 0.5,
            options: .allowUserInteraction
        ) {
            sender.superview?.transform = .identity
        }
    }

    @objc private func leaderboardTapped() {
        navigationController?.pushViewController(LeaderboardViewController(), animated: true)
    }

    @objc private func refreshRecommendationTapped() {
        loadRecommendation(force: true)
    }

    @objc private func startAllRecommendationsTapped() {
        guard !currentRecommendations.isEmpty else { return }
        let vc = FlashCardViewController(problems: currentRecommendations.map { $0.problem }, currentIndex: 0)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func questionRowTapped(_ sender: UIButton) {
        guard currentRecommendations.indices.contains(sender.tag) else { return }
        let problem = currentRecommendations[sender.tag].problem
        let vc = FlashCardViewController(problems: [problem], currentIndex: 0)
        navigationController?.pushViewController(vc, animated: true)
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
        recommendationCard.addSubview(questionListStack)
        recommendationCard.addSubview(startAllButton)
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

            questionListStack.topAnchor.constraint(equalTo: recommendationHeadlineLabel.bottomAnchor, constant: 12),
            questionListStack.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor),
            questionListStack.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor),

            startAllButton.topAnchor.constraint(equalTo: questionListStack.bottomAnchor, constant: 16),
            startAllButton.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 18),
            startAllButton.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -18),
            startAllButton.heightAnchor.constraint(equalToConstant: 46),

            recommendationRetryButton.topAnchor.constraint(equalTo: startAllButton.bottomAnchor, constant: 10),
            recommendationRetryButton.centerXAnchor.constraint(equalTo: recommendationCard.centerXAnchor),
            recommendationRetryButton.bottomAnchor.constraint(equalTo: recommendationCard.bottomAnchor, constant: -16),
        ])

        renderRecommendationLoadingState()
        return recommendationCard
    }

    private func makeQuestionRow(rank: Int, recommendation: PersonalizedRecommendation, index: Int) -> UIView {
        let container = UIButton(type: .system)
        container.tag = index
        container.addTarget(self, action: #selector(questionRowTapped(_:)), for: .touchUpInside)
        container.translatesAutoresizingMaskIntoConstraints = false

        let rankLabel = UILabel()
        rankLabel.text = "\(rank)"
        rankLabel.font = UIFont.boldSystemFont(ofSize: 13)
        rankLabel.textColor = .tertiaryLabel
        rankLabel.textAlignment = .center
        rankLabel.isUserInteractionEnabled = false
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.widthAnchor.constraint(equalToConstant: 28).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "#\(recommendation.problem.id) \(recommendation.problem.title)"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.isUserInteractionEnabled = false

        let difficulty = recommendation.problem.difficulty
        let diffLabel = UILabel()
        diffLabel.text = difficulty.rawValue
        diffLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        diffLabel.textAlignment = .center
        diffLabel.layer.cornerRadius = 6
        diffLabel.clipsToBounds = true
        diffLabel.isUserInteractionEnabled = false
        diffLabel.translatesAutoresizingMaskIntoConstraints = false
        diffLabel.widthAnchor.constraint(equalToConstant: 54).isActive = true
        diffLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        switch difficulty {
        case .easy:
            diffLabel.textColor = .systemGreen
            diffLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        case .medium:
            diffLabel.textColor = .systemOrange
            diffLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        case .hard:
            diffLabel.textColor = .systemRed
            diffLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        }

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.isUserInteractionEnabled = false
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true

        let row = UIStackView(arrangedSubviews: [rankLabel, titleLabel, diffLabel, chevron])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(row)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 44),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func makeListSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return sep
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
        card.backgroundColor = item.color.withAlphaComponent(0.10)
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.07
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.layer.shadowRadius = 12
        card.tag = index
        card.addTarget(self, action: #selector(cardPressDown(_:)), for: .touchDown)
        card.addTarget(self, action: #selector(cardPressUp(_:)), for: [.touchUpOutside, .touchCancel])
        card.addTarget(self, action: #selector(curatedTapped(_:)), for: .touchUpInside)

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
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
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
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.heightAnchor.constraint(equalToConstant: 90).isActive = true
        renderCategoryChips()
        return categoryScrollView
    }

    private func renderCategoryChips() {
        categoryScrollView.subviews.forEach { $0.removeFromSuperview() }

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),
        ])

        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.spacing = 8
        row1.translatesAutoresizingMaskIntoConstraints = false

        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.spacing = 8
        row2.translatesAutoresizingMaskIntoConstraints = false

        categoryDecks.enumerated().forEach { index, item in
            let chip = makeCategoryChip(item, index: index)
            if index % 2 == 0 {
                row1.addArrangedSubview(chip)
            } else {
                row2.addArrangedSubview(chip)
            }
        }

        // Spacers absorb leftover horizontal space so chips stay at natural width
        let spacer1 = UIView()
        spacer1.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        row1.addArrangedSubview(spacer1)
        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        row2.addArrangedSubview(spacer2)

        let outerStack = UIStackView(arrangedSubviews: [row1, row2])
        outerStack.axis = .vertical
        outerStack.spacing = 10
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStack)

        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    private func makeCategoryChip(_ item: DeckCardItem, index: Int) -> UIView {
        // Use UIView as container so systemLayoutSizeFitting returns the correct
        // content-driven width (UIButton with no title reports 0 intrinsic width).
        let chip = UIView()
        chip.backgroundColor = item.color.withAlphaComponent(0.10)
        chip.layer.cornerRadius = 20
        chip.layer.borderWidth = 1
        chip.layer.borderColor = item.color.withAlphaComponent(0.30).cgColor
        chip.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = UIFont.systemFont(ofSize: 15)
        iconLabel.isUserInteractionEnabled = false

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = item.color
        titleLabel.isUserInteractionEnabled = false

        let row = UIStackView(arrangedSubviews: [iconLabel, titleLabel])
        row.axis = .horizontal
        row.spacing = 5
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(row)

        // Transparent button overlay handles taps without disrupting size calculation
        let btn = UIButton(type: .system)
        btn.tag = index
        btn.addTarget(self, action: #selector(chipPressDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(chipPressUp(_:)), for: [.touchUpOutside, .touchCancel])
        btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(btn)

        NSLayoutConstraint.activate([
            chip.heightAnchor.constraint(equalToConstant: 40),

            row.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -14),
            row.centerYAnchor.constraint(equalTo: chip.centerYAnchor),

            btn.topAnchor.constraint(equalTo: chip.topAnchor),
            btn.leadingAnchor.constraint(equalTo: chip.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: chip.trailingAnchor),
            btn.bottomAnchor.constraint(equalTo: chip.bottomAnchor),
        ])
        return chip
    }

    // MARK: - Daily Challenge

    private func makeDailyChallengeCard() -> UIView {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .systemBackground
        btn.layer.cornerRadius = 18
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.07
        btn.layer.shadowOffset = CGSize(width: 0, height: 3)
        btn.layer.shadowRadius = 12
        btn.addTarget(self, action: #selector(cardPressDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(cardPressUp(_:)), for: [.touchUpOutside, .touchCancel])
        btn.addTarget(self, action: #selector(dailyTapped), for: .touchUpInside)

        // Accent icon bubble
        let iconBubble = UIView()
        iconBubble.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.18)
        iconBubble.layer.cornerRadius = 14
        iconBubble.isUserInteractionEnabled = false
        iconBubble.translatesAutoresizingMaskIntoConstraints = false
        iconBubble.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconBubble.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let iconLabel = UILabel()
        iconLabel.text = "⚡"
        iconLabel.font = UIFont.systemFont(ofSize: 24)
        iconLabel.textAlignment = .center
        iconLabel.isUserInteractionEnabled = false
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconBubble.addSubview(iconLabel)
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: iconBubble.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconBubble.centerYAnchor),
        ])

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

        let row = UIStackView(arrangedSubviews: [iconBubble, textStack, UIView(), spinner])
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
        // Spring back
        if let btn = dailyCardButton {
            UIView.animate(
                withDuration: 0.28, delay: 0,
                usingSpringWithDamping: 0.68, initialSpringVelocity: 0.6,
                options: .allowUserInteraction
            ) { btn.transform = .identity }
        }
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
        // Spring back
        UIView.animate(
            withDuration: 0.28, delay: 0,
            usingSpringWithDamping: 0.68, initialSpringVelocity: 0.6,
            options: .allowUserInteraction
        ) { sender.transform = .identity }

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
        // Spring parent chip back
        UIView.animate(
            withDuration: 0.25, delay: 0,
            usingSpringWithDamping: 0.70, initialSpringVelocity: 0.5,
            options: .allowUserInteraction
        ) { sender.superview?.transform = .identity }

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
                    self.renderCategoryChips()
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
            icon: ProblemDeckConfig.icon(forListTag: tag),
            color: ProblemDeckConfig.color(forListTag: tag)
        )
    }

    private func clearArrangedSubviews(in stackView: UIStackView) {
        stackView.arrangedSubviews.forEach { subview in
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }

    private func loadRecommendation(force: Bool = false) {
        guard !isRecommendationLoading else { return }
        if !currentRecommendations.isEmpty && !force { return }

        isRecommendationLoading = true
        renderRecommendationLoadingState()

        recommendationService.generateRecommendations(
            excludingProblemIds: shownRecommendationIds
        ) { [weak self] result in
            guard let self else { return }
            self.isRecommendationLoading = false

            switch result {
            case .success(let recommendations):
                self.currentRecommendations = recommendations
                recommendations.forEach { self.shownRecommendationIds.insert($0.problem.id) }
                self.renderRecommendation(recommendations)
            case .failure(let error):
                self.currentRecommendations = []
                self.renderRecommendationError(error.localizedDescription)
            }
        }
    }

    private func renderRecommendationLoadingState() {
        recommendationSpinner.startAnimating()
        recommendationBadgeLabel.text = "ANALYZING"
        recommendationHeadlineLabel.text = "Curating your top 10 questions…"
        questionListStack.arrangedSubviews.forEach {
            questionListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        startAllButton.isHidden = true
        recommendationRetryButton.isHidden = true
    }

    private func renderRecommendation(_ recommendations: [PersonalizedRecommendation]) {
        recommendationSpinner.stopAnimating()

        let anyAI = recommendations.contains { $0.source == .ai }
        recommendationBadgeLabel.text = anyAI ? "AI GENERATED" : "PERSONALIZED PICKS"
        recommendationHeadlineLabel.text = "Your Top \(recommendations.count) Recommended Questions"

        questionListStack.arrangedSubviews.forEach {
            questionListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        recommendations.enumerated().forEach { index, rec in
            questionListStack.addArrangedSubview(makeQuestionRow(rank: index + 1, recommendation: rec, index: index))
            if index < recommendations.count - 1 {
                questionListStack.addArrangedSubview(makeListSeparator())
            }
        }

        startAllButton.isHidden = false
        startAllButton.setTitle("Start All \(recommendations.count) Questions", for: .normal)
        recommendationRetryButton.isHidden = false
    }

    private func renderRecommendationError(_ message: String) {
        recommendationSpinner.stopAnimating()
        recommendationBadgeLabel.text = "RECOMMENDATION"
        recommendationHeadlineLabel.text = "We couldn’t load your questions"
        questionListStack.arrangedSubviews.forEach {
            questionListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        startAllButton.isHidden = true
        recommendationRetryButton.isHidden = false
    }

    // MARK: - Entrance Animation

    private func animateSectionsIn() {
        contentStack.arrangedSubviews.enumerated().forEach { index, sectionView in
            sectionView.transform = CGAffineTransform(translationX: 0, y: 18)
            UIView.animate(
                withDuration: 0.52,
                delay: Double(index) * 0.08,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.2,
                options: [.allowUserInteraction],
                animations: {
                    sectionView.alpha = 1
                    sectionView.transform = .identity
                }
            )
        }
    }

    private func makeGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning — pick a deck or try your next question"
        case 12..<17: return "Good afternoon — pick a deck or try your next question"
        default:     return "Good evening — pick a deck or try your next question"
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
