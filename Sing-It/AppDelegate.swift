//
//  AppDelegate.swift
//  Sing-It
//
//  Created by Voss, Markus on 21.04.25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Print platform detection info
    func printPlatformInfo() {
        let platformDescription: String
        
        #if targetEnvironment(simulator)
            #if os(iOS)
                platformDescription = "iOS Simulator"
            #else
                platformDescription = "Unknown Simulator"
            #endif
        #else
            #if os(iOS)
                platformDescription = "iOS Device (iPhone/iPad)"
            #else
                platformDescription = "macOS Native"
            #endif
        #endif
        
        print("🔍 Application running on: \(platformDescription)")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Print platform detection info
        printPlatformInfo()
        
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

