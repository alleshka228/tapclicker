import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()
    @Environment(\.scenePhase) private var scenePhase

    @State private var floats: [FloatingNumber] = []
    @State private var tapScale: CGFloat = 1
    @State private var showsReset = false

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DarkBackground()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 4)
                tapArea
                Spacer(minLength: 4)
                ShopView(game: game)
            }
            .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
        .onReceive(ticker) { _ in
            game.tick(0.1)
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                game.save()
            }
        }
        .alert("С возвращением!", isPresented: offlineBinding) {
            Button("Забрать", role: .cancel) {
                game.clearOfflineReward()
            }
        } message: {
            Text("Пока вас не было, автоклик принёс \(Format.short(game.offlineReward ?? 0)).")
        }
    }

    // MARK: - Верхняя панель

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("TAP CLICKER")
                        .font(.caption2.weight(.bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Кликер")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 0)

                Button {
                    showsReset = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .alert("Сбросить прогресс?", isPresented: $showsReset) {
                    Button("Отмена", role: .cancel) {}
                    Button("Сбросить", role: .destructive) {
                        game.reset()
                    }
                } message: {
                    Text("Очки и все улучшения будут удалены.")
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 2) {
                Text(Format.short(game.score))
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text("всего заработано \(Format.short(game.totalEarned))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                Chip(text: "+\(Format.short(game.perSecond))/сек", icon: "clock.fill", tint: .cyan)
                Chip(text: "x\(String(format: "%.1f", game.multiplier))", icon: "sparkles", tint: .pink)
                Chip(text: "крит \(Int((game.critChance * 100).rounded()))%", icon: "bolt.fill", tint: .yellow)
            }
        }
    }

    // MARK: - Кнопка тапа

    private var tapArea: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.045))
                .frame(width: 300, height: 300)

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [.pink, .purple, .blue, .cyan, .pink],
                        center: .center
                    ),
                    lineWidth: 7
                )
                .frame(width: 272, height: 272)
                .blur(radius: 1.5)
                .opacity(0.9)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.56, blue: 0.26),
                            Color(red: 0.84, green: 0.14, blue: 0.42)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.28),
                        startRadius: 6,
                        endRadius: 236
                    )
                )
                .frame(width: 226, height: 226)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 2)
                        .frame(width: 226, height: 226)
                )
                .shadow(color: Color(red: 0.95, green: 0.3, blue: 0.35).opacity(0.55), radius: 30, y: 12)

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 74, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .scaleEffect(tapScale)
        .contentShape(Circle())
        .onTapGesture(perform: registerTap)
        .overlay(
            ZStack {
                ForEach(floats) { item in
                    FloatingNumberView(item: item)
                }
            }
            .allowsHitTesting(false)
        )
    }

    // MARK: - Действия

    private func registerTap() {
        let result = game.tap()
        Haptics.tap(isCritical: result.isCritical)

        withAnimation(.spring(response: 0.15, dampingFraction: 0.55)) {
            tapScale = 0.92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                tapScale = 1
            }
        }

        let item = FloatingNumber(
            text: (result.isCritical ? "КРИТ +" : "+") + Format.short(result.amount),
            isCritical: result.isCritical
        )
        floats.append(item)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            floats.removeAll { $0.id == item.id }
        }
    }

    private var offlineBinding: Binding<Bool> {
        Binding(
            get: { game.offlineReward != nil },
            set: { newValue in
                if !newValue {
                    game.clearOfflineReward()
                }
            }
        )
    }
}

// MARK: - Мелкие компоненты

struct Chip: View {
    let text: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(tint.opacity(0.13)))
    }
}

struct DarkBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.12),
                    Color(red: 0.11, green: 0.05, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.purple.opacity(0.35))
                .frame(width: 420, height: 420)
                .blur(radius: 130)
                .offset(x: -140, y: -240)

            Circle()
                .fill(Color.orange.opacity(0.16))
                .frame(width: 380, height: 380)
                .blur(radius: 130)
                .offset(x: 150, y: 260)
        }
        .ignoresSafeArea()
    }
}
