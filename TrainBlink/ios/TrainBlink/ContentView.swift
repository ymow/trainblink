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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🚄 TrainBlink")
                    .font(.largeTitle)
                    .bold()

                if appState.isInStation {
                    Text("🚉 In Station: \(appState.currentStation?.name ?? "")")
                        .font(.headline)
                } else {
                    Text("Waiting for station...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Divider()

                // Example buttons to trigger analytics events
                VStack(spacing: 15) {
                    Button("Test: Enter Station") {
                        testEnterStation()
                    }
                    .buttonStyle(.borderedProminent)

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

                Spacer()
            }
            .padding()
            .navigationTitle("TrainBlink Demo")
            .onAppear {
                AnalyticsManager.shared.logScreenView(
                    screenName: "ContentView",
                    screenClass: "ContentView"
                )
            }
        }
    }

    // MARK: - Test Methods

    private func testEnterStation() {
        let station = Station(
            id: "1000",
            name: "台北車站",
            type: .tra
        )
        appState.enterStation(station)
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
