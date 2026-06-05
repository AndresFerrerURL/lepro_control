import Foundation

struct LeproDevice: Codable, Identifiable, Equatable {
    let did: StringOrInt
    let fid: StringOrInt?
    let name: String
    let series: String?
    let fwVersion: String?
    let hwVersion: String?
    var powerSwitch: Int?
    var d1: Int?
    var d2: Int?
    var d3: Int?
    var d4: Int?
    var d5: String?
    var d30: String?
    var d50: String?
    var d52: Int?
    var d60: String?
    var online: Bool?

    var id: String { did.stringValue }
    var deviceId: String { did.stringValue }
    var displayName: String { name.isEmpty ? deviceId : name }

    var isOn: Bool {
        if let d1 { return d1 != 0 }
        if let powerSwitch { return powerSwitch != 0 }
        return false
    }

    var brightness255: Int {
        if let d52 { return LeproBrightness.deviceToHomeAssistant(d52) }
        if let d3 { return LeproBrightness.deviceToHomeAssistant(d3) }
        if let d5, d5.count >= 12, let value = Int(d5.dropFirst(8).prefix(4), radix: 16) {
            return LeproBrightness.deviceToHomeAssistant(value)
        }
        return 255
    }

    enum CodingKeys: String, CodingKey {
        case did
        case fid
        case name
        case series
        case fwVersion
        case hwVersion
        case powerSwitch = "switch"
        case d1
        case d2
        case d3
        case d4
        case d5
        case d30
        case d50
        case d52
        case d60
        case online
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        did = try container.decode(StringOrInt.self, forKey: .did)
        fid = try container.decodeIfPresent(StringOrInt.self, forKey: .fid)
        name = (try? container.decode(String.self, forKey: .name)) ?? did.stringValue
        series = try container.decodeIfPresent(String.self, forKey: .series)
        fwVersion = try container.decodeIfPresent(String.self, forKey: .fwVersion)
        hwVersion = try container.decodeIfPresent(String.self, forKey: .hwVersion)
        powerSwitch = try container.decodeFlexibleIntIfPresent(forKey: .powerSwitch)
        d1 = try container.decodeFlexibleIntIfPresent(forKey: .d1)
        d2 = try container.decodeFlexibleIntIfPresent(forKey: .d2)
        d3 = try container.decodeFlexibleIntIfPresent(forKey: .d3)
        d4 = try container.decodeFlexibleIntIfPresent(forKey: .d4)
        d5 = try container.decodeIfPresent(String.self, forKey: .d5)
        d30 = try container.decodeIfPresent(String.self, forKey: .d30)
        d50 = try container.decodeIfPresent(String.self, forKey: .d50)
        d52 = try container.decodeFlexibleIntIfPresent(forKey: .d52)
        d60 = try container.decodeIfPresent(String.self, forKey: .d60)
        online = try container.decodeFlexibleBoolIfPresent(forKey: .online)
    }
}

struct LightState: Codable, Equatable {
    var isOn: Bool
    var brightness: Int
    var isOnline: Bool?
}
