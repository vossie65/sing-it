import Foundation

class Song: Codable, Identifiable {
    var id = UUID()
    var title: String
    var artist: String
    var tempo: Int
    var parts: [Part]
    
    init(title: String, artist: String, tempo: Int = 120, parts: [Part] = []) {
        self.title = title
        self.artist = artist
        self.tempo = tempo
        self.parts = parts
    }
    
    func addPart(partType: PartType, lyrics: String, chords: String) {
        let part = Part(partType: partType, lyrics: lyrics, chords: chords)
        parts.append(part)
    }
}