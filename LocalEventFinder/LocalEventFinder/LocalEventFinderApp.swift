//
//  LocalEventFinderApp.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/25/24.
//

import SwiftUI
import FirebaseCore
import UserNotifications  // Add this

@main
struct LocalEventFinderApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        requestNotificationPermission()  // Add this
    }
    
    // Add this function
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

