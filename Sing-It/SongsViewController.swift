import UIKit
import Foundation

// MARK: - Custom Song Cell
class SongTableViewCell: UITableViewCell {
    
    static let identifier = "SongTableViewCell"
    
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    var editHandler: (() -> Void)?
    var deleteHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Configure title label
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Configure artist label
        artistLabel.font = UIFont.systemFont(ofSize: 14)
        artistLabel.textColor = .gray
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artistLabel)
        
        // Configure edit button
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.tintColor = .systemBlue
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(editButton)
        
        // Configure delete button
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -8),
            
            // Artist label
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -8),
            artistLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            // Edit button
            editButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -16),
            editButton.widthAnchor.constraint(equalToConstant: 44),
            editButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Delete button
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func localMP3FileURL(for fileName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    func configure(with song: Song) {
        titleLabel.text = song.title
        artistLabel.text = song.artist
        // MP3 indicator
        let formattedTitle = SongViewerViewController.formatForFileNameStatic(song.title)
        let formattedArtist = SongViewerViewController.formatForFileNameStatic(song.artist)
        let fileName = formattedArtist.isEmpty ? "\(formattedTitle).mp3" : "\(formattedTitle)(\(formattedArtist)).mp3"
        let localURL = localMP3FileURL(for: fileName)
        if FileManager.default.fileExists(atPath: localURL.path) {
            // Show a small MP3 icon or label
            if contentView.viewWithTag(9999) == nil {
                let mp3Icon = UIImageView(image: UIImage(systemName: "music.note"))
                mp3Icon.tintColor = .systemPurple
                mp3Icon.translatesAutoresizingMaskIntoConstraints = false
                mp3Icon.tag = 9999
                contentView.addSubview(mp3Icon)
                NSLayoutConstraint.activate([
                    mp3Icon.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                    mp3Icon.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
                    mp3Icon.widthAnchor.constraint(equalToConstant: 20),
                    mp3Icon.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
        } else {
            // Remove icon if present
            if let icon = contentView.viewWithTag(9999) {
                icon.removeFromSuperview()
            }
        }
    }
    
    @objc private func editButtonTapped() {
        editHandler?()
    }
    
    @objc private func deleteButtonTapped() {
        deleteHandler?()
    }
}

class SongsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Replace the single button with three separate buttons
    @IBOutlet weak var createEmptySongButton: UIButton!
    @IBOutlet weak var importXMLButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    var songs: [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Songs"
        
        // Set up the table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.identifier)
        
        // Round the corners of the buttons
        createEmptySongButton.layer.cornerRadius = 8
        importXMLButton.layer.cornerRadius = 8  
        downloadButton.layer.cornerRadius = 8
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier, for: indexPath) as? SongTableViewCell else {
            return UITableViewCell()
        }
        let song = songs[indexPath.row]
        cell.configure(with: song)
        
        // Use song identifier rather than index path for edit and delete operations
        cell.editHandler = { [weak self] in
            self?.navigateToSongEditor(with: song)
        }
        
        cell.deleteHandler = { [weak self] in
            self?.deleteSong(song)
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let song = songs[indexPath.row]
        navigateToSongViewer(with: song)
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // Replace the createNewSongTapped action with three separate action methods
    
    @IBAction func createEmptySongTapped(_ sender: UIButton) {
        createEmptySong()
    }
    
    @IBAction func importXMLTapped(_ sender: UIButton) {
        importSongFromXML()
    }
    
    @IBAction func downloadTapped(_ sender: UIButton) {
        openDownloadPage()
    }
    
    // Existing method for creating an empty song
    private func createEmptySong() {
        // Show dialog to input title and artist
        let alert = UIAlertController(title: "Create New Song", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Song Title"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Artist"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let titleField = alert.textFields?[0],
                  let artistField = alert.textFields?[1],
                  let title = titleField.text, !title.isEmpty,
                  let artist = artistField.text, !artist.isEmpty else {
                return
            }
            
            // Create the new song
            let newSong = Song(title: title, artist: artist)
            
            // Navigate to the song part editor
            self.openSongEditor(for: newSong, isNew: true)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(createAction)
        
        present(alert, animated: true)
    }
    
    // New method for importing a song from XML
    private func importSongFromXML() {
        // Create and present a dedicated XML input view controller
        let xmlInputVC = XMLInputViewController()
        xmlInputVC.modalPresentationStyle = .formSheet
        xmlInputVC.preferredContentSize = CGSize(width: 600, height: 800)
        
        // Set completion handler
        xmlInputVC.onImport = { [weak self] xmlContent in
            guard let self = self else { return }
            
            // Parse the XML content
            if let song = self.parseSongFromXML(xmlContent) {
                // Navigate to the song part editor
                self.openSongEditor(for: song, isNew: true)
            } else {
                // Show error if parsing failed
                self.showErrorAlert(message: "Could not parse the XML data. Please check the format and try again.")
            }
        }
        
        present(xmlInputVC, animated: true)
    }
    
    // New method to open the download page
    private func openDownloadPage() {
        // Create a navigation controller with the web view controller
        let webViewController = WebViewController()
        let navigationController = UINavigationController(rootViewController: webViewController)
        navigationController.modalPresentationStyle = .fullScreen
        
        // Present the navigation controller
        present(navigationController, animated: true)
    }
    
    // Helper method to show error messages
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Parse song data from XML string
    private func parseSongFromXML(_ xmlString: String) -> Song? {
        // Create a simple XML parser
        let parser = XMLSongParser()
        return parser.parseSongFromXML(xmlString)
    }
    
    // Helper method to open the song editor - made public so WebViewController can access it
    func openSongEditor(for song: Song, isNew: Bool) {
        guard let songEditorVC = storyboard?.instantiateViewController(withIdentifier: "SongPartEditorViewController") as? SongPartEditorViewController else {
            return
        }
        
        // Configure the editor with the song
        songEditorVC.song = song
        songEditorVC.isNewSong = isNew
        
        // Push the editor view controller
        navigationController?.pushViewController(songEditorVC, animated: true)
    }
    
    // MARK: - Navigation
    
    private func navigateToSongViewer(with song: Song) {
        // Create and configure the song viewer
        let songViewerVC = SongViewerViewController()
        songViewerVC.song = song
        
        // Push the viewer view controller
        navigationController?.pushViewController(songViewerVC, animated: true)
    }
    
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
    
    private func deleteSong(_ song: Song) {
        // Show confirmation dialog before deleting
        let alert = UIAlertController(
            title: "Delete Song",
            message: "Are you sure you want to delete '\(song.title)' by \(song.artist)? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        // Delete action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Find the index of the song to delete before removing it
            if let index = self.songs.firstIndex(where: { $0.id == song.id }) {
                let indexPath = IndexPath(row: index, section: 0)
                
                // Delete song from data manager
                DataManager.shared.deleteSong(song)
                
                // Update local data
                self.loadSongs()
                
                // Update UI
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        alert.addAction(deleteAction)
        
        // Present the alert
        present(alert, animated: true)
    }
}

// XML Parser for iOS
class XMLSongParser: NSObject, XMLParserDelegate {
    private var song: Song?
    private var currentElement = ""
    private var currentPartType: PartType?
    private var currentLyrics = ""
    private var currentChords = ""
    private var isInLyrics = false
    private var isInChords = false
    private var isInLine = false
    private var lineContent = ""
    private var tempTitle = ""
    private var tempArtist = ""
    private var tempTempo = "" // Add temporary storage for tempo
    private var tempCapo = "" // Add temporary storage for capo
    
    func parseSongFromXML(_ xmlString: String) -> Song? {
        guard let data = xmlString.data(using: .utf8) else { return nil }
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        // Reset state
        song = nil
        currentElement = ""
        currentPartType = nil
        currentLyrics = ""
        currentChords = ""
        isInLyrics = false
        isInChords = false
        isInLine = false
        lineContent = ""
        tempTitle = ""
        tempArtist = ""
        tempTempo = "" // Reset tempo value
        tempCapo = "" // Reset capo value
        
        if parser.parse() {
            return song
        } else {
            print("Error parsing XML: \(String(describing: parser.parserError))")
            return nil
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "song":
            // Create a new song
            song = nil
        case "part":
            // Reset for a new part
            currentPartType = nil
            currentLyrics = ""
            currentChords = ""
        case "lyrics":
            isInLyrics = true
            isInChords = false
        case "chords":
            isInChords = true
            isInLyrics = false
        case "line":
            isInLine = true
            lineContent = ""
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "title":
            if song == nil && !tempTitle.isEmpty && !tempArtist.isEmpty {
                song = Song(title: tempTitle, artist: tempArtist)
            }
        case "artist":
            if song == nil && !tempTitle.isEmpty && !tempArtist.isEmpty {
                song = Song(title: tempTitle, artist: tempArtist)
            }
        case "tempo":
            if let song = song, let tempo = Int(tempTempo) {
                song.tempo = tempo
            }
        case "capo":
            if let song = song {
                if tempCapo.lowercased() == "none" {
                    song.capo = 0
                } else if let capo = Int(tempCapo), capo >= 1 && capo <= 11 {
                    song.capo = capo
                }
            }
        case "part":
            if let song = song, let partType = currentPartType {
                let part = Part(partType: partType, lyrics: currentLyrics, chords: currentChords)
                song.parts.append(part)
            }
        case "line":
            isInLine = false
            if isInLyrics {
                if !currentLyrics.isEmpty {
                    currentLyrics += "\n"
                }
                currentLyrics += lineContent
            } else if isInChords {
                if !currentChords.isEmpty {
                    currentChords += "\n"
                }
                currentChords += lineContent
            }
            lineContent = ""
        case "lyrics":
            isInLyrics = false
        case "chords":
            isInChords = false
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !data.isEmpty {
            switch currentElement {
            case "title":
                tempTitle += data
            case "artist":
                tempArtist += data
            case "tempo":
                tempTempo += data
            case "capo":
                tempCapo += data
            case "type":
                if let partType = PartType(rawValue: data) {
                    currentPartType = partType
                }
            case "line":
                if isInLine {
                    lineContent += data
                }
            default:
                break
            }
        }
    }
}

// MARK: - XMLInputViewController
class XMLInputViewController: UIViewController {
    
    private let containerView = UIView()
    private let textView = UITextView()
    private let importButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let instructionLabel = UILabel()
    
    var onImport: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray6
        
        // Container view
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 10
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Instruction label
        instructionLabel.text = "Paste the XML data for your song below:"
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.textAlignment = .left
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(instructionLabel)
        
        // Text view for XML input
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textView)
        
        // Import button
        importButton.setTitle("Import", for: .normal)
        importButton.backgroundColor = .systemBlue
        importButton.setTitleColor(.white, for: .normal)
        importButton.layer.cornerRadius = 8
        importButton.addTarget(self, action: #selector(importButtonTapped), for: .touchUpInside)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(importButton)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.setTitleColor(.darkGray, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        // Layout
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Text view
            textView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: importButton.topAnchor, constant: -20),
            
            // Buttons
            importButton.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 4),
            importButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            importButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            importButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -4),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func importButtonTapped() {
        guard let xmlContent = textView.text, !xmlContent.isEmpty else {
            showError(message: "Please enter XML data.")
            return
        }
        
        onImport?(xmlContent)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}