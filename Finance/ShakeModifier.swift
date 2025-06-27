//
//  ShakeModifier.swift
//  Finance
//
//  Created by Stepan Polyakov on 24.06.2025.
//

import UIKit
import Foundation
import SwiftUI

extension UIDevice {
    static let shake = Notification.Name(rawValue: "shaking")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: UIDevice.shake, object: nil)
  }
}

struct ShakeGestureViewModifier: ViewModifier {
  let action: () -> Void
  
  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.shake)) { _ in
        action()
      }
  }
}

