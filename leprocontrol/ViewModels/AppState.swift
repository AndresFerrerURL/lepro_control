import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    let authViewModel: AuthViewModel
    let devicesViewModel: DevicesViewModel

    private let apiClient: LeproAPIClient
    private var cancellables = Set<AnyCancellable>()

    init() {
        let apiClient = LeproAPIClient()
        self.apiClient = apiClient
        let authService = AuthService(apiClient: apiClient)
        let lightControlService = LightControlService(apiClient: apiClient)
        self.authViewModel = AuthViewModel(authService: authService)
        self.devicesViewModel = DevicesViewModel(lightControlService: lightControlService)

        authViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        devicesViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func bootstrap() async {
        authViewModel.bootstrap()
        if authViewModel.isAuthenticated {
            await devicesViewModel.refreshDevices(force: true)
        }
    }

    func logout() {
        authViewModel.logout()
        devicesViewModel.clear()
    }
}
