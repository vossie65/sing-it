import UIKit

class SongViewerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var song: Song!
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    
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
        
        // Set constraints for labels
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            artistLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            artistLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            artistLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -24) // Increased bottom padding from -16 to -24
        ])
        
        // Set header view to table view with increased height
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100) // Increased height from 80 to 100
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
    
    // Remove the section title since we're displaying the part type in the cell
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1 // Minimum height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView() // Empty view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongPartViewCell.identifier, for: indexPath) as? SongPartViewCell else {
            return UITableViewCell()
        }
        
        let part = song.parts[indexPath.section]
        cell.configure(with: part)
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
        lyricsLabel.font = UIFont.systemFont(ofSize: 20) // Increased from 18 to 20
        lyricsLabel.numberOfLines = 0
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(lyricsLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
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
        ])
    }
    
    func configure(with part: Part) {
        partTypeLabel.text = part.partType.rawValue
        chordsLabel.text = part.chords.isEmpty ? "No chords" : part.chords
        
        // Only show lyrics if they exist, otherwise show nothing
        if part.lyrics.isEmpty {
            lyricsLabel.isHidden = true
        } else {
            lyricsLabel.isHidden = false
            lyricsLabel.text = part.lyrics
        }
    }
}