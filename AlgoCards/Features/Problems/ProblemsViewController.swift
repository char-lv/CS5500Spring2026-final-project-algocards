//
//  ProblemsViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import UIKit

class ProblemsViewController: UIViewController {

    private let listTag: String
    private let viewModel = ProblemsViewModel()

    init(listTag: String, title: String) {
        self.listTag = listTag
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    required init?(coder: NSCoder) { fatalError() }

    private let progressView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let progressLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.text = "Loading..."
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
        tv.rowHeight = 62
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
        setupUI()
        bindViewModel()

        viewModel.loadProblems(listTag: listTag)
        viewModel.loadSolvedProblems()
    }

    private func setupUI() {
        [progressView, difficultySegment, searchBar,
         tableView, activityIndicator, emptyLabel].forEach {
            view.addSubview($0)
        }
        progressView.addSubview(progressLabel)
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        difficultySegment.addTarget(self, action: #selector(difficultyChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 36),
            progressLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            progressLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),

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


    private func bindViewModel() {
        viewModel.onProblemsUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.viewModel.isLoading {
                    self.activityIndicator.startAnimating()
                    self.emptyLabel.isHidden = true
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
            currentIndex: indexPath.row
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
