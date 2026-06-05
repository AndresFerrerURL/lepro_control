import Foundation

struct RGBColor: Codable, Equatable, Hashable, Identifiable {
    let red: Int
    let green: Int
    let blue: Int
    let name: String

    var id: String { "\(name)-\(red)-\(green)-\(blue)" }

    init(_ name: String, red: Int, green: Int, blue: Int) {
        self.name = name
        self.red = max(0, min(255, red))
        self.green = max(0, min(255, green))
        self.blue = max(0, min(255, blue))
    }

    var hexString: String {
        String(format: "%02X%02X%02X", red, green, blue)
    }

    static let white = RGBColor("Blanco", red: 255, green: 255, blue: 255)

    static let defaultPalette: [RGBColor] = [
        RGBColor("Rojo intenso", red: 255, green: 0, blue: 0),
        RGBColor("Coral", red: 255, green: 72, blue: 42),
        RGBColor("Naranja", red: 255, green: 124, blue: 0),
        RGBColor("Ambar", red: 255, green: 180, blue: 0),
        RGBColor("Amarillo", red: 255, green: 232, blue: 0),
        RGBColor("Lima", red: 180, green: 255, blue: 0),
        RGBColor("Verde acido", red: 88, green: 255, blue: 0),
        RGBColor("Verde", red: 0, green: 220, blue: 72),
        RGBColor("Menta", red: 0, green: 255, blue: 150),
        RGBColor("Turquesa", red: 0, green: 235, blue: 205),
        RGBColor("Cian", red: 0, green: 205, blue: 255),
        RGBColor("Azul cielo", red: 0, green: 145, blue: 255),
        RGBColor("Azul", red: 0, green: 80, blue: 255),
        RGBColor("Azul profundo", red: 32, green: 38, blue: 255),
        RGBColor("Indigo", red: 78, green: 54, blue: 255),
        RGBColor("Violeta", red: 140, green: 70, blue: 255),
        RGBColor("Purpura", red: 188, green: 55, blue: 255),
        RGBColor("Magenta", red: 255, green: 0, blue: 190),
        RGBColor("Fucsia", red: 255, green: 45, blue: 135),
        RGBColor("Rosa", red: 255, green: 96, blue: 170),
        RGBColor("Rosa suave", red: 255, green: 168, blue: 205),
        RGBColor("Blanco calido", red: 255, green: 214, blue: 170),
        RGBColor("Blanco neutro", red: 245, green: 245, blue: 235),
        RGBColor.white
    ]
}
