//
//  FlashCardViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/5/26.
//

import UIKit

class FlashCardViewController: UIViewController {

    // MARK: - Data

    private let problems: [ProblemListItem]
    private var currentIndex: Int
    /// Guards against stale network responses when the user navigates before a fetch completes.
    private var loadToken = UUID()
    /// True after the first viewDidAppear fires. Prevents the help dialog and startTimer()
    /// from being re-triggered when returning from a child screen (e.g. AnswerViewController).
    private var hasAppearedOnce = false

    private var problem: ProblemListItem { problems[currentIndex] }

    private var isFlipped = false
    /// Loaded once on viewDidLoad and updated in-memory on every toggle.
    private var likedProblemIds = Set<String>()
    /// Passed in at init from the caller's already-loaded data; updated in-memory when the user marks a problem solved.
    private var solvedProblemIds: Set<String>

    // MARK: - Timer State
    private var countdownTimer: Timer?
    private var remainingSeconds = 0
    private static let timerDuration = 10 * 60  // V1: fixed 10-minute session

    // MARK: - Hint State
    /// Tracks how many hint levels the user has revealed for the current card.
    /// Reset to 0 whenever the user navigates to a different problem.
    private var hintLevel = 0
    /// Hints loaded for the current problem. Nil until the first HintService response.
    /// Reset to nil in loadCurrentProblem() so a new problem always fetches fresh hints.
    private var loadedHints: [String]?
    /// Stored reference to the hint bar button for enabling/disabling during async fetch.
    private var hintBarButton: UIBarButtonItem?

    // MARK: - Card UI

