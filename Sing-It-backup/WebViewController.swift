import UIKit
import WebKit

class WebViewController: UIViewController {
    
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var didAttemptHTTP = false
    
    // Reference to the XML parser
    private let xmlParser = XMLSongParser()
    
    // Completion handler for song import
    var onSongImported: ((Song) -> Void)?
    
    override func loadView() {
        // Create a web view configuration
        let webConfiguration = WKWebViewConfiguration()
        
        // Create the web view with the configuration
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        
        // Set the web view as the view of this view controller
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Download Songs"
        
        // Add activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add a close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close, 
            target: self, 
            action: #selector(closeButtonTapped)
        )
        navigationItem.leftBarButtonItem = closeButton
        
        // Add a reload button
        let reloadButton = UIBarButtonItem(
            barButtonSystemItem: .refresh, 
            target: self, 
            action: #selector(reloadButtonTapped)
        )
        navigationItem.rightBarButtonItem = reloadButton
        
        // Configure web view to intercept navigation actions
        webView.navigationDelegate = self
        
        // Load xenon95.de
        loadWebsite()
    }
    
    private func loadWebsite() {
        activityIndicator.startAnimating()
        
        // First try with https
        let urlString = didAttemptHTTP ? "http://xenon95.de" : "https://xenon95.de"
        
        print("Attempting to load: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            activityIndicator.stopAnimating()
            showError(message: "Invalid URL format")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func showError(message: String) {
        activityIndicator.stopAnimating()
        
        let alert = UIAlertController(
            title: "Error Loading Website",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            self?.loadWebsite()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func reloadButtonTapped() {
        webView.reload()
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
        print("Started loading website...")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        title = webView.title ?? "Download Songs"
        print("Successfully loaded website: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleWebError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleWebError(error)
    }
    
    private func handleWebError(_ error: Error) {
        activityIndicator.stopAnimating()
        print("Error loading website: \(error.localizedDescription)")
        
        // Try with HTTP if HTTPS failed
        if !didAttemptHTTP {
            print("Trying with HTTP instead...")
            didAttemptHTTP = true
            loadWebsite()
            return
        }
        
        showError(message: "Failed to load website: \(error.localizedDescription)")
    }
    
    // Intercept link clicks
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // Check if this is a link click (not initial page load)
        if navigationAction.navigationType == .linkActivated {
            
            // Get the URL that was clicked
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // Check if it's an XML file based on extension
            if url.pathExtension.lowercased() == "xml" {
                print("XML link clicked: \(url.absoluteString)")
                
                // Show loading indicator
                activityIndicator.startAnimating()
                
                // Fetch the XML data
                let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                    guard let self = self else { return }
                    
                    // Move to main thread for UI updates
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        
                        if let error = error {
                            self.showError(message: "Failed to download file: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let data = data, let xmlContent = String(data: data, encoding: .utf8) else {
                            self.showError(message: "Could not read downloaded file")
                            return
                        }
                        
                        // Parse the XML content
                        if let song = self.xmlParser.parseSongFromXML(xmlContent) {
                            // Show success message
                            let alert = UIAlertController(
                                title: "Import Successful",
                                message: "Would you like to edit '\(song.title)' by \(song.artist)?",
                                preferredStyle: .alert
                            )
                            
                            // Add edit action
                            alert.addAction(UIAlertAction(title: "Yes, Edit", style: .default) { _ in
                                // Find the parent SongsViewController
                                if let navController = self.navigationController?.presentingViewController as? UINavigationController,
                                   let songsVC = navController.topViewController as? SongsViewController {
                                    // Close the web view
                                    self.dismiss(animated: true) {
                                        // Open song editor for the imported song
                                        songsVC.openSongEditor(for: song, isNew: true)
                                    }
                                } else {
                                    // Add the song to DataManager directly if we can't find SongsViewController
                                    DataManager.shared.addSong(song)
                                    self.dismiss(animated: true)
                                }
                            })
                            
                            // Add cancel action
                            alert.addAction(UIAlertAction(title: "No, Continue Browsing", style: .cancel))
                            
                            // Show alert
                            self.present(alert, animated: true)
                        } else {
                            self.showError(message: "Failed to parse song data. The file may be corrupted or in an incorrect format.")
                        }
                    }
                }
                
                // Start the download task
                task.resume()
                
                // Cancel the navigation
                decisionHandler(.cancel)
                return
            }
        }
        
        // Allow navigation for other URLs
        decisionHandler(.allow)
    }
}