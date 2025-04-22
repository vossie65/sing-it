import UIKit

class SongsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createNewSongButton: UIButton!
    
    var songs: [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Songs"
        
        // Set up the table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SongCell")
        
        // Round the corners of the create button
        createNewSongButton.layer.cornerRadius = 8
        
        // Load songs from data manager
        loadSongs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when coming back from song editor
        loadSongs()
        tableView.reloadData()
    }
    
    func loadSongs() {
        songs = DataManager.shared.songs
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        let song = songs[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = song.title
        content.secondaryText = song.artist
        cell.contentConfiguration = content
        
        return cell
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let song = songs[indexPath.row]
        navigateToSongEditor(with: song)
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createNewSongTapped(_ sender: Any) {
        // Show alert to get song title and artist
        let alertController = UIAlertController(title: "New Song", message: "Enter song details", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Song Title"
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Artist"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let titleField = alertController.textFields?[0],
                  let artistField = alertController.textFields?[1],
                  let title = titleField.text, !title.isEmpty,
                  let artist = artistField.text, !artist.isEmpty else {
                return
            }
            
            // Create a new song
            let song = Song(title: title, artist: artist, parts: [])
            self?.navigateToSongEditor(with: song)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        
        present(alertController, animated: true)
    }
    
    // MARK: - Navigation
    
    private func navigateToSongEditor(with song: Song) {
        // Get the song editor view controller
        guard let songEditorVC = storyboard?.instantiateViewController(withIdentifier: "SongPartEditorViewController") as? SongPartEditorViewController else {
            return
        }
        
        // Configure the editor with the song
        songEditorVC.song = song
        songEditorVC.isNewSong = !DataManager.shared.songs.contains { $0.id == song.id }
        
        // Push the editor view controller
        navigationController?.pushViewController(songEditorVC, animated: true)
    }
}