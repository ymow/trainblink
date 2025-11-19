package com.trainblink.app.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.models.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.UUID

/**
 * Main ViewModel
 * Central view model coordinating all managers and providing state to the UI
 */
class MainViewModel : ViewModel() {

    private val app = TrainBlinkApplication.instance

    // Manager references
    private val geofenceManager = app.geofenceManager
    private val nearbyConnectionsManager = app.nearbyConnectionsManager
    private val chatManager = app.chatManager
    private val contentSharingManager = app.contentSharingManager
    private val blockingManager = app.blockingManager
    private val reportingManager = app.reportingManager
    private val encounterTrackingManager = app.encounterTrackingManager
    private val analyticsManager = app.analyticsManager

    // User session
    private val sessionId = UUID.randomUUID().toString()
    private val displayName = "User${(1000..9999).random()}" // Demo: random name

    // Geofencing state
    val isInStation = geofenceManager.isInStation
    val currentStation = geofenceManager.currentStation

    // P2P state
    val discoveredPeers = nearbyConnectionsManager.discoveredPeers
    val connectedPeers = nearbyConnectionsManager.connectedPeers

    // Chat state
    val chatRooms = chatManager.chatRooms

    // Content sharing state
    val contentItems = contentSharingManager.contentItems

    // Blocking state
    val blockedPeers = blockingManager.blockedPeers

    // Encounter tracking state
    val encounterHistories = encounterTrackingManager.encounterHistories

    // UI state
    private val _isP2PActive = MutableStateFlow(false)
    val isP2PActive: StateFlow<Boolean> = _isP2PActive.asStateFlow()

    private val _statusMessage = MutableStateFlow("Welcome to TrainBlink")
    val statusMessage: StateFlow<String> = _statusMessage.asStateFlow()

    init {
        setupManagers()
        setupCallbacks()
        analyticsManager.logAppLaunched()
        println("🎯 MainViewModel initialized")
    }

    /**
     * Setup managers with user info
     */
    private fun setupManagers() {
        // Set user identities
        nearbyConnectionsManager.setMyDisplayName(displayName)
        nearbyConnectionsManager.setMyPeerId(sessionId)
        chatManager.setMyPeerId(sessionId)
        chatManager.setNearbyConnectionsManager(nearbyConnectionsManager)
        contentSharingManager.setMyPeerId(sessionId)
        contentSharingManager.setNearbyConnectionsManager(nearbyConnectionsManager)

        // Start geofencing
        geofenceManager.startMonitoring()
    }

    /**
     * Setup callbacks between managers
     */
    private fun setupCallbacks() {
        // Handle received data from P2P
        nearbyConnectionsManager.onDataReceived = { data, fromEndpointId ->
            handleReceivedData(data, fromEndpointId)
        }

        // Handle peer connection events
        nearbyConnectionsManager.onPeerConnected = { peer ->
            _statusMessage.value = "Connected to ${peer.displayName}"
        }

        nearbyConnectionsManager.onPeerDisconnected = { peerId ->
            _statusMessage.value = "Peer disconnected"
        }
    }

    /**
     * Handle received data from P2P
     */
    private fun handleReceivedData(data: ByteArray, fromEndpointId: String) {
        viewModelScope.launch {
            try {
                val dataString = String(data)

                // Try to parse as ChatMessage first
                if (dataString.contains("\"text\"") && dataString.contains("\"senderId\"")) {
                    chatManager.handleReceivedMessage(data, fromEndpointId)
                    return@launch
                }

                // Try to parse as ContentItem
                if (dataString.contains("\"type\"") && dataString.contains("\"imageData\"")) {
                    contentSharingManager.handleReceivedContent(data, fromEndpointId)
                    return@launch
                }

                println("⚠️ Unknown data type received")
            } catch (e: Exception) {
                println("❌ Error handling received data: ${e.message}")
            }
        }
    }

    // MARK: - P2P Actions

    /**
     * Start P2P (advertising + discovery)
     */
    fun startP2P() {
        nearbyConnectionsManager.startAdvertising()
        nearbyConnectionsManager.startDiscovery()
        _isP2PActive.value = true
        _statusMessage.value = "P2P active - discovering peers..."
    }

    /**
     * Stop P2P
     */
    fun stopP2P() {
        nearbyConnectionsManager.stopAll()
        _isP2PActive.value = false
        _statusMessage.value = "P2P stopped"
    }

    /**
     * Connect to a peer
     */
    fun connectToPeer(peer: Peer) {
        peer.endpointId?.let { endpointId ->
            nearbyConnectionsManager.connectToPeer(endpointId)
            _statusMessage.value = "Connecting to ${peer.displayName}..."
        }
    }

