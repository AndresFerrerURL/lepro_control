import SwiftUI

struct DeviceSidebarView: View {
    @ObservedObject var viewModel: DevicesViewModel
    let account: String
    var isCompact = false
    let logoutAction: () -> Void

    var body: some View {
        Group {
            if isCompact {
                compactBody
            } else {
                regularBody
            }
        }
        .padding(isCompact ? 12 : 16)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(AppTheme.ink.opacity(0.42))
        }
        .overlay {
            if isCompact {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
            } else {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1)
                }
            }
        }
        .onChange(of: viewModel.selectedDeviceID) { _, newValue in
            let device = viewModel.devices.first { $0.deviceId == newValue }
            viewModel.select(device: device)
        }
    }

    private var regularBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            brand
            cloudStatus
            deviceListHeader

            if viewModel.devices.isEmpty {
                sidebarEmptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(viewModel.devices) { device in
                            DeviceRowView(
                                device: device,
                                isSelected: viewModel.selectedDeviceID == device.deviceId
                            ) {
                                viewModel.select(device: device)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Spacer(minLength: 0)
            accountPanel
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            compactHeader

            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage)
                    .lineLimit(2)
            }

            if viewModel.devices.isEmpty {
                sidebarEmptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(viewModel.devices) { device in
                            DeviceRowView(
                                device: device,
                                isSelected: viewModel.selectedDeviceID == device.deviceId,
                                isCompact: true
                            ) {
                                viewModel.select(device: device)
                            }
                            .frame(width: 224)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    private var brand: some View {
        ConsolePanel(padding: 14, spacing: 13) {
            HStack(spacing: 12) {
                AppLogoMark(size: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Lepro Control")
                        .font(.headline.weight(.semibold))
                    Text("v1.0.0 - By FerrerLabs")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var compactHeader: some View {
        HStack(spacing: 12) {
            AppLogoMark(size: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Lepro Control")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Text("v1.0.0 - By FerrerLabs")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Button {
                Task { await viewModel.refreshDevices(force: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 32)
            }
            .buttonStyle(LiquidButtonStyle())
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            }
            .help("Refrescar")
            .disabled(viewModel.isLoading)

            Button {
                logoutAction()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 32)
            }
            .buttonStyle(LiquidButtonStyle())
            .background(AppTheme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.danger.opacity(0.24), lineWidth: 1)
            }
            .help(account.isEmpty ? "Cerrar sesion" : "Cerrar sesion de \(account)")
        }
    }

    private var cloudStatus: some View {
        ConsolePanel(padding: 14, spacing: 12) {
            HStack {
                SectionHeader(
                    title: "Cloud",
                    systemImage: viewModel.errorMessage == nil ? "checkmark.seal.fill" : "xmark.seal.fill",
                    value: viewModel.errorMessage == nil ? "OK" : "ERR"
                )
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage)
            } else {
                HStack(spacing: 9) {
                    StatusBadgeView(title: "Session", isActive: true, activeColor: AppTheme.success)
                    StatusBadgeView(title: viewModel.isLoading ? "Sync" : "Ready", isActive: !viewModel.isLoading, activeColor: AppTheme.cyan)
                }
            }
        }
    }

    private var deviceListHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dispositivos")
                    .font(.title3.weight(.semibold))
                Text("\(viewModel.devices.count) detectados")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await viewModel.refreshDevices(force: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 32)
            }
            .buttonStyle(LiquidButtonStyle())
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            }
            .help("Refrescar")
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 4)
    }

    private var sidebarEmptyState: some View {
        ConsolePanel(padding: 18, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isLoading ? "arrow.triangle.2.circlepath" : "lightbulb.slash")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.isLoading ? "Sincronizando" : "Sin dispositivos")
                        .font(.headline)
                    Text(viewModel.isLoading ? "Consultando Lepro Cloud" : "Pulsa refrescar para volver a consultar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var accountPanel: some View {
        ConsolePanel(padding: 14, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.isEmpty ? "Lepro" : account)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text("Sesion local")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                logoutAction()
            } label: {
                Label("Cerrar sesion", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(LiquidButtonStyle())
            .background(AppTheme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.danger.opacity(0.22), lineWidth: 1)
            }
        }
    }
}

private struct AppLogoMark: View {
    let size: CGFloat

    var body: some View {
        Image("icon")
            .resizable()
            .scaledToFit()
            .padding(size * 0.10)
            .frame(width: size, height: size)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            }
            .shadow(color: AppTheme.cyan.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}
