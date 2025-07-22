//
//  ContentView.swift
//  Finance
//
//  Created by Stepan Polyakov on 13.06.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State var selectedTab = 0
    
    let networkClient: NetworkClient
    let categoriesService: CategoriesService
    let bankAccountService: BankAccountsService
    let transactionsService: TransactionsService
    @State private var modelContainer: ModelContainer

    
    init() {
        self.networkClient = NetworkClient(
            baseURL: "https://shmr-finance.ru/api/v1/",
            token: "TmtbkBpyxXtgzPQCbLMvUnCD"
        )
        let container: ModelContainer = {
            do {
                return try ModelContainer(
                    for: TransactionStorage.self, BackupTransaction.self,
                        CategoryStorage.self,
                        BankAccountStorage.self,
                        BackupAccount.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false))
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }()
        _modelContainer = State(initialValue: container)

        let localStorage = SwiftDataTransactionStorage(container: container)
        let backupStorage = TransactionBackupStorage(container: container)
        let categoriesStorage = SwiftDataCategoriesStorage(container: container)
        let accountStorage = SwiftDataAccountStorage(container: container)
        let accountBackupStorage = AccountBackupStorage(container: container)
        
        self.categoriesService = CategoriesService(networkClient: networkClient, localStorage: categoriesStorage)
        self.bankAccountService = BankAccountsService(networkClient: networkClient, localStorage: accountStorage, backupStorage: accountBackupStorage)
        self.transactionsService = TransactionsService(networkClient: networkClient, bankAccountsService: bankAccountService, localStorage: localStorage, backupStorage: backupStorage)
            
        UITabBar.appearance().backgroundColor = UIColor.white
        UITabBar.appearance().barTintColor = UIColor.white
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TransactionsListView(transactionsService: transactionsService, categoriesService: categoriesService, direction: .outcome, bankAccountService: bankAccountService)
                .tabItem{
                    Text("Расходы")
                    Image("icon_outcome")
                        .renderingMode(.template)
                }
                .tag(0)
            TransactionsListView(transactionsService: transactionsService, categoriesService: categoriesService, direction: .income, bankAccountService: bankAccountService)
                .tabItem{
                    Text("Доходы")
                    Image("icon_income")
                        .renderingMode(.template)
                }
                .tag(1)
            AccountView(bankAccountModel: bankAccountService)
                .tabItem{
                    Text("Счет")
                    Image("icon_account")
                        .renderingMode(.template)
                }
                .tag(2)
            CategoriesView(categoriesService: categoriesService)
                .tabItem{
                    Text("Статьи")
                    Image("icon_category")
                        .renderingMode(.template)
                }
                .tag(3)
            Text("Настройки")
                .tabItem{
                    Text("Настройки")
                    Image("icon_settings")
                        .renderingMode(.template)
                }
                .tag(4)
        }
        .modelContainer(modelContainer)
    }
}

#Preview {
    ContentView()
}
