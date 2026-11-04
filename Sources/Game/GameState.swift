import Foundation
import Combine

struct TapResult {
    let amount: Double
    let isCritical: Bool
}

/// Состояние игры: очки, уровни улучшений, сохранение и оффлайн-доход.
final class GameState: ObservableObject {
    @Published private(set) var score: Double = 0
    @Published private(set) var bestScore: Double = 0
    @Published private(set) var totalTaps: Int = 0
    @Published private(set) var totalEarned: Double = 0
    @Published private(set) var levels: [String: Int] = [:]
    /// Награда за время, пока игра была закрыта. Показывается один раз.
    @Published private(set) var offlineReward: Double?

    private let storeKey = "tapclicker.save.v1"
    private let offlineLimit: TimeInterval = 8 * 60 * 60
    private var autosave: AnyCancellable?

    init() {
        load()
        autosave = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.save() }
    }

    // MARK: - Производные значения

    func level(of id: String) -> Int {
        levels[id] ?? 0
    }

    func cost(of upgrade: Upgrade) -> Double {
        upgrade.cost(atLevel: level(of: upgrade.id))
    }

    var critChance: Double {
        min(0.5, 0.05 * Double(level(of: "crit")))
    }

    var critMultiplier: Double { 5 }

    var multiplier: Double {
        1 + 0.1 * Double(level(of: "mult"))
    }

    var tapPower: Double {
        (1 + Double(level(of: "tap"))) * multiplier
    }

    var perSecond: Double {
        Double(level(of: "auto")) * multiplier
    }

    // MARK: - Действия

    func tap() -> TapResult {
        let isCritical = Double.random(in: 0 ..< 1) < critChance
        let amount = tapPower * (isCritical ? critMultiplier : 1)
        score += amount
        totalEarned += amount
        totalTaps += 1
        bestScore = max(bestScore, score)
        return TapResult(amount: amount, isCritical: isCritical)
    }

    @discardableResult
    func buy(_ upgrade: Upgrade) -> Bool {
        let price = cost(of: upgrade)
        guard score >= price else { return false }
        score -= price
        levels[upgrade.id, default: 0] += 1
        save()
        return true
    }

    func tick(_ delta: TimeInterval) {
        guard perSecond > 0, delta > 0 else { return }
        let gain = perSecond * delta
        score += gain
        totalEarned += gain
        bestScore = max(bestScore, score)
    }

    func clearOfflineReward() {
        offlineReward = nil
    }

    func reset() {
        score = 0
        bestScore = 0
        totalTaps = 0
        totalEarned = 0
        levels = [:]
        offlineReward = nil
        save()
    }

    // MARK: - Сохранение

    func save() {
        let file = SaveFile(
            score: score,
            bestScore: bestScore,
            totalTaps: totalTaps,
            totalEarned: totalEarned,
            levels: levels,
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(file) else { return }
        UserDefaults.standard.set(data, forKey: storeKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storeKey),
            let file = try? JSONDecoder().decode(SaveFile.self, from: data)
        else { return }

        score = file.score
        bestScore = file.bestScore
        totalTaps = file.totalTaps
        totalEarned = file.totalEarned
        levels = file.levels

        let elapsed = min(Date().timeIntervalSince(file.savedAt), offlineLimit)
        if elapsed > 60, perSecond > 0 {
            let reward = perSecond * elapsed
            score += reward
            totalEarned += reward
            bestScore = max(bestScore, score)
            offlineReward = reward
        }
    }
}

private struct SaveFile: Codable {
    var score: Double
    var bestScore: Double
    var totalTaps: Int
    var totalEarned: Double
    var levels: [String: Int]
    var savedAt: Date
}
