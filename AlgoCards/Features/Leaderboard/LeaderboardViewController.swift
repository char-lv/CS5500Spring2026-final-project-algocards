//
//  LeaderboardViewController.swift
//  AlgoCards
//

import UIKit

// MARK: - LeaderboardCell

private class LeaderboardCell: UITableViewCell {
    static let reuseId = "LeaderboardCustomCell"

    // Thin left accent stripe for top 3 + current user
    private let accentBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let rankLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Gradient circle with user initials — mirrors Profile avatar style
    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarGradient = CAGradientLayer()

    private let initialsLabel: UILabel = {
        let l = UILabel()
        l.font = .boldSystemFont(ofSize: 14)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Score pill: a container view so we get proper inset padding
    private let scorePill: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 11
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = .boldSystemFont(ofSize: 12)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarGradient.frame = avatarView.bounds
    }

    // MARK: - Layout

    private func setupUI() {
        selectionStyle = .none

        // Muted green → slate blue gradient (same as Profile avatar)
        avatarGradient.colors = [
            UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1.0).cgColor,
            UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1.0).cgColor,
        ]
        avatarGradient.startPoint = CGPoint(x: 0, y: 0)
        avatarGradient.endPoint = CGPoint(x: 1, y: 1)
        avatarView.layer.addSublayer(avatarGradient)

        avatarView.addSubview(initialsLabel)
        scorePill.addSubview(scoreLabel)
        [accentBar, rankLabel, avatarView, nameLabel, scorePill].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            accentBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: 3),

            rankLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 38),

            avatarView.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 6),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: scorePill.leadingAnchor, constant: -8),

            scorePill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scorePill.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            scorePill.heightAnchor.constraint(equalToConstant: 28),

            scoreLabel.leadingAnchor.constraint(equalTo: scorePill.leadingAnchor, constant: 10),
            scoreLabel.trailingAnchor.constraint(equalTo: scorePill.trailingAnchor, constant: -10),
            scoreLabel.centerYAnchor.constraint(equalTo: scorePill.centerYAnchor),
        ])
    }

    // MARK: - Configure

    func configure(user: User, rank: Int, isCurrentUser: Bool) {
        // Rank indicator
        if rank <= 3 {
            rankLabel.text = ["🥇", "🥈", "🥉"][rank - 1]
            rankLabel.font = .systemFont(ofSize: 22)
        } else {
            rankLabel.text = "#\(rank)"
            rankLabel.font = .boldSystemFont(ofSize: 13)
            rankLabel.textColor = .tertiaryLabel
        }

        // Avatar initials
        let words = user.userName.split(separator: " ").prefix(2)
        let initials = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        initialsLabel.text = initials.isEmpty ? "?" : initials

        nameLabel.text = user.userName
        scoreLabel.text = "\(user.score) pts"

        // Row color scheme — current user takes precedence over rank tint
        if isCurrentUser {
            let accent = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
            contentView.backgroundColor = accent.withAlphaComponent(0.10)
            accentBar.backgroundColor = accent
            scorePill.backgroundColor = accent.withAlphaComponent(0.20)
            scoreLabel.textColor = UIColor(red: 0.22, green: 0.48, blue: 0.22, alpha: 1.0)
            nameLabel.textColor = .label
        } else {
            nameLabel.textColor = .label
            switch rank {
            case 1:
                contentView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.10)
                accentBar.backgroundColor = UIColor(red: 0.95, green: 0.78, blue: 0.10, alpha: 1.0)
                scorePill.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.18)
                scoreLabel.textColor = UIColor(red: 0.52, green: 0.42, blue: 0.0, alpha: 1.0)
            case 2:
                contentView.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.55)
                accentBar.backgroundColor = UIColor(red: 0.68, green: 0.68, blue: 0.72, alpha: 1.0)
                scorePill.backgroundColor = UIColor.systemGray5
                scoreLabel.textColor = .secondaryLabel
            case 3:
                contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.07)
                accentBar.backgroundColor = UIColor(red: 0.72, green: 0.48, blue: 0.28, alpha: 1.0)
                scorePill.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.13)
                scoreLabel.textColor = UIColor(red: 0.52, green: 0.30, blue: 0.08, alpha: 1.0)
            default:
                contentView.backgroundColor = .systemBackground
                accentBar.backgroundColor = .clear
                scorePill.backgroundColor = .systemGray6
                scoreLabel.textColor = .secondaryLabel
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .systemBackground
        accentBar.backgroundColor = .clear
        scorePill.backgroundColor = .systemGray6
        scoreLabel.textColor = .secondaryLabel
        rankLabel.textColor = .label
    }
}

// MARK: - LeaderboardViewController

class LeaderboardViewController: UITableViewController {

    // MARK: - State

    private enum FetchState {
        case loading, loaded, empty, failed
    }

    private var state: FetchState = .loading
    private var users: [User] = []
    private let currentUserId = AuthService.shared.currentUserId
    private var hasAnimatedRows = false

    // MARK: - Subviews

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        return s
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Leaderboard"
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = 72
        // Separator starts after avatar column: accentBar(3)+pad(12)+rank(38)+gap(6)+avatar(40)+gap(12) = 111
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 111, bottom: 0, right: 0)
        tableView.register(LeaderboardCell.self, forCellReuseIdentifier: LeaderboardCell.reuseId)
        tableView.backgroundView = spinner
        spinner.startAnimating()
        loadLeaderboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Animate rows only once, and only when data is ready
        guard state == .loaded, !hasAnimatedRows else { return }
        hasAnimatedRows = true
        animateVisibleRows()
    }

    // MARK: - Animation

    private func animateVisibleRows() {
        tableView.visibleCells.enumerated().forEach { index, cell in
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 28)
            UIView.animate(
                withDuration: 0.46,
                delay: Double(index) * 0.055,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction],
                animations: {
                    cell.alpha = 1
                    cell.transform = .identity
                }
            )
        }
    }

    // MARK: - Data

    private func loadLeaderboard() {
        FirestoreService.shared.fetchLeaderboard { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                switch result {
                case .success(let users):
                    self.users = users
                    self.state = users.isEmpty ? .empty : .loaded
                case .failure:
                    self.state = .failed
                }
                self.tableView.reloadData()
                // Fire row animation immediately if the view is already on screen
                if !self.hasAnimatedRows, self.state == .loaded {
                    self.hasAnimatedRows = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateVisibleRows()
                    }
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .loading:          return 0
        case .loaded:           return users.count
        case .empty, .failed:   return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch state {
        case .loading:
            return UITableViewCell()

        case .empty:
            let cell = UITableViewCell()
            cell.textLabel?.text = "No entries yet."
            cell.textLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            cell.backgroundColor = .systemGroupedBackground
            return cell

        case .failed:
            let cell = UITableViewCell()
            cell.textLabel?.text = "Could not load leaderboard. Check your connection."
            cell.textLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            cell.backgroundColor = .systemGroupedBackground
            return cell

        case .loaded:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: LeaderboardCell.reuseId, for: indexPath
            ) as! LeaderboardCell
            let user = users[indexPath.row]
            cell.configure(user: user, rank: indexPath.row + 1, isCurrentUser: user.id == currentUserId)
            return cell
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
