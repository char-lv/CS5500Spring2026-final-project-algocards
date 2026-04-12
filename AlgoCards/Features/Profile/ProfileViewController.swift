//
//  ProfileViewController.swift
//  AlgoCards
//

import UIKit

class ProfileViewController: UIViewController {

    // MARK: - State

    private var user: User?
    private var masteredIds: [String] = []
    private var likedIds: [String] = []

    private var masteredCountLabel: UILabel?
    private var likedCountLabel: UILabel?
    private var hasAnimatedIn = false

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 20
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()


    private let heroCard: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 24
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 44
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarGradient = CAGradientLayer()

    private let avatarInitialsLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 30)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let userNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 22)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scoreBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 0.14)
        v.layer.cornerRadius = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scoreBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 13)
        l.textColor = UIColor(red: 0.28, green: 0.52, blue: 0.28, alpha: 1.0)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        loadUserData()
        contentStack.arrangedSubviews.forEach { $0.alpha = 0 }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true
        contentStack.arrangedSubviews.enumerated().forEach { index, v in
            v.transform = CGAffineTransform(translationX: 0, y: 22)
            UIView.animate(
                withDuration: 0.50,
                delay: Double(index) * 0.065,
                usingSpringWithDamping: 0.84,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction]
            ) {
                v.alpha = 1
                v.transform = .identity
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarGradient.frame = avatarView.bounds
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
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        buildHeroCard()
        buildStatsRow()
        buildSectionHeader("Review Questions")
        contentStack.addArrangedSubview(buildReviewCard(
            title: "Mastered Questions",
            subtitle: "Problems you've marked as solved",
            sfIcon: "checkmark.seal.fill",
            accent: UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0),
            action: #selector(masteredTapped)
        ))
        contentStack.addArrangedSubview(buildReviewCard(
            title: "Liked Questions",
            subtitle: "Problems you've saved with ♡",
            sfIcon: "heart.fill",
            accent: UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0),
            action: #selector(likedTapped)
        ))
        buildSignOut()
    }

    private func buildHeroCard() {
        // Gradient: muted green → slate blue
        avatarGradient.colors = [
            UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0).cgColor,
            UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0).cgColor,
        ]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0)
        avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarView.layer.addSublayer(avatarGradient)

        avatarView.addSubview(avatarInitialsLabel)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 88),
            avatarView.heightAnchor.constraint(equalToConstant: 88),
            avatarInitialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarInitialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
        ])

        scoreBadge.addSubview(scoreBadgeLabel)
        NSLayoutConstraint.activate([
            scoreBadgeLabel.topAnchor.constraint(equalTo: scoreBadge.topAnchor, constant: 6),
            scoreBadgeLabel.bottomAnchor.constraint(equalTo: scoreBadge.bottomAnchor, constant: -6),
            scoreBadgeLabel.leadingAnchor.constraint(equalTo: scoreBadge.leadingAnchor, constant: 14),
            scoreBadgeLabel.trailingAnchor.constraint(equalTo: scoreBadge.trailingAnchor, constant: -14),
        ])

        let infoStack = UIStackView(arrangedSubviews: [avatarView, userNameLabel, emailLabel, scoreBadge])
        infoStack.axis = .vertical
        infoStack.alignment = .center
        infoStack.spacing = 8
        infoStack.setCustomSpacing(16, after: avatarView)
        infoStack.setCustomSpacing(4, after: userNameLabel)
        infoStack.setCustomSpacing(14, after: emailLabel)
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        heroCard.addSubview(infoStack)
        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 28),
            infoStack.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -28),
        ])

        contentStack.addArrangedSubview(heroCard)
    }

    private func buildStatsRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false

        let (masteredCard, masteredCount) = buildStatTile(
            sfIcon: "checkmark.seal.fill",
            labelText: "Mastered",
            accent: UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0)
        )
        let (likedCard, likedCount) = buildStatTile(
            sfIcon: "heart.fill",
            labelText: "Liked",
            accent: UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0)
        )

        masteredCountLabel = masteredCount
        likedCountLabel = likedCount

        row.addArrangedSubview(masteredCard)
        row.addArrangedSubview(likedCard)

        masteredCard.heightAnchor.constraint(equalToConstant: 112).isActive = true

        contentStack.addArrangedSubview(row)
    }

    private func buildStatTile(sfIcon: String, labelText: String, accent: UIColor) -> (UIView, UILabel) {
        let tile = UIView()
        tile.backgroundColor = accent.withAlphaComponent(0.09)
        tile.layer.cornerRadius = 18
        tile.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: sfIcon))
        icon.tintColor = accent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let countLabel = UILabel()
        countLabel.text = "—"
        countLabel.font = UIFont.boldSystemFont(ofSize: 32)
        countLabel.textColor = .label
        countLabel.textAlignment = .center
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.minimumScaleFactor = 0.7
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = labelText
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        nameLabel.textColor = accent
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [icon, countLabel, nameLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        tile.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: tile.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: tile.trailingAnchor, constant: -8),
        ])

        return (tile, countLabel)
    }

    private func buildSectionHeader(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(label)
        contentStack.setCustomSpacing(8, after: label)
    }

    private func buildReviewCard(
        title: String,
        subtitle: String,
        sfIcon: String,
        accent: UIColor,
        action: Selector
    ) -> UIButton {
        let card = UIButton(type: .system)
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 10
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addTarget(self, action: #selector(reviewCardDown(_:)), for: .touchDown)
        card.addTarget(self, action: #selector(reviewCardUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        card.addTarget(self, action: action, for: .touchUpInside)

        // Icon bubble
        let iconBg = UIView()
        iconBg.backgroundColor = accent.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 14
        iconBg.isUserInteractionEnabled = false
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconBg.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let iconImg = UIImageView(image: UIImage(systemName: sfIcon))
        iconImg.tintColor = accent
        iconImg.contentMode = .scaleAspectFit
        iconImg.isUserInteractionEnabled = false
        iconImg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconImg)
        NSLayoutConstraint.activate([
            iconImg.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconImg.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconImg.widthAnchor.constraint(equalToConstant: 22),
            iconImg.heightAnchor.constraint(equalToConstant: 22),
        ])

        // Text
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // Chevron
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.isUserInteractionEnabled = false
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true

        let row = UIStackView(arrangedSubviews: [iconBg, textStack, UIView(), chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 76),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        return card
    }

    private func buildSignOut() {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer)

        let btn = UIButton(type: .system)
        btn.setTitle("Sign Out", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.backgroundColor = UIColor.systemRed.withAlphaComponent(0.08)
        btn.layer.cornerRadius = 14
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(btn)
    }

    // MARK: - Data

    private func loadUserData() {
        guard let userId = AuthService.shared.currentUserId else { return }

        let group = DispatchGroup()
        var fetchedUser: User?
        var fetchedLikedIds: [String] = []

        group.enter()
        FirestoreService.shared.fetchUser(userId: userId) { result in
            if case .success(let u) = result { fetchedUser = u }
            group.leave()
        }

        group.enter()
        FirestoreService.shared.fetchLikedProblemIds(userId: userId) { result in
            if case .success(let ids) = result { fetchedLikedIds = ids }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.user = fetchedUser
            self.masteredIds = fetchedUser?.solvedProblemIds ?? []
            self.likedIds = fetchedLikedIds
            self.renderProfile()
        }
    }

    private func renderProfile() {
        guard let user = user else { return }

        // Initials from username
        let words = user.userName.split(separator: " ").prefix(2)
        let initials = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        avatarInitialsLabel.text = initials.isEmpty ? "?" : initials

        userNameLabel.text = user.userName
        emailLabel.text = user.email
        scoreBadgeLabel.text = "⭐ \(user.score) pts"

        masteredCountLabel?.text = "\(masteredIds.count)"
        likedCountLabel?.text = "\(likedIds.count)"
    }

    // MARK: - Actions

    @objc private func reviewCardDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func reviewCardUp(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.28, delay: 0,
            usingSpringWithDamping: 0.68, initialSpringVelocity: 0.6,
            options: .allowUserInteraction
        ) {
            sender.transform = .identity
        }
    }

    @objc private func masteredTapped() {
        guard !masteredIds.isEmpty else {
            showAlert(title: "Nothing here yet",
                      message: "Mark problems as solved to build your mastered list.")
            return
        }
        openReview(ids: masteredIds, title: "Mastered",
                   icon: "✅",
                   accent: UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0))
    }

    @objc private func likedTapped() {
        guard !likedIds.isEmpty else {
            showAlert(title: "Nothing here yet",
                      message: "Tap ♡ on any problem to save it to your liked list.")
            return
        }
        openReview(ids: likedIds, title: "Liked",
                   icon: "❤️",
                   accent: UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0))
    }

    private func openReview(ids: [String], title: String, icon: String, accent: UIColor) {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)

        FirestoreService.shared.fetchProblems(frontendIds: ids) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.navigationItem.rightBarButtonItem = nil

                switch result {
                case .success(let problems) where !problems.isEmpty:
                    let vc = ProblemsViewController(
                        preloadedProblems: problems,
                        title: title,
                        icon: icon,
                        accent: accent
                    )
                    self.navigationController?.pushViewController(vc, animated: true)
                case .success:
                    self.showAlert(title: "No problems found",
                                   message: "We couldn't load this list right now.")
                case .failure:
                    self.showAlert(title: "Error",
                                   message: "Could not load problems. Please try again.")
                }
            }
        }
    }

    @objc private func signOutTapped() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            AuthService.shared.signOut()
            guard let scene = self?.view.window?.windowScene?.delegate as? SceneDelegate else { return }
            scene.showAuth()
        })
        present(alert, animated: true)
    }
}
