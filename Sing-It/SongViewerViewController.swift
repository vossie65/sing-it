import UIKit

class SongViewerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var song: Song!
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let oneRowButton = UIButton(type: .system)
    private let twoRowButton = UIButton(type: .system)
    
    // Display mode for song parts
    enum DisplayMode {
        case twoRow // Default - type+chords in first row, lyrics in second row
        case oneRow // All in one row - type + chords + lyrics side by side
    }
    
    // Current display mode, default is one row (changed from two row)
    private var currentDisplayMode: DisplayMode = .oneRow
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureHeaderView()
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
            
            // Two Row button on right of title
            twoRowButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            twoRowButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Title centered with padding for buttons
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: oneRowButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: twoRowButton.leadingAnchor, constant: -8),
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
        // Setup One-Row button
        oneRowButton.setTitle("1-row", for: .normal)
        oneRowButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        oneRowButton.addTarget(self, action: #selector(oneRowButtonTapped), for: .touchUpInside)
        oneRowButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(oneRowButton)
        
        // Setup Two-Row button (default mode)
        twoRowButton.setTitle("2-row", for: .normal)
        twoRowButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        twoRowButton.addTarget(self, action: #selector(twoRowButtonTapped), for: .touchUpInside)
        twoRowButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(twoRowButton)
        
        // Set initial button states
        updateButtonStates()
    }
    
    private func updateButtonStates() {
        switch currentDisplayMode {
        case .oneRow:
            oneRowButton.isEnabled = false
            oneRowButton.alpha = 0.5
            twoRowButton.isEnabled = true
            twoRowButton.alpha = 1.0
        case .twoRow:
            oneRowButton.isEnabled = true
            oneRowButton.alpha = 1.0
            twoRowButton.isEnabled = false
            twoRowButton.alpha = 0.5
        }
    }
    
    @objc private func oneRowButtonTapped() {
        if currentDisplayMode != .oneRow {
            currentDisplayMode = .oneRow
            updateButtonStates()
            tableView.reloadData()
        }
    }
    
    @objc private func twoRowButtonTapped() {
        if currentDisplayMode != .twoRow {
            currentDisplayMode = .twoRow
            updateButtonStates()
            tableView.reloadData()
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
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
        
        let part = song.parts[indexPath.section]
        cell.configure(with: part, displayMode: currentDisplayMode)
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
    
    // Store constraint references to be able to activate/deactivate them
    private var oneRowConstraints: [NSLayoutConstraint] = []
    private var twoRowConstraints: [NSLayoutConstraint] = []
    private var currentMode: SongViewerViewController.DisplayMode = .oneRow
    
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
        
        // Base container constraints that apply to both modes
        // Reduced top and bottom margins from 8 to 4 to decrease spacing between parts
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
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
            // Part type label (1/12 of width)
            partTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            partTypeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            partTypeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            partTypeLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0/12.0),
            
            // Chords label (3/12 of width)
            chordsLabel.leadingAnchor.constraint(equalTo: partTypeLabel.trailingAnchor, constant: 8),
            chordsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            chordsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            chordsLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 3.0/12.0),
            
            // Lyrics label (8/12 of width)
            lyricsLabel.leadingAnchor.constraint(equalTo: chordsLabel.trailingAnchor, constant: 8),
            lyricsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            lyricsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            lyricsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ]
        
        // Two row constraints (stacked)
        twoRowConstraints = [
            // Part type label on the left of the chords
            partTypeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            partTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            partTypeLabel.widthAnchor.constraint(equalToConstant: 70), // Fixed width for part type
            
            // Chords label to the right of part type
            chordsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            chordsLabel.leadingAnchor.constraint(equalTo: partTypeLabel.trailingAnchor, constant: 8),
            chordsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Lyrics label below chords
            lyricsLabel.topAnchor.constraint(equalTo: chordsLabel.bottomAnchor, constant: 12),
            lyricsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            lyricsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            lyricsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ]
    }
    
    private func activateOneRowMode() {
        NSLayoutConstraint.deactivate(twoRowConstraints)
        NSLayoutConstraint.activate(oneRowConstraints)
        currentMode = .oneRow
    }
    
    private func activateTwoRowMode() {
        NSLayoutConstraint.deactivate(oneRowConstraints)
        NSLayoutConstraint.activate(twoRowConstraints)
        currentMode = .twoRow
    }
    
    // Configure the cell with part data and display mode
    func configure(with part: Part, displayMode: SongViewerViewController.DisplayMode) {
        // Set content first
        partTypeLabel.text = part.partType.rawValue
        chordsLabel.text = part.chords.isEmpty ? "No chords" : part.chords
        lyricsLabel.text = part.lyrics
        
        // Only show lyrics label if they exist
        lyricsLabel.isHidden = part.lyrics.isEmpty
        
        // Apply the appropriate layout mode if different from current
        if displayMode != currentMode {
            switch displayMode {
            case .oneRow:
                activateOneRowMode()
            case .twoRow:
                activateTwoRowMode()
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clean up appearance but keep structure
        partTypeLabel.text = nil
        chordsLabel.text = nil
        lyricsLabel.text = nil
    }
}