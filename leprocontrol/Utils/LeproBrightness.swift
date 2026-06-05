import Foundation

enum LeproBrightness {
    static func homeAssistantToDevice(_ brightness: Int) -> Int {
        let clamped = max(0, min(255, brightness))
        return Int(Double(clamped) * 1000.0 / 255.0)
    }

    static func deviceToHomeAssistant(_ brightness: Int) -> Int {
        let clamped = max(0, min(1000, brightness))
        return Int(Double(clamped) * 255.0 / 1000.0)
    }
}
