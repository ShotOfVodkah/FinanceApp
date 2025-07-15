//
//  ContentView.swift
//  Finance
//
//  Created by Stepan Polyakov on 13.06.2025.
//

import SwiftUI

struct ContentView: View {
    @State var selectedTab = 0
    
    let networkClient: NetworkClient
    let categoriesService: CategoriesService
    let bankAccountService: BankAccountsService
    let transactionsService: TransactionsService

    init() {
        self.networkClient = NetworkClient(
            baseURL: "https://shmr-finance.ru/api/v1/",
            token: "TmtbkBpyxXtgzPQCbLMvUnCD"
        )

        self.categoriesService = CategoriesService(networkClient: networkClient)
        self.bankAccountService = BankAccountsService(networkClient: networkClient)
        self.transactionsService = TransactionsService(networkClient: networkClient, bankAccountsService: bankAccountService)
            
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
    }
}

#Preview {
    ContentView()
}
