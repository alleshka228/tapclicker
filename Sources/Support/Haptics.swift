import UIKit

/// Короткая тактильная отдача на тап.
enum Haptics {
    static func tap(isCritical: Bool) {
        let generator = UIImpactFeedbackGenerator(style: isCritical ? .heavy : .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
