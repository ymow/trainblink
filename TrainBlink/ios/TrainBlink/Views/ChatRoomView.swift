//
//  ChatRoomView.swift
//  TrainBlink
//
//  Feature 5: 1-on-1 Chat Rooms
//  UI for individual chat room with message bubbles and input
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import SwiftUI

struct ChatRoomView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var chatManager = ChatManager.shared
    @StateObject private var ephemeralManager = EphemeralMessageManager.shared

    let peerId: String
    let peerDisplayName: String

    @State private var messageText: String = ""
    @State private var isEphemeral: Bool = false
    @FocusState private var isInputFocused: Bool

    // Get chat room from manager
    private var chatRoom: ChatRoom? {
        chatManager.chatRooms.first(where: { $0.peerId == peerId })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Messages
            if let room = chatRoom {
                messagesView(room: room)
            } else {
                emptyStateView
            }

            Divider()

            // Input area
            inputView
        }
        .navigationTitle(peerDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            markAsRead()
        }
        .onDisappear {
            markAsRead()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)

                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }

            // Peer info
            VStack(alignment: .leading, spacing: 2) {
                Text(peerDisplayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let room = chatRoom {
                    Text("\(room.encounterCount) encounters")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Ephemeral toggle
            Toggle("", isOn: $isEphemeral)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .orange))

            Text(isEphemeral ? "10s" : "∞")
                .font(.caption)
                .foregroundColor(isEphemeral ? .orange : .secondary)
                .frame(width: 20)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Messages

    private func messagesView(room: ChatRoom) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(room.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isSentByMe: message.isSentByMe(myId: appState.sessionID)
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: room.messages.count) { _, _ in
                // Scroll to latest message
                if let lastMessage = room.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Scroll to latest message on appear
                if let lastMessage = room.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start a conversation with \(peerDisplayName)")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Input

    private var inputView: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let text = messageText
        messageText = ""

        let result = chatManager.sendMessage(
            text: text,
            to: peerId,
            isEphemeral: isEphemeral
        )

        switch result {
        case .success(let message):
            print("✅ Message sent: \(message.id)")

        case .failure(let error):
            print("❌ Failed to send message: \(error.localizedDescription)")
            // Could show alert here
            messageText = text // Restore text on failure
        }
    }

    private func markAsRead() {
        chatManager.markAsRead(peerId: peerId)
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    let isSentByMe: Bool

    @StateObject private var ephemeralManager = EphemeralMessageManager.shared
    @State private var timeRemaining: TimeInterval?
    @State private var timer: Timer?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isSentByMe {
                Spacer()
            }

            VStack(alignment: isSentByMe ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundColor(isSentByMe ? .white : .primary)
                    .cornerRadius(16)
                    .textSelection(.enabled)

                // Metadata
                HStack(spacing: 4) {
                    // Timestamp
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Ephemeral countdown
                    if message.isEphemeral, let remaining = timeRemaining, remaining > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text("\(Int(ceil(remaining)))s")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }

                    // Delivery status (for sent messages)
                    if isSentByMe {
                        Image(systemName: message.deliveryStatus.iconName)
                            .font(.caption2)
                            .foregroundColor(statusColor)
                    }
                }
            }

            if !isSentByMe {
                Spacer()
            }
        }
        .onAppear {
            if message.isEphemeral {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var bubbleColor: Color {
        if message.isEphemeral {
            return isSentByMe ? Color.orange : Color.orange.opacity(0.2)
        }
        return isSentByMe ? Color.blue : Color(.systemGray5)
    }

    private var statusColor: Color {
        switch message.deliveryStatus {
        case .pending, .sending:
            return .gray
        case .sent, .delivered:
            return .blue
        case .read:
            return .green
        case .failed:
            return .red
        }
    }

    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateTimeRemaining()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeRemaining() {
        timeRemaining = message.timeRemainingSeconds
    }
}

// MARK: - Previews

#Preview("Empty Chat") {
    NavigationView {
        ChatRoomView(
            peerId: "peer-123",
            peerDisplayName: "Alice"
        )
        .environmentObject(AppState())
    }
}

#Preview("With Messages") {
    let appState = AppState()
    let chatManager = ChatManager.shared

    // Set my peer ID
    chatManager.setMyPeerId(appState.sessionID)

    // Create test peer
    let peer = Peer(id: "peer-123", displayName: "Alice")

    // Get or create chat room
    var room = chatManager.getChatRoom(with: peer)

    // Add test messages
    let msg1 = ChatMessage.textMessage(
        text: "Hey! How are you?",
        from: "peer-123",
        to: appState.sessionID
    )
    let msg2 = ChatMessage.textMessage(
        text: "I'm good, thanks! Just riding the train.",
        from: appState.sessionID,
        to: "peer-123"
    )
    let msg3 = ChatMessage.ephemeralMessage(
        text: "This message will disappear in 10 seconds! 👻",
        from: "peer-123",
        to: appState.sessionID
    )

    room.addMessage(msg1)
    room.addMessage(msg2)
    room.addMessage(msg3)

    return NavigationView {
        ChatRoomView(
            peerId: "peer-123",
            peerDisplayName: "Alice"
        )
        .environmentObject(appState)
    }
}
