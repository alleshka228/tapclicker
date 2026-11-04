import SwiftUI

struct ShopView: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Улучшения")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Format.short(game.tapPower)) за тап")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(UpgradeCatalog.all) { upgrade in
                        let cost = game.cost(of: upgrade)
                        UpgradeCard(
                            upgrade: upgrade,
                            level: game.level(of: upgrade.id),
                            cost: cost,
                            isAffordable: game.score >= cost,
                            action: {
                                if game.buy(upgrade) {
                                    Haptics.success()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .frame(height: 156)
        }
        .padding(.bottom, 4)
    }
}

struct UpgradeCard: View {
    let upgrade: Upgrade
    let level: Int
    let cost: Double
    let isAffordable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: upgrade.systemImage)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(upgrade.tint)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(upgrade.tint.opacity(0.16)))
                    Spacer(minLength: 0)
                    Text("ур. \(level)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Text(upgrade.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.top, 10)

                Text(upgrade.details)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)

                Spacer(minLength: 6)

                HStack(spacing: 5) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 10))
                    Text(Format.short(cost))
                        .font(.footnote.weight(.heavy))
                        .monospacedDigit()
                }
                .foregroundStyle(isAffordable ? Color.white : Color.white.opacity(0.35))
            }
            .padding(12)
            .frame(width: 152, height: 146, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isAffordable ? upgrade.tint.opacity(0.75) : Color.white.opacity(0.06),
                        lineWidth: 1.5
                    )
            )
            .opacity(isAffordable ? 1 : 0.55)
        }
        .buttonStyle(.plain)
    }
}
