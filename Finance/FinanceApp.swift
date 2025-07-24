//
//  FinanceApp.swift
//  Finance
//
//  Created by Stepan Polyakov on 13.06.2025.
//

import SwiftUI

@main
struct FinanceApp: App {
    @State private var splashFinished = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished {
                    ContentView()
                        .transition(.opacity.animation(.easeIn(duration: 0.5)))
                }
                if !splashFinished {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.5)) {
                            splashFinished = true
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.default, value: splashFinished)
        }
    }
}
