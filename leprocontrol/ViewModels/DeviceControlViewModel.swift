import Combine
import Foundation

@MainActor
final class DeviceControlViewModel: ObservableObject {
    @Published private(set) var selectedDevice: LeproDevice?
    @Published var brightness: Double = 255
    @Published var selectedColor: RGBColor?
    @Published var segmentColors: [RGBColor] = LeproD50Codec.defaultColors
    @Published var selectedSegmentIndexes: Set<Int> = Set(0..<LeproD50Codec.segmentCount)
    @Published private(set) var savedSegmentPresets: [SavedSegmentPreset] = []
    @Published private(set) var isOn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let lightControlService: LightControlService
    private let segmentPresetStore: SegmentPresetStore
    var onDeviceUpdated: ((LeproDevice) -> Void)?

    init(lightControlService: LightControlService) {
        self.lightControlService = lightControlService
        let segmentPresetStore = SegmentPresetStore()
        self.segmentPresetStore = segmentPresetStore
        self.savedSegmentPresets = segmentPresetStore.load()
    }

    func select(_ device: LeproDevice?) {
        selectedDevice = device
        brightness = Double(device?.brightness255 ?? 255)
        isOn = device?.isOn ?? false
        segmentColors = LeproD50Codec.parse(device?.d50)
        selectedColor = segmentColors.first
        selectedSegmentIndexes = Set(0..<LeproD50Codec.segmentCount)
        errorMessage = nil
    }

    var supportsSegments: Bool {
        guard let device = selectedDevice else { return false }
        let series = (device.series ?? "").uppercased()
        return series.contains("S1-5") || (!isLikelyBModel(device) && device.d50 != nil)
    }

    var selectedSegmentCount: Int {
        selectedSegmentIndexes.count
    }

    func turnOn() async {
        guard var device = selectedDevice else { return }
        await runCommand {
            try await lightControlService.turnOn(deviceId: device.deviceId)
            device.d1 = 1
            device.powerSwitch = 1
            applyOptimisticUpdate(device)
        }
    }

    func turnOff() async {
        guard var device = selectedDevice else { return }
        await runCommand {
            try await lightControlService.turnOff(deviceId: device.deviceId)
            device.d1 = 0
            device.powerSwitch = 0
            applyOptimisticUpdate(device)
        }
    }

    func commitBrightness() async {
        guard var device = selectedDevice else { return }
        let value = Int(brightness.rounded())
        await runCommand {
            try await lightControlService.setBrightness(deviceId: device.deviceId, value: value)
            device.d52 = LeproBrightness.homeAssistantToDevice(value)
            device.d3 = device.d3 == nil ? device.d3 : LeproBrightness.homeAssistantToDevice(value)
            device.d1 = 1
            device.powerSwitch = 1
            applyOptimisticUpdate(device)
        }
    }

    func applyColor(_ color: RGBColor) async {
        guard var device = selectedDevice else { return }
        let value = Int(brightness.rounded())
        await runCommand {
            try await lightControlService.setColor(deviceId: device.deviceId, color: color, brightness: value)
            device.d1 = 1
            device.powerSwitch = 1
            device.d2 = isLikelyBModel(device) ? (isWhiteLike(color) ? 0 : 1) : 2
            device.d52 = LeproBrightness.homeAssistantToDevice(value)
            if !isLikelyBModel(device) {
                segmentColors = Array(repeating: color, count: LeproD50Codec.segmentCount)
                device.d50 = LeproD50Codec.solid(color)
            }
            selectedColor = color
            applyOptimisticUpdate(device)
        }
    }

    func selectAllSegments() {
        selectedSegmentIndexes = Set(0..<LeproD50Codec.segmentCount)
    }

    func clearSegmentSelection() {
        selectedSegmentIndexes = []
    }

    func selectEvenSegments() {
        selectedSegmentIndexes = Set((0..<LeproD50Codec.segmentCount).filter { ($0 + 1).isMultiple(of: 2) })
    }

    func selectOddSegments() {
        selectedSegmentIndexes = Set((0..<LeproD50Codec.segmentCount).filter { !($0 + 1).isMultiple(of: 2) })
    }

    func selectFirstHalfSegments() {
        selectedSegmentIndexes = Set(0..<(LeproD50Codec.segmentCount / 2))
    }

    func selectSecondHalfSegments() {
        selectedSegmentIndexes = Set((LeproD50Codec.segmentCount / 2)..<LeproD50Codec.segmentCount)
    }

