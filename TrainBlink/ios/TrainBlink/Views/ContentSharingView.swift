//
//  ContentSharingView.swift
//  TrainBlink
//
//  Feature 3: Content Sharing
//  UI for sharing and viewing content
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import SwiftUI

/// View for sharing content with peers
struct ContentSharingView: View {

    @EnvironmentObject var appState: AppState
    @State private var textInput: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedPeerId: String?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Feature 3: Content Sharing")
                .font(.headline)

            // Content creation section
            VStack(alignment: .leading, spacing: 8) {
                Text("Create Content")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Text input
                HStack {
                    TextField("Type a message...", text: $textInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send Text") {
                        createAndSendText()
                    }
                    .disabled(textInput.isEmpty || selectedPeerId == nil)
                }

                // Photo button
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Send Photo")
                    }
                }
                .disabled(selectedPeerId == nil)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            // Peer selection
            if !appState.connectedPeers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send to:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Picker("Select Peer", selection: $selectedPeerId) {
                        Text("Select a peer").tag(nil as String?)
                        ForEach(appState.connectedPeers) { peer in
                            Text(peer.displayName).tag(peer.id as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            } else {
                Text("No connected peers")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Divider()

            // Content lists
            ScrollView {
                VStack(spacing: 16) {
                    // Pending content
                    if !appState.pendingContent.isEmpty {
                        ContentListSection(
                            title: "Pending (\(appState.pendingContent.count))",
                            items: appState.pendingContent
                        )
                    }

                    // Sent content
                    if !appState.sentContent.isEmpty {
                        ContentListSection(
                            title: "Sent (\(appState.sentContent.count))",
                            items: appState.sentContent
                        )
                    }

                    // Received content
                    if !appState.receivedContent.isEmpty {
                        ContentListSection(
                            title: "Received (\(appState.receivedContent.count))",
                            items: appState.receivedContent
                        )
                    }

                    if appState.pendingContent.isEmpty &&
                       appState.sentContent.isEmpty &&
                       appState.receivedContent.isEmpty {
                        Text("No content yet")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, onImageSelected: {
                if let image = selectedImage {
                    createAndSendPhoto(image)
                }
            })
        }
    }

    // MARK: - Methods

    private func createAndSendText() {
        guard !textInput.isEmpty, let peerId = selectedPeerId else { return }

        // Create content
        let result = appState.createTextContent(text: textInput)

        switch result {
        case .success(let item):
            print("✅ Text content created: \(item.id)")
            textInput = ""

            // Review and send
            Task {
                let reviewResult = await appState.reviewContent(contentId: item.id)
                switch reviewResult {
                case .success:
                    let sendResult = await appState.sendContent(contentId: item.id, toPeerId: peerId)
                    switch sendResult {
                    case .success:
                        print("✅ Text sent successfully")
                    case .failure(let error):
                        print("❌ Failed to send: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("❌ AI review failed: \(error.localizedDescription)")
                }
            }

        case .failure(let error):
            print("❌ Failed to create text: \(error.localizedDescription)")
        }
    }

    private func createAndSendPhoto(_ image: UIImage) {
        guard let peerId = selectedPeerId else { return }

        // Create content
        let result = appState.createPhotoContent(image: image)

        switch result {
        case .success(let item):
            print("✅ Photo content created: \(item.id)")
            selectedImage = nil

            // Review and send
            Task {
                let reviewResult = await appState.reviewContent(contentId: item.id)
                switch reviewResult {
                case .success:
                    let sendResult = await appState.sendContent(contentId: item.id, toPeerId: peerId)
                    switch sendResult {
                    case .success:
                        print("✅ Photo sent successfully")
                    case .failure(let error):
                        print("❌ Failed to send: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("❌ AI review failed: \(error.localizedDescription)")
                }
            }

        case .failure(let error):
            print("❌ Failed to create photo: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views

struct ContentListSection: View {
    let title: String
    let items: [ContentItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            ForEach(items) { item in
                ContentItemRow(item: item)
            }
        }
    }
}

struct ContentItemRow: View {
    let item: ContentItem

    var body: some View {
        HStack {
            // Icon
            Image(systemName: item.iconName)
                .foregroundColor(.blue)

            // Content info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.caption)

                if item.type == .text, let text = item.textContent {
                    Text(text)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                // File size
                Text(String(format: "%.2f MB", item.fileSizeMB))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // State icon
            Image(systemName: item.stateIconName)
                .foregroundColor(stateColor(for: item.state))

            // Progress
            if item.isTransferring {
                Text("\(item.progressPercentage)%")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
    }

    private func stateColor(for state: ContentState) -> Color {
        switch state {
        case .pending, .aiReviewing:
            return .orange
        case .aiApproved:
            return .green
        case .aiRejected, .failed:
            return .red
        case .sending, .receiving:
            return .blue
        case .sent, .received:
            return .green
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            picker.dismiss(animated: true) {
                self.parent.onImageSelected()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

struct ContentSharingView_Previews: PreviewProvider {
    static var previews: some View {
        ContentSharingView()
            .environmentObject(AppState())
    }
}
