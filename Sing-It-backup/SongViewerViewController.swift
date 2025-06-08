import UIKit
import AVFoundation

class SongViewerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var song: Song!
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let capoLabel = UILabel() // New label for capo information
    private let oneRowButton = UIButton(type: .system)
    private let lyricsOnlyButton = UIButton(type: .system) // Renamed from twoRowButton
    private let playAllButton = UIButton(type: .system) // New Play All button
    private let stopButton = UIButton(type: .system) // New Stop button
    private let transposeDownButton = UIButton(type: .system) // Transpose down button
    private let transposeUpButton = UIButton(type: .system) // Transpose up button
    private let mp3Button = UIButton(type: .system) // New MP3 button
    
    // Display mode for song parts
    enum DisplayMode {
        case oneRow // All in one row - type + chords + lyrics side by side
        case lyricsOnly // Show only parts with lyrics, and only the lyrics
    }
    
    // Current display mode, default is one row
    private var currentDisplayMode: DisplayMode = .oneRow
    
    // Audio settings - using fixed default values
    private var currentInstrument: UInt8 = 0  // Always use piano
    private var chordDuration: TimeInterval? = nil  // Always use full-beat (nil means use tempo-based timing)
    private var tempo: Double = 60.0  // Default will be overwritten by song.tempo
    
    // Indicate if playback is in progress
    private var isPlaying = false
    
    // Transposition level (semitones): 0 means no transposition
    var transpositionLevel = 0
    
    // MP3 file properties
    private var mp3URL: URL? = nil
    private var mp3Exists: Bool = false {
        didSet {
            if mp3Exists {
                let playImage = UIImage(systemName: "play.circle.fill")
                mp3Button.setImage(playImage, for: .normal)
                mp3Button.setTitle(" MP3", for: .normal)
                mp3Button.setTitleColor(.systemBlue, for: .normal)
                mp3Button.tintColor = .systemBlue
                mp3Button.isEnabled = true
                mp3Button.alpha = 1.0
            } else {
                mp3Button.setImage(nil, for: .normal)
                mp3Button.setTitle("no MP3", for: .normal)
                mp3Button.setTitleColor(.systemGray, for: .normal)
                mp3Button.tintColor = .systemGray
                mp3Button.isEnabled = false
                mp3Button.alpha = 0.4
            }
        }
    }
    private var mp3Player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureHeaderView()
        
        // Start audio engine when view loads
        AudioEngine.shared.start()
        
        // Set tempo from song model
        if let song = song {
            tempo = Double(song.tempo)
            AudioEngine.shared.setTempo(tempo)
            checkForMP3File()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop audio engine when leaving the view
        AudioEngine.shared.stop()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongPartViewCell.self, forCellReuseIdentifier: SongPartViewCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.backgroundColor = .systemBackground
        tableView.estimatedRowHeight = 180
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
        
        // Set constraints for table view
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Add back button if needed
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
    }
    
    private func configureHeaderView() {
        headerView.backgroundColor = .systemBackground
        
        // Title label setup
        titleLabel.text = song.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Artist label setup - contains only the artist name, no capo or transposition info
        artistLabel.text = song.artist
        artistLabel.font = UIFont.systemFont(ofSize: 18)
        artistLabel.textColor = .secondaryLabel
        artistLabel.textAlignment = .center
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(artistLabel)
        
        // Capo label setup - it will also show transposition info when needed
        if song.capo > 0 {
            capoLabel.text = "Capo: \(song.capo)"
        } else {
            capoLabel.text = ""
        }
        capoLabel.font = UIFont.systemFont(ofSize: 16)
        capoLabel.textColor = .systemBlue
        capoLabel.textAlignment = .left
        capoLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(capoLabel)
        
        // MP3 button setup (move to far left, text label)
        mp3Button.setTitle("no MP3", for: .normal)
        mp3Button.setTitleColor(.systemGray, for: .normal)
        mp3Button.setImage(nil, for: .normal)
        mp3Button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        mp3Button.translatesAutoresizingMaskIntoConstraints = false
        mp3Button.isEnabled = false
        mp3Button.alpha = 0.4
        mp3Button.addTarget(self, action: #selector(mp3ButtonTapped), for: .touchUpInside)
        headerView.addSubview(mp3Button)
        
        // Configure the mode toggle buttons
        setupModeButtons()
        
        // Set constraints for labels and buttons
        NSLayoutConstraint.activate([
            // MP3 button on the far left
            mp3Button.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            mp3Button.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            mp3Button.widthAnchor.constraint(equalToConstant: 110), // Increased from 56 to 110
            mp3Button.heightAnchor.constraint(equalToConstant: 36),
            
            // Capo label to the right of MP3 button
            capoLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            capoLabel.leadingAnchor.constraint(equalTo: mp3Button.trailingAnchor, constant: 8),
            
            // Transpose Down button right after mp3 button
            transposeDownButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            transposeDownButton.leadingAnchor.constraint(equalTo: capoLabel.trailingAnchor, constant: 8),
            transposeDownButton.widthAnchor.constraint(equalToConstant: 36),
            transposeDownButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Transpose Up button to the right of Transpose Down
            transposeUpButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            transposeUpButton.leadingAnchor.constraint(equalTo: transposeDownButton.trailingAnchor, constant: 8),
            transposeUpButton.widthAnchor.constraint(equalToConstant: 36),
            transposeUpButton.heightAnchor.constraint(equalToConstant: 36),
            
            // One Row (Chords & Lyrics) button right of the title
            oneRowButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            oneRowButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Lyrics Only button to the left of One Row button
            lyricsOnlyButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            lyricsOnlyButton.trailingAnchor.constraint(equalTo: oneRowButton.leadingAnchor, constant: -16),
            
            // Play All button to the left of lyrics only button
            playAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            playAllButton.trailingAnchor.constraint(equalTo: lyricsOnlyButton.leadingAnchor, constant: -16),
            playAllButton.widthAnchor.constraint(equalToConstant: 36),
            playAllButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Stop button to the left of play all button
            stopButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            stopButton.trailingAnchor.constraint(equalTo: playAllButton.leadingAnchor, constant: -8),
            stopButton.widthAnchor.constraint(equalToConstant: 36),
            stopButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Title centered between transpose and play buttons
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: transposeUpButton.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: stopButton.leadingAnchor, constant: -16),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            // Artist below title
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            artistLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            artistLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            artistLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            artistLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])
        
        // Set header view to table view with increased height
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100)
        tableView.tableHeaderView = headerView
        
        // Make sure header view is sized correctly
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        // Calculate the required height based on content
        let height = max(100, headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame
        
        // Update the table header view with the proper size
        tableView.tableHeaderView = headerView
    }
    
    private func setupModeButtons() {
        // Setup Chords & Lyrics button (renamed from One-Row button)
        oneRowButton.setTitle("Chords & Lyrics", for: .normal)
        oneRowButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        oneRowButton.addTarget(self, action: #selector(oneRowButtonTapped), for: .touchUpInside)
        oneRowButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(oneRowButton)
        
        // Setup Lyrics-Only button
        lyricsOnlyButton.setTitle("Lyrics Only", for: .normal)
        lyricsOnlyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        lyricsOnlyButton.addTarget(self, action: #selector(lyricsOnlyButtonTapped), for: .touchUpInside)
        lyricsOnlyButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(lyricsOnlyButton)
        
        // Setup Play All button
        playAllButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playAllButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .selected)
        playAllButton.tintColor = .systemGreen
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        playAllButton.addTarget(self, action: #selector(playAllButtonTapped), for: .touchUpInside)
        headerView.addSubview(playAllButton)
        
        // Setup Stop button
        stopButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
        stopButton.tintColor = .systemRed
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        headerView.addSubview(stopButton)
        
        // Setup Transpose Down button
        transposeDownButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        transposeDownButton.tintColor = .systemBlue
        transposeDownButton.translatesAutoresizingMaskIntoConstraints = false
        transposeDownButton.addTarget(self, action: #selector(transposeDownButtonTapped), for: .touchUpInside)
        headerView.addSubview(transposeDownButton)
        
        // Setup Transpose Up button
        transposeUpButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        transposeUpButton.tintColor = .systemBlue
        transposeUpButton.translatesAutoresizingMaskIntoConstraints = false
        transposeUpButton.addTarget(self, action: #selector(transposeUpButtonTapped), for: .touchUpInside)
        headerView.addSubview(transposeUpButton)
        
        // Set initial button states
        updateButtonStates()
    }
    
    private func updateButtonStates() {
        switch currentDisplayMode {
        case .oneRow:
            oneRowButton.isEnabled = false
            oneRowButton.alpha = 0.5
            lyricsOnlyButton.isEnabled = true
            lyricsOnlyButton.alpha = 1.0
        case .lyricsOnly:
            oneRowButton.isEnabled = true
            oneRowButton.alpha = 1.0
            lyricsOnlyButton.isEnabled = false
            lyricsOnlyButton.alpha = 0.5
        }
    }
    
    @objc private func oneRowButtonTapped() {
        if currentDisplayMode != .oneRow {
            currentDisplayMode = .oneRow
            updateButtonStates()
            tableView.reloadData()
        }
    }
    
    @objc private func lyricsOnlyButtonTapped() {
        if currentDisplayMode != .lyricsOnly {
            currentDisplayMode = .lyricsOnly
            updateButtonStates()
            tableView.reloadData()
        }
    }
    
    @objc private func backButtonTapped() {
        // Stop any playing music before navigating back
        AudioEngine.shared.stopPlayback()
        isPlaying = false
        playAllButton.isSelected = false
        
        // Navigate back
        navigationController?.popViewController(animated: true)
    }
    
    // Helper method to convert beats to seconds based on current tempo
    private func beatsToSeconds(_ beats: Double = 1.0) -> TimeInterval {
        return 60.0 / tempo * beats
    }
    
    // Function to handle playing all chords
    @objc private func playAllButtonTapped() {
        if isPlaying {
            // Stop playback if already playing
            AudioEngine.shared.stopPlayback()
            isPlaying = false
            playAllButton.isSelected = false
            return
        }
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.playAllButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playAllButton.transform = .identity
            }
        }
        
        // Make sure instrument is set to piano before playing
        AudioEngine.shared.setInstrument(currentInstrument)
        
        // Collect all chords from all parts into a single string
        var allChords = ""
        
        // Debug info for troubleshooting
        print("🔍 Starting to collect chords from \(song.parts.count) parts")
        
        for (index, part) in song.parts.enumerated() {
            print("📝 Processing part #\(index+1): \(part.partType.rawValue), has chords: \(!part.chords.isEmpty)")
            
            if !part.chords.isEmpty {
                // Add space before adding more chords unless it's the first set
                if !allChords.isEmpty {
                    allChords += " "
                }
                
                // Add chords for this part - preserve dots by only replacing newlines with spaces
                let partChords = part.chords
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                allChords += partChords
                print("➕ Added chords: \"\(partChords)\"")
            }
        }
        
        // Check if we have any chords to play
        if allChords.isEmpty {
            print("⚠️ No chords to play - providing default C chord for testing")
            // Provide at least a C chord for testing
            allChords = "C"
        }
        
        // Apply transposition if needed
        if transpositionLevel != 0 {
            allChords = SongViewerViewController.transposeChordProgression(allChords, by: transpositionLevel)
        }
        
        print("🎵 Final chord progression: \"\(allChords)\"")
        
        // Set playing state
        isPlaying = true
        playAllButton.isSelected = true
        
        // Play all chords with tempo-based timing
        DispatchQueue.global(qos: .userInitiated).async {
            // Play the chord progression with optional duration and count-in beats
            AudioEngine.shared.playChordProgression(
                chordString: allChords,
                duration: self.chordDuration,
                withCountIn: true // Add four count-in beats
            )
            
            // Reset playing state after playback completes
            DispatchQueue.main.async {
                self.isPlaying = false
                self.playAllButton.isSelected = false
            }
        }
    }
    
    // New function to handle stop button
    @objc private func stopButtonTapped() {
        // Stop any ongoing playback
        AudioEngine.shared.stopPlayback()
        isPlaying = false
        playAllButton.isSelected = false
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.stopButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.stopButton.transform = .identity
            }
        }
    }
    
    // MARK: - Transpose Button Actions
    
    @objc private func transposeDownButtonTapped() {
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.transposeDownButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transposeDownButton.transform = .identity
            }
        }
        
        // Transpose down one semitone
        transpositionLevel -= 1
        
        // Update UI to show new transposition level
        updateTranspositionUI()
        
        print("Transposed chords down by 1 semitone. Current level: \(transpositionLevel)")
    }
    
    @objc private func transposeUpButtonTapped() {
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.transposeUpButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transposeUpButton.transform = .identity
            }
        }
        
        // Transpose up one semitone
        transpositionLevel += 1
        
        // Update UI to show new transposition level
        updateTranspositionUI()
        
        print("Transposed chords up by 1 semitone. Current level: \(transpositionLevel)")
    }
    
    // MARK: - Chord Transposition
    
    // Helper function to transpose a single chord by the given number of semitones
    static func transposeChord(_ chord: String, by semitones: Int) -> String {
        // Skip transposition if semitones is 0
        if semitones == 0 { return chord }
        
        // Root notes in order (using sharps)
        let sharpNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        // Root notes in order (using flats)
        let flatNotes = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        
        // Prefer using flats for these positions when transposing
        let preferFlatsPositions = [1, 3, 5, 8, 10] // Db, Eb, F, Ab, Bb
        
        // Extract root note and suffix (everything after the root)
        var rootNote = ""
        var suffix = ""
        var isSlashChord = false
        var bassNote = ""
        
        // Handle slash chords (e.g. C/G)
        let components = chord.split(separator: "/")
        if components.count > 1 {
            isSlashChord = true
            bassNote = String(components[1])
        }
        
        // Regular expression to match chord pattern
        let chordPattern = "^([A-G][#b]?)(.*)"
        let regex = try? NSRegularExpression(pattern: chordPattern, options: [])
        
        if let match = regex?.firstMatch(in: chord.components(separatedBy: "/")[0], 
                                        options: [], 
                                        range: NSRange(location: 0, length: chord.components(separatedBy: "/")[0].count)) {
            if let rootRange = Range(match.range(at: 1), in: chord.components(separatedBy: "/")[0]) {
                rootNote = String(chord.components(separatedBy: "/")[0][rootRange])
            }
            
            if let suffixRange = Range(match.range(at: 2), in: chord.components(separatedBy: "/")[0]) {
                suffix = String(chord.components(separatedBy: "/")[0][suffixRange])
            }
        } else {
            // If no match found, return the original chord
            return chord
        }
        
        // Find the index of the root note
        var noteIndex: Int?
        
        if rootNote.contains("#") {
            if let index = sharpNotes.firstIndex(of: rootNote) {
                noteIndex = index
            }
        } else if rootNote.contains("b") {
            if let index = flatNotes.firstIndex(of: rootNote) {
                noteIndex = index
            }
        } else {
            // Plain note (no accidental)
            if let index = sharpNotes.firstIndex(of: rootNote) {
                noteIndex = index
            }
        }
        
        guard let currentIndex = noteIndex else { return chord }
        
        // Calculate new index after transposition
        var newIndex = (currentIndex + semitones) % 12
        if newIndex < 0 {
            newIndex += 12
        }
        
        // Choose whether to use sharp or flat notation
        let newRoot: String
        if preferFlatsPositions.contains(newIndex) {
            newRoot = flatNotes[newIndex]
        } else {
            newRoot = sharpNotes[newIndex]
        }
        
        // Handle the bass note if it's a slash chord
        var newBass = ""
        if isSlashChord {
            // Apply the same transposition to the bass note
            newBass = "/" + transposeChord(bassNote, by: semitones)
        }
        
        return newRoot + suffix + newBass
    }
    
    // Transpose all chords in a chord progression string
    static func transposeChordProgression(_ chordString: String, by semitones: Int) -> String {
        guard semitones != 0 else { return chordString }
        
        // Define a chord pattern to match (includes handling for dots, dashes, and spaces)
        let regex = try! NSRegularExpression(pattern: "([A-G][#b]?[^\\s/]*(?:/[A-G][#b]?[^\\s]*)?)([\\s.-]*)", options: [])
        
        let nsString = chordString as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let result = NSMutableString(string: chordString)
        
        // Process matches from end to beginning to avoid index issues when replacing
        let matches = regex.matches(in: chordString, options: [], range: range)
        for match in matches.reversed() {
            let fullChordRange = match.range(at: 1)
            let separatorRange = match.range(at: 2)
            
            if fullChordRange.location != NSNotFound {
                let chord = nsString.substring(with: fullChordRange)
                let separator = separatorRange.location != NSNotFound ? nsString.substring(with: separatorRange) : ""
                
                // Transpose the chord
                let transposedChord = transposeChord(chord, by: semitones)
                
                // Replace the original chord with the transposed one (keep separator)
                result.replaceCharacters(in: NSRange(location: fullChordRange.location, 
                                                    length: fullChordRange.length + separatorRange.length), 
                                        with: transposedChord + separator)
            }
        }
        
        return result as String
    }
    
    // Function to update the UI to show the current transposition level
    private func updateTranspositionUI() {
        // Update capo label with transposition info if needed
        if transpositionLevel != 0 {
            let transLabel = transpositionLevel > 0 ? "+\(transpositionLevel)" : "\(transpositionLevel)"
            
            if song.capo > 0 {
                capoLabel.text = "Capo: \(song.capo) | Trans: \(transLabel)"
            } else {
                capoLabel.text = "Trans: \(transLabel)"
            }
        } else {
            // Just show capo info if no transposition
            if song.capo > 0 {
                capoLabel.text = "Capo: \(song.capo)"
            } else {
                capoLabel.text = ""
            }
        }
        
        // Only show the pure artist name without any additional text
        artistLabel.text = song.artist
        
        // Reload table to refresh all chord displays
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if currentDisplayMode == .lyricsOnly {
            // Count only parts with lyrics
            return song.parts.filter { !$0.lyrics.isEmpty }.count
        }
        return song.parts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Reduce the section header height to bring parts closer together
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0 // Changed from 1 to 0 for minimum spacing
    }
    
    // Remove any space in the footer as well
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView() // Empty view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView() // Empty view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongPartViewCell.identifier, for: indexPath) as? SongPartViewCell else {
            return UITableViewCell()
        }
        
        // Get the appropriate part based on the current display mode
        let part: Part
        
        if currentDisplayMode == .lyricsOnly {
            // Get only parts with lyrics
            let partsWithLyrics = song.parts.filter { !$0.lyrics.isEmpty }
            part = partsWithLyrics[indexPath.section]
        } else {
            // Get all parts
            part = song.parts[indexPath.section]
        }
        
        // Pass the transposition level directly to the cell
        cell.configure(with: part, displayMode: currentDisplayMode, transpositionLevel: transpositionLevel)
        
        // Set up chord playing handler (without count-in for individual parts)
        cell.playChordHandler = { [weak self] chordString in
            guard let self = self, !chordString.isEmpty else { return }
            // Explicitly set the instrument to piano (0) before playing individual parts
            AudioEngine.shared.setInstrument(0, waitForLoad: true)
            AudioEngine.shared.playChordProgression(
                chordString: chordString, 
                duration: self.chordDuration,
                withCountIn: false // No count-in for individual part playback
            )
        }
        
        return cell
    }
    
    // MARK: - MP3 Handling (with local caching and Last-Modified check)
    
    private func localMP3FileURL(for fileName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    private func checkForMP3File() {
        guard let song = song else { mp3Exists = false; return }
        let formattedTitle = SongViewerViewController.formatForFileNameStatic(song.title)
        let formattedArtist = SongViewerViewController.formatForFileNameStatic(song.artist)
        let fileName = formattedArtist.isEmpty ? "\(formattedTitle).mp3" : "\(formattedTitle)(\(formattedArtist)).mp3"
        let xmlFileName = formattedArtist.isEmpty ? "\(formattedTitle).xml" : "\(formattedTitle)(\(formattedArtist)).xml"
        let baseUrl = "http://xenon95.de/"
        let xmlUrlString = baseUrl + xmlFileName
        let mp3UrlString = baseUrl + fileName
        let localURL = localMP3FileURL(for: fileName)
        print("[MP3 DIAG] Checking XML URL: \(xmlUrlString)")
        guard let xmlUrl = URL(string: xmlUrlString) else { print("[MP3 DIAG] Invalid XML URL"); mp3Exists = false; return }
        var xmlRequest = URLRequest(url: xmlUrl)
        xmlRequest.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: xmlRequest) { [weak self] (_, xmlResponse, _) in
            DispatchQueue.main.async {
                if let xmlHttpResp = xmlResponse as? HTTPURLResponse {
                    print("[MP3 DIAG] XML status code: \(xmlHttpResp.statusCode)")
                } else {
                    print("[MP3 DIAG] No response for XML file.")
                }
                // Now check MP3
                print("[MP3 DIAG] Checking MP3 URL: \(mp3UrlString)")
                guard let mp3Url = URL(string: mp3UrlString) else { print("[MP3 DIAG] Invalid MP3 URL"); self?.mp3Exists = false; return }
                self?.mp3URL = mp3Url
                var mp3Request = URLRequest(url: mp3Url)
                mp3Request.httpMethod = "HEAD"
                URLSession.shared.dataTask(with: mp3Request) { [weak self] (_, mp3Response, _) in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let mp3HttpResp = mp3Response as? HTTPURLResponse {
                            print("[MP3 DIAG] MP3 status code: \(mp3HttpResp.statusCode)")
                            if mp3HttpResp.statusCode == 200 {
                                self.mp3Exists = true
                                // Check Last-Modified header
                                let lastModifiedStr = mp3HttpResp.allHeaderFields["Last-Modified"] as? String
                                var serverDate: Date? = nil
                                if let lastModifiedStr = lastModifiedStr {
                                    let formatter = DateFormatter()
                                    formatter.locale = Locale(identifier: "en_US_POSIX")
                                    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                                    serverDate = formatter.date(from: lastModifiedStr)
                                }
                                // Check local file
                                if FileManager.default.fileExists(atPath: localURL.path),
                                   let attrs = try? FileManager.default.attributesOfItem(atPath: localURL.path),
                                   let localDate = attrs[.modificationDate] as? Date, let serverDate = serverDate {
                                    print("[MP3] Checking if local MP3 is up to date with the server version...")
                                    print("[MP3 DIAG] Local MP3 date: \(localDate), Server MP3 date: \(serverDate)")
                                    if serverDate > localDate {
                                        print("[MP3 DIAG] Server MP3 is newer, will re-download on play.")
                                    } else {
                                        print("[MP3 DIAG] Local MP3 is up to date.")
                                    }
                                } else if FileManager.default.fileExists(atPath: localURL.path) {
                                    print("[MP3] Local MP3 exists, but no server date to compare.")
                                    print("[MP3 DIAG] Local MP3 exists, but no server date to compare.")
                                } else {
                                    print("[MP3 DIAG] No local MP3 file, will download on play.")
                                }
                            } else {
                                self.mp3Exists = false
                            }
                        } else {
                            print("[MP3 DIAG] No response for MP3 file.")
                            self.mp3Exists = false
                        }
                    }
                }.resume()
            }
        }.resume()
    }

    @objc private func mp3ButtonTapped() {
        guard mp3Exists, let mp3Url = mp3URL, let song = song else { return }
        let formattedTitle = SongViewerViewController.formatForFileNameStatic(song.title)
        let formattedArtist = SongViewerViewController.formatForFileNameStatic(song.artist)
        let fileName = formattedArtist.isEmpty ? "\(formattedTitle).mp3" : "\(formattedTitle)(\(formattedArtist)).mp3"
        let localURL = localMP3FileURL(for: fileName)
        // Before downloading the mp3, check if the XML file for the same song is accessible
        let xmlFileName = formattedArtist.isEmpty ? "\(formattedTitle).xml" : "\(formattedTitle)(\(formattedArtist)).xml"
        let baseUrl = "http://xenon95.de/"
        let xmlUrlString = baseUrl + xmlFileName
        guard let xmlUrl = URL(string: xmlUrlString) else {
            print("[MP3 DIAG] Could not construct XML URL: \(xmlUrlString)")
            return
        }
        var xmlRequest = URLRequest(url: xmlUrl)
        xmlRequest.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: xmlRequest) { [weak self] (_, xmlResponse, _) in
            guard let self = self else { return }
            if let httpResp = xmlResponse as? HTTPURLResponse {
                print("[MP3 DIAG] XML HEAD status code: \(httpResp.statusCode) for \(xmlUrlString)")
                if httpResp.statusCode == 200 {
                    // XML file is accessible, proceed to check local MP3 and download if needed
                    self.downloadAndPlayMP3WithCache(mp3Url, localURL: localURL)
                } else {
                    print("[MP3 DIAG] XML file not found or inaccessible. Aborting MP3 download.")
                }
            } else {
                print("[MP3 DIAG] No HTTP response for XML HEAD request. Possible network/server issue.")
            }
        }.resume()
    }

    private func downloadAndPlayMP3WithCache(_ url: URL, localURL: URL) {
        // Check if local file exists and if server has a newer version
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { [weak self] (_, response, _) in
            guard let self = self else { return }
            var shouldDownload = true
            var serverDate: Date? = nil
            if let httpResp = response as? HTTPURLResponse,
               let lastModifiedStr = httpResp.allHeaderFields["Last-Modified"] as? String {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                serverDate = formatter.date(from: lastModifiedStr)
            }
            if FileManager.default.fileExists(atPath: localURL.path),
               let attrs = try? FileManager.default.attributesOfItem(atPath: localURL.path),
               let localDate = attrs[.modificationDate] as? Date, let serverDate = serverDate {
                if serverDate <= localDate {
                    shouldDownload = false
                }
            } else if FileManager.default.fileExists(atPath: localURL.path) && serverDate == nil {
                shouldDownload = false
            }
            if shouldDownload {
                print("[MP3 DIAG] Downloading MP3 from server...")
                let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
                    guard let self = self, let tempURL = tempURL, error == nil else {
                        print("[MP3 DIAG] MP3 download failed: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    do {
                        // Remove old file if exists
                        if FileManager.default.fileExists(atPath: localURL.path) {
                            try FileManager.default.removeItem(at: localURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: localURL)
                        print("[MP3 DIAG] MP3 saved to local cache: \(localURL.path)")
                        DispatchQueue.main.async {
                            self.playMP3File(localURL)
                        }
                    } catch {
                        print("[MP3 DIAG] Failed to save MP3: \(error.localizedDescription)")
                    }
                }
                task.resume()
            } else {
                print("[MP3 DIAG] Using cached MP3 file: \(localURL.path)")
                DispatchQueue.main.async {
                    self.playMP3File(localURL)
                }
            }
        }.resume()
    }

    private func playMP3File(_ url: URL) {
        do {
            mp3Player = try AVAudioPlayer(contentsOf: url)
            mp3Player?.prepareToPlay()
            mp3Player?.play()
        } catch {
            print("[MP3 DIAG] Failed to play MP3: \(error.localizedDescription)")
        }
    }
    
    // Helper for MP3 filename formatting (static, matches SongViewerViewController)
    static func formatForFileNameStatic(_ input: String) -> String {
        guard !input.isEmpty else { return "" }
        let allowedCharSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " "))
        let cleanedString = input.components(separatedBy: allowedCharSet.inverted).joined()
        let words = cleanedString.components(separatedBy: .whitespaces)
        let capitalizedWords = words.map { word in
            if !word.isEmpty {
                let firstChar = word.prefix(1).uppercased()
                let restOfWord = word.dropFirst()
                return firstChar + restOfWord
            }
            return ""
        }
        return capitalizedWords.joined()
    }
}

