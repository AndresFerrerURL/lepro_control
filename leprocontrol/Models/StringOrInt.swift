import Foundation

struct StringOrInt: Codable, Hashable, CustomStringConvertible {
    let stringValue: String

    var intValue: Int? {
        Int(stringValue)
    }

    var description: String { stringValue }

    init(_ value: String) {
        stringValue = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            stringValue = string
        } else if let int = try? container.decode(Int.self) {
            stringValue = String(int)
        } else if let double = try? container.decode(Double.self) {
            stringValue = String(Int(double))
        } else {
            throw DecodingError.typeMismatch(
                StringOrInt.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string or number")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return int
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Int(string)
        }
        if let bool = try? decodeIfPresent(Bool.self, forKey: key) {
            return bool ? 1 : 0
        }
        return nil
    }

    func decodeFlexibleBoolIfPresent(forKey key: Key) throws -> Bool? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: key) {
            return bool
        }
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return int != 0
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            if let int = Int(string) {
                return int != 0
            }
            return ["true", "yes", "online"].contains(string.lowercased())
        }
        return nil
    }
}
