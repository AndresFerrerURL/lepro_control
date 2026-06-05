import SwiftUI

struct SegmentControlView: View {
    @ObservedObject var viewModel: DeviceControlViewModel
    var showsBackground = true
    var closeAction: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var customColor = Color.white
    @State private var savedPresetName = ""

    private let paletteColumns = [GridItem(.adaptive(minimum: 30, maximum: 34), spacing: 8)]

    var body: some View {
        ZStack {
            if showsBackground {
                ConsoleBackground()
            }

            GeometryReader { proxy in
                let isCompact = proxy.size.width < 780
                let editorWidth = min(380, max(320, proxy.size.width * 0.42))

                VStack(alignment: .leading, spacing: isCompact ? 14 : 18) {
                    header(isCompact: isCompact)

                    if isCompact {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                editorPanel(isCompact: true)
                                palettePanel
                                presetPanel(isCompact: true)
                                savedPanel
                            }
                            .padding(.bottom, 2)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 18) {
                            editorPanel(isCompact: false)
                                .frame(width: editorWidth)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    palettePanel
                                    presetPanel(isCompact: false)
                                    savedPanel
                                }
                                .padding(.trailing, 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBannerView(message: errorMessage)
                    }
                }
                .padding(isCompact ? 14 : 22)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func header(isCompact: Bool) -> some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    titleBlock(isCompact: true)
                    Spacer()
                    closeButton
                }

                HStack(spacing: 10) {
                    StatusBadgeView(
                        title: "\(viewModel.selectedSegmentCount) selected",
                        isActive: viewModel.selectedSegmentCount > 0,
                        activeColor: AppTheme.cyan
                    )

                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
        } else {
            HStack(alignment: .center, spacing: 14) {
                titleBlock(isCompact: false)

                Spacer()

                StatusBadgeView(
                    title: "\(viewModel.selectedSegmentCount) selected",
                    isActive: viewModel.selectedSegmentCount > 0,
                    activeColor: AppTheme.cyan
                )

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                closeButton
            }
        }
    }

    private func titleBlock(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Segment Lab")
                .font(.system(size: isCompact ? 26 : 30, weight: .semibold, design: .rounded))
            Text(viewModel.selectedDevice?.displayName ?? "Lepro")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var closeButton: some View {
        Button {
            if let closeAction {
                closeAction()
            } else {
                dismiss()
            }
        } label: {
            if closeAction == nil {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 34, height: 32)
                    .contentShape(Rectangle())
            } else {
                Label("Volver", systemImage: "chevron.left")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 11)
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(LiquidButtonStyle())
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        }
        .help("Cerrar")
    }

    private func editorPanel(isCompact: Bool) -> some View {
        ConsolePanel(padding: 18, spacing: 16) {
            SectionHeader(title: "Segment editor", systemImage: "square.grid.3x3", value: "25")
            selectionToolbar
            segmentGrid(isCompact: isCompact)
        }
    }

