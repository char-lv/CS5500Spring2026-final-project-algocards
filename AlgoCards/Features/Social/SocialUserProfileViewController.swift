//
//  SocialUserProfileViewController.swift
//  AlgoCards
//

import UIKit
import FirebaseFirestore

final class SocialUserProfileViewController: UIViewController {
    private let userId: String

    private var summary: SocialUserSummary?
    private var masteredIds: [String] = []
    private var likedIds: [String] = []
    private var likeState: SocialCollectionLikeState?
    private var profileListener: ListenerRegistration?

    private var masteredCountLabel: UILabel?
    private var likedCountLabel: UILabel?
    private var collectionLikesCountLabel: UILabel?

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let heroCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.07
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 44
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let avatarGradient = CAGradientLayer()

    private let avatarInitialsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scoreBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 0.14)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scoreBadgeIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "star.fill"))
        imageView.tintColor = UIColor(red: 0.28, green: 0.52, blue: 0.28, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let scoreBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.28, green: 0.52, blue: 0.28, alpha: 1.0)
        label.text = "0 pts"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        label.lineBreakMode = .byClipping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let likesBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 0.14)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let likesBadgeIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "hand.thumbsup.fill"))
        imageView.tintColor = UIColor(red: 0.33, green: 0.45, blue: 0.62, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let likesBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.33, green: 0.45, blue: 0.62, alpha: 1.0)
        label.text = "0 likes"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        label.lineBreakMode = .byClipping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 24
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 8
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        profileListener?.remove()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Learner"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        loadData()
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
        buildSectionHeader("Friend's Decks")
        contentStack.addArrangedSubview(buildReviewCard(
            title: "Mastered Questions",
            subtitle: "Review problems this learner has already solved",
            sfIcon: "checkmark.seal.fill",
            accent: UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0),
            action: #selector(masteredTapped)
        ))
        contentStack.addArrangedSubview(buildReviewCard(
            title: "Liked Questions",
            subtitle: "Practice directly from this learner's saved collection",
            sfIcon: "heart.fill",
            accent: UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0),
            action: #selector(likedTapped)
        ))
    }

    private func buildHeroCard() {
        avatarGradient.colors = [
            UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0).cgColor,
            UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0).cgColor,
        ]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0)
        avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarView.layer.addSublayer(avatarGradient)
        avatarView.addSubview(avatarInitialsLabel)

        scoreBadge.addSubview(scoreBadgeIcon)
        scoreBadge.addSubview(scoreBadgeLabel)
        likesBadge.addSubview(likesBadgeIcon)
        likesBadge.addSubview(likesBadgeLabel)

        likeButton.addTarget(self, action: #selector(likeCollectionTapped), for: .touchUpInside)

        [heroCard].forEach { contentStack.addArrangedSubview($0) }

        let badgeRow = UIStackView(arrangedSubviews: [scoreBadge, likesBadge])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 10
        badgeRow.alignment = .center
        badgeRow.distribution = .fill
        badgeRow.translatesAutoresizingMaskIntoConstraints = false

        [scoreBadge, likesBadge].forEach {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        [scoreBadgeLabel, likesBadgeLabel].forEach {
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        let infoStack = UIStackView(arrangedSubviews: [avatarView, userNameLabel, badgeRow, likeButton])
        infoStack.axis = .vertical
        infoStack.alignment = .center
        infoStack.spacing = 12
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        heroCard.addSubview(infoStack)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 88),
            avatarView.heightAnchor.constraint(equalToConstant: 88),
            avatarInitialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarInitialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            scoreBadgeIcon.leadingAnchor.constraint(equalTo: scoreBadge.leadingAnchor, constant: 12),
            scoreBadgeIcon.centerYAnchor.constraint(equalTo: scoreBadge.centerYAnchor),
            scoreBadgeIcon.widthAnchor.constraint(equalToConstant: 12),
            scoreBadgeIcon.heightAnchor.constraint(equalToConstant: 12),

            scoreBadgeLabel.topAnchor.constraint(equalTo: scoreBadge.topAnchor, constant: 8),
            scoreBadgeLabel.bottomAnchor.constraint(equalTo: scoreBadge.bottomAnchor, constant: -8),
            scoreBadgeLabel.leadingAnchor.constraint(equalTo: scoreBadgeIcon.trailingAnchor, constant: 6),
            scoreBadgeLabel.trailingAnchor.constraint(equalTo: scoreBadge.trailingAnchor, constant: -12),

            likesBadgeIcon.leadingAnchor.constraint(equalTo: likesBadge.leadingAnchor, constant: 12),
            likesBadgeIcon.centerYAnchor.constraint(equalTo: likesBadge.centerYAnchor),
            likesBadgeIcon.widthAnchor.constraint(equalToConstant: 13),
            likesBadgeIcon.heightAnchor.constraint(equalToConstant: 13),

            likesBadgeLabel.topAnchor.constraint(equalTo: likesBadge.topAnchor, constant: 8),
            likesBadgeLabel.bottomAnchor.constraint(equalTo: likesBadge.bottomAnchor, constant: -8),
            likesBadgeLabel.leadingAnchor.constraint(equalTo: likesBadgeIcon.trailingAnchor, constant: 6),
            likesBadgeLabel.trailingAnchor.constraint(equalTo: likesBadge.trailingAnchor, constant: -12),

            infoStack.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 28),
            infoStack.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -28),
        ])
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
        let (collectionLikesCard, collectionLikesCount) = buildStatTile(
            sfIcon: "hand.thumbsup.fill",
            labelText: "Collection Likes",
            accent: UIColor.systemOrange
        )

        masteredCountLabel = masteredCount
        likedCountLabel = likedCount
        collectionLikesCountLabel = collectionLikesCount

        [masteredCard, likedCard, collectionLikesCard].forEach {
            $0.heightAnchor.constraint(equalToConstant: 112).isActive = true
            row.addArrangedSubview($0)
        }

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
        nameLabel.numberOfLines = 2
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

        let iconBg = UIView()
        iconBg.backgroundColor = accent.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 14
        iconBg.isUserInteractionEnabled = false
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconBg.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let iconImage = UIImageView(image: UIImage(systemName: sfIcon))
        iconImage.tintColor = accent
        iconImage.isUserInteractionEnabled = false
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconImage)

        NSLayoutConstraint.activate([
            iconImage.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconImage.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 22),
            iconImage.heightAnchor.constraint(equalToConstant: 22),
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
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
            card.heightAnchor.constraint(equalToConstant: 88),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        return card
    }

    private func loadData() {
        profileListener?.remove()
        profileListener = FirestoreService.shared.observeSocialUserProfileLiveData(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let liveData):
                    self.summary = liveData.summary
                    self.masteredIds = liveData.solvedProblemIds
                    self.likedIds = liveData.likedProblemIds

                    let viewerUserId = AuthService.shared.currentUserId
                    let existingViewerLike = self.likeState?.isLikedByViewer ?? false
                    self.likeState = SocialCollectionLikeState(
                        ownerUserId: self.userId,
                        viewerUserId: viewerUserId,
                        likeCount: liveData.summary.likedCollectionLikeCount,
                        isLikedByViewer: existingViewerLike
                    )
                    self.renderProfile()
                case .failure(let error):
                    self.showAlert(title: "Could not load profile", message: error.localizedDescription)
                }
            }
        }

        FirestoreService.shared.fetchLikedCollectionViewerState(
            ownerUserId: userId,
            viewerUserId: AuthService.shared.currentUserId
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let isLikedByViewer):
                    let count = self.likeState?.likeCount ?? self.summary?.likedCollectionLikeCount ?? 0
                    self.likeState = SocialCollectionLikeState(
                        ownerUserId: self.userId,
                        viewerUserId: AuthService.shared.currentUserId,
                        likeCount: count,
                        isLikedByViewer: isLikedByViewer
                    )
                    self.renderLikeState()
                case .failure(let error):
                    print("[SocialUserProfileViewController] Failed to load viewer like state: \(error.localizedDescription)")
                }
            }
        }
    }

    private func renderProfile() {
        guard let summary else { return }

        title = summary.userName
        avatarInitialsLabel.text = summary.initials
        userNameLabel.text = summary.userName
        scoreBadgeLabel.text = "\(summary.score) pts"

        masteredCountLabel?.text = "\(masteredIds.count)"
        likedCountLabel?.text = "\(likedIds.count)"
        renderLikeState()
    }

    private func renderLikeState() {
        let count = likeState?.likeCount ?? summary?.likedCollectionLikeCount ?? 0
        likesBadgeLabel.text = "\(count) likes"
        collectionLikesCountLabel?.text = "\(count)"

        let isLiked = likeState?.isLikedByViewer == true
        let symbolName = isLiked ? "hand.thumbsup.fill" : "hand.thumbsup"
        likeButton.setImage(UIImage(systemName: symbolName), for: .normal)
        likeButton.backgroundColor = isLiked
            ? UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 0.14)
            : UIColor.systemBlue.withAlphaComponent(0.10)
        likeButton.tintColor = isLiked
            ? UIColor(red: 0.33, green: 0.45, blue: 0.62, alpha: 1.0)
            : .systemBlue
        likeButton.accessibilityLabel = isLiked ? "Unlike collection" : "Like collection"
    }

    @objc private func likeCollectionTapped() {
        guard let viewerUserId = AuthService.shared.currentUserId else {
            showAlert(title: "Login Required", message: "Please log in to like collections.")
            return
        }

        let shouldLike = !(likeState?.isLikedByViewer == true)
        likeButton.isEnabled = false

        FirestoreService.shared.setLikedCollectionLike(
            ownerUserId: userId,
            viewerUserId: viewerUserId,
            liked: shouldLike
        ) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.likeButton.isEnabled = true

                if let error {
                    self.showAlert(title: "Could not update like", message: error.localizedDescription)
                    return
                }

                let currentCount = self.likeState?.likeCount ?? self.summary?.likedCollectionLikeCount ?? 0
                let nextCount = shouldLike ? currentCount + 1 : max(0, currentCount - 1)
                self.likeState = SocialCollectionLikeState(
                    ownerUserId: self.userId,
                    viewerUserId: viewerUserId,
                    likeCount: nextCount,
                    isLikedByViewer: shouldLike
                )
                self.renderLikeState()
                self.animateLikeButtonChange(isLiking: shouldLike)
            }
        }
    }

    @objc private func masteredTapped() {
        guard !masteredIds.isEmpty else {
            showAlert(title: "Nothing here yet", message: "This learner has not mastered any questions yet.")
            return
        }

        openReview(
            ids: masteredIds,
            title: "Mastered",
            icon: "✅",
            accent: UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0)
        )
    }

    @objc private func likedTapped() {
        guard !likedIds.isEmpty else {
            showAlert(title: "Nothing here yet", message: "This learner has not liked any questions yet.")
            return
        }

        openReview(
            ids: likedIds,
            title: "Liked",
            icon: "❤️",
            accent: UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0)
        )
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
                    let ownerName = self.summary?.userName ?? "Friend"
                    let descriptionText = title == "Liked"
                        ? "Practice directly from \(ownerName)'s saved collection."
                        : "Review questions \(ownerName) has already mastered."
                    let viewController = ProblemsViewController(
                        preloadedProblems: problems,
                        title: "\(ownerName) \(title)",
                        icon: icon,
                        accent: accent,
                        descriptionText: descriptionText
                    )
                    self.navigationController?.pushViewController(viewController, animated: true)
                case .success:
                    self.showAlert(title: "No problems found", message: "We couldn't load this deck right now.")
                case .failure:
                    self.showAlert(title: "Error", message: "Could not load problems. Please try again.")
                }
            }
        }
    }

    @objc private func reviewCardDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func reviewCardUp(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.68,
            initialSpringVelocity: 0.6,
            options: .allowUserInteraction
        ) {
            sender.transform = .identity
        }
    }

    private func animateLikeButtonChange(isLiking: Bool) {
        let generator = UIImpactFeedbackGenerator(style: isLiking ? .medium : .light)
        generator.impactOccurred()

        likeButton.transform = CGAffineTransform(scaleX: 0.84, y: 0.84)
        UIView.animate(
            withDuration: 0.42,
            delay: 0,
            usingSpringWithDamping: 0.52,
            initialSpringVelocity: 0.8,
            options: [.allowUserInteraction]
        ) {
            self.likeButton.transform = .identity
        }
    }
}
