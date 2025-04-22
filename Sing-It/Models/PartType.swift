import Foundation

enum PartType: String, Codable, CaseIterable {
    case verse = "Verse"
    case chorus = "Chorus"
    case bridge = "Bridge"
    case intro = "Intro"
    case outro = "Outro"
    case solo = "Solo"
}