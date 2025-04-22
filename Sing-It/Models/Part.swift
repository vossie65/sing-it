import Foundation

class Part: Codable, Identifiable {
    var id = UUID()
    var partType: PartType
    var lyrics: String
    var chords: String
    
    init(partType: PartType, lyrics: String, chords: String) {
        self.partType = partType
        self.lyrics = lyrics
        self.chords = chords
    }
}