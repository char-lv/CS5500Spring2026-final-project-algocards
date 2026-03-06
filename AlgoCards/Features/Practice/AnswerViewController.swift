//
//  AnswerViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/5/26.
//

import Foundation
import UIKit

class AnswerViewController: UIViewController {

    private let problem: ProblemListItem
    private var isSaving = false
    private var keyboardHeight: CGFloat = 0

    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let difficultyBadge: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 11)
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let problemTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 15)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textColor = .label
        tv.backgroundColor = .systemBackground
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "Write your approach, key insights, or notes here..."
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = .tertiaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let charCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.text = "0 characters"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save Notes", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 123/255, green: 143/255, blue: 161/255, alpha: 1.0)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var bottomBarBottomConstraint: NSLayoutConstraint!

    init(problem: ProblemListItem) {
        self.problem = problem
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Notes"
        view.backgroundColor = .systemBackground
        setupUI()
        setupKeyboard()
        configureProblemHeader()
        // loadExistingAnswer()  // uncomment after Firebase Auth is set up
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    private func setupUI() {
        [headerView, divider, textView, placeholderLabel, bottomBar].forEach {
            view.addSubview($0)
        }
        headerView.addSubview(difficultyBadge)
        headerView.addSubview(problemTitleLabel)
        bottomBar.addSubview(charCountLabel)
        bottomBar.addSubview(saveButton)

        textView.delegate = self
        saveButton.addTarget(self, action: #selector(onSaveTapped), for: .touchUpInside)

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self,
                                   action: #selector(dismissKeyboard))
        toolbar.items = [flex, done]
        textView.inputAccessoryView = toolbar

        bottomBarBottomConstraint = bottomBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            difficultyBadge.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            difficultyBadge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            difficultyBadge.widthAnchor.constraint(equalToConstant: 58),
            difficultyBadge.heightAnchor.constraint(equalToConstant: 22),

            problemTitleLabel.leadingAnchor.constraint(equalTo: difficultyBadge.trailingAnchor, constant: 10),
            problemTitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            problemTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),


            divider.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            textView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 20),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 18),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -18),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 80),
            bottomBarBottomConstraint,

            charCountLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            charCountLabel.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),

            saveButton.topAnchor.constraint(equalTo: charCountLabel.bottomAnchor, constant: 4),
            saveButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func configureProblemHeader() {
        problemTitleLabel.text = problem.title
        switch problem.difficulty {
        case .easy:
            difficultyBadge.text = "Easy"
            difficultyBadge.textColor = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
            difficultyBadge.backgroundColor = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 0.15)
        case .medium:
            difficultyBadge.text = "Medium"
            difficultyBadge.textColor = UIColor(red: 196/255, green: 168/255, blue: 130/255, alpha: 1.0)
            difficultyBadge.backgroundColor = UIColor(red: 196/255, green: 168/255, blue: 130/255, alpha: 0.15)
        case .hard:
            difficultyBadge.text = "Hard"
            difficultyBadge.textColor = UIColor(red: 176/255, green: 138/255, blue: 138/255, alpha: 1.0)
            difficultyBadge.backgroundColor = UIColor(red: 176/255, green: 138/255, blue: 138/255, alpha: 0.15)
        }
    }

    // Keyboard
    private func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        bottomBarBottomConstraint.constant = -keyboardFrame.height
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        bottomBarBottomConstraint.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func onSaveTapped() {
        guard !isSaving else { return }
        let notes = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !notes.isEmpty else {
            showAlert(title: "Empty Notes", message: "Nothing to save, feel free to write down some notes.")
            return
        }
        guard let userId = AuthService.shared.currentUserId else {
            showAlert(title: "Login Required", message: "Please log in to save your notes.")
            return
        }

        isSaving = true
        saveButton.setTitle("Saving...", for: .normal)
        saveButton.isEnabled = false

        let answer = Answer(problemId: problem.id, userId: userId, notes: notes)

        FirestoreService.shared.saveAnswer(answer, userId: userId) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                self?.saveButton.isEnabled = true
                if error == nil {
                    self?.saveButton.setTitle("✅  Saved!", for: .normal)
                    self?.saveButton.backgroundColor = UIColor(
                        red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0
                    )
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.saveButton.setTitle("Save Notes", for: .normal)
                        self?.saveButton.backgroundColor = UIColor(
                            red: 123/255, green: 143/255, blue: 161/255, alpha: 1.0
                        )
                    }
                } else {
                    self?.saveButton.setTitle("Save Notes", for: .normal)
                    self?.showError(error!.localizedDescription)
                }
            }
        }
    }
}

extension AnswerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        charCountLabel.text = "\(textView.text.count) characters"
    }
}
