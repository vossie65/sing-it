import UIKit

class SongPartTableViewCell: UITableViewCell {
    
    static let identifier = "SongPartTableViewCell"
    
    // Remove all multi-row layout and containers, switch to a single horizontal stack view for all content
    private let partTypeLabel = UILabel()
    private let chordsLabel = UILabel()
    private let lyricsLabel = UILabel()
    private let trashButton = UIButton(type: .system)
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let hStack = UIStackView()
    private let actionStack = UIStackView()
    
    // Add a closure to handle delete button tap
    var deleteHandler: (() -> Void)?
    // Add closures to handle up and down button taps
    var moveUpHandler: (() -> Void)?
    var moveDownHandler: (() -> Void)?
    
    // User defined color dictionary - this makes it configurable from Interface Builder
    private var partTypeColors: [String: UIColor] = [
        "Verse": UIColor.systemBlue.withAlphaComponent(0.2),
        "Chorus": UIColor.systemGreen.withAlphaComponent(0.2),
        "Pre-Chorus": UIColor.systemGreen.withAlphaComponent(0.2),
        "Post-Chorus": UIColor.systemGreen.withAlphaComponent(0.2),
        "Bridge": UIColor.systemRed.withAlphaComponent(0.2),
        "Intro": UIColor.systemYellow.withAlphaComponent(0.2),
        "Interlude": UIColor.systemYellow.withAlphaComponent(0.2),
        "Outro": UIColor.systemYellow.withAlphaComponent(0.2),
        "Solo": UIColor.systemYellow.withAlphaComponent(0.2)
    ]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        // Configure labels
        partTypeLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        partTypeLabel.textAlignment = .center
        partTypeLabel.numberOfLines = 1
        partTypeLabel.backgroundColor = .clear
        partTypeLabel.layer.masksToBounds = true
        // Add padding to partTypeLabel by using a container view
        let partTypeContainer = UIView()
        partTypeContainer.translatesAutoresizingMaskIntoConstraints = false
        partTypeContainer.backgroundColor = .clear
        partTypeContainer.layer.masksToBounds = true
        partTypeContainer.layer.cornerRadius = 6
        partTypeContainer.addSubview(partTypeLabel)
        partTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            partTypeLabel.leadingAnchor.constraint(equalTo: partTypeContainer.leadingAnchor, constant: 0),
            partTypeLabel.trailingAnchor.constraint(equalTo: partTypeContainer.trailingAnchor, constant: 0),
            partTypeLabel.topAnchor.constraint(equalTo: partTypeContainer.topAnchor, constant: 0),
            partTypeLabel.bottomAnchor.constraint(equalTo: partTypeContainer.bottomAnchor, constant: 0)
        ])
        // Configure other labels
        chordsLabel.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        chordsLabel.textAlignment = .left
        chordsLabel.numberOfLines = 0
        chordsLabel.lineBreakMode = .byWordWrapping
        lyricsLabel.font = UIFont.systemFont(ofSize: 15)
        lyricsLabel.textAlignment = .left
        lyricsLabel.numberOfLines = 0
        lyricsLabel.lineBreakMode = .byWordWrapping
        // Configure buttons
        trashButton.setImage(UIImage(systemName: "trash"), for: .normal)
        upButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        downButton.setImage(UIImage(systemName: "arrow.down"), for: .normal)
        // Action stack for icons
        actionStack.axis = .horizontal
        actionStack.spacing = 8
        actionStack.alignment = .center
        actionStack.addArrangedSubview(trashButton)
        actionStack.addArrangedSubview(upButton)
        actionStack.addArrangedSubview(downButton)
        // Main horizontal stack
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 16
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(partTypeContainer)
        hStack.addArrangedSubview(chordsLabel)
        hStack.addArrangedSubview(lyricsLabel)
        // Add a flexible spacer before the actionStack to push it to the far right
        let flexibleSpacer = UIView()
        flexibleSpacer.translatesAutoresizingMaskIntoConstraints = false
        flexibleSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        flexibleSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        hStack.addArrangedSubview(flexibleSpacer)
        hStack.addArrangedSubview(actionStack)
        // Make sure the flexibleSpacer expands as much as possible
        flexibleSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
        contentView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            partTypeContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.1),
            partTypeContainer.topAnchor.constraint(equalTo: hStack.topAnchor),
            partTypeContainer.bottomAnchor.constraint(equalTo: hStack.bottomAnchor),
            chordsLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
            lyricsLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.6),
            actionStack.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.1)
            // No fixed width for flexibleSpacer, it will expand as needed
        ])
        // Store for later use in configure
        self.partTypeContainer = partTypeContainer
    }

    // Store the container for coloring
    private var partTypeContainer: UIView?

    func configure(with part: Part, index: Int, isFirst: Bool, isLast: Bool, transpositionLevel: Int) {
        partTypeLabel.text = part.partType.rawValue
        // Use color dictionary for part type coloring
        let color = partTypeColors[part.partType.rawValue] ?? UIColor.systemGray5.withAlphaComponent(0.2)
        partTypeContainer?.backgroundColor = color
        partTypeLabel.backgroundColor = .clear
        // Transpose chords for display if needed
        if transpositionLevel != 0 && !part.chords.isEmpty {
            chordsLabel.text = SongViewerViewController.transposeChordProgression(part.chords, by: transpositionLevel)
        } else {
            chordsLabel.text = part.chords
        }
        lyricsLabel.text = part.lyrics
        upButton.isEnabled = !isFirst
        downButton.isEnabled = !isLast
        // Restore button actions
        upButton.tag = index
        downButton.tag = index
        trashButton.tag = index
        upButton.removeTarget(nil, action: nil, for: .allEvents)
        downButton.removeTarget(nil, action: nil, for: .allEvents)
        trashButton.removeTarget(nil, action: nil, for: .allEvents)
        upButton.addTarget(self, action: #selector(upTapped), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(downTapped), for: .touchUpInside)
        trashButton.addTarget(self, action: #selector(trashTapped), for: .touchUpInside)
    }

    @objc private func upTapped(_ sender: UIButton) { moveUpHandler?() }
    @objc private func downTapped(_ sender: UIButton) { moveDownHandler?() }
    @objc private func trashTapped(_ sender: UIButton) { deleteHandler?() }
}