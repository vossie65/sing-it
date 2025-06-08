import UIKit

protocol PartTableViewCellDelegate: AnyObject {
    func partTypeChanged(atIndex index: Int, to newType: PartType)
    func lyricsChanged(atIndex index: Int, to newLyrics: String)
    func chordsChanged(atIndex index: Int, to newChords: String)
}

class PartTableViewCell: UITableViewCell {
    
    @IBOutlet weak var partTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var lyricsTextView: UITextView!
    @IBOutlet weak var chordsTextView: UITextView!
    @IBOutlet weak var expandedStackView: UIStackView!
    @IBOutlet weak var expandButton: UIButton!
    
    private weak var delegate: PartTableViewCellDelegate?
    private var index: Int = 0
    private var part: Part?
    
    // User defined color dictionary - uses Interface Builder data for colors
    private var partTypeColors: [PartType: UIColor] = [
        .verse: UIColor.systemBlue.withAlphaComponent(0.2),
        .chorus: UIColor.systemGreen.withAlphaComponent(0.2),
        .preChorus: UIColor.systemGreen.withAlphaComponent(0.2),
        .postChorus: UIColor.systemGreen.withAlphaComponent(0.2),
        .bridge: UIColor.systemRed.withAlphaComponent(0.2),
        .intro: UIColor.systemYellow.withAlphaComponent(0.2),
        .interlude: UIColor.systemYellow.withAlphaComponent(0.2),
        .outro: UIColor.systemYellow.withAlphaComponent(0.2),
        .solo: UIColor.systemYellow.withAlphaComponent(0.2)
    ]
    
    var isExpanded: Bool = false {
        didSet {
            updateExpandedState()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Configure part types in segmented control
        partTypeSegmentedControl.removeAllSegments()
        for (index, type) in PartType.allCases.enumerated() {
            partTypeSegmentedControl.insertSegment(withTitle: type.rawValue, at: index, animated: false)
        }
        
        // Set up text view delegates
        lyricsTextView.delegate = self
        chordsTextView.delegate = self
    }
    
    func configure(with part: Part, index: Int, delegate: PartTableViewCellDelegate) {
        self.part = part
        self.index = index
        self.delegate = delegate
        
        // Set part type
        if let typeIndex = PartType.allCases.firstIndex(where: { $0 == part.partType }) {
            partTypeSegmentedControl.selectedSegmentIndex = typeIndex
            
            // Apply color styling based on part type (using Interface Builder data)
            if let color = partTypeColors[part.partType] {
                partTypeSegmentedControl.selectedSegmentTintColor = color
            }
        }
        
        lyricsTextView.text = part.lyrics
        chordsTextView.text = part.chords
        
        updateExpandedState()
    }
    
    private func updateExpandedState() {
        expandedStackView.isHidden = !isExpanded
        updateExpandButtonImage()
    }
    
    private func updateExpandButtonImage() {
        let imageName = isExpanded ? "chevron.up" : "chevron.down"
        if #available(iOS 13.0, *) {
            expandButton.setImage(UIImage(systemName: imageName), for: .normal)
        } else {
            // Fallback for older iOS versions
            expandButton.setTitle(isExpanded ? "▲" : "▼", for: .normal)
        }
    }
    
    @IBAction func partTypeChanged(_ sender: UISegmentedControl) {
        guard let selectedType = PartType.allCases[safe: sender.selectedSegmentIndex] else { return }
        
        // Apply color styling based on part type (using Interface Builder data)
        if let color = partTypeColors[selectedType] {
            partTypeSegmentedControl.selectedSegmentTintColor = color
        }
        
        delegate?.partTypeChanged(atIndex: index, to: selectedType)
    }
    
    @IBAction func expandButtonTapped(_ sender: UIButton) {
        isExpanded = !isExpanded
    }
}

// MARK: - UITextViewDelegate
extension PartTableViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == lyricsTextView {
            delegate?.lyricsChanged(atIndex: index, to: textView.text)
        } else if textView == chordsTextView {
            delegate?.chordsChanged(atIndex: index, to: textView.text)
        }
    }
}

// MARK: - Safe array subscript extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}