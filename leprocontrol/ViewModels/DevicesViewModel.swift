import Combine
import Foundation

@MainActor
final class DevicesViewModel: ObservableObject {
    @Published private(set) var devices: [LeproDevice] = []
    @Published var selectedDeviceID: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let controlViewModel: DeviceControlViewModel
    private let lightControlService: LightControlService
    private let minimumRefreshInterval: TimeInterval = 30
    private var lastRefreshAttemptAt: Date?

    var selectedDevice: LeproDevice? {
        guard let selectedDeviceID else { return nil }
        return devices.first { $0.deviceId == selectedDeviceID }
    }

    init(lightControlService: LightControlService) {
        self.lightControlService = lightControlService
        self.controlViewModel = DeviceControlViewModel(lightControlService: lightControlService)
        self.controlViewModel.onDeviceUpdated = { [weak self] device in
            self?.replaceDevice(device)
        }
    }

    func refreshDevices(force: Bool = false) async {
        guard !isLoading else {
            return
        }

        if !force,
           let lastRefreshAttemptAt,
           Date().timeIntervalSince(lastRefreshAttemptAt) < minimumRefreshInterval,
           !devices.isEmpty {
            errorMessage = nil
            return
        }

        lastRefreshAttemptAt = Date()
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await lightControlService.fetchDevices()
            devices = fetched.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            if selectedDeviceID == nil || !devices.contains(where: { $0.deviceId == selectedDeviceID }) {
                selectedDeviceID = devices.first?.deviceId
            }
            controlViewModel.select(selectedDevice)
        } catch let error as LeproError {
            print("Fetch devices error: \(error.localizedDescription)")
            errorMessage = devices.isEmpty ? error.userMessage : nil
        } catch {
            print("Fetch devices error: \(error)")
            errorMessage = devices.isEmpty ? LeproError.unknown(error.localizedDescription).userMessage : nil
        }
        isLoading = false
    }

    func select(device: LeproDevice?) {
        selectedDeviceID = device?.deviceId
        controlViewModel.select(device)
    }

    func clear() {
        devices = []
        selectedDeviceID = nil
        controlViewModel.select(nil)
        errorMessage = nil
    }

    private func replaceDevice(_ device: LeproDevice) {
        guard let index = devices.firstIndex(where: { $0.deviceId == device.deviceId }) else {
            return
        }
        devices[index] = device
    }
}
