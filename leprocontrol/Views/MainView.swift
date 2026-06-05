import SwiftUI

struct MainView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var devicesViewModel: DevicesViewModel
    let logoutAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 860
            let sidebarWidth = min(AppTheme.sidebarWidth, max(250, proxy.size.width * 0.28))

            ZStack {
                ConsoleBackground()

                if isCompact {
                    VStack(spacing: 0) {
                        DeviceSidebarView(
                            viewModel: devicesViewModel,
                            account: authViewModel.email,
                            isCompact: true,
                            logoutAction: logoutAction
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: min(260, max(205, proxy.size.height * 0.34)))

                        Divider()
                            .overlay(Color.white.opacity(0.08))

                        DeviceDetailView(viewModel: devicesViewModel.controlViewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    HStack(spacing: 0) {
                        DeviceSidebarView(
                            viewModel: devicesViewModel,
                            account: authViewModel.email,
                            logoutAction: logoutAction
                        )
                        .frame(width: sidebarWidth)

                        Divider()
                            .overlay(Color.white.opacity(0.08))

                        DeviceDetailView(viewModel: devicesViewModel.controlViewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if devicesViewModel.devices.isEmpty {
                await devicesViewModel.refreshDevices()
            }
        }
    }
}
