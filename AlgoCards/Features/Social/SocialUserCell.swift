//
//  SocialUserCell.swift
//  AlgoCards
//

import UIKit

final class SocialUserCell: UITableViewCell {
    static let reuseId = "SocialUserCell"

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let avatarGradient = CAGradientLayer()

    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scorePill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 0.14)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor(red: 0.28, green: 0.52, blue: 0.28, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scoreIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "star.fill"))
        imageView.tintColor = UIColor(red: 0.28, green: 0.52, blue: 0.28, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let likesPill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 0.12)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(red: 0.33, green: 0.45, blue: 0.62, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let likesIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "hand.thumbsup.fill"))
        imageView.tintColor = UIColor(red: 0.33, green: 0.45, blue: 0.62, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let chevronView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .tertiaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarGradient.frame = avatarView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        initialsLabel.text = "?"
        nameLabel.text = nil
        subtitleLabel.text = nil
        scoreLabel.text = nil
        likesLabel.text = nil
    }

    func configure(with user: SocialUserSummary) {
        initialsLabel.text = user.initials
        nameLabel.text = user.userName
        subtitleLabel.text = "\(user.solvedCount) mastered • \(user.likedCount) liked"
        scoreLabel.text = "\(user.score) pts"
        likesLabel.text = "\(user.likedCollectionLikeCount)"
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarGradient.colors = [
            UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0).cgColor,
            UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0).cgColor,
        ]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0)
        avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarView.layer.addSublayer(avatarGradient)
        avatarView.addSubview(initialsLabel)
        initialsLabel.text = "?"

        scorePill.addSubview(scoreIcon)
        scorePill.addSubview(scoreLabel)
        likesPill.addSubview(likesIcon)
        likesPill.addSubview(likesLabel)
        contentView.addSubview(cardView)
        [avatarView, nameLabel, subtitleLabel, scorePill, likesPill, chevronView].forEach {
            cardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: scorePill.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: likesLabel.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16),

            scorePill.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            scorePill.trailingAnchor.constraint(equalTo: likesPill.leadingAnchor, constant: -8),

            scoreIcon.leadingAnchor.constraint(equalTo: scorePill.leadingAnchor, constant: 10),
            scoreIcon.centerYAnchor.constraint(equalTo: scorePill.centerYAnchor),
            scoreIcon.widthAnchor.constraint(equalToConstant: 11),
            scoreIcon.heightAnchor.constraint(equalToConstant: 11),

            scoreLabel.topAnchor.constraint(equalTo: scorePill.topAnchor, constant: 6),
            scoreLabel.bottomAnchor.constraint(equalTo: scorePill.bottomAnchor, constant: -6),
            scoreLabel.leadingAnchor.constraint(equalTo: scoreIcon.trailingAnchor, constant: 6),
            scoreLabel.trailingAnchor.constraint(equalTo: scorePill.trailingAnchor, constant: -10),

            likesPill.centerYAnchor.constraint(equalTo: scorePill.centerYAnchor),
            likesPill.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -10),

            likesIcon.leadingAnchor.constraint(equalTo: likesPill.leadingAnchor, constant: 10),
            likesIcon.centerYAnchor.constraint(equalTo: likesPill.centerYAnchor),
            likesIcon.widthAnchor.constraint(equalToConstant: 12),
            likesIcon.heightAnchor.constraint(equalToConstant: 12),

            likesLabel.topAnchor.constraint(equalTo: likesPill.topAnchor, constant: 6),
            likesLabel.bottomAnchor.constraint(equalTo: likesPill.bottomAnchor, constant: -6),
            likesLabel.leadingAnchor.constraint(equalTo: likesIcon.trailingAnchor, constant: 6),
            likesLabel.trailingAnchor.constraint(equalTo: likesPill.trailingAnchor, constant: -10),

            chevronView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronView.widthAnchor.constraint(equalToConstant: 10),
        ])
    }
}
