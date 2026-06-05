import SwiftUI

struct DeviceDetailView: View {
    @ObservedObject var viewModel: DeviceControlViewModel
    @State private var selectedPanel: DetailPanel = .control

    private enum DetailPanel {
        case control
        case segments
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 760
            let horizontalPadding: CGFloat = isCompact ? 16 : 26
            let contentWidth = max(0, proxy.size.width - horizontalPadding * 2)

            ZStack {
                if let device = viewModel.selectedDevice {
                    if selectedPanel == .segments {
                        SegmentControlView(
                            viewModel: viewModel,
                            showsBackground: false,
                            closeAction: { selectedPanel = .control }
                        )
                        .transition(.opacity)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: isCompact ? 14 : 18) {
                                DetailHeaderBar(device: device, isOn: viewModel.isOn, isCompact: isCompact)

                                if device.online == false {
                                    ErrorBannerView(message: "El dispositivo esta offline.")
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                if let errorMessage = viewModel.errorMessage {
                                    ErrorBannerView(message: errorMessage)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                commandDeck(for: device, width: contentWidth)
                            }
                            .padding(horizontalPadding)
                            .frame(maxWidth: 1320, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .transition(.opacity)
                    }
                } else {
                    EmptyStateView(
                        title: "Selecciona una tira",
                        systemImage: "lightbulb",
                        message: "El panel de control se activara cuando elijas un dispositivo."
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.errorMessage)
        .animation(.smooth(duration: 0.22), value: selectedPanel)
        .onChange(of: viewModel.selectedDevice?.deviceId) { _, _ in
            selectedPanel = .control
        }
    }

    @ViewBuilder
    private func commandDeck(for device: LeproDevice, width: CGFloat) -> some View {
        let canControl = device.online != false && !viewModel.isLoading
        let isTiny = width < 560
        let isCompact = width < 720
        let isMedium = width < 1040
        let sideWidth = min(330, max(292, width * 0.28))
        let powerTint = currentLightTint(for: device)

        if isTiny {
            VStack(alignment: .leading, spacing: 12) {
                PowerCommandPanel(
                    isOn: viewModel.isOn,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    isCompact: true,
                    tint: powerTint,
                    turnOn: { Task { await viewModel.turnOn() } },
                    turnOff: { Task { await viewModel.turnOff() } }
                )

                BrightnessCommandPanel(
                    brightness: $viewModel.brightness,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    isCompact: true,
                    commit: { Task { await viewModel.commitBrightness() } }
                )

                ColorCommandPanel(
                    selectedColor: viewModel.selectedColor,
                    supportsSegments: viewModel.supportsSegments,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    showsPresets: false,
                    applyColor: { color in Task { await viewModel.applyColor(color) } },
                    applyPreset: { preset in Task { await viewModel.applySegmentPreset(preset) } },
                    openSegments: { selectedPanel = .segments }
                )
            }
        } else if isCompact {
            VStack(alignment: .leading, spacing: 18) {
                PowerCommandPanel(
                    isOn: viewModel.isOn,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    isCompact: true,
                    tint: powerTint,
                    turnOn: { Task { await viewModel.turnOn() } },
                    turnOff: { Task { await viewModel.turnOff() } }
                )

                BrightnessCommandPanel(
                    brightness: $viewModel.brightness,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    isCompact: true,
                    commit: { Task { await viewModel.commitBrightness() } }
                )

                ColorCommandPanel(
                    selectedColor: viewModel.selectedColor,
                    supportsSegments: viewModel.supportsSegments,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    showsPresets: true,
                    applyColor: { color in Task { await viewModel.applyColor(color) } },
                    applyPreset: { preset in Task { await viewModel.applySegmentPreset(preset) } },
                    openSegments: { selectedPanel = .segments }
                )

                DeviceDiagnosticsPanel(
                    device: device,
                    isOn: viewModel.isOn,
                    brightness: viewModel.brightness,
                    segmentCount: LeproD50Codec.segmentCount
                )
            }
        } else if isMedium {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    PowerCommandPanel(
                        isOn: viewModel.isOn,
                        isLoading: viewModel.isLoading,
                        isEnabled: canControl,
                        tint: powerTint,
                        turnOn: { Task { await viewModel.turnOn() } },
                        turnOff: { Task { await viewModel.turnOff() } }
                    )
                    .frame(maxWidth: .infinity)

                    DeviceDiagnosticsPanel(
                        device: device,
                        isOn: viewModel.isOn,
                        brightness: viewModel.brightness,
                        segmentCount: LeproD50Codec.segmentCount
                    )
                    .frame(maxWidth: .infinity)
                }

                BrightnessCommandPanel(
                    brightness: $viewModel.brightness,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    commit: { Task { await viewModel.commitBrightness() } }
                )

                ColorCommandPanel(
                    selectedColor: viewModel.selectedColor,
                    supportsSegments: viewModel.supportsSegments,
                    isLoading: viewModel.isLoading,
                    isEnabled: canControl,
                    showsPresets: true,
                    applyColor: { color in Task { await viewModel.applyColor(color) } },
                    applyPreset: { preset in Task { await viewModel.applySegmentPreset(preset) } },
                    openSegments: { selectedPanel = .segments }
                )
            }
        } else {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        BrightnessCommandPanel(
                            brightness: $viewModel.brightness,
                            isLoading: viewModel.isLoading,
                            isEnabled: canControl,
                            commit: { Task { await viewModel.commitBrightness() } }
                        )

                        ColorCommandPanel(
                            selectedColor: viewModel.selectedColor,
                            supportsSegments: viewModel.supportsSegments,
                            isLoading: viewModel.isLoading,
                            isEnabled: canControl,
                            showsPresets: true,
                            applyColor: { color in Task { await viewModel.applyColor(color) } },
                            applyPreset: { preset in Task { await viewModel.applySegmentPreset(preset) } },
                            openSegments: { selectedPanel = .segments }
                        )
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 18) {
                        PowerCommandPanel(
                            isOn: viewModel.isOn,
                            isLoading: viewModel.isLoading,
                            isEnabled: canControl,
                            tint: powerTint,
                            turnOn: { Task { await viewModel.turnOn() } },
                            turnOff: { Task { await viewModel.turnOff() } }
                        )

                        DeviceDiagnosticsPanel(
                            device: device,
                            isOn: viewModel.isOn,
                            brightness: viewModel.brightness,
                            segmentCount: LeproD50Codec.segmentCount
                        )
                    }
                    .frame(width: sideWidth)
                }
            }
        }
    }

    private func currentLightTint(for device: LeproDevice) -> Color {
        if let selectedColor = viewModel.selectedColor {
            return selectedColor.swiftUIColor
        }

        if let segmentColor = viewModel.segmentColors.first {
            return segmentColor.swiftUIColor
        }

        if let parsedColor = LeproD50Codec.parse(device.d50).first {
            return parsedColor.swiftUIColor
        }

        return AppTheme.amber
    }
}

