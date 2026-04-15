//
//  ProblemCell.swift
//  AlgoCards
//
//  Created by Minghui Xu on 3/4/26.
//

import Foundation
import UIKit

class ProblemCell: UITableViewCell {

    static let identifier = "ProblemCell"

    private let numberLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let acRateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 11)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let difficultyBadge: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 11)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let checkmark: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .systemGreen
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let difficultyBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        [difficultyBar, numberLabel, titleLabel,
         acRateLabel, difficultyBadge, checkmark].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            difficultyBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            difficultyBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            difficultyBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            difficultyBar.widthAnchor.constraint(equalToConstant: 4),

            numberLabel.leadingAnchor.constraint(equalTo: difficultyBar.trailingAnchor, constant: 12),
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            numberLabel.widthAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: numberLabel.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: difficultyBadge.leadingAnchor, constant: -8),

            acRateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            acRateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            acRateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            difficultyBadge.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -8),
            difficultyBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            difficultyBadge.widthAnchor.constraint(equalToConstant: 62),
            difficultyBadge.heightAnchor.constraint(equalToConstant: 22),

            checkmark.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 20),
            checkmark.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with problem: ProblemListItem, isSolved: Bool) {
        numberLabel.text = "#\(problem.id)"
        checkmark.isHidden = !isSolved

        if problem.isPaidOnly {
            titleLabel.text = "🔒 \(problem.title)"
            titleLabel.textColor = .secondaryLabel
            acRateLabel.text = "Premium only"
        } else {
            titleLabel.text = problem.title
            titleLabel.textColor = .label
            acRateLabel.text = "AC: \(problem.formattedAcRate)"
        }

        switch problem.difficulty {
        case .easy:
            let easyColor = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
            difficultyBadge.text = "Easy"
            difficultyBadge.textColor = easyColor
            difficultyBadge.backgroundColor = easyColor.withAlphaComponent(0.15)
            difficultyBar.backgroundColor = easyColor
        case .medium:
            let medColor = UIColor(red: 196/255, green: 168/255, blue: 130/255, alpha: 1.0)
            difficultyBadge.text = "Medium"
            difficultyBadge.textColor = medColor
            difficultyBadge.backgroundColor = medColor.withAlphaComponent(0.15)
            difficultyBar.backgroundColor = medColor
        case .hard:
            let hardColor = UIColor(red: 176/255, green: 138/255, blue: 138/255, alpha: 1.0)
            difficultyBadge.text = "Hard"
            difficultyBadge.textColor = hardColor
            difficultyBadge.backgroundColor = hardColor.withAlphaComponent(0.15)
            difficultyBar.backgroundColor = hardColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        checkmark.isHidden = true
        titleLabel.textColor = .label
    }
}

