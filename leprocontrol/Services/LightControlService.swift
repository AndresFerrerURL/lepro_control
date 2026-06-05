import Foundation

final class LightControlService {
    private let apiClient: LeproAPIClient

    init(apiClient: LeproAPIClient) {
        self.apiClient = apiClient
    }

    func fetchDevices() async throws -> [LeproDevice] {
        try await apiClient.fetchDevices()
    }

    func turnOn(deviceId: String) async throws {
        try await apiClient.turnOn(deviceId: deviceId)
    }

    func turnOff(deviceId: String) async throws {
        try await apiClient.turnOff(deviceId: deviceId)
    }

    func setBrightness(deviceId: String, value: Int) async throws {
        try await apiClient.setBrightness(deviceId: deviceId, value: value)
    }

    func setColor(deviceId: String, color: RGBColor, brightness: Int) async throws {
        try await apiClient.setColor(deviceId: deviceId, color: color, brightness: brightness)
    }

    func setSegmentColors(deviceId: String, colors: [RGBColor], brightness: Int) async throws {
        try await apiClient.setSegmentColors(deviceId: deviceId, colors: colors, brightness: brightness)
    }
}
