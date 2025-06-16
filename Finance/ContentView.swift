//
//  ContentView.swift
//  Finance
//
//  Created by Stepan Polyakov on 13.06.2025.
//

import SwiftUI

struct ContentView: View {
    @State var selectedTab = 0
    let transactionsService = TransactionsService()
    let categoriesService = CategoriesService()
    
    init() {
        UITabBar.appearance().backgroundColor = UIColor.white
        UITabBar.appearance().barTintColor = UIColor.white
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            IncomeView(transactionsService: transactionsService, categoriesService: categoriesService, direction: .outcome)
                .tabItem{
                    Label("Расходы", systemImage: "cart.fill.badge.minus")
                }
                .tag(0)
            IncomeView(transactionsService: transactionsService, categoriesService: categoriesService, direction: .income)
                .tabItem{
                    Label("Доходы", systemImage: "cart.fill.badge.plus")
                }
                .tag(1)
            Text("Счет")
                .tabItem{
                    Label("Счет", systemImage: "creditcard.fill")
                }
                .tag(2)
            Text("Статьи")
                .tabItem{
                    Label("Статьи", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
                .tag(3)
            Text("Настройки")
                .tabItem{
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