struct DetailHeaderBar: View {
    let device: LeproDevice
    let isOn: Bool
    var isCompact = false

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 12) {
                    titleBlock
                    badgeRow
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    titleBlock
                    Spacer()
                    badgeRow
                }
            }
        }
        .padding(.top, 6)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(device.displayName)
                .font(.system(size: isCompact ? 28 : 36, weight: .semibold, design: .rounded))
                .lineLimit(isCompact ? 2 : 1)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    deviceIDText
                    seriesBadge
                }

                VStack(alignment: .leading, spacing: 6) {
                    deviceIDText
                    seriesBadge
                }
            }
        }
    }

    private var deviceIDText: some View {
        Text(device.deviceId)
            .font(.callout.monospacedDigit())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .textSelection(.enabled)
    }

    @ViewBuilder
    private var seriesBadge: some View {
        if let series = device.series {
            Text(series)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private var badgeRow: some View {
        HStack(spacing: 8) {
            StatusBadgeView(title: isOn ? "Power on" : "Power off", isActive: isOn, activeColor: AppTheme.success)

            if let online = device.online {
                StatusBadgeView(
                    title: online ? "Online" : "Offline",
                    isActive: online,
                    activeColor: AppTheme.success,
                    inactiveColor: AppTheme.danger
                )
            }
        }
    }
}

struct PowerCommandPanel: View {
    let isOn: Bool
    let isLoading: Bool
    let isEnabled: Bool
    var isCompact = false
    var tint: Color = AppTheme.amber
    let turnOn: () -> Void
    let turnOff: () -> Void

    var body: some View {
        ConsolePanel(padding: isCompact ? 14 : AppTheme.cardPadding, spacing: isCompact ? 12 : 18) {
            SectionHeader(title: "Power", systemImage: "power", value: isLoading ? "..." : (isOn ? "ON" : "OFF"))

            Button {
                isOn ? turnOff() : turnOn()
            } label: {
                VStack(spacing: isCompact ? 9 : 14) {
                    Image(systemName: "power")
                        .font(.system(size: isCompact ? 28 : 44, weight: .semibold))
                        .foregroundStyle(isOn ? tint : tint.opacity(0.56))
                        .frame(width: isCompact ? 72 : 112, height: isCompact ? 64 : 112)
                        .background(isOn ? tint.opacity(0.16) : tint.opacity(0.07), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(isOn ? tint.opacity(0.52) : tint.opacity(0.22), lineWidth: 1)
                        }
                        .shadow(color: isOn ? tint.opacity(0.28) : .clear, radius: 18, x: 0, y: 10)

                    Text(isOn ? "Encendida" : "Apagada")
                        .font((isCompact ? Font.callout : Font.title3).weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(LiquidButtonStyle())
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.46)

            HStack(spacing: 10) {
                commandButton("ON", icon: "bolt.fill", active: isOn, disabled: !isEnabled || isOn, action: turnOn)
                commandButton("OFF", icon: "moon.fill", active: !isOn, disabled: !isEnabled || !isOn, action: turnOff)
            }
        }
    }

    private func commandButton(_ title: String, icon: String, active: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonStyle())
        .background(active ? AppTheme.cyan.opacity(0.16) : Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(active ? AppTheme.cyan.opacity(0.42) : AppTheme.cardStroke, lineWidth: 1)
        }
        .disabled(disabled)
    }
}

struct BrightnessCommandPanel: View {
    @Binding var brightness: Double
    let isLoading: Bool
    let isEnabled: Bool
    var isCompact = false
    let commit: () -> Void

    var body: some View {
        ConsolePanel(padding: isCompact ? 14 : AppTheme.cardPadding, spacing: isCompact ? 12 : 16) {
            SectionHeader(title: "Brightness", systemImage: "sun.max.fill", value: "\(Int(brightness.rounded()))")

            Slider(value: $brightness, in: 0...255, step: 1) {
                Text("Brillo")
            } minimumValueLabel: {
                Text("0").foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("255").foregroundStyle(.secondary)
            }
            .disabled(!isEnabled)
            .onSubmit(commit)

            Button {
                commit()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Label("Aplicar", systemImage: "slider.horizontal.3")
                        .font(.callout.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(LiquidButtonStyle())
            .background(AppTheme.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cyan.opacity(0.28), lineWidth: 1)
            }
            .disabled(!isEnabled)
        }
        .opacity(isEnabled ? 1 : 0.58)
    }
}

struct ColorCommandPanel: View {
    let selectedColor: RGBColor?
    let supportsSegments: Bool
    let isLoading: Bool
    let isEnabled: Bool
    var showsPresets = true
    let applyColor: (RGBColor) -> Void
    let applyPreset: (SegmentPalettePreset) -> Void
    let openSegments: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 30, maximum: 34), spacing: 9)]
    private let presetColumns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        ConsolePanel(spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    SectionHeader(title: "Chromatic matrix", systemImage: "paintpalette.fill")
                    Spacer()
                    segmentButton
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Chromatic matrix", systemImage: "paintpalette.fill")
                    segmentButton
                }
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 11) {
                ForEach(RGBColor.defaultPalette) { color in
                    Button {
                        applyColor(color)
                    } label: {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(color.swiftUIColor)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                            .overlay {
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.white.opacity(color == selectedColor ? 0.90 : 0.22), lineWidth: color == selectedColor ? 3 : 1)
                            }
                            .overlay {
                                if color == selectedColor {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(color.isLight ? .black : .white)
                                }
                            }
                    }
                    .buttonStyle(LiquidButtonStyle())
                    .help(color.name)
                    .disabled(!isEnabled || isLoading)
                }
            }

            if supportsSegments && showsPresets {
                Divider()
                    .overlay(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Segment presets", systemImage: "wand.and.stars")

                    LazyVGrid(columns: presetColumns, alignment: .leading, spacing: 10) {
                        ForEach(SegmentPalettePreset.allCases) { preset in
                            Button {
                                applyPreset(preset)
                            } label: {
                                Label(preset.title, systemImage: preset.systemImage)
                                    .font(.callout.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(LiquidButtonStyle())
                            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            }
                            .disabled(!isEnabled || isLoading)
                        }
                    }
                }
            }
        }
        .opacity(isEnabled ? 1 : 0.58)
    }

    @ViewBuilder
    private var segmentButton: some View {
        if supportsSegments {
            Button {
                openSegments()
            } label: {
                Label("Segmentos", systemImage: "square.grid.3x3")
                    .font(.callout.weight(.semibold))
                    .contentShape(Rectangle())
            }
            .buttonStyle(LiquidButtonStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(AppTheme.violet.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.violet.opacity(0.32), lineWidth: 1)
            }
            .disabled(!isEnabled)
        }
    }
}

struct DeviceDiagnosticsPanel: View {
    let device: LeproDevice
    let isOn: Bool
    let brightness: Double
    let segmentCount: Int

    var body: some View {
        ConsolePanel(spacing: 14) {
            SectionHeader(title: "Diagnostics", systemImage: "waveform.path.ecg", value: device.online == false ? "OFFLINE" : "NOMINAL")

            VStack(spacing: 8) {
                diagnosticRow("Power", isOn ? "ON" : "OFF")
                diagnosticRow("Brillo", "\(Int(brightness.rounded())) / 255")
                diagnosticRow("Segmentos", "\(segmentCount)")
                diagnosticRow("Modelo", device.series ?? "Unknown")
                diagnosticRow("Firmware", device.fwVersion ?? "Unknown")
                diagnosticRow("Hardware", device.hwVersion ?? "Unknown")
                diagnosticRow("FID", device.fid?.stringValue ?? "Unknown")
            }
        }
    }

    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 6))
    }
}
