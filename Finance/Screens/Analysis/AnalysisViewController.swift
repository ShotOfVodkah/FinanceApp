//
//  AnalysisViewController.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//

import UIKit

class AnalysisViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var viewModel: AnalysisViewModel!
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let fromDatePicker = UIDatePicker()
    private let toDatePicker = UIDatePicker()
    private let totalLabel = UILabel()
    
    init(viewModel: AnalysisViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6

        setupDatePickers()
        setupTotalLabel()
        setupTableView()
        setupBindings()
        
        loadData()
    }
    
    
    private func setupDatePickers() {
        fromDatePicker.datePickerMode = .date
        fromDatePicker.maximumDate = Date()
        fromDatePicker.date = viewModel.from
        fromDatePicker.addTarget(self, action: #selector(fromDateChanged), for: .valueChanged)
        fromDatePicker.preferredDatePickerStyle = .compact
        
        toDatePicker.datePickerMode = .date
        toDatePicker.maximumDate = Date()
        toDatePicker.date = viewModel.to
        toDatePicker.addTarget(self, action: #selector(toDateChanged), for: .valueChanged)
        toDatePicker.preferredDatePickerStyle = .compact
    }
    
    private func setupTotalLabel() {
        totalLabel.textAlignment = .right
        totalLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        totalLabel.textColor = .label
        updateTotalLabel()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        tableView.register(AnalysisTopRow.self, forCellReuseIdentifier: "FilterCell")
        tableView.backgroundColor = UIColor.systemGray6
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.onDatesUpdated = { [weak self] in
            guard let self = self else { return }
            self.fromDatePicker.date = self.viewModel.from
            self.toDatePicker.date = self.viewModel.to
        }
        
        viewModel.onDataLoaded = { [weak self] in
            self?.tableView.reloadData()
            self?.updateTotalLabel()
            self?.title = "Анализ"
        }
    }
    
    @objc private func fromDateChanged() {
        viewModel.updateFromDate(fromDatePicker.date)
    }
    
    @objc private func toDateChanged() {
        viewModel.updateToDate(toDatePicker.date)
    }
    
    private func loadData() {
        viewModel.loadData()
    }
    
    private func updateTotalLabel() {
        totalLabel.text = "\(viewModel.total) ₽"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? "ОПЕРАЦИИ" : nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 3 : viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as! AnalysisTopRow
            
            switch indexPath.row {
            case 0:
                cell.configure(title: "Начало", control: fromDatePicker)
            case 1:
                cell.configure(title: "Конец", control: toDatePicker)
            case 2:
                cell.configure(title: "Сумма", value: totalLabel.text ?? "")
            default:
                break
            }
            
            return cell
        } else {
            let (transaction, category) = viewModel.items[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionTableViewCell
            let percentage = viewModel.percentage(for: transaction)
            cell.configure(with: transaction, category: category, percentage: percentage)
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        indexPath.section != 0
    }
}




