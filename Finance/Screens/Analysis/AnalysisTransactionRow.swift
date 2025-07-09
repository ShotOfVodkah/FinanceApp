//
//  AnalysisTransactionRow.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        label.backgroundColor = UIColor(named: "AccentColor")?.withAlphaComponent(0.2)
        label.layer.cornerRadius = 16
        label.layer.masksToBounds = true
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    
    private let amountStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .trailing
        return stack
    }()
    
    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "chevron.right")
        imageView.image = image
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("")
    }

    private func setup() {
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(emojiLabel)
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(UIView())
        amountStack.addArrangedSubview(percentageLabel)
        amountStack.addArrangedSubview(amountLabel)
        stack.addArrangedSubview(amountStack)
        stack.addArrangedSubview(chevronImageView)
        
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        amountStack.setContentHuggingPriority(.required, for: .horizontal)
        amountStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            emojiLabel.widthAnchor.constraint(equalToConstant: 32),
            emojiLabel.heightAnchor.constraint(equalToConstant: 32),
            
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }


    func configure(with transaction: Transaction, category: Category, percentage: String) {
        emojiLabel.text = String(category.emoji)
        nameLabel.text = category.name
        amountLabel.text = "\(transaction.amount) ₽"
        percentageLabel.text = percentage
    }
}

