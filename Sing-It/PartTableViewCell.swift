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
    
    var isExpanded: Bool = false {
        didSet {
            updateExpandedState()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Configure lyrics text view
        lyricsTextView.layer.borderColor = UIColor.systemGray4.cgColor
        lyricsTextView.layer.borderWidth = 1
        lyricsTextView.layer.cornerRadius = 8
        lyricsTextView.font = UIFont.systemFont(ofSize: 16)
        lyricsTextView.delegate = self
        
        // Configure chords text view
        chordsTextView.layer.borderColor = UIColor.systemGray4.cgColor
        chordsTextView.layer.borderWidth = 1
        chordsTextView.layer.cornerRadius = 8
        chordsTextView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        chordsTextView.delegate = self
        
        // Configure segmented control with part types
        partTypeSegmentedControl.removeAllSegments()
        for (index, type) in PartType.allCases.enumerated() {
            partTypeSegmentedControl.insertSegment(withTitle: type.rawValue, at: index, animated: false)
        }
        
        // Set expand button image
        updateExpandButtonImage()
    }
    
    func configure(with part: Part, index: Int, delegate: PartTableViewCellDelegate) {
        self.part = part
        self.index = index
        self.delegate = delegate
        
        // Set part type
        if let typeIndex = PartType.allCases.firstIndex(where: { $0 == part.partType }) {
            partTypeSegmentedControl.selectedSegmentIndex = typeIndex
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