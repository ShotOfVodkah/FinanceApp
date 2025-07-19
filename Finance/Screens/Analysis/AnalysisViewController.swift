//
//  AnalysisViewController.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//
import UIKit
import SwiftUI
import Combine

class AnalysisViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAdaptivePresentationControllerDelegate {
    
    private var viewModel: AnalysisViewModel!
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let fromDatePicker = UIDatePicker()
    private let toDatePicker = UIDatePicker()
    private let totalLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var sortControl: UISegmentedControl = {
        let control = UISegmentedControl(items: AnalysisViewModel.SortType.allCases.map { $0.rawValue })
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        return control
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    init(viewModel: AnalysisViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        loadData()
//
//        view.addSubview(loadingIndicator)
//        NSLayoutConstraint.activate([
//            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionChange),
            name: .transactionDidChange,
            object: nil
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGray6
        setupDatePickers()
        setupTotalLabel()
        setupTableView()
        
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupDatePickers() {
        [fromDatePicker, toDatePicker].forEach {
            $0.datePickerMode = .date
            $0.maximumDate = Date()
            $0.preferredDatePickerStyle = .compact
        }
        
        fromDatePicker.date = viewModel.from
        toDatePicker.date = viewModel.to
        
        fromDatePicker.addTarget(self, action: #selector(fromDateChanged), for: .valueChanged)
        toDatePicker.addTarget(self, action: #selector(toDateChanged), for: .valueChanged)
    }
    
    private func setupTotalLabel() {
        totalLabel.textAlignment = .right
        totalLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        totalLabel.textColor = .label
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        tableView.register(AnalysisTopRow.self, forCellReuseIdentifier: "FilterCell")
        tableView.backgroundColor = .systemGray6
        
        let titleLabel = UILabel()
        titleLabel.text = "Анализ"
        titleLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        
        let headerView = UIView()
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        tableView.tableHeaderView = headerView
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.onDatesUpdated = { [weak self] in
            self?.fromDatePicker.date = self?.viewModel.from ?? Date()
            self?.toDatePicker.date = self?.viewModel.to ?? Date()
        }
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                isLoading ? self?.loadingIndicator.startAnimating() : self?.loadingIndicator.stopAnimating()
            }
            .store(in: &cancellables)
        
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$total
            .combineLatest(viewModel.$сurrencySymbol)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total, symbol in
                self?.totalLabel.text = "\(total) \(symbol)"
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showErrorAlert(error)
            }
            .store(in: &cancellables)
    }
    
    @objc private func fromDateChanged() {
        viewModel.updateFromDate(fromDatePicker.date)
    }
    
    @objc private func toDateChanged() {
        viewModel.updateToDate(toDatePicker.date)
    }
    
    @objc private func sortChanged() {
        viewModel.updateSortType(index: sortControl.selectedSegmentIndex)
    }
    
    @objc private func handleTransactionChange() {
        loadData()
    }
    
    private func loadData() {
        viewModel.loadData()
    }
    
//    private func updateTotalLabel() {
//        totalLabel.text = "\(viewModel.total) \(viewModel.сurrencySymbol)"
//    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.viewModel.error = nil
        }))
        present(alert, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "ОПЕРАЦИИ" : nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 4 : viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as! AnalysisTopRow
            
            switch indexPath.row {
            case 0: cell.configure(title: "Начало", control: fromDatePicker)
            case 1: cell.configure(title: "Конец", control: toDatePicker)
            case 2: cell.configure(title: "Сортировка", control: sortControl)
            case 3: cell.configure(title: "Сумма", value: totalLabel.text ?? "")
            default: break
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionTableViewCell
            let (transaction, category) = viewModel.items[indexPath.row]
            cell.configure(
                with: transaction,
                category: category,
                percentage: viewModel.percentage(for: transaction),
                symbol: viewModel.сurrencySymbol
            )
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        
        let transaction = viewModel.items[indexPath.row]
        
        let editDeleteView = EditDeleteView(
            transactionsService: viewModel.transactionService,
            categoriesService: viewModel.categoriesService,
            direction: viewModel.direction,
            bankAccountService: viewModel.bankAccountsService,
            selectedTransaction: transaction
        )
        
        let hostingController = UIHostingController(rootView: editDeleteView)
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .coverVertical
        hostingController.presentationController?.delegate = self
        present(hostingController, animated: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel.loadData()
    }
}

extension Notification.Name {
    static let transactionDidChange = Notification.Name("TransactionDidChangeNotification")
}