// MARK: - SongPartViewCell for read-only viewing
class SongPartViewCell: UITableViewCell {
    static let identifier = "SongPartViewCell"
    
    private let partTypeLabel = UILabel()
    private let chordsLabel = UILabel()
    private let lyricsLabel = UILabel()
    private let containerView = UIView()
    private let playButton = UIButton(type: .system)
    
    // Store constraint references to be able to activate/deactivate them
    private var oneRowConstraints: [NSLayoutConstraint] = []
    private var lyricsOnlyConstraints: [NSLayoutConstraint] = [] // Renamed from twoRowConstraints
    private var currentMode: SongViewerViewController.DisplayMode = .oneRow
    
    // Closure to handle playing chords
    var playChordHandler: ((String) -> Void)?
    private var currentChords: String = ""
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container view setup
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Part type label setup
        partTypeLabel.font = UIFont.boldSystemFont(ofSize: 14)
        partTypeLabel.textColor = .systemGray
        partTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(partTypeLabel)
        
        // Chords label setup - changed to 18
        chordsLabel.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .medium)
        chordsLabel.textColor = .systemBlue
        chordsLabel.numberOfLines = 0
        chordsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chordsLabel)
        
        // Lyrics label setup - keeping at 19
        lyricsLabel.font = UIFont.systemFont(ofSize: 19)
        lyricsLabel.numberOfLines = 0
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(lyricsLabel)
        
        // Play button setup - moved to left side above part type
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = .systemGreen
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        containerView.addSubview(playButton)
        
        // Reduced top and bottom margins from 8 to 4 to decrease spacing between parts
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Play button constraints - moved to top left corner
            playButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            playButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            playButton.widthAnchor.constraint(equalToConstant: 36),
            playButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Create both sets of constraints but only activate the default mode
        createConstraints()
        
        // Default to one-row mode
        activateOneRowMode()
    }
    
    // Create both sets of constraints once but don't activate them yet
    private func createConstraints() {
        // One row constraints (side-by-side)
        oneRowConstraints = [
            // Part type label below play button
            partTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            partTypeLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 4),
            partTypeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            partTypeLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0/12.0),
            
            // Chords label (3/12 of width)
            chordsLabel.leadingAnchor.constraint(equalTo: partTypeLabel.trailingAnchor, constant: 8),
            chordsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            chordsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            chordsLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 3.0/12.0),
            
            // Lyrics label
            lyricsLabel.leadingAnchor.constraint(equalTo: chordsLabel.trailingAnchor, constant: 8),
            lyricsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            lyricsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            lyricsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ]
        
        // Lyrics only constraints (table layout)
        lyricsOnlyConstraints = [
            // Part type label as first column (20% width)
            partTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            partTypeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            partTypeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            partTypeLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.20),
            
            // Lyrics label as second column (80% width)
            lyricsLabel.leadingAnchor.constraint(equalTo: partTypeLabel.trailingAnchor, constant: 16),
            lyricsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            lyricsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            lyricsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ]
    }
    
    private func activateOneRowMode() {
        NSLayoutConstraint.deactivate(lyricsOnlyConstraints)
        NSLayoutConstraint.activate(oneRowConstraints)
        currentMode = .oneRow
    }
    
    private func activateLyricsOnlyMode() {
        NSLayoutConstraint.deactivate(oneRowConstraints)
        NSLayoutConstraint.activate(lyricsOnlyConstraints)
        currentMode = .lyricsOnly
    }
    
    // Configure the cell with part data and display mode
    func configure(with part: Part, displayMode: SongViewerViewController.DisplayMode, transpositionLevel: Int = 0) {
        // Set content first
        partTypeLabel.text = part.partType.rawValue
        
        // Apply transposition to chords if needed
        if !part.chords.isEmpty && transpositionLevel != 0 {
            // Use the static method from SongViewerViewController directly
            let transposedChords = SongViewerViewController.transposeChordProgression(part.chords, by: transpositionLevel)
            chordsLabel.text = transposedChords
            currentChords = transposedChords // Store transposed version for playback
        } else {
            chordsLabel.text = part.chords.isEmpty ? "No chords" : part.chords
            currentChords = part.chords
        }
        
        lyricsLabel.text = part.lyrics
        
        // Handle visibility based on mode
        if displayMode == .lyricsOnly {
            // In lyrics-only mode, hide chords and play button completely
            chordsLabel.isHidden = true
            playButton.isHidden = true
            // Adjust part type appearance to be more prominent as section header
            partTypeLabel.font = UIFont.boldSystemFont(ofSize: 16)
            partTypeLabel.textColor = .label
        } else {
            // In one-row mode, show chords if they exist
            chordsLabel.isHidden = false
            // Show play button only if chords exist
            playButton.isHidden = part.chords.isEmpty
            // Set part type to its normal appearance
            partTypeLabel.font = UIFont.boldSystemFont(ofSize: 14)
            partTypeLabel.textColor = .systemGray
        }
        
        // Only show lyrics label if they exist
        lyricsLabel.isHidden = part.lyrics.isEmpty
        
        // Apply the appropriate layout mode if different from current
        if displayMode != currentMode {
            switch displayMode {
            case .oneRow:
                activateOneRowMode()
            case .lyricsOnly:
                activateLyricsOnlyMode()
            }
        }
    }
    
    @objc private func playButtonTapped() {
        // Play button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.playButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playButton.transform = .identity
            }
        }
        
        // Call the handler to play the chords
        playChordHandler?(currentChords)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean up appearance but keep structure
        partTypeLabel.text = nil
        chordsLabel.text = nil
        lyricsLabel.text = nil
    }
}