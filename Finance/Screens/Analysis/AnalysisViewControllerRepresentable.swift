//
//  AnalysisViewControllerRepresentable.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//

import SwiftUI

struct AnalysisView: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {
        // todo
    }
    
    let transactionService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountsService: BankAccountsService
    let direction: Direction

    func makeUIViewController(context: Context) -> AnalysisViewController {
        let viewModel = AnalysisViewModel(
            transactionService: transactionService,
            categoriesService: categoriesService,
            bankAccountsService: bankAccountsService,
            direction: direction
        )
        return AnalysisViewController(viewModel: viewModel)
    }
}
