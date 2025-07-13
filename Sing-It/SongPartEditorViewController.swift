import UIKit
import MessageUI

class SongPartEditorViewController: UIViewController {
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var partsTableView: UITableView!
    @IBOutlet weak var addPartButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var repeatPartButton: UIButton!
    @IBOutlet weak var showXMLButton: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    // Controls View Outlets
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tempoSlider: UISlider!
    @IBOutlet weak var tempoValueLabel: UILabel!
    @IBOutlet weak var capoLabel: UILabel!
    @IBOutlet weak var capoSegmentedControl: UISegmentedControl!
    @IBOutlet weak var transposeLabel: UILabel!
    @IBOutlet weak var transposeDownButton: UIButton!
    @IBOutlet weak var transposeUpButton: UIButton!
    
    var song: Song!
    var isNewSong: Bool = false
    private let dataManager = DataManager.shared
    private var selectedPartIndex: Int?
    
    // Transposition level (semitones): 0 means no transposition
    var transpositionLevel: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        // Set the artist label text from the song model
        artistLabel.text = song.artist
        // Set the song title label text from the song model
        songTitleLabel.text = song.title
        
        // Setup controls from model
        tempoSlider.minimumValue = 40
        tempoSlider.maximumValue = 200
        tempoSlider.value = Float(song.tempo)
        tempoValueLabel.text = "\(song.tempo) BPM"
        
        let capoOptions = ["None", "1", "2", "3", "4", "5", "6"]
        capoSegmentedControl.removeAllSegments()
        for (index, option) in capoOptions.enumerated() {
            capoSegmentedControl.insertSegment(withTitle: option, at: index, animated: false)
        }
        capoSegmentedControl.selectedSegmentIndex = min(song.capo, 6)
        
        transposeLabel.text = "Trans: 0"
        