    private let cardContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let frontView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let frontBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 12)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let frontTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 20)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let frontScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let frontDescriptionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let frontHintLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap or shake to reveal solution 👆"
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let backView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 12
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "💡 Solution Approach"
        l.font = UIFont.boldSystemFont(ofSize: 20)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let backScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let backContentLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let backHintLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap or shake to go back 👆"
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let loadingView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private let loadingLabel: UILabel = {
        let l = UILabel()
        l.text = "Loading problem..."
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Tag Chips UI

    private let tagScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let tagStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// Stored so updateTagChips() can collapse the row to 0 when a problem has no topic tags.
    private var tagScrollViewHeightConstraint: NSLayoutConstraint?

    // MARK: - Timer UI

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Progress UI

    private let progressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
        pv.trackTintColor = .systemGray5
        pv.layer.cornerRadius = 2
        pv.clipsToBounds = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let progressLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Deck Navigation Buttons

    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: symbolConfig), for: .normal)
        btn.setTitle("  Prev", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.setTitleColor(.tertiaryLabel, for: .disabled)
        btn.tintColor = .secondaryLabel
        btn.backgroundColor = .systemGray6
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.right", withConfiguration: symbolConfig), for: .normal)
        btn.setTitle("Next  ", for: .normal)
        btn.semanticContentAttribute = .forceRightToLeft
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.setTitleColor(.tertiaryLabel, for: .disabled)
        btn.tintColor = .secondaryLabel
        btn.backgroundColor = .systemGray6
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let navButtonStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Action Buttons

    private let answerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("📝 My Notes", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 196/255, green: 168/255, blue: 130/255, alpha: 1.0)
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let leetcodeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("🔗 LeetCode", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Init

    init(problems: [ProblemListItem], currentIndex: Int, solvedProblemIds: Set<String> = []) {
        self.problems = problems
        self.currentIndex = currentIndex
        self.solvedProblemIds = solvedProblemIds
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = problem.title
        setupUI()
        updateProgress()
        updateTagChips()
        setupGestures()
        setupNavigationBar()
        setupLikeButton()
        updateNavButtons()
        loadLikedProblemIds()
        fetchContent(token: loadToken)
        // Timer start and help dialog are deferred to viewDidAppear so that
        // the view is fully on-screen before any presentation or timer logic runs.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        if !hasAppearedOnce {
            hasAppearedOnce = true
            // First appearance: show help (which also triggers startTimer at the right moment).
            showHelpIfNeeded()
        } else {
            // Subsequent appearances (returning from child screen): resume the existing timer.
            resumeTimer()
        }
    }

    // MARK: - Layout

    private func setupUI() {
        // Timer label and progress row sit between the navigation bar and the card container.
        view.addSubview(timerLabel)
        view.addSubview(progressBar)
        view.addSubview(progressLabel)

        view.addSubview(cardContainer)
        cardContainer.addSubview(frontView)
        cardContainer.addSubview(backView)
        cardContainer.addSubview(loadingView)

        frontView.addSubview(frontBadgeLabel)
        frontView.addSubview(frontTitleLabel)
        frontView.addSubview(tagScrollView)
        tagScrollView.addSubview(tagStack)
        frontView.addSubview(frontScrollView)
        frontScrollView.addSubview(frontDescriptionLabel)
        frontView.addSubview(frontHintLabel)

        backView.addSubview(backTitleLabel)
        backView.addSubview(backScrollView)
        backScrollView.addSubview(backContentLabel)
        backView.addSubview(backHintLabel)

        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(loadingLabel)

        navButtonStack.addArrangedSubview(prevButton)
        navButtonStack.addArrangedSubview(nextButton)
        view.addSubview(navButtonStack)

        view.addSubview(answerButton)
        view.addSubview(leetcodeButton)

        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        answerButton.addTarget(self, action: #selector(onAnswerTapped), for: .touchUpInside)
        leetcodeButton.addTarget(self, action: #selector(onLeetCodeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timerLabel.heightAnchor.constraint(equalToConstant: 28),

            // Progress row: label on the right (fixed width to fit "150 / 150"),
            // bar stretches to fill the remaining leading space.
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),
            progressLabel.widthAnchor.constraint(equalToConstant: 64),

            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -10),
            progressBar.centerYAnchor.constraint(equalTo: progressLabel.centerYAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4),

            // Card container attaches below the progress row.
            cardContainer.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 10),
            cardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardContainer.bottomAnchor.constraint(equalTo: navButtonStack.topAnchor, constant: -16),

            frontView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            frontView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            frontView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            frontView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),

            backView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            backView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            backView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            backView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),

            loadingView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),

            frontBadgeLabel.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 20),
            frontBadgeLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 20),
            frontBadgeLabel.widthAnchor.constraint(equalToConstant: 74),
            frontBadgeLabel.heightAnchor.constraint(equalToConstant: 24),

            frontTitleLabel.topAnchor.constraint(equalTo: frontBadgeLabel.bottomAnchor, constant: 10),
            frontTitleLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 20),
            frontTitleLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -20),

            // Tag chip row: horizontally scrollable, fixed height, sits between title and description.
            tagScrollView.topAnchor.constraint(equalTo: frontTitleLabel.bottomAnchor, constant: 10),
            tagScrollView.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 20),
            tagScrollView.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -20),
            {
                let hc = tagScrollView.heightAnchor.constraint(equalToConstant: 28)
                tagScrollViewHeightConstraint = hc
                return hc
            }(),

            tagStack.topAnchor.constraint(equalTo: tagScrollView.topAnchor),
            tagStack.leadingAnchor.constraint(equalTo: tagScrollView.leadingAnchor),
            tagStack.trailingAnchor.constraint(equalTo: tagScrollView.trailingAnchor),
            tagStack.bottomAnchor.constraint(equalTo: tagScrollView.bottomAnchor),
            tagStack.heightAnchor.constraint(equalTo: tagScrollView.heightAnchor),

            frontScrollView.topAnchor.constraint(equalTo: tagScrollView.bottomAnchor, constant: 8),
            frontScrollView.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 20),
            frontScrollView.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -20),
            frontScrollView.bottomAnchor.constraint(equalTo: frontHintLabel.topAnchor, constant: -8),

            frontDescriptionLabel.topAnchor.constraint(equalTo: frontScrollView.topAnchor),
            frontDescriptionLabel.leadingAnchor.constraint(equalTo: frontScrollView.leadingAnchor),
            frontDescriptionLabel.trailingAnchor.constraint(equalTo: frontScrollView.trailingAnchor),
            frontDescriptionLabel.bottomAnchor.constraint(equalTo: frontScrollView.bottomAnchor),
            frontDescriptionLabel.widthAnchor.constraint(equalTo: frontScrollView.widthAnchor),

            frontHintLabel.bottomAnchor.constraint(equalTo: frontView.bottomAnchor, constant: -16),
            frontHintLabel.centerXAnchor.constraint(equalTo: frontView.centerXAnchor),

            backTitleLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 20),
            backTitleLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 20),
            backTitleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -20),

            backScrollView.topAnchor.constraint(equalTo: backTitleLabel.bottomAnchor, constant: 12),
            backScrollView.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 20),
            backScrollView.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -20),
            backScrollView.bottomAnchor.constraint(equalTo: backHintLabel.topAnchor, constant: -8),

            backContentLabel.topAnchor.constraint(equalTo: backScrollView.topAnchor),
            backContentLabel.leadingAnchor.constraint(equalTo: backScrollView.leadingAnchor),
            backContentLabel.trailingAnchor.constraint(equalTo: backScrollView.trailingAnchor),
            backContentLabel.bottomAnchor.constraint(equalTo: backScrollView.bottomAnchor),
            backContentLabel.widthAnchor.constraint(equalTo: backScrollView.widthAnchor),

            backHintLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -16),
            backHintLabel.centerXAnchor.constraint(equalTo: backView.centerXAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -16),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),

            // Deck navigation buttons sit directly above the action buttons
            navButtonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            navButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            navButtonStack.bottomAnchor.constraint(equalTo: answerButton.topAnchor, constant: -10),
            navButtonStack.heightAnchor.constraint(equalToConstant: 46),

            answerButton.bottomAnchor.constraint(equalTo: leetcodeButton.topAnchor, constant: -10),
            answerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            answerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            answerButton.heightAnchor.constraint(equalToConstant: 50),

            leetcodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            leetcodeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            leetcodeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            leetcodeButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        configureDifficultyBadge()
    }

    private func setupNavigationBar() {
        let solvedButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle"),
            style: .done,
            target: self,
            action: #selector(onSolvedTapped)
        )
        solvedButton.tintColor = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)

        let hintNavButton = UIBarButtonItem(
            image: UIImage(systemName: "lightbulb"),
            style: .plain,
            target: self,
            action: #selector(hintTapped)
        )
        hintNavButton.tintColor = .systemYellow
        // Store a direct reference so hintTapped() can enable/disable it without index access.
        hintBarButton = hintNavButton

        let listButton = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: #selector(listTapped)
        )
        listButton.tintColor = .systemIndigo

        // [0] = solvedButton (rightmost), [1] = hintNavButton, [2] = listButton (leftmost).
        // updateSolvedButton() targets index 0; keep this order in sync if buttons change.
        navigationItem.rightBarButtonItems = [solvedButton, hintNavButton, listButton]
        updateSolvedButton()
    }

    private func updateSolvedButton() {
        let isSolved = solvedProblemIds.contains(problem.id)
        navigationItem.rightBarButtonItems?.first?.image = UIImage(
            systemName: isSolved ? "checkmark.circle.fill" : "checkmark.circle"
        )
        navigationItem.rightBarButtonItems?.first?.isEnabled = !isSolved
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardContainer.addGestureRecognizer(tap)
        cardContainer.isUserInteractionEnabled = true
    }

    private func configureDifficultyBadge() {
        frontTitleLabel.text = problem.title
        switch problem.difficulty {
        case .easy:
            let c = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
            frontBadgeLabel.text = "Easy"
            frontBadgeLabel.textColor = c
            frontBadgeLabel.backgroundColor = c.withAlphaComponent(0.15)
        case .medium:
            let c = UIColor(red: 196/255, green: 168/255, blue: 130/255, alpha: 1.0)
            frontBadgeLabel.text = "Medium"
            frontBadgeLabel.textColor = c
            frontBadgeLabel.backgroundColor = c.withAlphaComponent(0.15)
        case .hard:
            let c = UIColor(red: 176/255, green: 138/255, blue: 138/255, alpha: 1.0)
            frontBadgeLabel.text = "Hard"
            frontBadgeLabel.textColor = c
            frontBadgeLabel.backgroundColor = c.withAlphaComponent(0.15)
        }
    }

    // MARK: - Deck Navigation

    private func updateNavButtons() {
        prevButton.isEnabled = currentIndex > 0
        nextButton.isEnabled = currentIndex < problems.count - 1
    }

    private func updateProgress() {
        guard !problems.isEmpty else { return }
        let current = currentIndex + 1
        let total   = problems.count
        progressBar.setProgress(Float(current) / Float(total), animated: true)
        progressLabel.text = "\(current) / \(total)"
    }

    /// Rebuilds the tag chip row for the current problem.
    /// Clears existing chips first so navigation between problems always shows the correct tags.
    /// Hides the row entirely when the problem has no topic tags.
    private func updateTagChips() {
        tagStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let tags = problem.topicTags
        tagScrollView.isHidden = tags.isEmpty
        tagScrollViewHeightConstraint?.constant = tags.isEmpty ? 0 : 28
        for (index, tag) in tags.enumerated() {
            let color = ProblemDeckConfig.color(forListTag: tag.slug)
            let icon  = ProblemDeckConfig.icon(forListTag: tag.slug)
            let btn   = UIButton(type: .system)
            btn.setTitle("\(icon) \(tag.name)", for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            btn.setTitleColor(color, for: .normal)
            btn.backgroundColor = color.withAlphaComponent(0.12)
            btn.layer.cornerRadius = 10
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
            btn.tag = index  // used in tap handler to look up the correct TopicTag
            btn.addTarget(self, action: #selector(tagChipTapped(_:)), for: .touchUpInside)
            tagStack.addArrangedSubview(btn)
        }
    }

    /// Navigates to a ProblemsViewController filtered by the tapped topic tag.
    /// Reuses the existing listTag-based fetch path — no new Firestore logic needed.
    @objc private func tagChipTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < problem.topicTags.count else { return }
        let topicTag = problem.topicTags[index]
        let vc = ProblemsViewController(listTag: topicTag.slug, title: topicTag.name)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func prevTapped() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadCurrentProblem()
    }

    @objc private func nextTapped() {
        guard currentIndex < problems.count - 1 else { return }
        currentIndex += 1
        loadCurrentProblem()
    }

    private func loadCurrentProblem() {
        isFlipped = false
        title = problem.title
        configureDifficultyBadge()
        updateNavButtons()
        hintLevel = 0
        loadedHints = nil  // Force a fresh HintService fetch for the new problem.

        // Reset scroll positions so the new problem starts at the top
        frontScrollView.setContentOffset(.zero, animated: false)
        backScrollView.setContentOffset(.zero, animated: false)

        // Sync buttons, progress, and tag chips from in-memory state — no Firestore reads needed.
        updateSolvedButton()
        updateLikeButton()
        updateProgress()
        updateTagChips()

        let token = UUID()
        loadToken = token
        fetchContent(token: token)
    }

    // MARK: - Like

    private func setupLikeButton() {
        let heartBtn = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(likeTapped)
        )
        heartBtn.tintColor = .systemRed

        // Custom back button so we can intercept the tap and show a confirmation
        // dialog before popping. hidesBackButton suppresses the auto-generated item.
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItems = [backBtn, heartBtn]
    }

    @objc private func backTapped() {
        let alert = UIAlertController(
            title: "Exit Study Session?",
            message: "Your timer progress will be lost if you leave now.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continue Studying", style: .cancel))
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func updateLikeButton() {
        let isLiked = likedProblemIds.contains(problem.id)
        // leftBarButtonItems = [backBtn, heartBtn] — heart is at index 1.
        navigationItem.leftBarButtonItems?[1].image = UIImage(
            systemName: isLiked ? "heart.fill" : "heart"
        )
    }

    private func loadLikedProblemIds() {
        guard let userId = AuthService.shared.currentUserId else { return }
        FirestoreService.shared.fetchLikedProblemIds(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                if case .success(let ids) = result {
                    self.likedProblemIds = Set(ids)
                }
                self.updateLikeButton()
            }
        }
    }

    @objc private func likeTapped() {
        guard let userId = AuthService.shared.currentUserId else {
            showAlert(title: "Login Required", message: "Please log in to like problems.")
            return
        }
        let problemId = problem.id
        let isCurrentlyLiked = likedProblemIds.contains(problemId)

        // Optimistic update: reflect the change in UI immediately.
        if isCurrentlyLiked {
            likedProblemIds.remove(problemId)
        } else {
            likedProblemIds.insert(problemId)
        }
        updateLikeButton()

        FirestoreService.shared.setLikeProblem(userId: userId, problemId: problemId, liked: !isCurrentlyLiked) { [weak self] error in
            guard let error else { return }
            // Revert the optimistic update on failure.
            DispatchQueue.main.async {
                guard let self else { return }
                if isCurrentlyLiked {
                    self.likedProblemIds.insert(problemId)
                } else {
                    self.likedProblemIds.remove(problemId)
                }
                self.updateLikeButton()
                self.showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Content Loading

    private func fetchContent(token: UUID) {
        showLoading(true)
        // Capture titleSlug now so a later index change doesn't affect this fetch.
        let titleSlug = problem.titleSlug

        let group = DispatchGroup()
        var localFront = ""
        var localBack = "No official solution available for this problem.\n\nTry checking Solutions on Leetcode. 🔗"
        var localFrontErrorMessage = "Could not load problem. Please check your connection."

        group.enter()
        NetworkManager.shared.fetchProblemDetail(titleSlug: titleSlug) { [weak self] result in
            defer { group.leave() }
            guard let self else { return }
            switch result {
            case .success(let p):
                localFront = self.parseHTML(p.description)
            case .failure(.premiumQuestion):
                localFront = "⭐ This is a premium problem.\nDescription not available — open on LeetCode to view."
            case .failure(let error):
                localFrontErrorMessage = error.localizedDescription
            }
        }

        group.enter()
        NetworkManager.shared.fetchOfficialSolution(titleSlug: titleSlug) { [weak self] result in
            defer { group.leave() }
            guard let self else { return }
            if case .success(let content) = result {
                localBack = self.parseHTML(content)
            }
        }

        group.notify(queue: .main) { [weak self] in
            // Discard results if the user navigated away before this fetch completed.
            guard let self = self, self.loadToken == token else { return }
            self.frontDescriptionLabel.text = localFront.isEmpty
                ? localFrontErrorMessage
                : localFront
            self.backContentLabel.text = localBack
            self.showLoading(false)
        }
    }

    private func showLoading(_ loading: Bool) {
        loadingView.isHidden = !loading
        frontView.isHidden = loading
        backView.isHidden = true
        isFlipped = false
        if loading {
            activityIndicator.startAnimating()
            // Disable hint while problem content is loading — description may not be
            // in NetworkManager's cache yet, which HintGenerator needs for Claude.
            hintBarButton?.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            hintBarButton?.isEnabled = true
        }
    }

    // MARK: - Card Flip

    @objc func flipCard() {
        let fromView = isFlipped ? backView : frontView
        let toView   = isFlipped ? frontView : backView

        UIView.transition(
            from: fromView,
            to: toView,
            duration: 0.3,
            options: [.transitionFlipFromRight, .showHideTransitionViews]
        )
        isFlipped.toggle()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            flipCard()
        }
    }

    // MARK: - Actions

    @objc private func onSolvedTapped() {
        guard let userId = AuthService.shared.currentUserId else {
            showAlert(title: "Login Required", message: "Please log in to track your progress.")
            return
        }
        let problemId = problem.id
        FirestoreService.shared.markProblemSolved(userId: userId, problemId: problemId) { [weak self] error in
            DispatchQueue.main.async {
                guard let self, error == nil else { return }
                self.solvedProblemIds.insert(problemId)
                self.updateSolvedButton()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    @objc private func onLeetCodeTapped() {
        guard let url = problem.leetcodeURL else { return }
        UIApplication.shared.open(url)
    }

    @objc private func onAnswerTapped() {
        let answerVC = AnswerViewController(problem: problem)
        navigationController?.pushViewController(answerVC, animated: true)
    }

    @objc private func listTapped() {
        let picker = ProblemListPickerViewController(
            problems: problems,
            currentIndex: currentIndex,
            solvedProblemIds: solvedProblemIds
        ) { [weak self] selectedIndex in
            guard let self else { return }
            self.currentIndex = selectedIndex
            self.loadCurrentProblem()
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Hints

    @objc private func hintTapped() {
        // Hints are accessible on both card sides; no flip-state restriction.

        // If hints were already fetched for this problem, show immediately — no network needed.
        if let hints = loadedHints {
            showHint(from: hints)
            return
        }

        // First tap for this problem: fetch from HintService (Firestore cache or placeholder).
        // Disable the button to prevent duplicate requests while the fetch is in flight.
        let expectedProblem = problem
        hintBarButton?.isEnabled = false

        HintService.shared.getHints(for: expectedProblem) { [weak self] hints in
            guard let self, self.problem.id == expectedProblem.id else { return }
            self.hintBarButton?.isEnabled = true
            self.loadedHints = hints
            self.showHint(from: hints)
        }
    }

    private func showHint(from hints: [String]) {
        let total = hints.count
        let nextLevel = hintLevel + 1

        let title: String
        let message: String
        if nextLevel <= total {
            title = "Hint \(nextLevel) / \(total)"
            message = hints[nextLevel - 1]
            hintLevel = nextLevel
        } else {
            title = "No More Hints"
            message = "You've already seen all \(total) hints for this problem."
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Timer

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    deinit {
        countdownTimer?.invalidate()
    }

    private func startTimer() {
        stopTimer()  // Invalidates any existing timer before creating a new one, preventing duplicates.
        remainingSeconds = FlashCardViewController.timerDuration
        updateTimerDisplay()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingSeconds -= 1
            self.updateTimerDisplay()
            if self.remainingSeconds <= 0 {
                self.handleTimerExpired()
            }
        }
    }

    /// Resumes the countdown tick from the current remainingSeconds without resetting it.
    /// Called from viewDidAppear so the timer continues whenever this screen is visible,
    /// and naturally pauses (via viewWillDisappear → stopTimer) when a child screen is pushed.
    /// Guards ensure this is a no-op if the timer is already running or has already expired.
    private func resumeTimer() {
        guard remainingSeconds > 0, countdownTimer == nil else { return }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingSeconds -= 1
            self.updateTimerDisplay()
            if self.remainingSeconds <= 0 {
                self.handleTimerExpired()
            }
        }
    }

    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateTimerDisplay() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = "⏱ \(String(format: "%02d:%02d", minutes, seconds))"
    }

    private func handleTimerExpired() {
        stopTimer()
        timerLabel.text = "⏱ 00:00"
        showAlert(title: "⏰ Time's Up!", message: "Your study session has ended.")
    }

    // MARK: - Help Dialog

    private static let helpSeenKey = "hasSeenFlashCardHelp"

    /// Shows a one-time usage guide the first time the user opens a study session.
    /// After the user taps "Got it", the flag is written to UserDefaults and the alert
    /// never appears again — even across app restarts.
    private func showHelpIfNeeded() {
        if UserDefaults.standard.bool(forKey: Self.helpSeenKey) {
            // Returning user: start the session timer immediately, no dialog needed.
            startTimer()
            return
        }
        // First-time user: show the help dialog. The timer starts only after
        // "Got it" is tapped so no session time is lost while reading.
        let body = """
            • Tap the card to flip between question and solution
            • Shake your phone to flip
            • 💡 Hints reveal step-by-step clues
            • ✓ Mark a problem solved when you're ready
            • Timer counts down your 10-minute session
            """
        let alert = UIAlertController(title: "How to Use Flash Cards", message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default) { [weak self] _ in
            UserDefaults.standard.set(true, forKey: Self.helpSeenKey)
            self?.startTimer()
        })
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func parseHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
              ) else {
            return html
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
