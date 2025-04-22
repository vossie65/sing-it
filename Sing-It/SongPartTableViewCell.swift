import UIKit

class SongPartTableViewCell: UITableViewCell {
    
    static let identifier = "SongPartTableViewCell"
    
    private let typeLabel = UILabel()
    private let lyricsLabel = UILabel()
    private let chordsLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    
    private let containerView = UIView()
    private let topRowView = UIView()
    private let typeContainerView = UIView()
    private let chordsContainerView = UIView()
    private let bottomRowView = UIView()
    private let lyricsContainerView = UIView()
    
    // Add a closure to handle delete button tap
    var deleteHandler: (() -> Void)?
    
    // User defined color dictionary - this makes it configurable from Interface Builder
    private var partTypeColors: [String: UIColor] = [
        "Verse": UIColor.systemBlue.withAlphaComponent(0.2),
        "Chorus": UIColor.systemGreen.withAlphaComponent(0.2),
        "Bridge": UIColor.systemRed.withAlphaComponent(0.2),
        "Intro": UIColor.systemYellow.withAlphaComponent(0.2),
        "Outro": UIColor.systemYellow.withAlphaComponent(0.2),
        "Solo": UIColor.systemYellow.withAlphaComponent(0.2)
    ]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Add main container view
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Add top and bottom rows
        containerView.addSubview(topRowView)
        containerView.addSubview(bottomRowView)
        
        topRowView.translatesAutoresizingMaskIntoConstraints = false
        bottomRowView.translatesAutoresizingMaskIntoConstraints = false
        
        // Position top and bottom rows
        NSLayoutConstraint.activate([
            topRowView.topAnchor.constraint(equalTo: containerView.topAnchor),
            topRowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topRowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            bottomRowView.topAnchor.constraint(equalTo: topRowView.bottomAnchor, constant: 8),
            bottomRowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomRowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomRowView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Add elements to top row
        topRowView.addSubview(typeContainerView)
        topRowView.addSubview(chordsContainerView)
        topRowView.addSubview(deleteButton)
        
        typeContainerView.translatesAutoresizingMaskIntoConstraints = false
        chordsContainerView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure delete button
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Set up borders and styles
        [typeContainerView, chordsContainerView, lyricsContainerView].forEach { view in
            view.layer.borderColor = UIColor.systemGray4.cgColor
            view.layer.borderWidth = 1
            view.layer.cornerRadius = 4
            view.backgroundColor = UIColor.systemBackground
        }
        
        // Position elements in top row
        NSLayoutConstraint.activate([
            typeContainerView.topAnchor.constraint(equalTo: topRowView.topAnchor),
            typeContainerView.leadingAnchor.constraint(equalTo: topRowView.leadingAnchor),
            typeContainerView.bottomAnchor.constraint(equalTo: topRowView.bottomAnchor),
            typeContainerView.widthAnchor.constraint(equalTo: topRowView.widthAnchor, multiplier: 0.2),
            
            chordsContainerView.topAnchor.constraint(equalTo: topRowView.topAnchor),
            chordsContainerView.leadingAnchor.constraint(equalTo: typeContainerView.trailingAnchor, constant: 8),
            chordsContainerView.bottomAnchor.constraint(equalTo: topRowView.bottomAnchor),
            chordsContainerView.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            
            deleteButton.centerYAnchor.constraint(equalTo: topRowView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: topRowView.trailingAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Add lyrics container to bottom row (full width)
        bottomRowView.addSubview(lyricsContainerView)
        lyricsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lyricsContainerView.topAnchor.constraint(equalTo: bottomRowView.topAnchor),
            lyricsContainerView.leadingAnchor.constraint(equalTo: bottomRowView.leadingAnchor),
            lyricsContainerView.trailingAnchor.constraint(equalTo: bottomRowView.trailingAnchor),
            lyricsContainerView.bottomAnchor.constraint(equalTo: bottomRowView.bottomAnchor)
        ])
        
        // Add labels to containers
        typeContainerView.addSubview(typeLabel)
        chordsContainerView.addSubview(chordsLabel)
        lyricsContainerView.addSubview(lyricsLabel)
        
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        chordsLabel.translatesAutoresizingMaskIntoConstraints = false
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Label styles
        typeLabel.textAlignment = .center
        typeLabel.font = UIFont.boldSystemFont(ofSize: 14)
        
        chordsLabel.numberOfLines = 0
        chordsLabel.lineBreakMode = .byWordWrapping
        chordsLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        lyricsLabel.numberOfLines = 0
        lyricsLabel.lineBreakMode = .byWordWrapping
        lyricsLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)  // Changed from 22 to 20 for consistency
        
        // Label position constraints
        NSLayoutConstraint.activate([
            typeLabel.topAnchor.constraint(equalTo: typeContainerView.topAnchor, constant: 8),
            typeLabel.leadingAnchor.constraint(equalTo: typeContainerView.leadingAnchor, constant: 4),
            typeLabel.trailingAnchor.constraint(equalTo: typeContainerView.trailingAnchor, constant: -4),
            typeLabel.bottomAnchor.constraint(equalTo: typeContainerView.bottomAnchor, constant: -8),
            
            chordsLabel.topAnchor.constraint(equalTo: chordsContainerView.topAnchor, constant: 8),
            chordsLabel.leadingAnchor.constraint(equalTo: chordsContainerView.leadingAnchor, constant: 8),
            chordsLabel.trailingAnchor.constraint(equalTo: chordsContainerView.trailingAnchor, constant: -8),
            chordsLabel.bottomAnchor.constraint(equalTo: chordsContainerView.bottomAnchor, constant: -8),
            
            lyricsLabel.topAnchor.constraint(equalTo: lyricsContainerView.topAnchor, constant: 8),
            lyricsLabel.leadingAnchor.constraint(equalTo: lyricsContainerView.leadingAnchor, constant: 8),
            lyricsLabel.trailingAnchor.constraint(equalTo: lyricsContainerView.trailingAnchor, constant: -8),
            lyricsLabel.bottomAnchor.constraint(equalTo: lyricsContainerView.bottomAnchor, constant: -8)
        ])
    }
    
    @objc private func deleteButtonTapped() {
        deleteHandler?()
    }
    
    func configure(with part: Part, index: Int) {
        typeLabel.text = part.partType.rawValue
        lyricsLabel.text = part.lyrics.isEmpty ? "(No lyrics)" : part.lyrics
        chordsLabel.text = part.chords.isEmpty ? "(No chords)" : part.chords
        
        // Use the partTypeColors dictionary to set background color based on part type
        if let color = partTypeColors[part.partType.rawValue] {
            typeContainerView.backgroundColor = color
        } else {
            // Default background color
            typeContainerView.backgroundColor = UIColor.systemBackground
        }
    }
}