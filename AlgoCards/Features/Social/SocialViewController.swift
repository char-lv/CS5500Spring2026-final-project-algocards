//
//  SocialViewController.swift
//  AlgoCards
//

import UIKit
import FirebaseFirestore

final class SocialViewController: UIViewController {
    private var users: [SocialUserSummary] = []
    private var usersListener: ListenerRegistration?

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 96
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No other learners yet.\nInvite a friend to start sharing decks."
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Social"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        startObservingUsers()
    }

    deinit {
        usersListener?.remove()
    }

    private func setupUI() {
        tableView.register(SocialUserCell.self, forCellReuseIdentifier: SocialUserCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),

            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func startObservingUsers() {
        loadingView.startAnimating()
        usersListener?.remove()
        usersListener = FirestoreService.shared.observeSocialUsers(excluding: AuthService.shared.currentUserId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loadingView.stopAnimating()

                switch result {
                case .success(let users):
                    self.users = users
                    self.emptyStateLabel.isHidden = !users.isEmpty
                    self.tableView.reloadData()
                case .failure(let error):
                    self.emptyStateLabel.isHidden = false
                    self.emptyStateLabel.text = "Could not load users right now.\n\(error.localizedDescription)"
                }
            }
        }
    }
}

extension SocialViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SocialUserCell.reuseId, for: indexPath) as? SocialUserCell else {
            return UITableViewCell()
        }

        cell.configure(with: users[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let viewController = SocialUserProfileViewController(userId: user.id)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
