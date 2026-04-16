//
//  ProblemListPickerViewController.swift
//  AlgoCards
//
//  Lightweight modal sheet that lists all problems in the current study deck.
//  The user taps a row to jump directly to that card in FlashCardViewController.
//
//  V1 constraints:
//  - Display-only: no search, no difficulty filter, no sorting
//  - Data comes entirely from the caller's in-memory array (zero Firestore calls)
//  - Navigation is handled by the caller via the onSelect closure
//

import UIKit

class ProblemListPickerViewController: UIViewController {

    // MARK: - State

    private let problems: [ProblemListItem]
    private let currentIndex: Int
    private let solvedProblemIds: Set<String>
    /// Invoked with the chosen row index when the user taps a non-premium problem.
    /// The caller is responsible for updating currentIndex and reloading the card.
    private let onSelect: (Int) -> Void

    // MARK: - UI

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(ProblemCell.self, forCellReuseIdentifier: ProblemCell.identifier)
        tv.rowHeight = 68
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Init

    init(
        problems: [ProblemListItem],
        currentIndex: Int,
        solvedProblemIds: Set<String>,
        onSelect: @escaping (Int) -> Void
    ) {
        self.problems = problems
        self.currentIndex = currentIndex
        self.solvedProblemIds = solvedProblemIds
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Jump to Problem"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Scroll so the currently active card is visible without the user having to hunt for it.
        let indexPath = IndexPath(row: currentIndex, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ProblemListPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        problems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProblemCell.identifier,
            for: indexPath
        ) as! ProblemCell
        let problem = problems[indexPath.row]
        cell.configure(with: problem, isSolved: solvedProblemIds.contains(problem.id))
        // Highlight the row that matches the card currently on-screen.
        cell.backgroundColor = indexPath.row == currentIndex
            ? UIColor.systemIndigo.withAlphaComponent(0.08)
            : .systemBackground
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProblemListPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let problem = problems[indexPath.row]
        guard !problem.isPaidOnly else {
            let alert = UIAlertController(
                title: "Premium Problem",
                message: "This problem requires a LeetCode Premium subscription.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        onSelect(indexPath.row)
        dismiss(animated: true)
    }
}
