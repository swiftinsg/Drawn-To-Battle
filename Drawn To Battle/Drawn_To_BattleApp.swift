//
//  Drawn_To_BattleApp.swift
//  Drawn To Battle
//
//  Created by Pratheesh on 11/11/26.
//

import SwiftUI
import UIKit

final class DrawnToBattleAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .landscape
    }
}

@main
struct Drawn_To_BattleApp: App {
    @UIApplicationDelegateAdaptor(DrawnToBattleAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
