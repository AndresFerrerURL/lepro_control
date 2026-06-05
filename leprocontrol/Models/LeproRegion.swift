import Foundation

enum LeproRegion: String, CaseIterable, Identifiable, Codable {
    case eu
    case us
    case na
    case fe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eu: "Europe"
        case .us: "United States"
        case .na: "North America"
        case .fe: "Far East"
        }
    }

    var apiHost: String {
        switch self {
        case .eu: "api-eu-iot.lepro.com"
        case .na: "api-na-iot.lepro.com"
        case .fe: "api-fe-iot.lepro.com"
        case .us: "api-us-iot.lepro.com"
        }
    }
}
