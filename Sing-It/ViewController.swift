//
//  ViewController.swift
//  Sing-It
//
//  Created by Voss, Markus on 21.04.25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var createSongButton: UIButton!
    @IBOutlet weak var createSetButton: UIButton!
    @IBOutlet weak var playSetButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var backgroundImageView: UIImageView! // Connect this to your background image view in storyboard
    @IBOutlet weak var adminButton: UIButton! // Connect this to your Admin button in storyboard
    
    enum StartScreenType: String, CaseIterable {
        case male = "StartScreenM"
        case female = "StartScreenF"
        case cat = "StartScreenC"
        
        var displayName: String {
            switch self {
            case .male: return "Male Artist"
            case .female: return "Female Artist"
            case .cat: return "Cat Artist"
            }
        }
    }

    let startScreenKey = "StartScreenTypeKey"

    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectStartScreenIfNeeded()
    }

    // MARK: - UI Styling
    private func styleUI() {
        view.backgroundColor = .white
        [createSongButton, createSetButton, playSetButton].forEach { btn in
            btn?.setTitleColor(.black, for: .normal)
        }
    }

    private func selectStartScreenIfNeeded() {
        let defaults = UserDefaults.standard
        let saved = defaults.string(forKey: startScreenKey)
        print("[DEBUG] UserDefaults for startScreenKey: \(String(describing: saved))")
        if let saved = saved,
           let type = StartScreenType(rawValue: saved) {
            setBackgroundImage(type)
        } else {
            presentStartScreenSelection()
        }
    }

    private func setBackgroundImage(_ type: StartScreenType) {
        backgroundImageView.image = UIImage(named: type.rawValue)
    }

    private func presentStartScreenSelection() {
        print("[DEBUG] presentStartScreenSelection called")
        let alert = UIAlertController(title: "Choose Start Screen", message: "Select your preferred background:", preferredStyle: .alert)
        for type in StartScreenType.allCases {
            alert.addAction(UIAlertAction(title: type.displayName, style: .default) { [weak self] _ in
                print("[DEBUG] Selected: \(type.rawValue)")
                UserDefaults.standard.set(type.rawValue, forKey: self?.startScreenKey ?? "")
                self?.setBackgroundImage(type)
            })
        }
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true)
        }
    }

    // MARK: - Actions
    @IBAction func createSongTapped() {
        // Note: Navigation is handled by the storyboard segue
        print("Create Song button tapped")
    }
    
    @IBAction func createSetTapped() {
        // Note: Navigation is handled by the storyboard segue
        print("Create Set button tapped")
    }
    
    @IBAction func playSetTapped() {
        // Note: Navigation is handled by the storyboard segue
        print("Play Set button tapped")
    }
    
    @IBAction func adminButtonTapped() {
        print("[DEBUG] Admin button tapped")
        presentStartScreenSelection()
    }

    // MARK: - Navigation
    @IBAction func unwindToMainMenu(_ unwindSegue: UIStoryboardSegue) {
        // This method handles returning to the main menu from other screens
        print("Returned to main menu")
    }
}

