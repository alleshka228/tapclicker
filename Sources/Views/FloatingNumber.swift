import SwiftUI

/// Всплывающее "+N" над кнопкой тапа.
struct FloatingNumber: Identifiable {
    let id = UUID()
    let text: String
    let isCritical: Bool
    var xOffset: CGFloat = CGFloat.random(in: -60 ... 60)
}

struct FloatingNumberView: View {
    let item: FloatingNumber
    @State private var isFlying = false

    var body: some View {
        Text(item.text)
            .font(.system(size: item.isCritical ? 36 : 26, weight: .heavy, design: .rounded))
            .foregroundStyle(item.isCritical ? Color.yellow : Color.white)
            .shadow(
                color: item.isCritical ? Color.orange.opacity(0.9) : Color.black.opacity(0.5),
                radius: item.isCritical ? 10 : 5,
                y: 2
            )
            .offset(x: item.xOffset, y: isFlying ? -130 : 6)
            .opacity(isFlying ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.75)) {
                    isFlying = true
                }
            }
    }
}
