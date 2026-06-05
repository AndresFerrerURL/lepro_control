import CryptoKit
import Foundation

enum LeproMACFactory {
    static func persistentMAC(for account: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(account.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        let parts = [
            "02",
            String(hex.prefix(2)),
            String(hex.dropFirst(2).prefix(2)),
            String(hex.dropFirst(4).prefix(2)),
            String(hex.dropFirst(6).prefix(2)),
            String(hex.dropFirst(8).prefix(2))
        ]
        return parts.joined(separator: ":")
    }
}
