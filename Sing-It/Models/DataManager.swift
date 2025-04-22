import Foundation

class DataManager {
    
    // MARK: - File paths
    static let songsFileName = "songs.json"
    static let setsFileName = "sets.json"
    
    // MARK: - Singleton instance
    static let shared = DataManager()
    private init() {
        loadSongs()
        loadSets()
    }
    
    // MARK: - Data storage
    private(set) var songs: [Song] = []
    private(set) var sets: [Setlist] = []
    
    // MARK: - Document directory
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - File URLs
    private var songsFileURL: URL {
        documentsDirectory.appendingPathComponent(DataManager.songsFileName)
    }
    
    private var setsFileURL: URL {
        documentsDirectory.appendingPathComponent(DataManager.setsFileName)
    }
    
    // MARK: - Songs CRUD operations
    func addSong(_ song: Song) {
        songs.append(song)
        saveSongs()
    }
    
    func updateSong(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index] = song
            saveSongs()
        }
    }
    
    func deleteSong(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs.remove(at: index)
            saveSongs()
        }
    }
    
    // MARK: - Sets CRUD operations
    func addSet(_ set: Setlist) {
        sets.append(set)
        saveSets()
    }
    
    func updateSet(_ set: Setlist) {
        if let index = sets.firstIndex(where: { $0.id == set.id }) {
            sets[index] = set
            saveSets()
        }
    }
    
    func deleteSet(_ set: Setlist) {
        if let index = sets.firstIndex(where: { $0.id == set.id }) {
            sets.remove(at: index)
            saveSets()
        }
    }
    
    // MARK: - Persistence
    private func saveSongs() {
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: songsFileURL)
        } catch {
            print("Error saving songs: \(error)")
        }
    }
    
    private func loadSongs() {
        guard FileManager.default.fileExists(atPath: songsFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: songsFileURL)
            songs = try JSONDecoder().decode([Song].self, from: data)
        } catch {
            print("Error loading songs: \(error)")
        }
    }
    
    private func saveSets() {
        do {
            let data = try JSONEncoder().encode(sets)
            try data.write(to: setsFileURL)
        } catch {
            print("Error saving sets: \(error)")
        }
    }
    
    private func loadSets() {
        guard FileManager.default.fileExists(atPath: setsFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: setsFileURL)
            sets = try JSONDecoder().decode([Setlist].self, from: data)
        } catch {
            print("Error loading sets: \(error)")
        }
    }
}