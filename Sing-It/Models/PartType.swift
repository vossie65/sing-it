import Foundation

enum PartType: String, Codable, CaseIterable {
    case verse = "Verse"
    case chorus = "Chorus"
    case preChorus = "Pre-Chorus"
    case postChorus = "Post-Chorus"
    case bridge = "Bridge"
    case intro = "Intro"
    case interlude = "Interlude"
    case outro = "Outro"
    case solo = "Solo"
}