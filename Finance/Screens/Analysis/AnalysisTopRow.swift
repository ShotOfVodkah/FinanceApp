//
//  AnalysisTopRow.swift
//  Finance
//
//  Created by Stepan Polyakov on 09.07.2025.
//
import UIKit

class AnalysisTopRow: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }
    
    private func setupViews() {
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .label
        
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.textAlignment = .right
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(title: String, control: UIView) {
        titleLabel.text = title
        valueLabel.text = nil
        
        contentView.subviews.filter { $0 is UIControl }.forEach { $0.removeFromSuperview() }
        
        control.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(control)
        
        NSLayoutConstraint.activate([
            control.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
        
        contentView.subviews.filter { $0 is UIControl }.forEach { $0.removeFromSuperview() }
    }
}
