//
//  HomeViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/5/26.
//

import Foundation
import UIKit

class HomeViewController: UIViewController {


    private let categoryLists = APIConfigs.Category.allCases
    private let curatedLists: [(title: String, tag: String, icon: String, color: UIColor)] = [
        ("Blind 75",  "blind75", "🎯", .systemPurple),
        ("Hot 100",   "hot100",  "🔥", .systemRed),
    ]

    private var isDailyLoading = false
    private weak var dailyCardButton: UIButton?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 24
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "AlgoCards"
        l.font = UIFont.boldSystemFont(ofSize: 32)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose a list to start practicing"
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = ""
        print("[HomeViewController] Loaded — current UID: \(AuthService.shared.currentUserId ?? "nil")")
        setupUI()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Sign Out",
            style: .plain,
            target: self,
            action: #selector(signOutTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trophy"),
            style: .plain,
            target: self,
            action: #selector(leaderboardTapped)
        )
    }

    @objc private func leaderboardTapped() {
        navigationController?.pushViewController(LeaderboardViewController(), animated: true)
    }

    @objc private func signOutTapped() {
        AuthService.shared.signOut()
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.showAuth()
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
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        buildHeader()

        // Daily Challenge
        buildSection(title: "⚡ Daily Challenge") {
            self.makeDailyChallengeCard()
        }

        // Curated Lists
        buildSection(title: "📚 Curated Lists") {
            self.buildCuratedGrid()
        }

        // Category
        buildSection(title: "🗂 By Category") {
            self.buildCategoryGrid()
        }
    }

    private func buildHeader() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        contentStack.addArrangedSubview(stack)
    }

    private func buildSection(title: String, content: () -> UIView) {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 12

        let label = UILabel()
        label.text = title
        label.font = UIFont.boldSystemFont(ofSize: 18)
        sectionStack.addArrangedSubview(label)
        sectionStack.addArrangedSubview(content())
        contentStack.addArrangedSubview(sectionStack)
    }

    private func buildCuratedGrid() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually

        curatedLists.forEach { item in
            let card = makeCuratedCard(item)
            stack.addArrangedSubview(card)
        }
        return stack
    }

    private func makeCuratedCard(
        _ item: (title: String, tag: String, icon: String, color: UIColor)
    ) -> UIView {
        let card = UIButton(type: .system)
        card.backgroundColor = item.color.withAlphaComponent(0.12)
        card.layer.cornerRadius = 16
        card.tag = curatedLists.firstIndex(where: { $0.tag == item.tag }) ?? 0
        card.addTarget(self, action: #selector(curatedTapped(_:)), for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = UIFont.systemFont(ofSize: 32)

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = item.color

        stack.addArrangedSubview(iconLabel)
        stack.addArrangedSubview(titleLabel)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        return card
    }


    private func buildCategoryGrid() -> UIView {
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 12


        let chunked = categoryLists.chunked(into: 2)
        chunked.forEach { row in
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually

            row.forEach { category in
                let card = makeCategoryCard(category)
                rowStack.addArrangedSubview(card)
            }
            outerStack.addArrangedSubview(rowStack)
        }
        return outerStack
    }

    private func makeCategoryCard(_ category: APIConfigs.Category) -> UIView {
        let card = UIButton(type: .system)
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.tag = APIConfigs.Category.allCases.firstIndex(of: category) ?? 0
        card.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = category.icon
        iconLabel.font = UIFont.systemFont(ofSize: 28)

        let titleLabel = UILabel()
        titleLabel.text = category.displayName
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .label

        stack.addArrangedSubview(iconLabel)
        stack.addArrangedSubview(titleLabel)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 90),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        return card
    }

    // MARK: - Daily Challenge

    private func makeDailyChallengeCard() -> UIView {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.12)
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(dailyTapped), for: .touchUpInside)

        let iconLabel = UILabel()
        iconLabel.text = "⚡"
        iconLabel.font = UIFont.systemFont(ofSize: 28)
        iconLabel.isUserInteractionEnabled = false

        let titleLabel = UILabel()
        titleLabel.text = "Today's Challenge"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap to solve today's problem"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.tag = 42

        let row = UIStackView(arrangedSubviews: [iconLabel, textStack, UIView(), spinner])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        btn.addSubview(row)
        NSLayoutConstraint.activate([
            btn.heightAnchor.constraint(equalToConstant: 80),
            row.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
        ])

        dailyCardButton = btn
        return btn
    }

    @objc private func dailyTapped() {
        guard !isDailyLoading else { return }
        isDailyLoading = true
        dailyCardButton?.isEnabled = false
        (dailyCardButton?.viewWithTag(42) as? UIActivityIndicatorView)?.startAnimating()

        NetworkManager.shared.fetchDailyProblem { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isDailyLoading = false
                self.dailyCardButton?.isEnabled = true
                (self.dailyCardButton?.viewWithTag(42) as? UIActivityIndicatorView)?.stopAnimating()

                switch result {
                case .success(let problem):
                    let listItem = ProblemListItem(
                        id: problem.id,
                        title: problem.title,
                        titleSlug: problem.titleSlug,
                        difficulty: problem.difficulty,
                        acRate: 0.0,
                        isPaidOnly: false,
                        hasSolution: true,
                        topicTags: []
                    )
                    let vc = FlashCardViewController(problems: [listItem], currentIndex: 0)
                    self.navigationController?.pushViewController(vc, animated: true)
                case .failure:
                    self.showAlert(title: "Could not load daily problem",
                                   message: "Please check your connection and try again.")
                }
            }
        }
    }

    @objc private func curatedTapped(_ sender: UIButton) {
        let item = curatedLists[sender.tag]
        let vc = ProblemsViewController(listTag: item.tag, title: item.title)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let category = APIConfigs.Category.allCases[sender.tag]
        let vc = ProblemsViewController(listTag: category.rawValue, title: category.displayName)
        navigationController?.pushViewController(vc, animated: true)
    }
}


private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
