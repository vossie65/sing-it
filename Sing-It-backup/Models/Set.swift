import Foundation

class Setlist: Codable, Identifiable {
    var id = UUID()
    var name: String
    var songs: [Song]
    
    init(name: String, songs: [Song] = []) {
        self.name = name
        self.songs = songs
    }
    
    func addSong(song: Song) {
        songs.append(song)
    }
    
    func removeSong(at index: Int) {
        guard index < songs.count else { return }
        songs.remove(at: index)
    }
}