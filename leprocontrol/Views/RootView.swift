import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.authViewModel.isAuthenticated {
                MainView(
                    authViewModel: appState.authViewModel,
                    devicesViewModel: appState.devicesViewModel,
                    logoutAction: appState.logout
                )
            } else {
                LoginView(viewModel: appState.authViewModel)
            }
        }
        .task {
            await appState.bootstrap()
        }
    }
}
