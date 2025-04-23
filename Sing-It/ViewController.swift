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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createSongButton: UIButton!
    @IBOutlet weak var createSetButton: UIButton!
    @IBOutlet weak var playSetButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
    }

    // MARK: - UI Styling
    private func styleUI() {
        view.backgroundColor = .white
        // Ensure text is visible: set label and button title colors to black
        titleLabel.textColor = .black
        [createSongButton, createSetButton, playSetButton].forEach { btn in
            btn?.backgroundColor = .systemGray4
            btn?.setTitleColor(.black, for: .normal)
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

    // MARK: - Navigation
    @IBAction func unwindToMainMenu(_ unwindSegue: UIStoryboardSegue) {
        // This method handles returning to the main menu from other screens
        print("Returned to main menu")
    }
}

