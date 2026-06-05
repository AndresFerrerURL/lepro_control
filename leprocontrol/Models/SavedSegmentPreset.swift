import Foundation

struct SavedSegmentPreset: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var colors: [RGBColor]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, colors: [RGBColor], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colors = LeproD50Codec.normalize(colors)
        self.createdAt = createdAt
    }
}
