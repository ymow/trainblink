//
//  TrainBlinkApp.swift
//  TrainBlink
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import SwiftUI
import Firebase

@main
struct TrainBlinkApp: App {

    // MARK: - Properties

    @StateObject private var appState = AppState()

    // MARK: - Initialization

    init() {
        // 1. Initialize Firebase (must be first)
        FirebaseApp.configure()

        // 2. Configure Crashlytics with session metadata
        configureCrashlytics()

        // 3. Check user privacy settings for Analytics
        configureAnalytics()

        // 4. Log app initialization
        AnalyticsManager.shared.logAppLaunched()

        print("🚀 TrainBlink initialized successfully")
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    AnalyticsManager.shared.logScreenView(screenName: "ContentView")
                }
        }
    }

    // MARK: - Private Methods

    private func configureCrashlytics() {
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        print("⚠️ Crashlytics disabled in DEBUG mode")
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        print("✅ Crashlytics enabled")
        #endif

        // Set initial custom keys
        Crashlytics.crashlytics().setCustomValue("iOS", forKey: "platform")
        Crashlytics.crashlytics().setCustomValue(
            UIDevice.current.systemVersion,
            forKey: "os_version"
        )
    }

    private func configureAnalytics() {
        // Check user privacy preferences
        let analyticsEnabled = UserDefaults.standard.bool(forKey: "analytics_enabled")

        // Default to true for first-time users
        if UserDefaults.standard.object(forKey: "analytics_enabled") == nil {
            UserDefaults.standard.set(true, forKey: "analytics_enabled")
            Analytics.setAnalyticsCollectionEnabled(true)
            print("✅ Analytics enabled (default)")
        } else {
            Analytics.setAnalyticsCollectionEnabled(analyticsEnabled)
            print(analyticsEnabled ? "✅ Analytics enabled" : "⚠️ Analytics disabled by user")
        }
    }
}
