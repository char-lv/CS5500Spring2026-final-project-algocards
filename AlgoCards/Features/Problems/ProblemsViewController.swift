//
//  ProblemsViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import UIKit

class ProblemsViewController: UIViewController {

    private let listTag: String
    private let deckTitleText: String
    private let viewModel = ProblemsViewModel()

    // Set when initialized from Profile (pre-fetched problems, no listTag lookup needed)
    private var preloadedProblems: [ProblemListItem]?
    private var overrideIcon: String?
    private var overrideAccent: UIColor?
    private var overrideDescriptionText: String?

    init(listTag: String, title: String) {
        self.listTag = listTag
        self.deckTitleText = title
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    /// Init for Profile lists (Mastered / Liked) — skips Firestore fetch.
    convenience init(
        preloadedProblems: [ProblemListItem],
        title: String,
        icon: String,
        accent: UIColor,
        descriptionText: String? = nil
    ) {
        self.init(listTag: "__preloaded__", title: title)
        self.preloadedProblems = preloadedProblems
        self.overrideIcon = icon
        self.overrideAccent = accent
        self.overrideDescriptionText = descriptionText
    }

    required init?(coder: NSCoder) { fatalError() }

    private let progressView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let deckIconBadge: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28)
        l.textAlignment = .center
        l.layer.cornerRadius = 22
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let deckTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 22)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let deckDescriptionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let progressLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        l.text = "Loading..."
        l.textAlignment = .center
        l.layer.cornerRadius = 10
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let difficultySegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["All", "Easy", "Medium", "Hard"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search by title or number..."
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(ProblemCell.self, forCellReuseIdentifier: ProblemCell.identifier)
        tv.rowHeight = 68
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No problems found"
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        setupUI()
        configureDeckPresentation()
        bindViewModel()

        if let preloaded = preloadedProblems {
            viewModel.setPreloadedProblems(preloaded)
        } else {
            viewModel.loadProblems(listTag: listTag)
        }
        viewModel.loadSolvedProblems()
    }

    private func setupUI() {
        [progressView, difficultySegment, searchBar,
         tableView, activityIndicator, emptyLabel].forEach {
            view.addSubview($0)
        }
        [deckIconBadge, deckTitleLabel, deckDescriptionLabel, progressLabel].forEach {
            progressView.addSubview($0)
        }
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        difficultySegment.addTarget(self, action: #selector(difficultyChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            deckIconBadge.topAnchor.constraint(equalTo: progressView.topAnchor, constant: 16),
            deckIconBadge.leadingAnchor.constraint(equalTo: progressView.leadingAnchor, constant: 16),
            deckIconBadge.widthAnchor.constraint(equalToConstant: 44),
            deckIconBadge.heightAnchor.constraint(equalToConstant: 44),

            deckTitleLabel.topAnchor.constraint(equalTo: progressView.topAnchor, constant: 16),
            deckTitleLabel.leadingAnchor.constraint(equalTo: deckIconBadge.trailingAnchor, constant: 12),
            deckTitleLabel.trailingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: -16),

            deckDescriptionLabel.topAnchor.constraint(equalTo: deckTitleLabel.bottomAnchor, constant: 4),
            deckDescriptionLabel.leadingAnchor.constraint(equalTo: deckTitleLabel.leadingAnchor),
            deckDescriptionLabel.trailingAnchor.constraint(equalTo: deckTitleLabel.trailingAnchor),

            progressLabel.topAnchor.constraint(equalTo: deckDescriptionLabel.bottomAnchor, constant: 12),
            progressLabel.leadingAnchor.constraint(equalTo: progressView.leadingAnchor, constant: 16),
            progressLabel.bottomAnchor.constraint(equalTo: progressView.bottomAnchor, constant: -16),
            progressLabel.heightAnchor.constraint(equalToConstant: 28),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 132),

            difficultySegment.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
            difficultySegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            difficultySegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            searchBar.topAnchor.constraint(equalTo: difficultySegment.bottomAnchor, constant: 4),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])
    }

    private func configureDeckPresentation() {
        let accentColor = overrideAccent ?? ProblemDeckConfig.color(forListTag: listTag)

        progressView.backgroundColor = accentColor.withAlphaComponent(0.10)
        progressView.layer.borderWidth = 1
        progressView.layer.borderColor = accentColor.withAlphaComponent(0.18).cgColor

        deckIconBadge.text = overrideIcon ?? ProblemDeckConfig.icon(forListTag: listTag)
        deckIconBadge.backgroundColor = accentColor.withAlphaComponent(0.16)
        deckTitleLabel.text = deckTitleText
        if let overrideDescriptionText {
            deckDescriptionLabel.text = overrideDescriptionText
        } else {
            deckDescriptionLabel.text = preloadedProblems != nil
                ? "Your saved \(deckTitleText.lowercased()) — filter by difficulty or search by title."
                : descriptionText(for: listTag, title: deckTitleText)
        }
        progressLabel.textColor = accentColor
        progressLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.82)
        searchBar.placeholder = searchPlaceholder(for: deckTitleText)
        emptyLabel.text = emptyStateText(for: listTag)
    }


    private func bindViewModel() {
        viewModel.onProblemsUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.viewModel.isLoading {
                    self.activityIndicator.startAnimating()
                    self.emptyLabel.isHidden = true
                    self.progressLabel.text = "Loading \(self.deckTitleText)..."
                } else {
                    self.activityIndicator.stopAnimating()
                    self.emptyLabel.isHidden = !self.viewModel.filteredProblems.isEmpty
                    self.tableView.reloadData()
                    self.progressLabel.text = "\(self.viewModel.solvedCount) / \(self.viewModel.totalCount) solved"
                }
            }
        }
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showError(message)
            }
        }
    }

    @objc private func difficultyChanged() {
        viewModel.applyDifficultyFilter(currentDifficultyFilter())
    }

    private func currentDifficultyFilter() -> DifficultyFilter? {
        switch difficultySegment.selectedSegmentIndex {
        case 1: return .easy
        case 2: return .medium
        case 3: return .hard
        default: return nil
        }
    }

    private func descriptionText(for tag: String, title: String) -> String {
        switch tag {
        case ProblemDeckConfig.favoritesTag:
            return "Save the problems you want to revisit, then come back here for focused review sessions."
        case "blind75":
            return "A focused interview deck covering the highest-signal classics across the most important patterns."
        case "hot100":
            return "A broad set of popular interview problems with strong coverage across frequently tested techniques."
        case "interview150":
            return "A broad interview prep deck modeled after LeetCode's classic Top Interview 150 study plan."
        case "linked-list":
            return "Practice pointer movement, in-place updates, and structural transformations on linked data."
        case "dynamic-programming":
            return "Build recurrence intuition, state transitions, and optimization patterns step by step."
        case "binary-search":
            return "Sharpen boundary handling, monotonic reasoning, and logarithmic search strategies."
        case "sliding-window":
            return "Train your eye for contiguous ranges, frequency tracking, and efficient window updates."
        case "two-pointers":
            return "Strengthen index coordination, partitioning, and ordered scanning techniques."
        case "tree":
            return "Work through recursive traversal, subtree reasoning, and hierarchical state management."
        case "graph":
            return "Cover traversal, connectivity, and dependency problems with BFS, DFS, and graph modeling."
        case "stack":
            return "Review monotonic stacks, expression parsing, and last-in-first-out modeling patterns."
        case "queue":
            return "Explore breadth-first traversal, scheduling, and first-in-first-out problem structures."
        default:
            return "Explore \(title.lowercased()) problems with searchable practice, difficulty filters, and saved progress."
        }
    }

    private func searchPlaceholder(for title: String) -> String {
        "Search \(title) by title or number..."
    }

    private func emptyStateText(for tag: String) -> String {
        if tag == ProblemDeckConfig.favoritesTag {
            return AuthService.shared.currentUserId == nil
                ? "Log in to save favorite problems and build your review deck."
                : "Tap the heart on any problem you want to revisit, and it will appear here."
        }

        return "No problems match the current filters."
    }
}


extension ProblemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredProblems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProblemCell.identifier,
            for: indexPath
        ) as! ProblemCell
        let problem = viewModel.filteredProblems[indexPath.row]
        cell.configure(with: problem, isSolved: viewModel.isSolved(problem.id))
        return cell
    }
}


extension ProblemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let problem = viewModel.filteredProblems[indexPath.row]

        guard !problem.isPaidOnly else {
            showAlert(title: "Premium Problem",
                      message: "This problem requires a LeetCode Premium subscription.")
            return
        }

        let flashCardVC = FlashCardViewController(
            problems: viewModel.filteredProblems,
            currentIndex: indexPath.row,
            solvedProblemIds: Set(viewModel.solvedProblemIds)
        )
        navigationController?.pushViewController(flashCardVC, animated: true)
    }
}

extension ProblemsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
