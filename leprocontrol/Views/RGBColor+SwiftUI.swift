import SwiftUI

#if os(macOS)
import AppKit
#endif

extension RGBColor {
    var swiftUIColor: Color {
        Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }

    var isLight: Bool {
        (red * 299 + green * 587 + blue * 114) / 1000 > 160
    }
}

extension Color {
    func rgbColor(named name: String = "Personalizado") -> RGBColor {
        #if os(macOS)
        let color = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return RGBColor(
            name,
            red: Int(round(color.redComponent * 255)),
            green: Int(round(color.greenComponent * 255)),
            blue: Int(round(color.blueComponent * 255))
        )
        #else
        return .white
        #endif
    }
}
