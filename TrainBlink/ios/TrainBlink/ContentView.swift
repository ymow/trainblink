//
//  ContentView.swift
//  TrainBlink
//
//  Main content view with Firebase integration examples
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedStation: Station = Station.samples[0]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("🚄 TrainBlink")
                        .font(.largeTitle)
                        .bold()

                    // Geofence Status Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Geofence Status")
                            .font(.headline)

                        if appState.isInStation {
                            HStack {
                                Text("🚉")
                                    .font(.title)
                                VStack(alignment: .leading) {
                                    Text(appState.currentStation?.name ?? "Unknown")
                                        .font(.headline)
                                    Text(appState.currentStation?.type.rawValue ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        } else {
                            HStack {
                                Text("🚶")
                                    .font(.title)
                                Text("Not in station")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }

                        // Location Permission Status
                        HStack {
                            Image(systemName: authStatusIcon)
                                .foregroundColor(authStatusColor)
                            Text(authStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)

                    Divider()

                    // Geofencing Tests
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Feature 1: Geofencing")
                            .font(.headline)

                        // Station Selector
                        Picker("Select Station", selection: $selectedStation) {
                            ForEach(Station.samples, id: \.self) { station in
                                Text(station.name).tag(station)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack(spacing: 10) {
                            Button("Simulate Entry") {
                                testEnterStation(selectedStation)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Simulate Exit") {
                                testExitStation()
                            }
                            .buttonStyle(.bordered)
                            .disabled(!appState.isInStation)
                        }

                        Button("Request Location Permission") {
                            appState.geofenceManager.requestAuthorization()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)

                    Divider()

                    // P2P Discovery (Feature 2)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Feature 2: P2P Discovery")
                            .font(.headline)

                        // Discovery controls
                        HStack(spacing: 10) {
                            Button(appState.isDiscovering ? "Stop Discovery" : "Start Discovery") {
                                if appState.isDiscovering {
                                    appState.stopDiscovery()
                                } else {
                                    appState.startDiscovery()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(appState.isDiscovering ? .red : .green)

                            // Peer count badge
                            if appState.isDiscovering {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.caption)
                                    Text("\(appState.discoveredPeers.count)")
                                        .font(.caption)
                                        .bold()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }

                        // Peer list
                        if appState.isDiscovering {
                            PeerListView()
                                .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)

                    Divider()

                    // Other Tests
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Other Tests")
                            .font(.headline)

                        Button("Test: Content Sharing") {
                            testContentSharing()
                        }
                        .buttonStyle(.bordered)

                        Button("Test: AI Review") {
                            testAIReview()
                        }
                        .buttonStyle(.bordered)

                        Button("Test: Error Tracking") {
                            testErrorTracking()
                        }
                        .buttonStyle(.bordered)
                            .tint(.red)

                        Button("Test: Performance Trace") {
                            Task {
                                await testPerformanceTrace()
                            }
                        }
                        .buttonStyle(.bordered)
                            .tint(.green)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)

                    // Database Info
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Station Database")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("TRA: \(StationDatabase.shared.count(ofType: .tra)) stations")
                            .font(.caption2)
                        Text("THSR: \(StationDatabase.shared.count(ofType: .thsr)) stations")
                            .font(.caption2)
                        Text("Total: \(StationDatabase.shared.totalCount) stations")
                            .font(.caption2)
                            .bold()
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("TrainBlink Demo")
            .onAppear {
                AnalyticsManager.shared.logScreenView(
                    screenName: "ContentView",
                    screenClass: "ContentView"
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var authStatusIcon: String {
        switch appState.geofenceManager.authorizationStatus {
        case .authorizedAlways:
            return "checkmark.circle.fill"
        case .authorizedWhenInUse:
            return "location.circle.fill"
        case .denied, .restricted:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }

    private var authStatusColor: Color {
        switch appState.geofenceManager.authorizationStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }

    private var authStatusText: String {
        switch appState.geofenceManager.authorizationStatus {
        case .authorizedAlways:
            return "Location: Always (✓)"
        case .authorizedWhenInUse:
            return "Location: When In Use (needs Always)"
        case .denied:
            return "Location: Denied (✗)"
        case .restricted:
            return "Location: Restricted (✗)"
        case .notDetermined:
            return "Location: Not Determined"
        @unknown default:
            return "Location: Unknown"
        }
    }

    // MARK: - Test Methods

    private func testEnterStation(_ station: Station) {
        appState.enterStation(station)
    }

    private func testExitStation() {
        appState.exitStation()
    }

    private func testContentSharing() {
        // Test content selection
        AnalyticsManager.shared.logContentSelectionStarted(contentType: .photo)

        // Simulate AI review
        AnalyticsManager.shared.logContentReviewedByAI(
            contentType: .photo,
            reviewResult: .approved,
            reviewDurationMs: 450
        )

        // Simulate sending
        AnalyticsManager.shared.logContentSent(
            contentType: .photo,
            recipientCount: 2,
            fileSizeKB: 2048
        )

        print("✅ Content sharing events logged")
    }

    private func testAIReview() {
        AnalyticsManager.shared.logAINSFWDetected(
            confidence: "low",
            action: "approved"
        )

        AnalyticsManager.shared.logAIFaceDetected(
            faceCount: 1,
            action: "warned"
        )

        print("✅ AI review events logged")
    }

    private func testErrorTracking() {
        // Test P2P error
        ErrorTracker.record(
            .p2pConnectionFailed(reason: "timeout"),
            context: [
                "peer_count": 3,
                "attempt": 2
            ]
        )

        // Test content error
        ErrorTracker.record(
            .contentTransferFailed(
                contentType: .photo,
                reason: "peer_offline"
            )
        )

        print("✅ Error tracking tested")
    }

    private func testPerformanceTrace() async {
        // Test AI inference tracking
        let result = try? await PerformanceTracker.trackAIInference(
            modelType: "nsfw",
            contentType: .photo
        ) {
            // Simulate AI inference
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            return .approved
        }

        print("✅ Performance trace completed: \(result?.rawValue ?? "error")")
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
