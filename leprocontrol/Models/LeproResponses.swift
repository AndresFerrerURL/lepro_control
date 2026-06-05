import Foundation

struct LoginRequest: Encodable {
    let platform: String
    let account: String
    let password: String
    let mac: String
    let timestamp: String
    let language: String
    let fcmToken: String
}

struct LoginResponse: Decodable {
    let code: Int
    let msg: String?
    let data: LoginData?
}

struct LeproCloudErrorResponse: Decodable {
    let code: Int
    let msg: String?
}

struct LoginData: Decodable {
    let token: String?
}

struct UserProfileResponse: Decodable {
    let code: Int?
    let msg: String?
    let data: UserProfileData?
}

struct UserProfileData: Decodable {
    let uid: StringOrInt
    let mqtt: MqttInfo
}

struct MqttInfo: Codable, Equatable {
    let host: String
    let port: StringOrInt
    let root: URL
    let cert: URL
}

struct FamilyListResponse: Decodable {
    let code: Int?
    let msg: String?
    let data: FamilyListData?
}

struct FamilyListData: Decodable {
    let list: [LeproFamily]
}

struct LeproFamily: Decodable, Identifiable {
    let fid: StringOrInt
    var id: String { fid.stringValue }
}

struct DeviceListResponse: Decodable {
    let code: Int?
    let msg: String?
    let data: DeviceListData?
}

struct DeviceListData: Decodable {
    let list: [LeproDevice]
}

struct MqttCommandEnvelope: Encodable {
    let id: Int
    let t: Int
    let d: [String: LeproCommandValue]
}

enum LeproCommandValue: Encodable, Equatable {
    case int(Int)
    case string(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}
