import Foundation

enum LeproD50Codec {
    static let segmentCount = 25
    private static let solidEffectTail = "000640000E1"

    static var defaultColors: [RGBColor] {
        Array(repeating: .white, count: segmentCount)
    }

    static func solid(_ color: RGBColor) -> String {
        generate(colors: Array(repeating: color, count: segmentCount))
    }

    static func generate(colors inputColors: [RGBColor]) -> String {
        let colors = normalize(inputColors)
        let groups = compressedGroups(colors)
        let colorHex = groups.map(\.color.hexString).joined()
        let lengthsHex = groups.map { String(format: "%04X", $0.count) }.joined()
        let groupCount = groups.count

        return "N01:P1000\(groupCount)\(colorHex)F21000\(groupCount)\(lengthsHex)U3V3\(solidEffectTail);"
    }

    static func parse(_ d50: String?) -> [RGBColor] {
        guard let d50, !d50.isEmpty else {
            return defaultColors
        }

        do {
            return try parseGrouped(d50)
        } catch {
            if let fallback = parseSingleColor(d50) {
                return Array(repeating: fallback, count: segmentCount)
            }
            print("Could not parse d50 segment colors: \(error)")
            return defaultColors
        }
    }

    private static func parseGrouped(_ d50: String) throws -> [RGBColor] {
        guard let pRange = d50.range(of: "P1000") else {
            throw LeproError.invalidResponse("Missing P1000 marker in d50")
        }
        guard let fRange = d50.range(of: "F21000", range: pRange.upperBound..<d50.endIndex) else {
            throw LeproError.invalidResponse("Missing F21000 marker in d50")
        }

        let block = String(d50[pRange.upperBound..<fRange.lowerBound])
        var groupCount: Int?
        var digitCount: Int?

        for digits in 1...3 where block.count >= digits {
            let prefix = String(block.prefix(digits))
            guard let candidate = Int(prefix) else { continue }
            if block.count - digits == candidate * 6 {
                groupCount = candidate
                digitCount = digits
                break
            }
        }

        guard let groupCount, let digitCount else {
            throw LeproError.invalidResponse("Could not infer d50 group count")
        }

        let colorsHex = String(block.dropFirst(digitCount))
        let colors = try stride(from: 0, to: groupCount * 6, by: 6).map { offset in
            let start = colorsHex.index(colorsHex.startIndex, offsetBy: offset)
            let end = colorsHex.index(start, offsetBy: 6)
            let hex = String(colorsHex[start..<end])
            guard let color = parseHexColor(hex, name: "#\(hex)") else {
                throw LeproError.invalidResponse("Invalid d50 color \(hex)")
            }
            return color
        }

        let lengthsStart = d50.index(fRange.upperBound, offsetBy: digitCount, limitedBy: d50.endIndex)
        guard let lengthsStart else {
            throw LeproError.invalidResponse("Missing d50 group count after F21000")
        }

        let lengthCharCount = groupCount * 4
        guard let lengthsEnd = d50.index(lengthsStart, offsetBy: lengthCharCount, limitedBy: d50.endIndex) else {
            throw LeproError.invalidResponse("Not enough d50 segment length data")
        }

        let lengthsHex = String(d50[lengthsStart..<lengthsEnd])
        let lengths = stride(from: 0, to: lengthCharCount, by: 4).map { offset -> Int in
            let start = lengthsHex.index(lengthsHex.startIndex, offsetBy: offset)
            let end = lengthsHex.index(start, offsetBy: 4)
            return Int(lengthsHex[start..<end], radix: 16) ?? 0
        }

        var segments: [RGBColor] = []
        for (color, length) in zip(colors, lengths) {
            segments.append(contentsOf: Array(repeating: color, count: length))
        }
        return normalize(segments)
    }

    private static func parseSingleColor(_ d50: String) -> RGBColor? {
        guard let marker = d50.range(of: "P10001") else {
            return nil
        }
        let colorStart = marker.upperBound
        guard let colorEnd = d50.index(colorStart, offsetBy: 6, limitedBy: d50.endIndex) else {
            return nil
        }
        let hex = String(d50[colorStart..<colorEnd])
        return parseHexColor(hex, name: "#\(hex)")
    }

    private static func parseHexColor(_ hex: String, name: String) -> RGBColor? {
        guard hex.count == 6,
              let red = Int(hex.prefix(2), radix: 16),
              let green = Int(hex.dropFirst(2).prefix(2), radix: 16),
              let blue = Int(hex.dropFirst(4).prefix(2), radix: 16) else {
            return nil
        }
        return RGBColor(name, red: red, green: green, blue: blue)
    }

    static func normalize(_ colors: [RGBColor]) -> [RGBColor] {
        guard !colors.isEmpty else {
            return defaultColors
        }

        if colors.count == segmentCount {
            return colors
        }
        if colors.count > segmentCount {
            return Array(colors.prefix(segmentCount))
        }

        var normalized = colors
        normalized.append(contentsOf: Array(repeating: colors.last ?? .white, count: segmentCount - colors.count))
        return normalized
    }

    private static func compressedGroups(_ colors: [RGBColor]) -> [(color: RGBColor, count: Int)] {
        colors.reduce(into: []) { groups, color in
            if let last = groups.last, last.color == color {
                groups[groups.count - 1] = (last.color, last.count + 1)
            } else {
                groups.append((color, 1))
            }
        }
    }
}
