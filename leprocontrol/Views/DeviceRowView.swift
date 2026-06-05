import SwiftUI

struct DeviceRowView: View {
    let device: LeproDevice
    let isSelected: Bool
    var isCompact = false
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: isCompact ? 9 : 11) {
                HStack(spacing: isCompact ? 9 : 11) {
                    deviceIcon

                    VStack(alignment: .leading, spacing: 3) {
                        Text(device.displayName)
                            .font((isCompact ? Font.caption : Font.callout).weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(device.series ?? device.deviceId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    statusDot
                }

                HStack(spacing: 8) {
                    miniLevel
                    Text("\(device.brightness255)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(isCompact ? 10 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(LiquidButtonStyle())
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(isSelected ? AppTheme.cyan.opacity(0.48) : AppTheme.mutedStroke, lineWidth: 1)
        }
        .shadow(color: isSelected ? AppTheme.cyan.opacity(0.16) : .clear, radius: 14, x: 0, y: 8)
        .scaleEffect(isHovering ? 1.012 : 1.0)
        .animation(.easeOut(duration: 0.16), value: isHovering)
        .animation(.easeOut(duration: 0.16), value: isSelected)
        .onHover { isHovering = $0 }
    }

    private var deviceIcon: some View {
        ZStack {
            if device.isOn {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.warmAccent.opacity(0.22))
                    .frame(width: isCompact ? 34 : 42, height: isCompact ? 34 : 42)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: isCompact ? 34 : 42, height: isCompact ? 34 : 42)
            }

            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: isCompact ? 15 : 18, weight: .bold))
                .foregroundStyle(device.isOn ? AppTheme.amber : .secondary)
        }
    }

    private var statusDot: some View {
        VStack(spacing: 6) {
            Circle()
                .fill((device.online ?? true) ? AppTheme.success : AppTheme.danger)
                .frame(width: 9, height: 9)
            Circle()
                .fill(device.isOn ? AppTheme.amber : Color.secondary.opacity(0.55))
                .frame(width: 9, height: 9)
        }
    }

    private var miniLevel: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                if device.isOn {
                    Capsule()
                        .fill(AppTheme.accent)
                        .frame(width: proxy.size.width * CGFloat(device.brightness255) / 255.0)
                } else {
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: proxy.size.width * CGFloat(device.brightness255) / 255.0)
                }
            }
        }
        .frame(height: 6)
    }

    private var backgroundColor: Color {
        if isSelected { return AppTheme.cyan.opacity(0.16) }
        if isHovering { return Color.white.opacity(0.075) }
        return Color.white.opacity(0.040)
    }
}
