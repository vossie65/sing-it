import UIKit
import AVFoundation

class SongViewerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var song: Song!
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let oneRowButton = UIButton(type: .system)
    private let lyricsOnlyButton = UIButton(type: .system) // Renamed from twoRowButton
    private let playAllButton = UIButton(type: .system) // New Play All button
    private let stopButton = UIButton(type: .system) // New Stop button
    
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
        
        // Artist label setup
        artistLabel.text = song.artist
        artistLabel.font = UIFont.systemFont(ofSize: 18)
        artistLabel.textColor = .secondaryLabel
        artistLabel.textAlignment = .center
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(artistLabel)
        
        // Configure the mode toggle buttons
        setupModeButtons()
        
        // Set constraints for labels and buttons
        NSLayoutConstraint.activate([
            // One Row button on left of title
            oneRowButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            oneRowButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            // Lyrics Only button on right of title
            lyricsOnlyButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            lyricsOnlyButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Play All button beside lyrics only button (slightly to the left)
            playAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            playAllButton.trailingAnchor.constraint(equalTo: lyricsOnlyButton.leadingAnchor, constant: -16),
            playAllButton.widthAnchor.constraint(equalToConstant: 36),
            playAllButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Stop button to the right of play all button (repositioned)
            stopButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            stopButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 8),
            stopButton.widthAnchor.constraint(equalToConstant: 36),
            stopButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Title centered with padding for buttons
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: oneRowButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: playAllButton.leadingAnchor, constant: -8),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            // Artist below title
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            artistLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            artistLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            artistLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -24)
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
        
        cell.configure(with: part, displayMode: currentDisplayMode)
        
        // Set up chord playing handler (without count-in for individual parts)
        cell.playChordHandler = { [weak self] chordString in
            guard let self = self, !chordString.isEmpty else { return }
            AudioEngine.shared.playChordProgression(
                chordString: chordString, 
                duration: self.chordDuration,
                withCountIn: false // No count-in for individual part playback
            )
        }
        
        return cell
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
        
        // Chords label setup
        chordsLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        chordsLabel.textColor = .systemBlue
        chordsLabel.numberOfLines = 0
        chordsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chordsLabel)
        
        // Lyrics label setup
        lyricsLabel.font = UIFont.systemFont(ofSize: 20)
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
    func configure(with part: Part, displayMode: SongViewerViewController.DisplayMode) {
        // Set content first
        partTypeLabel.text = part.partType.rawValue
        chordsLabel.text = part.chords.isEmpty ? "No chords" : part.chords
        lyricsLabel.text = part.lyrics
        
        // Store chord data for playing
        currentChords = part.chords
        
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