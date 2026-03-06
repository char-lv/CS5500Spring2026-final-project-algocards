//
//  FlashCardViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/5/26.
//

import UIKit

class FlashCardViewController: UIViewController {

    private let problem: ProblemListItem
    private var isFlipped = false
    private var frontContent = ""
    private var backContent = ""

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


    private let solvedButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✅ Got It", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemGreen
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

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


    init(problem: ProblemListItem) {
        self.problem = problem
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = problem.title
        setupUI()
        setupGestures()
        setupNavigationBar()
        fetchContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    private func setupNavigationBar() {
        let image = UIImage(systemName: "checkmark.circle")
        let gotItButton = UIBarButtonItem(
            image: image,
            style: .done,
            target: self,
            action: #selector(onSolvedTapped)
        )
        gotItButton.tintColor = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
        navigationItem.rightBarButtonItem = gotItButton
    }

    private func setupUI() {

        view.addSubview(cardContainer)
        cardContainer.addSubview(frontView)
        cardContainer.addSubview(backView)
        cardContainer.addSubview(loadingView)


        frontView.addSubview(frontBadgeLabel)
        frontView.addSubview(frontTitleLabel)
        frontView.addSubview(frontScrollView)
        frontScrollView.addSubview(frontDescriptionLabel)
        frontView.addSubview(frontHintLabel)


        backView.addSubview(backTitleLabel)
        backView.addSubview(backScrollView)
        backScrollView.addSubview(backContentLabel)
        backView.addSubview(backHintLabel)


        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(loadingLabel)


        view.addSubview(answerButton)
        view.addSubview(leetcodeButton)

        NSLayoutConstraint.activate([

            cardContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardContainer.bottomAnchor.constraint(equalTo: answerButton.topAnchor, constant: -20),

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
            frontBadgeLabel.widthAnchor.constraint(equalToConstant: 70),
            frontBadgeLabel.heightAnchor.constraint(equalToConstant: 24),

            frontTitleLabel.topAnchor.constraint(equalTo: frontBadgeLabel.bottomAnchor, constant: 10),
            frontTitleLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 20),
            frontTitleLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -20),

            frontScrollView.topAnchor.constraint(equalTo: frontTitleLabel.bottomAnchor, constant: 12),
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

//            solvedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            solvedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            solvedButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
//            solvedButton.heightAnchor.constraint(equalToConstant: 52),
            
            answerButton.bottomAnchor.constraint(equalTo: leetcodeButton.topAnchor, constant: -10),
            answerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            answerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            answerButton.heightAnchor.constraint(equalToConstant: 52),

            leetcodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            leetcodeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            leetcodeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            leetcodeButton.heightAnchor.constraint(equalToConstant: 48),
        ])

        answerButton.addTarget(self, action: #selector(onAnswerTapped), for: .touchUpInside)
        leetcodeButton.addTarget(self, action: #selector(onLeetCodeTapped), for: .touchUpInside)

        configureDifficultyBadge()
    }

    private func configureDifficultyBadge() {
        frontTitleLabel.text = problem.title
        switch problem.difficulty {
        case .easy:
            frontBadgeLabel.text = "Easy"
            frontBadgeLabel.textColor = .systemGreen
            frontBadgeLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        case .medium:
            frontBadgeLabel.text = "Medium"
            frontBadgeLabel.textColor = .systemOrange
            frontBadgeLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        case .hard:
            frontBadgeLabel.text = "Hard"
            frontBadgeLabel.textColor = .systemRed
            frontBadgeLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
        }
    }

    // Gestures
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardContainer.addGestureRecognizer(tap)
        cardContainer.isUserInteractionEnabled = true
    }
    
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


    // Fetch Content
    private func fetchContent() {
        showLoading(true)

        let group = DispatchGroup()

        group.enter()
        NetworkManager.shared.fetchProblemDetail(titleSlug: problem.titleSlug) { [weak self] result in
            if case .success(let p) = result {
                self?.frontContent = self?.parseHTML(p.description) ?? ""
            }
            group.leave()
        }


        group.enter()
        NetworkManager.shared.fetchOfficialSolution(titleSlug: problem.titleSlug) { [weak self] result in
            if case .success(let content) = result {
                self?.backContent = self?.parseHTML(content) ?? ""
            } else {
                self?.backContent = "No official solution available for this problem.\n\nTry checking Solutions on Leetcode. 🔗"
            }
            group.leave()
        }


        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.frontDescriptionLabel.text = self.frontContent.isEmpty
                ? "Could not load problem. Please check your connection."
                : self.frontContent
            self.backContentLabel.text = self.backContent
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
        } else {
            activityIndicator.stopAnimating()
        }
    }

    // Flip Animation
    @objc func flipCard() {
        let fromView = isFlipped ? backView : frontView
        let toView   = isFlipped ? frontView : backView

        UIView.transition(
            from: fromView,
            to: toView,
            duration: 0.5,
            options: [.transitionFlipFromRight, .showHideTransitionViews]
        )
        isFlipped.toggle()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // Shake to flip
    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            flipCard()
        }
    }

    // Actions
    @objc private func onSolvedTapped() {
        guard let userId = AuthService.shared.currentUserId else {
            showAlert(title: "Login Required", message: "Please log in to track your progress.")
            return
        }
        FirestoreService.shared.markProblemSolved(userId: userId, problemId: problem.id) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "checkmark.circle.fill")
                    self?.navigationItem.rightBarButtonItem?.isEnabled = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
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
}