    /**
     * Disconnect from a peer
     */
    fun disconnectFromPeer(peer: Peer) {
        peer.endpointId?.let { endpointId ->
            nearbyConnectionsManager.disconnectFromPeer(endpointId)
            _statusMessage.value = "Disconnected from ${peer.displayName}"
        }
    }

    // MARK: - Chat Actions

    /**
     * Send a chat message
     */
    fun sendMessage(
        text: String,
        receiverId: String,
        isEphemeral: Boolean = false,
        expirationSeconds: Int? = null
    ) {
        viewModelScope.launch {
            chatManager.sendMessage(text, receiverId, isEphemeral, expirationSeconds)
        }
    }

    /**
     * Get or create chat room
     */
    fun getOrCreateChatRoom(peerId: String, peerDisplayName: String): ChatRoom {
        return chatManager.getOrCreateChatRoom(peerId, peerDisplayName)
    }

    /**
     * Mark chat room as read
     */
    fun markChatRoomAsRead(peerId: String) {
        chatManager.markChatRoomAsRead(peerId)
    }

    /**
     * Delete chat room
     */
    fun deleteChatRoom(peerId: String) {
        chatManager.deleteChatRoom(peerId)
    }

    /**
     * Get total unread count
     */
    fun getTotalUnreadCount(): Int {
        return chatManager.getTotalUnreadCount()
    }

    // MARK: - Content Sharing Actions

    /**
     * Create text content
     */
    fun createTextContent(text: String): ContentItem {
        return contentSharingManager.createTextContent(text)
    }

    /**
     * Create photo content
     */
    fun createPhotoContent(imageData: ByteArray, onResult: (ContentItem) -> Unit) {
        contentSharingManager.createPhotoContent(imageData, onResult)
    }

    /**
     * Send content to peer
     */
    fun sendContent(contentItem: ContentItem, recipientId: String) {
        contentSharingManager.sendContent(contentItem, recipientId)
    }

    /**
     * Delete content
     */
    fun deleteContent(contentId: String) {
        contentSharingManager.deleteContent(contentId)
    }

    // MARK: - Blocking Actions

    /**
     * Block a peer
     */
    fun blockPeer(peer: Peer, reason: BlockReason? = null) {
        blockingManager.blockPeer(peer, reason)
        // Disconnect if connected
        peer.endpointId?.let { nearbyConnectionsManager.disconnectFromPeer(it) }
        _statusMessage.value = "Blocked ${peer.displayName}"
    }

    /**
     * Unblock a peer
     */
    fun unblockPeer(peerId: String) {
        if (blockingManager.unblockPeer(peerId)) {
            _statusMessage.value = "Peer unblocked"
        }
    }

    /**
     * Check if peer is blocked
     */
    fun isBlocked(peerId: String): Boolean {
        return blockingManager.isBlocked(peerId)
    }

    // MARK: - Reporting Actions

    /**
     * Report a peer
     */
    fun reportPeer(
        peer: Peer,
        reason: ReportReason,
        description: String? = null,
        contextType: ReportContextType? = null
    ) {
        viewModelScope.launch {
            val result = reportingManager.reportPeer(peer, reason, description, contextType)
            when (result) {
                is Result.Success -> {
                    _statusMessage.value = "Report submitted"
                }
                is Result.Failure -> {
                    _statusMessage.value = "Report failed: ${result.error}"
                }
            }
        }
    }

    // MARK: - Encounter Tracking

    /**
     * Get encounter history for a peer
     */
    fun getEncounterHistory(peerId: String): EncounterHistory? {
        return encounterTrackingManager.getHistory(peerId)
    }

    /**
     * Get frequent encounters
     */
    fun getFrequentEncounters(): List<EncounterHistory> {
        return encounterTrackingManager.getFrequentEncounters()
    }

    /**
     * Get sorted encounter histories
     */
    fun getSortedEncounterHistories(): List<EncounterHistory> {
        return encounterTrackingManager.getSortedByEncounterCount()
    }

    // MARK: - Lifecycle

    override fun onCleared() {
        super.onCleared()
        stopP2P()
        chatManager.cleanup()
        contentSharingManager.cleanup()
        nearbyConnectionsManager.cleanup()
        println("🎯 MainViewModel cleared")
    }
}

/**
 * Result sealed class for operations
 */
sealed class Result<out T, out E> {
    data class Success<T>(val value: T) : Result<T, Nothing>()
    data class Failure<E>(val error: E) : Result<Nothing, E>()
}