    private var selectionToolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                quickSelectionButton("Todos", icon: "checkmark.square", action: viewModel.selectAllSegments)
                quickSelectionButton("Ninguno", icon: "square", action: viewModel.clearSegmentSelection)
            }
            HStack(spacing: 8) {
                quickSelectionButton("Pares", icon: "circle.grid.2x2", action: viewModel.selectEvenSegments)
                quickSelectionButton("Impares", icon: "circle.grid.2x1", action: viewModel.selectOddSegments)
            }
            HStack(spacing: 8) {
                quickSelectionButton("Inicio", icon: "rectangle.leadinghalf.inset.filled", action: viewModel.selectFirstHalfSegments)
                quickSelectionButton("Final", icon: "rectangle.trailinghalf.inset.filled", action: viewModel.selectSecondHalfSegments)
            }
        }
    }

    private func quickSelectionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonStyle())
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        }
        .disabled(viewModel.isLoading)
    }

    private func segmentGrid(isCompact: Bool) -> some View {
        let tileWidth: CGFloat = isCompact ? 52 : 62
        let tileHeight: CGFloat = isCompact ? 46 : 52

        return LazyVGrid(columns: segmentColumns(isCompact: isCompact), alignment: .leading, spacing: isCompact ? 8 : 10) {
            ForEach(0..<LeproD50Codec.segmentCount, id: \.self) { index in
                let color = viewModel.segmentColors.indices.contains(index) ? viewModel.segmentColors[index] : .white
                Button {
                    viewModel.toggleSegment(index)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(color.swiftUIColor)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .fill(Color.black.opacity(color.isLight ? 0.02 : 0.08))
                            }

                        VStack {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption.monospacedDigit().weight(.bold))
                                    .foregroundStyle(color.isLight ? .black : .white)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(7)

                        if viewModel.selectedSegmentIndexes.contains(index) {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(Color.white.opacity(0.92), lineWidth: 3)
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(color.isLight ? .black : .white)
                        }
                    }
                    .frame(width: tileWidth, height: tileHeight)
                }
                .buttonStyle(LiquidButtonStyle())
                .help("Segmento \(index + 1)")
                .disabled(viewModel.isLoading)
            }
        }
    }

    private func segmentColumns(isCompact: Bool) -> [GridItem] {
        let minimum: CGFloat = isCompact ? 44 : 54
        let maximum: CGFloat = isCompact ? 58 : 68
        return Array(repeating: GridItem(.flexible(minimum: minimum, maximum: maximum), spacing: isCompact ? 8 : 10), count: 5)
    }

    private var palettePanel: some View {
        ConsolePanel(padding: 18, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    SectionHeader(title: "Palette", systemImage: "paintpalette.fill")
                    Spacer()
                    colorApplyControls
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Palette", systemImage: "paintpalette.fill")
                    colorApplyControls
                }
            }

            LazyVGrid(columns: paletteColumns, alignment: .leading, spacing: 8) {
                ForEach(RGBColor.defaultPalette) { color in
                    Button {
                        Task { await viewModel.applyColorToSelectedSegments(color) }
                    } label: {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(color.swiftUIColor)
                            .frame(width: 32, height: 32)
                            .overlay {
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            }
                    }
                    .buttonStyle(LiquidButtonStyle())
                    .help(color.name)
                    .disabled(viewModel.isLoading || viewModel.selectedSegmentIndexes.isEmpty)
                }
            }
        }
    }

    private var colorApplyControls: some View {
        HStack(spacing: 10) {
            ColorPicker("", selection: $customColor, supportsOpacity: false)
                .labelsHidden()

            Button {
                Task { await viewModel.applyColorToSelectedSegments(customColor.rgbColor()) }
                    } label: {
                        Label("Aplicar", systemImage: "eyedropper")
                            .font(.caption.weight(.semibold))
                            .contentShape(Rectangle())
                    }
            .buttonStyle(LiquidButtonStyle())
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(AppTheme.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cyan.opacity(0.28), lineWidth: 1)
            }
            .disabled(viewModel.isLoading || viewModel.selectedSegmentIndexes.isEmpty)
        }
    }

    private func presetPanel(isCompact: Bool) -> some View {
        ConsolePanel(padding: 18, spacing: 14) {
            SectionHeader(title: "Combinaciones", systemImage: "wand.and.stars")

            LazyVGrid(columns: presetColumns(isCompact: isCompact), alignment: .leading, spacing: 10) {
                ForEach(SegmentPalettePreset.allCases) { preset in
                    Button {
                        Task { await viewModel.applySegmentPreset(preset) }
                    } label: {
                        Label(preset.title, systemImage: preset.systemImage)
                            .font(.callout.weight(.semibold))
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
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    private func presetColumns(isCompact: Bool) -> [GridItem] {
        if isCompact {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var savedPanel: some View {
        ConsolePanel(padding: 18, spacing: 14) {
            SectionHeader(title: "Guardados", systemImage: "tray.full", value: "\(viewModel.savedSegmentPresets.count)")

            HStack(spacing: 8) {
                TextField("Nombre del diseno", text: $savedPresetName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    }

                Button {
                    viewModel.saveCurrentSegmentPreset(named: savedPresetName)
                    if viewModel.errorMessage == nil {
                        savedPresetName = ""
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .frame(width: 34, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(LiquidButtonStyle())
                .background(AppTheme.success.opacity(0.13), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.success.opacity(0.26), lineWidth: 1)
                }
                .disabled(viewModel.isLoading)
                .help("Guardar")
            }

            if viewModel.savedSegmentPresets.isEmpty {
                Text("Sin disenos guardados")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.savedSegmentPresets) { preset in
                        savedPresetRow(preset)
                    }
                }
            }
        }
    }

    private func savedPresetRow(_ preset: SavedSegmentPreset) -> some View {
        HStack(spacing: 10) {
            preview(for: preset.colors)

            Button {
                Task { await viewModel.applySavedSegmentPreset(preset) }
            } label: {
                Text(preset.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(LiquidButtonStyle())
            .disabled(viewModel.isLoading)

            Button {
                viewModel.deleteSavedSegmentPreset(preset)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(AppTheme.danger)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(LiquidButtonStyle())
            .help("Borrar")
            .disabled(viewModel.isLoading)
        }
        .padding(8)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func preview(for colors: [RGBColor]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(LeproD50Codec.normalize(colors).enumerated()), id: \.offset) { _, color in
                Rectangle()
                    .fill(color.swiftUIColor)
                    .frame(width: 3, height: 20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .frame(width: 75, height: 20)
    }
}
