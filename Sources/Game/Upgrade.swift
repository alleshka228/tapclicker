import Foundation
import SwiftUI

/// Описание одного улучшения в магазине.
struct Upgrade: Identifiable {
    let id: String
    let title: String
    let details: String
    let systemImage: String
    let tint: Color
    let baseCost: Double
    /// Во сколько раз дорожает улучшение с каждым уровнем.
    let growth: Double

    func cost(atLevel level: Int) -> Double {
        baseCost * pow(growth, Double(level))
    }
}

enum UpgradeCatalog {
    static let all: [Upgrade] = [
        Upgrade(
            id: "tap",
            title: "Крепкий палец",
            details: "+1 к силе каждого тапа",
            systemImage: "hand.tap.fill",
            tint: .orange,
            baseCost: 15,
            growth: 1.18
        ),
        Upgrade(
            id: "auto",
            title: "Автоклик",
            details: "+1 клик в секунду, пока игра открыта",
            systemImage: "gearshape.2.fill",
            tint: .cyan,
            baseCost: 100,
            growth: 1.22
        ),
        Upgrade(
            id: "crit",
            title: "Критический удар",
            details: "+5% шанс крита (максимум 50%), урон x5",
            systemImage: "bolt.fill",
            tint: .yellow,
            baseCost: 400,
            growth: 1.35
        ),
        Upgrade(
            id: "mult",
            title: "Множитель дохода",
            details: "+10% ко всем кликам и автоклику",
            systemImage: "sparkles",
            tint: .pink,
            baseCost: 1200,
            growth: 1.45
        )
    ]
}
