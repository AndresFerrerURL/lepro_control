import Foundation

final class SegmentPresetStore {
    private let defaults: UserDefaults
    private let key = "ferrerlabs.leprocontrol.savedSegmentPresets"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [SavedSegmentPreset] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SavedSegmentPreset].self, from: data)
        } catch {
            print("Could not decode saved segment presets: \(error)")
            return []
        }
    }

    func save(_ presets: [SavedSegmentPreset]) {
        do {
            let data = try JSONEncoder().encode(presets)
            defaults.set(data, forKey: key)
        } catch {
            print("Could not save segment presets: \(error)")
        }
    }
}
