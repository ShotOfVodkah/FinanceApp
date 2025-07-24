//
//  Splash.swift
//  Finance
//
//  Created by Stepan Polyakov on 24.07.2025.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    let completion: (() -> Void)?

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName)
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.play { finished in
            if finished { completion?() }
        }
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) { }
}

struct SplashView: View {
    let onFinished: () -> Void
    @State private var contentOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            LottieView(animationName: "upload") {
                withAnimation(.easeOut(duration: 0.5)) {
                    contentOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onFinished()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
            .opacity(contentOpacity)
        }
    }
}
