import Foundation

enum SegmentPalettePreset: String, CaseIterable, Identifiable {
    case rainbow
    case sunset
    case aurora
    case ocean
    case warmCool
    case alternating

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rainbow: "Arcoiris"
        case .sunset: "Atardecer"
        case .aurora: "Aurora"
        case .ocean: "Oceano"
        case .warmCool: "Calido/frio"
        case .alternating: "Alterno"
        }
    }

    var systemImage: String {
        switch self {
        case .rainbow: "rainbow"
        case .sunset: "sunset"
        case .aurora: "sparkles"
        case .ocean: "water.waves"
        case .warmCool: "thermometer.sun"
        case .alternating: "circle.grid.cross"
        }
    }

    func colors(segmentCount: Int = LeproD50Codec.segmentCount) -> [RGBColor] {
        let stops: [RGBColor]
        switch self {
        case .rainbow:
            stops = [
                RGBColor("Rojo", red: 255, green: 0, blue: 0),
                RGBColor("Naranja", red: 255, green: 128, blue: 0),
                RGBColor("Amarillo", red: 255, green: 230, blue: 0),
                RGBColor("Verde", red: 0, green: 220, blue: 72),
                RGBColor("Cian", red: 0, green: 205, blue: 255),
                RGBColor("Azul", red: 0, green: 80, blue: 255),
                RGBColor("Violeta", red: 150, green: 70, blue: 255)
            ]
        case .sunset:
            stops = [
                RGBColor("Dorado", red: 255, green: 205, blue: 40),
                RGBColor("Naranja", red: 255, green: 110, blue: 0),
                RGBColor("Coral", red: 255, green: 55, blue: 60),
                RGBColor("Magenta", red: 235, green: 0, blue: 150),
                RGBColor("Violeta", red: 92, green: 45, blue: 255)
            ]
        case .aurora:
            stops = [
                RGBColor("Verde aurora", red: 0, green: 255, blue: 130),
                RGBColor("Menta", red: 0, green: 220, blue: 190),
                RGBColor("Azul hielo", red: 80, green: 180, blue: 255),
                RGBColor("Violeta", red: 160, green: 85, blue: 255),
                RGBColor("Rosa", red: 255, green: 110, blue: 210)
            ]
        case .ocean:
            stops = [
                RGBColor("Azul profundo", red: 0, green: 45, blue: 170),
                RGBColor("Azul", red: 0, green: 95, blue: 255),
                RGBColor("Cian", red: 0, green: 210, blue: 255),
                RGBColor("Turquesa", red: 0, green: 255, blue: 200),
                RGBColor("Blanco espuma", red: 230, green: 255, blue: 255)
            ]
        case .warmCool:
            stops = [
                RGBColor("Blanco calido", red: 255, green: 210, blue: 165),
                RGBColor("Ambar", red: 255, green: 170, blue: 0),
                RGBColor("Rosa", red: 255, green: 100, blue: 165),
                RGBColor("Azul frio", red: 70, green: 145, blue: 255),
                RGBColor("Blanco frio", red: 220, green: 245, blue: 255)
            ]
        case .alternating:
            stops = [
                RGBColor("Azul", red: 0, green: 90, blue: 255),
                RGBColor("Magenta", red: 255, green: 0, blue: 190),
                RGBColor("Azul", red: 0, green: 90, blue: 255),
                RGBColor("Magenta", red: 255, green: 0, blue: 190),
                RGBColor("Azul", red: 0, green: 90, blue: 255),
                RGBColor("Magenta", red: 255, green: 0, blue: 190),
                RGBColor("Azul", red: 0, green: 90, blue: 255),
                RGBColor("Magenta", red: 255, green: 0, blue: 190),
                RGBColor("Azul", red: 0, green: 90, blue: 255)
            ]
        }

        return bands(stops: stops, count: segmentCount)
    }

    private func bands(stops: [RGBColor], count: Int) -> [RGBColor] {
        guard let first = stops.first else {
            return Array(repeating: .white, count: count)
        }
        guard stops.count > 1, count > 1 else {
            return Array(repeating: first, count: count)
        }

        var colors: [RGBColor] = []
        for index in 0..<count {
            let stopIndex = min(index * stops.count / count, stops.count - 1)
            colors.append(stops[stopIndex])
        }
        return colors
    }
}
