import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 18
    static let sidebarWidth: CGFloat = 310

    static let ink = Color(red: 0.025, green: 0.027, blue: 0.035)
    static let graphite = Color(red: 0.075, green: 0.078, blue: 0.092)
    static let graphite2 = Color(red: 0.105, green: 0.102, blue: 0.120)
    static let steel = Color(red: 0.62, green: 0.66, blue: 0.72)
    static let cyan = Color(red: 0.12, green: 0.80, blue: 0.92)
    static let violet = Color(red: 0.48, green: 0.38, blue: 1.00)
    static let amber = Color(red: 1.00, green: 0.70, blue: 0.20)
    static let success = Color(red: 0.24, green: 0.86, blue: 0.50)
    static let danger = Color(red: 1.00, green: 0.30, blue: 0.34)
    static let warning = amber

    static let cardStroke = Color.white.opacity(0.12)
    static let mutedStroke = Color.white.opacity(0.07)
    static let glassHighlight = Color.white.opacity(0.18)
    static let glassFill = Color.white.opacity(0.075)

    static let background = LinearGradient(
        colors: [
            ink,
            Color(red: 0.045, green: 0.045, blue: 0.060),
            Color(red: 0.030, green: 0.035, blue: 0.040)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [
            cyan,
            violet
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmAccent = LinearGradient(
        colors: [
            amber,
            Color(red: 1.00, green: 0.33, blue: 0.30)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ConsoleBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background

            Canvas { context, size in
                let gridColor = Color.white.opacity(0.035)
                var path = Path()

                for x in stride(from: CGFloat(0), through: size.width, by: 44) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }

                for y in stride(from: CGFloat(0), through: size.height, by: 44) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(path, with: .color(gridColor), lineWidth: 0.6)

                var diagonals = Path()
                diagonals.move(to: CGPoint(x: size.width * 0.56, y: 0))
                diagonals.addLine(to: CGPoint(x: size.width, y: size.height * 0.46))
                diagonals.move(to: CGPoint(x: size.width * 0.72, y: size.height))
                diagonals.addLine(to: CGPoint(x: size.width, y: size.height * 0.70))
                context.stroke(diagonals, with: .color(AppTheme.cyan.opacity(0.08)), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}

struct ConsolePanel<Content: View>: View {
    let padding: CGFloat
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(padding: CGFloat = AppTheme.cardPadding, spacing: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(padding)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.13),
                                    Color.white.opacity(0.045),
                                    Color.white.opacity(0.018)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.glassHighlight, AppTheme.mutedStroke, AppTheme.cyan.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 14)
        .shadow(color: AppTheme.cyan.opacity(0.055), radius: 18, x: 0, y: 0)
    }
}

struct LiquidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .brightness(configuration.isPressed ? 0.035 : 0)
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
    }
}

typealias GlassCard = ConsolePanel

struct SectionHeader: View {
    let title: String
    let systemImage: String
    var value: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.cyan)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(.headline)

            Spacer()

            if let value {
                Text(value)
                    .font(.callout.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.danger)
            Text(message)
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AppTheme.danger.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.danger.opacity(0.34), lineWidth: 1)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var message: String?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.steel.opacity(0.78))
            Text(title)
                .font(.title2.weight(.semibold))
            if let message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

struct StatusBadgeView: View {
    let title: String
    let isActive: Bool
    var activeColor: Color = AppTheme.success
    var inactiveColor: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 18, height: 6)

            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.primary.opacity(0.88))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.mutedStroke, lineWidth: 1)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        }
    }
}