    func toggleSegment(_ index: Int) {
        guard 0..<LeproD50Codec.segmentCount ~= index else { return }
        if selectedSegmentIndexes.contains(index) {
            selectedSegmentIndexes.remove(index)
        } else {
            selectedSegmentIndexes.insert(index)
        }
    }

    func applyColorToSelectedSegments(_ color: RGBColor) async {
        guard var device = selectedDevice else { return }
        guard supportsSegments else {
            errorMessage = "Este dispositivo no expone segmentos d50."
            return
        }
        guard !selectedSegmentIndexes.isEmpty else {
            errorMessage = "Selecciona al menos un segmento."
            return
        }

        var colors = segmentColors
        for index in selectedSegmentIndexes where colors.indices.contains(index) {
            colors[index] = color
        }
        let d50 = LeproD50Codec.generate(colors: colors)
        let value = Int(brightness.rounded())

        await runCommand {
            try await lightControlService.setSegmentColors(deviceId: device.deviceId, colors: colors, brightness: value)
            device.d1 = 1
            device.powerSwitch = 1
            device.d2 = 2
            device.d52 = LeproBrightness.homeAssistantToDevice(value)
            device.d50 = d50
            segmentColors = colors
            selectedColor = color
            applyOptimisticUpdate(device)
        }
    }

    func applySegmentPreset(_ preset: SegmentPalettePreset) async {
        guard var device = selectedDevice else { return }
        guard supportsSegments else {
            errorMessage = "Este dispositivo no expone segmentos d50."
            return
        }

        let colors = preset.colors()
        let d50 = LeproD50Codec.generate(colors: colors)
        let value = Int(brightness.rounded())

        await runCommand {
            try await lightControlService.setSegmentColors(deviceId: device.deviceId, colors: colors, brightness: value)
            device.d1 = 1
            device.powerSwitch = 1
            device.d2 = 2
            device.d52 = LeproBrightness.homeAssistantToDevice(value)
            device.d50 = d50
            segmentColors = colors
            selectedSegmentIndexes = Set(0..<LeproD50Codec.segmentCount)
            selectedColor = colors.first
            applyOptimisticUpdate(device)
        }
    }

    func saveCurrentSegmentPreset(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Pon un nombre al diseno."
            return
        }

        let preset = SavedSegmentPreset(name: trimmedName, colors: segmentColors)
        savedSegmentPresets.insert(preset, at: 0)
        segmentPresetStore.save(savedSegmentPresets)
        errorMessage = nil
    }

    func deleteSavedSegmentPreset(_ preset: SavedSegmentPreset) {
        savedSegmentPresets.removeAll { $0.id == preset.id }
        segmentPresetStore.save(savedSegmentPresets)
    }

    func applySavedSegmentPreset(_ preset: SavedSegmentPreset) async {
        guard var device = selectedDevice else { return }
        guard supportsSegments else {
            errorMessage = "Este dispositivo no expone segmentos d50."
            return
        }

        let colors = LeproD50Codec.normalize(preset.colors)
        let d50 = LeproD50Codec.generate(colors: colors)
        let value = Int(brightness.rounded())

        await runCommand {
            try await lightControlService.setSegmentColors(deviceId: device.deviceId, colors: colors, brightness: value)
            device.d1 = 1
            device.powerSwitch = 1
            device.d2 = 2
            device.d52 = LeproBrightness.homeAssistantToDevice(value)
            device.d50 = d50
            segmentColors = colors
            selectedSegmentIndexes = Set(0..<LeproD50Codec.segmentCount)
            selectedColor = colors.first
            applyOptimisticUpdate(device)
        }
    }

    private func runCommand(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await operation()
        } catch let error as LeproError {
            print("Device command error: \(error.localizedDescription)")
            errorMessage = error.userMessage
        } catch {
            print("Device command error: \(error)")
            errorMessage = LeproError.unknown(error.localizedDescription).userMessage
        }
        isLoading = false
    }

    private func applyOptimisticUpdate(_ device: LeproDevice) {
        selectedDevice = device
        isOn = device.isOn
        brightness = Double(device.brightness255)
        onDeviceUpdated?(device)
    }

    private func isLikelyBModel(_ device: LeproDevice) -> Bool {
        let model = (device.series ?? "").uppercased()
        return ["B1", "BC1", "B2", "B3", "T1", "BP1", "SE1"].contains { model.contains($0) }
    }

    private func isWhiteLike(_ color: RGBColor) -> Bool {
        max(color.red, color.green, color.blue) - min(color.red, color.green, color.blue) <= 12
    }
}
