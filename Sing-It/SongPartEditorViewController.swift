import UIKit

class SongPartEditorViewController: UIViewController {
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var partsTableView: UITableView!
    @IBOutlet weak var addPartButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    // New button for repeating parts
    private var repeatPartButton: UIButton!
    // New button for showing XML representation
    private var showXMLButton: UIButton!
    
    var song: Song!
    var isNewSong: Bool = false
    private let dataManager = DataManager.shared
    private var selectedPartIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        // Add a back button item to the navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back", 
            style: .plain, 
            target: self, 
            action: #selector(backButtonTapped)
        )
        
        // Change save button to done
        saveButton.setTitle("Done", for: .normal)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        songTitleLabel.text = "\(song.title) by \(song.artist)"
        
        // Configure the Add Part button
        addPartButton.backgroundColor = .systemBlue
        addPartButton.setTitleColor(.white, for: .normal)
        addPartButton.layer.cornerRadius = 8
        
        // Configure the Save (Done) button
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.setTitle("Done", for: .normal)
        
        // Create the Repeat Part button
        repeatPartButton = UIButton(type: .system)
        repeatPartButton.setTitle("Repeat Part", for: .normal)
        repeatPartButton.backgroundColor = .systemPurple
        repeatPartButton.setTitleColor(.white, for: .normal)
        repeatPartButton.layer.cornerRadius = 8
        repeatPartButton.addTarget(self, action: #selector(repeatPartButtonTapped), for: .touchUpInside)
        repeatPartButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Create the Show XML button
        showXMLButton = UIButton(type: .system)
        showXMLButton.setTitle("Show XML", for: .normal)
        showXMLButton.backgroundColor = .systemOrange
        showXMLButton.setTitleColor(.white, for: .normal)
        showXMLButton.layer.cornerRadius = 8
        showXMLButton.addTarget(self, action: #selector(showXMLButtonTapped), for: .touchUpInside)
        showXMLButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the buttons to the view
        view.addSubview(repeatPartButton)
        view.addSubview(showXMLButton)
        
        // Reposition the existing buttons
        if let addPartSuperview = addPartButton.superview {
            addPartButton.removeFromSuperview()
            view.addSubview(addPartButton)
            addPartButton.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if let saveSuperview = saveButton.superview {
            saveButton.removeFromSuperview()
            view.addSubview(saveButton)
            saveButton.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Make sure the table is anchored to the top section
        if let tableView = partsTableView {
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 20),
                tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            ])
        }
        
        // Calculate button width based on screen width
        let screenWidth = UIScreen.main.bounds.width
        let buttonSpacing: CGFloat = 10
        let sideMargin: CGFloat = 20
        let totalButtonWidth = (screenWidth - (2 * sideMargin) - (3 * buttonSpacing)) / 4
        
        // Position all four buttons in a horizontal row at the bottom
        NSLayoutConstraint.activate([
            // Add Part button (leftmost)
            addPartButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: sideMargin),
            addPartButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            addPartButton.widthAnchor.constraint(equalToConstant: totalButtonWidth),
            addPartButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Repeat Part button (second from left)
            repeatPartButton.leadingAnchor.constraint(equalTo: addPartButton.trailingAnchor, constant: buttonSpacing),
            repeatPartButton.bottomAnchor.constraint(equalTo: addPartButton.bottomAnchor),
            repeatPartButton.widthAnchor.constraint(equalTo: addPartButton.widthAnchor),
            repeatPartButton.heightAnchor.constraint(equalTo: addPartButton.heightAnchor),
            
            // Show XML button (third from left)
            showXMLButton.leadingAnchor.constraint(equalTo: repeatPartButton.trailingAnchor, constant: buttonSpacing),
            showXMLButton.bottomAnchor.constraint(equalTo: addPartButton.bottomAnchor),
            showXMLButton.widthAnchor.constraint(equalTo: addPartButton.widthAnchor),
            showXMLButton.heightAnchor.constraint(equalTo: addPartButton.heightAnchor),
            
            // Done button (rightmost)
            saveButton.leadingAnchor.constraint(equalTo: showXMLButton.trailingAnchor, constant: buttonSpacing),
            saveButton.bottomAnchor.constraint(equalTo: addPartButton.bottomAnchor),
            saveButton.widthAnchor.constraint(equalTo: addPartButton.widthAnchor),
            saveButton.heightAnchor.constraint(equalTo: addPartButton.heightAnchor),
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -sideMargin)
        ])
        
        // Make the table view end above the buttons
        if let tableView = partsTableView {
            NSLayoutConstraint.activate([
                tableView.bottomAnchor.constraint(equalTo: addPartButton.topAnchor, constant: -20)
            ])
        }
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
        // Create a new custom view controller for adding parts
        let addVC = EditPartViewController()
        addVC.modalPresentationStyle = .formSheet
        addVC.preferredContentSize = CGSize(width: 400, height: 550) // Increased from 450 to 550
        
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
        if isNewSong {
            dataManager.addSong(song)
            isNewSong = false // Not a new song anymore
        } else {
            dataManager.updateSong(song)
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func backButtonTapped() {
        // Show alert to confirm going back without saving
        let alert = UIAlertController(title: "Unsaved Changes", message: "Do you want to save changes before going back?", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Handle saving differently based on whether this is a new song or existing song
            if self.isNewSong {
                self.dataManager.addSong(self.song)
                self.isNewSong = false
            } else {
                self.dataManager.updateSong(self.song)
            }
            
            self.navigationController?.popViewController(animated: true)
        }
        
        let discardAction = UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(discardAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        // Remove this action or repurpose it
        backButtonTapped()
    }
    
    @objc private func repeatPartButtonTapped() {
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
    
    @objc private func showXMLButtonTapped() {
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
        // Create and configure the custom edit view controller
        let editVC = EditPartViewController()
        editVC.modalPresentationStyle = .formSheet
        editVC.preferredContentSize = CGSize(width: 400, height: 550) // Increased from 450 to 550
        
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
    
    // UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let typeSegmentControl = UISegmentedControl()
    private let lyricsTextView = UITextView()
    private let chordsTextView = UITextView()
    private let lyricsLabel = UILabel()
    private let chordsLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
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
        
        // Add container view
        view.addSubview(containerView)
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 10
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        titleLabel.text = "Edit Song Part"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Type segment control
        for (index, type) in PartType.allCases.enumerated() {
            typeSegmentControl.insertSegment(withTitle: type.rawValue, at: index, animated: false)
        }
        typeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Labels
        lyricsLabel.text = "Lyrics"
        lyricsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        chordsLabel.text = "Chords"
        chordsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        chordsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Text views
        lyricsTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular) // Changed back to match chords font size
        lyricsTextView.layer.borderColor = UIColor.systemGray4.cgColor
        lyricsTextView.layer.borderWidth = 1
        lyricsTextView.layer.cornerRadius = 8
        lyricsTextView.translatesAutoresizingMaskIntoConstraints = false
        
        chordsTextView.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        chordsTextView.layer.borderColor = UIColor.systemGray4.cgColor
        chordsTextView.layer.borderWidth = 1
        chordsTextView.layer.cornerRadius = 8
        chordsTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.setTitleColor(.darkGray, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        containerView.addSubview(titleLabel)
        containerView.addSubview(typeSegmentControl)
        containerView.addSubview(lyricsLabel)
        containerView.addSubview(lyricsTextView)
        containerView.addSubview(chordsLabel)
        containerView.addSubview(chordsTextView)
        containerView.addSubview(saveButton)
        containerView.addSubview(cancelButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Type segment
            typeSegmentControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            typeSegmentControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            typeSegmentControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Lyrics label
            lyricsLabel.topAnchor.constraint(equalTo: typeSegmentControl.bottomAnchor, constant: 20),
            lyricsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            lyricsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Lyrics text view
            lyricsTextView.topAnchor.constraint(equalTo: lyricsLabel.bottomAnchor, constant: 8),
            lyricsTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            lyricsTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            lyricsTextView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.25),
            
            // Chords label
            chordsLabel.topAnchor.constraint(equalTo: lyricsTextView.bottomAnchor, constant: 16),
            chordsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            chordsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Chords text view
            chordsTextView.topAnchor.constraint(equalTo: chordsLabel.bottomAnchor, constant: 8),
            chordsTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            chordsTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            chordsTextView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.25),
            
            // Button container
            saveButton.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 4),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.topAnchor.constraint(equalTo: chordsTextView.bottomAnchor, constant: 20),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -4),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: chordsTextView.bottomAnchor, constant: 20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with part: Part, isNewPart: Bool = false) {
        self.part = part
        
        // Store the initial values to be used when view is loaded
        let initialTitle = isNewPart ? "Add \(part.partType.rawValue)" : "Edit \(part.partType.rawValue)"
        let initialLyrics = part.lyrics
        let initialChords = part.chords
        let initialType = part.partType
        
        // If view is already loaded, update UI immediately
        if isViewLoaded {
            updateUI(title: initialTitle, lyrics: initialLyrics, chords: initialChords, type: initialType)
        } else {
            // Otherwise, update UI when view loads
            loadViewIfNeeded() // Force view to load if needed
            DispatchQueue.main.async { [weak self] in
                self?.updateUI(title: initialTitle, lyrics: initialLyrics, chords: initialChords, type: initialType)
            }
        }
    }
    
    private func updateUI(title: String, lyrics: String, chords: String, type: PartType) {
        titleLabel.text = title
        lyricsTextView.text = lyrics
        chordsTextView.text = chords
        
        if let index = PartType.allCases.firstIndex(of: type) {
            typeSegmentControl.selectedSegmentIndex = index
        }
    }
    
    @objc private func saveButtonTapped() {
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
    
    @objc private func cancelButtonTapped() {
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