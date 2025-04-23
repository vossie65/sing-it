import UIKit

class SongPartEditorViewController: UIViewController {
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var partsTableView: UITableView!
    @IBOutlet weak var addPartButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var repeatPartButton: UIButton!
    @IBOutlet weak var showXMLButton: UIButton!
    
    // Replace static label with editable fields
    private let titleTextField = UITextField()
    private let artistTextField = UITextField()
    
    var song: Song!
    var isNewSong: Bool = false
    private let dataManager = DataManager.shared
    private var selectedPartIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        // Change save button to done
        saveButton.setTitle("Done", for: .normal)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Hide the original title label
        songTitleLabel.isHidden = true
        
        // Configure title text field
        titleTextField.text = song.title
        titleTextField.font = UIFont.boldSystemFont(ofSize: 24)
        titleTextField.textAlignment = .center
        titleTextField.borderStyle = .none
        titleTextField.placeholder = "Song Title"
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.returnKeyType = .done
        titleTextField.delegate = self
        view.addSubview(titleTextField)
        
        // Configure artist text field
        artistTextField.text = song.artist
        artistTextField.font = UIFont.systemFont(ofSize: 18)
        artistTextField.textColor = .secondaryLabel
        artistTextField.textAlignment = .center
        artistTextField.borderStyle = .none
        artistTextField.placeholder = "Artist Name"
        artistTextField.translatesAutoresizingMaskIntoConstraints = false
        artistTextField.returnKeyType = .done
        artistTextField.delegate = self
        view.addSubview(artistTextField)
        
        // Position the editable fields where the labels would have been
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: songTitleLabel.topAnchor),
            titleTextField.leadingAnchor.constraint(equalTo: songTitleLabel.leadingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: songTitleLabel.trailingAnchor),
            titleTextField.heightAnchor.constraint(equalToConstant: 40),
            
            artistTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 8),
            artistTextField.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            artistTextField.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            artistTextField.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Add light borders and padding to make it clear they're editable
        titleTextField.layer.borderColor = UIColor.systemGray5.cgColor
        titleTextField.layer.borderWidth = 0.5
        titleTextField.layer.cornerRadius = 6
        
        artistTextField.layer.borderColor = UIColor.systemGray5.cgColor
        artistTextField.layer.borderWidth = 0.5
        artistTextField.layer.cornerRadius = 6
        
        // Configure the Add Part button
        addPartButton.backgroundColor = .systemBlue
        addPartButton.setTitleColor(.white, for: .normal)
        addPartButton.layer.cornerRadius = 8
        
        // Configure the Save (Done) button
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        
        // Configure Repeat Part button
        repeatPartButton.backgroundColor = .systemPurple
        repeatPartButton.setTitleColor(.white, for: .normal)
        repeatPartButton.layer.cornerRadius = 8
        
        // Configure Show XML button
        showXMLButton.backgroundColor = .systemOrange
        showXMLButton.setTitleColor(.white, for: .normal)
        showXMLButton.layer.cornerRadius = 8
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
        addVC.preferredContentSize = CGSize(width: 780, height: 820) // Updated to match XIB dimensions
        
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
        song.title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? song.title
        song.artist = artistTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? song.artist
        
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
        xmlVC.modalPresentationStyle = .formSheet
        xmlVC.preferredContentSize = CGSize(width: 600, height: 800)
        present(xmlVC, animated: true)
    }
    
    private func generateXML(for song: Song) -> String {
        var xmlString = "<song>\n"
        xmlString += "  <title>\(escapeXML(song.title))</title>\n"
        xmlString += "  <artist>\(escapeXML(song.artist))</artist>\n"
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
        editVC.preferredContentSize = CGSize(width: 780, height: 820) // Updated to match XIB dimensions
        
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
        cell.configure(with: part, index: indexPath.row)
        
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
class XMLViewController: UIViewController {
    
    var xmlContent: String?
    var songTitle: String?
    
    private let textView = UITextView()
    private let titleLabel = UILabel()
    
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
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(textView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
}

// MARK: - UITextFieldDelegate
extension SongPartEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Dismiss keyboard when return key is pressed
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Update the song object when editing is finished
        if textField == titleTextField {
            song.title = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? song.title
        } else if textField == artistTextField {
            song.artist = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? song.artist
        }
    }
}