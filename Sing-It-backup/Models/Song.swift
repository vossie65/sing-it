import Foundation

class Song: Codable, Identifiable {
    var id = UUID()
    var title: String
    var artist: String
    var tempo: Int
    var capo: Int // 0 means "None", 1-11 represent fret positions
    var parts: [Part]
    
    init(title: String, artist: String, tempo: Int = 120, capo: Int = 0, parts: [Part] = []) {
        self.title = title
        self.artist = artist
        self.tempo = tempo
        self.capo = capo
        self.parts = parts
    }
    
    func addPart(partType: PartType, lyrics: String, chords: String) {
        let part = Part(partType: partType, lyrics: lyrics, chords: chords)
        parts.append(part)
    }
}