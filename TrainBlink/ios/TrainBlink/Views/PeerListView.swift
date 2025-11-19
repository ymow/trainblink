//
//  PeerListView.swift
//  TrainBlink
//
//  Feature 2: P2P Discovery
//  Displays list of discovered peers with connection controls
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import SwiftUI

struct PeerListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Nearby Users")
                    .font(.headline)

                Spacer()

                // Discovery status indicator
                if appState.isDiscovering {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Discovering...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Not discovering")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Peer count
            Text("\(appState.discoveredPeers.count) peers found")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // Peer list
            if appState.discoveredPeers.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.discoveredPeers) { peer in
                            PeerRowView(peer: peer)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No peers found")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if appState.isInStation {
                Text("Make sure Bluetooth is enabled")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Enter a station to discover peers")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }
}

struct PeerRowView: View {
    @EnvironmentObject var appState: AppState
    let peer: Peer

    var body: some View {
        HStack(spacing: 12) {
            // Avatar/Icon
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)

                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }

            // Peer info
            VStack(alignment: .leading, spacing: 4) {
                Text(peer.displayName)
                    .font(.headline)

                HStack(spacing: 4) {
                    // Connection status icon
                    Image(systemName: peer.connectionIcon)
                        .font(.caption)
                        .foregroundColor(statusColor)

                    // Status text
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Signal strength indicator (if available)
            if let strength = peer.signalStrength {
                signalStrengthView(strength: strength)
            }

            // Connection button
            connectionButton
        }
        .padding()
        .background(peer.isConnected ? Color.green.opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private var avatarColor: Color {
        switch peer.connectionState {
        case .notConnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        }
    }

    private var statusColor: Color {
        switch peer.connectionState {
        case .notConnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        }
    }

    private var statusText: String {
        switch peer.connectionState {
        case .notConnected:
            return "Available"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        }
    }

    private func signalStrengthView(strength: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index < signalBars(for: strength) ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + index * 3))
            }
        }
    }

    private func signalBars(for strength: Double) -> Int {
        switch strength {
        case 0..<0.25: return 1
        case 0.25..<0.5: return 2
        case 0.5..<0.75: return 3
        default: return 4
        }
    }

    private var connectionButton: some View {
        Button(action: {
            handleConnectionAction()
        }) {
            if peer.isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
            } else if peer.isConnected {
                Text("Disconnect")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("Connect")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(.bordered)
        .disabled(peer.isConnecting)
    }

    private func handleConnectionAction() {
        if peer.isConnected {
            appState.disconnect(from: peer)
        } else {
            appState.connect(to: peer)
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    PeerListView()
        .environmentObject(AppState())
}

#Preview("With Peers") {
    let appState = AppState()
    // Simulate discovered peers
    appState.multipeerManager.discoveredPeers = Peer.samples

    return PeerListView()
        .environmentObject(appState)
}

#Preview("Single Peer Row") {
    PeerRowView(peer: Peer.samples[0])
        .environmentObject(AppState())
        .padding()
}
