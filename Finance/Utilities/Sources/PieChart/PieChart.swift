//
//  PieChart.swift
//  Utilities
//
//  Created by Stepan Polyakov on 24.07.2025.
//

import Foundation
import UIKit

public struct Entity: Equatable {
    public let value: Decimal
    public let label: String

    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}

public struct PieChart {
    public static let segmentColors: [UIColor] = [
        UIColor.systemRed,
        UIColor.systemBlue,
        UIColor.systemGreen,
        UIColor.systemOrange,
        UIColor.systemPurple,
        UIColor.lightGray
    ]
}

public final class PieChartView: UIView {
    
    private var entities: [Entity] = []
    
    public var lineWidth: CGFloat = 10.0
    public var legendFont: UIFont = .systemFont(ofSize: 10)
    public var legendTextColor: UIColor = .black
    
    private var isAnimating = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    
    public func setEntities(_ newEntities: [Entity], animated: Bool = false) {
            guard animated else {
                self.entities = newEntities
                setNeedsDisplay()
                return
            }
            
            animateTransition(to: newEntities)
        }

    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !entities.isEmpty else { return }
        
        let radius = min(bounds.width, bounds.height) / 2 - 5
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let total = entities.prefix(5).reduce(0) { $0 + ($1.value as NSDecimalNumber).doubleValue }
        let othersTotal = entities.dropFirst(5).reduce(0) { $0 + ($1.value as NSDecimalNumber).doubleValue }
        
        let totalValue = total + othersTotal
        guard totalValue > 0 else { return }
        
        var startAngle = -CGFloat.pi / 2
        var allEntitiesToDisplay = Array(entities.prefix(5))
        if othersTotal > 0 {
            allEntitiesToDisplay.append(Entity(value: Decimal(othersTotal), label: "Остальные"))
        }

        for (index, entity) in allEntitiesToDisplay.enumerated() {
            let value = (entity.value as NSDecimalNumber).doubleValue
            let angle = CGFloat(value / totalValue) * 2 * .pi
            let endAngle = startAngle + angle
            
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            
            path.lineWidth = lineWidth
            PieChart.segmentColors[safe: index]?.setStroke()
            path.stroke()
            
            startAngle = endAngle
        }
        
        drawLegend(in: context, center: center, entities: allEntitiesToDisplay)
    }
    
    private func drawLegend(in context: CGContext, center: CGPoint, entities: [Entity]) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let maxLegendWidth = bounds.width * 0.5
        let circleSize: CGFloat = 10
        let spacing: CGFloat = 6
        let lineHeight = max(circleSize, legendFont.lineHeight)

        let totalHeight = CGFloat(entities.count) * lineHeight + CGFloat(entities.count - 1) * spacing
        var yOffset = center.y - totalHeight / 2

        for (index, entity) in entities.enumerated() {
            let color = PieChart.segmentColors[safe: index] ?? .black

            let circleRect = CGRect(
                x: center.x - maxLegendWidth/2,
                y: yOffset,
                width: circleSize,
                height: circleSize
            )
            
            let circlePath = UIBezierPath(ovalIn: circleRect)
            context.setFillColor(color.cgColor)
            context.addPath(circlePath.cgPath)
            context.fillPath()

            let label = "\(entity.value)% \(entity.label)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: legendFont,
                .foregroundColor: legendTextColor,
                .paragraphStyle: paragraphStyle
            ]

            let textSize = (label as NSString).size(withAttributes: attributes)
            let textRect = CGRect(
                x: circleRect.maxX + 5,
                y: yOffset - (textSize.height - circleSize)/2,
                width: maxLegendWidth - circleSize - 5,
                height: textSize.height
            )

            label.draw(in: textRect, withAttributes: attributes)
            yOffset += lineHeight + spacing
        }
    }
    
    private func animateTransition(to newEntities: [Entity]) {
        guard !isAnimating else { return }
        isAnimating = true

        let halfTurn = CGAffineTransform(rotationAngle: .pi)

        UIView.animate(withDuration: 0.4, animations: {
            self.transform = halfTurn
            self.alpha = 0
        }, completion: { _ in
            self.entities = newEntities
            self.setNeedsDisplay()

            self.transform = CGAffineTransform(rotationAngle: -.pi)
            self.alpha = 0

            UIView.animate(withDuration: 0.4, animations: {
                self.transform = .identity
                self.alpha = 1
            }, completion: { _ in
                self.isAnimating = false
            })
        })
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