        // Add targets for controls
        tempoSlider.addTarget(self, action: #selector(tempoSliderChanged(_:)), for: .valueChanged)
        transposeDownButton.addTarget(self, action: #selector(transposeDownButtonTapped), for: .touchUpInside)
        transposeUpButton.addTarget(self, action: #selector(transposeUpButtonTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        partsTableView.delegate = self
        partsTableView.dataSource = self
        
        // Register the new cell
        partsTableView.register(SongPartTableViewCell.self, forCellReuseIdentifier: SongPartTableViewCell.identifier)
        
        // Set row height
        partsTableView.rowHeight = UITableView.automaticDimension
        partsTableView.estimatedRowHeight = 120
        
        // Add table header view with column labels
        let headerView = createTableHeaderView()
        partsTableView.tableHeaderView = headerView
    }
    
    private func createTableHeaderView() -> UIView {
        // Create an empty header view to maintain spacing but without labels
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: partsTableView.frame.width, height: 20))
        headerView.backgroundColor = .clear
        return headerView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Update table header width
        if let headerView = partsTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(CGSize(width: partsTableView.frame.width, height: 0)).height
            var frame = headerView.frame
            frame.size.height = height
            frame.size.width = partsTableView.frame.width
            headerView.frame = frame
            partsTableView.tableHeaderView = headerView
        }
    }
    
    @IBAction func addPartButtonTapped(_ sender: UIButton) {
        // Create a new view controller loaded from XIB file
        let addVC = EditPartViewController(nibName: "EditPartViewController", bundle: nil)
        addVC.modalPresentationStyle = .formSheet
        addVC.preferredContentSize = CGSize(width: 950, height: 1000) // Increased width
        
        // Configure with default part type
        let newPart = Part(partType: .verse, lyrics: "", chords: "")
        addVC.configure(with: newPart, isNewPart: true)
        
        // Set completion handler to add the part
        addVC.onSave = { [weak self] part in
            guard let self = self else { return }
            self.song.parts.append(part)
            self.partsTableView.reloadData()
        }
        
        // Present the custom view controller
        present(addVC, animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        // Update song with the current text field values
        song.title = songTitleLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? song.title
        song.tempo = Int(tempoSlider.value)
        song.capo = capoSegmentedControl.selectedSegmentIndex // 0 = "None", 1-11 = fret position

        // --- Apply persistent transposition to all chords if needed ---
        if transpositionLevel != 0 {
            for part in song.parts {
                if !part.chords.isEmpty {
                    part.chords = SongViewerViewController.transposeChordProgression(part.chords, by: transpositionLevel)
                }
            }
            transpositionLevel = 0
            updateTransposeLabel()
            updateAllChordsDisplay()
        }
        // --- End persistent transposition logic ---

        if isNewSong {
            dataManager.addSong(song)
            isNewSong = false // Not a new song anymore
        } else {
            dataManager.updateSong(song)
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        // Simply pop view controller without confirmation
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func repeatPartButtonTapped(_ sender: UIButton) {
        // Check if there are parts to repeat
        guard !song.parts.isEmpty else {
            // Show alert if there are no parts to repeat
            let alert = UIAlertController(title: "No Parts", message: "There are no parts to repeat. Add a part first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Create alert controller for the part selection dialog
        let alert = UIAlertController(title: "Repeat Part", message: "Select a part to repeat:", preferredStyle: .actionSheet)
        
        // Add an action for each part in the song
        for (index, part) in song.parts.enumerated() {
            // Create a descriptive title for the part
            let partTypeText = part.partType.rawValue
            let lyricsPreview = part.lyrics.isEmpty ? "(No lyrics)" : String(part.lyrics.prefix(20)) + (part.lyrics.count > 20 ? "..." : "")
            let actionTitle = "\(index + 1). \(partTypeText) - \(lyricsPreview)"
            
            let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Create a copy of the part
                let repeatedPart = Part(partType: part.partType, lyrics: part.lyrics, chords: part.chords)
                
                // Add the copied part to the song
                self.song.parts.append(repeatedPart)
                
                // Reload the table view to show the new part
                self.partsTableView.reloadData()
                
                // Scroll to the new part
                let lastRow = self.song.parts.count - 1
                let indexPath = IndexPath(row: lastRow, section: 0)
                self.partsTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            
            alert.addAction(action)
        }
        
        // Add cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad, we need to set the source view for the popover
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = repeatPartButton
            popoverController.sourceRect = repeatPartButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @IBAction func showXMLButtonTapped(_ sender: UIButton) {
        // Generate XML representation of the song
        let xmlString = generateXML(for: song)
        
        // Create and present a dedicated XML view controller
        let xmlVC = XMLViewController()
        xmlVC.xmlContent = xmlString
        xmlVC.songTitle = song.title
        xmlVC.songArtist = song.artist // Pass the artist name to the XML view controller
        xmlVC.modalPresentationStyle = .formSheet
        xmlVC.preferredContentSize = CGSize(width: 600, height: 800)
        present(xmlVC, animated: true)
    }
    
    private func generateXML(for song: Song) -> String {
        var xmlString = "<song>\n"
        xmlString += "  <title>\(escapeXML(song.title))</title>\n"
        xmlString += "  <artist>\(escapeXML(song.artist))</artist>\n"
        xmlString += "  <tempo>\(song.tempo)</tempo>\n"
        
        // Add capo information to XML
        let capoValue = song.capo == 0 ? "None" : String(song.capo)
        xmlString += "  <capo>\(capoValue)</capo>\n"
        
        xmlString += "  <parts>\n"
        
        for part in song.parts {
            xmlString += "    <part>\n"
            xmlString += "      <type>\(part.partType.rawValue)</type>\n"
            
            // Handle lyrics with multiple lines
            xmlString += "      <lyrics>\n"
            let lyricsLines = part.lyrics.components(separatedBy: .newlines)
            for line in lyricsLines {
                xmlString += "        <line>\(escapeXML(line))</line>\n"
            }
            xmlString += "      </lyrics>\n"
            
            // Handle chords with multiple lines
            xmlString += "      <chords>\n"
            let chordsLines = part.chords.components(separatedBy: .newlines)
            for line in chordsLines {
                xmlString += "        <line>\(escapeXML(line))</line>\n"
            }
            xmlString += "      </chords>\n"
            
            xmlString += "    </part>\n"
        }
        
        xmlString += "  </parts>\n"
        xmlString += "</song>"
        
        return xmlString
    }
    
    private func escapeXML(_ string: String) -> String {
        // Basic XML escaping but keeping apostrophes (') as-is
        var escaped = string.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        // Remove the line that replaces apostrophes
        // escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }
    
    private func showEditPartAlert(for part: Part, at indexPath: IndexPath) {
        // Create and configure the custom edit view controller loaded from XIB
        let editVC = EditPartViewController(nibName: "EditPartViewController", bundle: nil)
        editVC.modalPresentationStyle = .formSheet
        editVC.preferredContentSize = CGSize(width: 950, height: 1000) // Increased width
        
        // Configure with part data
        editVC.configure(with: part)
        
        // Set the completion handler
        editVC.onSave = { [weak self] updatedPart in
            guard let self = self else { return }
            
            // Update the part with new values
            part.partType = updatedPart.partType
            part.lyrics = updatedPart.lyrics
            part.chords = updatedPart.chords
            
            // Refresh the UI
            self.partsTableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        // Present the custom view controller
        present(editVC, animated: true)
    }
    
    @objc private func tempoSliderChanged(_ sender: UISlider) {
        let tempo = Int(sender.value)
        tempoValueLabel.text = "\(tempo) BPM"
    }
    
    // MARK: - Transpose Actions
    
    @objc private func transposeDownButtonTapped() {
        transpositionLevel -= 1
        updateTransposeLabel()
        updateAllChordsDisplay()
    }

    @objc private func transposeUpButtonTapped() {
        transpositionLevel += 1
        updateTransposeLabel()
        updateAllChordsDisplay()
    }

    private func updateAllChordsDisplay() {
        // Reload the table view so all SongPartTableViewCells update their chord display
        partsTableView.reloadData()
    }

    private func updateTransposeLabel() {
        if transpositionLevel == 0 {
            transposeLabel.text = "Trans: 0"
        } else if transpositionLevel > 0 {
            transposeLabel.text = "Trans: +\(transpositionLevel)"
        } else {
            transposeLabel.text = "Trans: \(transpositionLevel)"
        }
    }
}

// MARK: - Custom Edit Part View Controller
class EditPartViewController: UIViewController {
    
    // UI Elements - keeping these as properties but will initialize them programmatically
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var typeSegmentControl: UISegmentedControl!
    @IBOutlet weak var lyricsTextView: UITextView!
    @IBOutlet weak var chordsTextView: UITextView!
    @IBOutlet weak var lyricsLabel: UILabel!
    @IBOutlet weak var chordsLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // Data
    private var part: Part?
    var onSave: ((Part) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Configure main view
        view.backgroundColor = UIColor.systemGray6
        
        // When using IBOutlets from a XIB file, we don't need to create UI elements programmatically
        // Just customize appearance or behavior as needed
    }
    
    func configure(with part: Part, isNewPart: Bool = false) {
        self.part = part
        
        // When view loads (or is already loaded), update the UI elements
        if isViewLoaded {
            updateUI(with: part, isNewPart: isNewPart)
        } else {
            // When view loads later, update UI
            DispatchQueue.main.async { [weak self] in
                self?.updateUI(with: part, isNewPart: isNewPart)
            }
        }
    }
    
    private func updateUI(with part: Part, isNewPart: Bool) {
        // Only update the title if it's a new part or editing
        if isNewPart {
            titleLabel.text = "Add Song Part"
        } else {
            // Keep the original title from XIB for editing
            titleLabel.text = "Edit Song Part"
        }
        
        // Set content
        lyricsTextView.text = part.lyrics
        chordsTextView.text = part.chords
        
        // Set selected part type
        if let index = PartType.allCases.firstIndex(of: part.partType) {
            typeSegmentControl.selectedSegmentIndex = index
        }
    }
    
    @objc func saveButtonTapped(_ sender: Any) {
        guard let part = part else { return }
        
        // Update part with new values
        if let selectedType = PartType.allCases[safe: typeSegmentControl.selectedSegmentIndex] {
            part.partType = selectedType
        }
        
        part.lyrics = lyricsTextView.text
        part.chords = chordsTextView.text
        
        // Call completion handler with updated part
        onSave?(part)
        
        // Dismiss
        dismiss(animated: true)
    }
    
    @objc func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SongPartEditorViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return song.parts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongPartTableViewCell.identifier, for: indexPath) as! SongPartTableViewCell
        let part = song.parts[indexPath.row]
        let isFirstPart = indexPath.row == 0
        let isLastPart = indexPath.row == song.parts.count - 1
        // Pass the transposition level to the cell for display
        cell.configure(with: part, index: indexPath.row, isFirst: isFirstPart, isLast: isLastPart, transpositionLevel: transpositionLevel)
        
        // Set the delete handler to remove the part when trash icon is clicked
        cell.deleteHandler = { [weak self] in
            guard let self = self else { return }
            
            // First check if the part still exists at this index to prevent out-of-bounds
            guard indexPath.row < self.song.parts.count else { return }
            
            // Remove the part from the song
            self.song.parts.remove(at: indexPath.row)
            
            // Update the table view - use beginUpdates/endUpdates for safer animations
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
            
            // Reload remaining cells to ensure they have the correct indexes
            tableView.reloadData()
        }
        
        // Set the move up handler for the up arrow button
        cell.moveUpHandler = { [weak self] in
            guard let self = self else { return }
            
            // Don't move up if it's already at the top
            guard indexPath.row > 0 else { return }
            
            // Get the current part
            let currentPart = self.song.parts[indexPath.row]
            
            // Remove it from its current position
            self.song.parts.remove(at: indexPath.row)
            
            // Insert it at the new position (one higher in the list)
            self.song.parts.insert(currentPart, at: indexPath.row - 1)
            
            // Reload the tableView to reflect changes
            tableView.reloadData()
            
            // Optional: scroll to make sure the moved row is visible
            tableView.scrollToRow(at: IndexPath(row: indexPath.row - 1, section: 0), at: .middle, animated: true)
        }
        
        // Set the move down handler for the down arrow button
        cell.moveDownHandler = { [weak self] in
            guard let self = self else { return }
            
            // Don't move down if it's already at the bottom
            guard indexPath.row < self.song.parts.count - 1 else { return }
            
            // Get the current part
            let currentPart = self.song.parts[indexPath.row]
            
            // Remove it from its current position
            self.song.parts.remove(at: indexPath.row)
            
            // Insert it at the new position (one lower in the list)
            self.song.parts.insert(currentPart, at: indexPath.row + 1)
            
            // Reload the tableView to reflect changes
            tableView.reloadData()
            
            // Optional: scroll to make sure the moved row is visible
            tableView.scrollToRow(at: IndexPath(row: indexPath.row + 1, section: 0), at: .middle, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show edit dialog for the selected part
        let part = song.parts[indexPath.row]
        showEditPartAlert(for: part, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            song.parts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - XMLViewController
class XMLViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    var xmlContent: String?
    var songTitle: String?
    var songArtist: String? // Added to store the artist name
    
    private let textView = UITextView()
    private let titleLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let uploadButton = UIButton(type: .system)
    private let buttonStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title label
        titleLabel.text = songTitle ?? "XML Representation"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Text view
        textView.text = xmlContent
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure Copy to Clipboard button
        copyButton.setTitle("Copy to Clipboard", for: .normal)
        copyButton.backgroundColor = .systemBlue
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 8
        copyButton.addTarget(self, action: #selector(copyToClipboardTapped), for: .touchUpInside)
        
        // Configure Upload button
        uploadButton.setTitle("Upload", for: .normal)
        uploadButton.backgroundColor = .systemGreen
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 8
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        
        // Button stack view
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        buttonStackView.alignment = .fill
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(copyButton)
        buttonStackView.addArrangedSubview(uploadButton)
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(textView)
        view.addSubview(buttonStackView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            buttonStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -20)
        ])
    }
    
    @objc private func copyToClipboardTapped() {
        guard let xmlContent = textView.text, !xmlContent.isEmpty else { return }
        
        // Copy to clipboard
        UIPasteboard.general.string = xmlContent
        
        // Show feedback to the user
        let alert = UIAlertController(title: "Copied", message: "XML has been copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func uploadTapped() {
        guard let xmlContent = textView.text, !xmlContent.isEmpty else { return }
        guard let songTitle = songTitle else { return }
        
        // Get artist or use empty string if nil
        let artist = songArtist ?? ""
        
        // Show activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // Format song title and artist for the filename (camel case, no spaces, no special chars)
        let formattedTitle = formatForFileName(songTitle)
        let formattedArtist = formatForFileName(artist)
        
        // Create file name with both song title and artist
        let fileName = formattedArtist.isEmpty ? 
            "\(formattedTitle).xml" : 
            "\(formattedTitle)(\(formattedArtist)).xml"
        
        // Create email subject with the song title and artist
        let emailSubject = "Song XML Upload: \(songTitle) (\(artist))"
        
        // Check if mail composer is available
        if MFMailComposeViewController.canSendMail() {
            // Create mail composer
            let composer = MFMailComposeViewController()
            composer.mailComposeDelegate = self
            composer.setToRecipients(["sing-it@xenon95.de"])
            composer.setSubject(emailSubject)
            
            // Convert XML string to Data and attach it
            if let xmlData = xmlContent.data(using: .utf8) {
                // Attach the XML file with the formatted filename
                composer.addAttachmentData(xmlData, mimeType: "application/xml", fileName: fileName)
                
                // Format the XML for the email body to ensure proper structure preservation
                // We need to use HTML formatting with a pre tag to preserve whitespace and line breaks
                let xmlForHtml = xmlContent
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                
                let htmlBody = """
                <html>
                <body>
                <pre style="font-family: monospace;">
                \(xmlForHtml)
                </pre>
                </body>
                </html>
                """
                
                // Use HTML body to preserve formatting
                composer.setMessageBody(htmlBody, isHTML: true)
                
                // Present the mail composer
                activityIndicator.removeFromSuperview()
                present(composer, animated: true)
            } else {
                activityIndicator.removeFromSuperview()
                showErrorAlert(message: "Could not create XML data from the song")
            }
        } else {
            // Fallback to mailto if Mail is not configured
            if let emailURL = createMailtoURL(recipient: "sing-it@xenon95.de", 
                                             subject: emailSubject,
                                             body: xmlContent) {
                
                activityIndicator.removeFromSuperview()
                
                if UIApplication.shared.canOpenURL(emailURL) {
                    UIApplication.shared.open(emailURL, options: [:]) { success in
                        if !success {
                            self.showErrorAlert(message: "Could not open email client")
                        }
                    }
                } else {
                    showErrorAlert(message: "No email client is configured on this device")
                }
            } else {
                activityIndicator.removeFromSuperview()
                showErrorAlert(message: "Could not create email with the song XML")
            }
        }
    }
    
    // Format a string for use in filenames: remove special characters and convert to camel case
    private func formatForFileName(_ input: String) -> String {
        guard !input.isEmpty else { return "" }
        
        // First remove apostrophes, question marks, exclamation marks and other special characters
        let allowedCharSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " "))
        let cleanedString = input.components(separatedBy: allowedCharSet.inverted).joined()
        
        // Split by spaces and capitalize each word
        let words = cleanedString.components(separatedBy: .whitespaces)
        let capitalizedWords = words.map { word in
            if !word.isEmpty {
                let firstChar = word.prefix(1).uppercased()
                let restOfWord = word.dropFirst()
                return firstChar + restOfWord
            }
            return ""
        }
        
        // Join words without spaces
        return capitalizedWords.joined()
    }
    
    private func sanitizeFileName(_ fileName: String) -> String {
        let illegalCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return fileName.components(separatedBy: illegalCharacters).joined(separator: "_")
    }
    
    private func showFeedbackAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func createMailtoURL(recipient: String, subject: String, body: String) -> URL? {
        // Fallback to mailto URL
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(recipient)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        return URL(string: mailtoString)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Handle mail composer result
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss mail composer
        controller.dismiss(animated: true) {
            // Show appropriate feedback based on result
            switch result {
            case .sent:
                self.showFeedbackAlert(title: "Success", message: "Email was sent successfully")
            case .saved:
                self.showFeedbackAlert(title: "Saved", message: "Email was saved as draft")
            case .cancelled:
                // No feedback needed for cancellation
                break
            case .failed:
                if let error = error {
                    self.showErrorAlert(message: "Failed to send email: \(error.localizedDescription)")
                } else {
                    self.showErrorAlert(message: "Failed to send email")
                }
            @unknown default:
                break
            }
        }
    }
}
