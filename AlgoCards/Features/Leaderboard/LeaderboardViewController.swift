//
//  LeaderboardViewController.swift
//  AlgoCards
//

import UIKit

class LeaderboardViewController: UITableViewController {

    // MARK: - State

    private enum FetchState {
        case loading
        case loaded
        case empty
        case failed
    }

    private var state: FetchState = .loading
    private var users: [User] = []
    private let currentUserId = AuthService.shared.currentUserId

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
        tableView.rowHeight = 60
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.backgroundView = spinner
        spinner.startAnimating()
        loadLeaderboard()
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
        // Use .value1 style (name on left, score on right) without a custom subclass.
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "LeaderboardCell")

        cell.selectionStyle = .none

        switch state {
        case .loading:
            break

        case .empty:
            cell.textLabel?.text = "No entries yet."
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.text = nil
            cell.backgroundColor = .systemGroupedBackground

        case .failed:
            cell.textLabel?.text = "Could not load leaderboard. Check your connection."
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.text = nil
            cell.backgroundColor = .systemGroupedBackground

        case .loaded:
            let user = users[indexPath.row]
            let rank = indexPath.row + 1
            let prefix: String
            switch rank {
            case 1: prefix = "🥇"
            case 2: prefix = "🥈"
            case 3: prefix = "🥉"
            default: prefix = "#\(rank)"
            }

            cell.textLabel?.text = "\(prefix)  \(user.userName)"
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.text = "\(user.score) pts"
            cell.detailTextLabel?.textColor = .secondaryLabel

            // Highlight the current user's row.
            if let uid = currentUserId, user.id == uid {
                cell.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
            } else {
                cell.backgroundColor = .systemBackground
            }
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
