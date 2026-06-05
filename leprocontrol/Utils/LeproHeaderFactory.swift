import Foundation

enum LeproHeaderFactory {
    static let appVersion = "1.0.9.202"
    static let platform = "2"
    static let deviceModel = "custom_integration"
    static let deviceSystem = "custom"

    static func timestamp() -> String {
        String(Int(Date().timeIntervalSince1970))
    }

    static func headers(apiHost: String, language: String, timestamp: String, token: String? = nil) -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "App-Version": appVersion,
            "Device-Model": deviceModel,
            "Device-System": deviceSystem,
            "GMT": "+0",
            "Host": apiHost,
            "Language": language,
            "Platform": platform,
            "Screen-Size": "1536*2048",
            "Slanguage": language,
            "Timestamp": timestamp,
            "User-Agent": "LE/\(appVersion) (Custom Integration)"
        ]

        if let token {
            headers["Authorization"] = "Bearer \(token)"
            headers["Accept-Encoding"] = "gzip"
        }

        return headers
    }
}
