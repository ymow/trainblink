package com.trainblink.app.managers

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date

/**
 * Chat Manager
 * Feature 5: Chat messaging system
 * Android equivalent of iOS ChatManager with SharedPreferences persistence
 */
class ChatManager(private val context: Context) {

    private val prefs = context.getSharedPreferences("trainblink_chat", Context.MODE_PRIVATE)
    private val gson = Gson()
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager
    private val blockingManager get() = TrainBlinkApplication.instance.blockingManager
    private val encounterTrackingManager get() = TrainBlinkApplication.instance.encounterTrackingManager
    private val ephemeralMessageManager get() = TrainBlinkApplication.instance.ephemeralMessageManager

    private val _chatRooms = MutableStateFlow<List<ChatRoom>>(emptyList())
    val chatRooms: StateFlow<List<ChatRoom>> = _chatRooms.asStateFlow()

    private var myPeerId: String = ""
    private var nearbyConnectionsManager: NearbyConnectionsManager? = null

    init {
        loadChatRooms()
        setupEphemeralMessageHandler()
        println("💬 ChatManager initialized - ${_chatRooms.value.size} chat rooms")
    }

    /**
     * Set my peer ID
     */
    fun setMyPeerId(peerId: String) {
        myPeerId = peerId
        println("💬 My peer ID: $peerId")
    }

    /**
     * Set Nearby Connections Manager for message delivery
     */
    fun setNearbyConnectionsManager(manager: NearbyConnectionsManager) {
        nearbyConnectionsManager = manager
        println("💬 Connected to NearbyConnectionsManager")
    }

    /**
     * Setup ephemeral message expiration handler
     */
    private fun setupEphemeralMessageHandler() {
        ephemeralMessageManager.onMessageExpired = { messageId ->
            deleteMessage(messageId)
        }
    }

    /**
     * Send a message
     */
    fun sendMessage(
        text: String,
        receiverId: String,
        isEphemeral: Boolean = false,
        expirationSeconds: Int? = null
    ): ChatMessage? {
        // Check if receiver is blocked
        if (blockingManager.isBlocked(receiverId)) {
            println("⚠️ Cannot send message to blocked peer: $receiverId")
            return null
        }

        // Create message
        val expiresAt = if (isEphemeral && expirationSeconds != null) {
            Date(System.currentTimeMillis() + expirationSeconds * 1000L)
        } else null

        val message = ChatMessage(
            text = text,
            senderId = myPeerId,
            receiverId = receiverId,
            deliveryStatus = MessageDeliveryStatus.SENDING,
            isEphemeral = isEphemeral,
            expiresAt = expiresAt
        )

        // Add to chat room
        addMessageToChatRoom(message)

        // Track ephemeral message
        if (isEphemeral) {
            ephemeralMessageManager.trackMessage(message)
        }

        // Send via Nearby Connections
        val success = sendMessageViaNearby(message)

        // Update delivery status
        val updatedMessage = if (success) {
            message.markAsDelivered()
        } else {
            message.copy(deliveryStatus = MessageDeliveryStatus.FAILED)
        }
        updateMessage(updatedMessage)

        // Record encounter
        val peerDisplayName = getChatRoom(receiverId)?.peerDisplayName ?: "Unknown"
        val peer = Peer(
            id = receiverId,
            displayName = peerDisplayName,
            connectionState = PeerConnectionState.CONNECTED,
            lastSeenAt = Date()
        )
        encounterTrackingManager.recordEncounter(
            peer = peer,
            interactionType = InteractionType.CHAT
        )

        // Log analytics
        analyticsManager.logMessageSent(
            peerId = receiverId,
            isEphemeral = isEphemeral,
            messageLength = text.length
        )

        println("💬 Message sent: ${message.id} (${if (isEphemeral) "ephemeral" else "normal"})")
        return updatedMessage
    }

    /**
     * Receive a message
     */
    fun handleReceivedMessage(data: ByteArray, from: String) {
        try {
            val message = gson.fromJson(String(data), ChatMessage::class.java)

            // Check if sender is blocked
            if (blockingManager.isBlocked(message.senderId)) {
                println("🚫 Blocked message from: ${message.senderId}")
                return
            }

            // Add to chat room
            addMessageToChatRoom(message)

            // Track ephemeral message
            if (message.isEphemeral) {
                ephemeralMessageManager.trackMessage(message)
            }

            // Record encounter
            val peer = Peer(
                id = message.senderId,
                displayName = message.senderDisplayName ?: "Unknown",
                connectionState = PeerConnectionState.CONNECTED,
                lastSeenAt = Date()
            )
            encounterTrackingManager.recordEncounter(
                peer = peer,
                interactionType = InteractionType.CHAT
            )

            // Log analytics
            analyticsManager.logMessageReceived(
                peerId = message.senderId,
                isEphemeral = message.isEphemeral,
                messageLength = message.text.length
            )

            println("💬 Message received: ${message.id} from ${message.senderId}")
        } catch (e: Exception) {
            println("❌ Failed to handle received message: ${e.message}")
        }
    }

    /**
     * Get or create chat room for a peer
     */
    fun getOrCreateChatRoom(peerId: String, peerDisplayName: String): ChatRoom {
        val existing = getChatRoom(peerId)
        if (existing != null) {
            return existing
        }

        val newRoom = ChatRoom(
            peerId = peerId,
            peerDisplayName = peerDisplayName
        )
        _chatRooms.value = _chatRooms.value + newRoom
        saveChatRooms()

        println("💬 Created chat room: $peerDisplayName")
        return newRoom
    }

    /**
     * Get chat room for a peer
     */
    fun getChatRoom(peerId: String): ChatRoom? {
        return _chatRooms.value.find { it.peerId == peerId }
    }

    /**
     * Get all messages for a peer
     */
    fun getMessages(peerId: String): List<ChatMessage> {
        return getChatRoom(peerId)?.messages ?: emptyList()
    }

    /**
     * Get sorted chat rooms (by last message)
     */
    fun getSortedChatRooms(): List<ChatRoom> {
        return _chatRooms.value.sortedByDescending {
            it.lastMessage?.timestamp?.time ?: 0
        }
    }

    /**
     * Get active chat rooms (with messages)
     */
    fun getActiveChatRooms(): List<ChatRoom> {
        return _chatRooms.value.filter { it.messages.isNotEmpty() }
    }

    /**
     * Mark chat room as read
     */
    fun markChatRoomAsRead(peerId: String) {
        val room = getChatRoom(peerId) ?: return
        val updatedRoom = room.markAsRead()
        updateChatRoom(updatedRoom)
        println("💬 Marked chat room as read: $peerId")
    }

    /**
     * Delete a message
     */
    fun deleteMessage(messageId: String) {
        _chatRooms.value = _chatRooms.value.map { room ->
            val updatedMessages = room.messages.filter { it.id != messageId }
            if (updatedMessages.size != room.messages.size) {
                room.copy(messages = updatedMessages)
            } else {
                room
            }
        }
        saveChatRooms()
        println("💬 Deleted message: $messageId")
    }

    /**
     * Delete chat room
     */
    fun deleteChatRoom(peerId: String) {
        _chatRooms.value = _chatRooms.value.filter { it.peerId != peerId }
        saveChatRooms()
        println("💬 Deleted chat room: $peerId")
    }

    /**
     * Clear all chat rooms
     */
    fun clearAllChatRooms() {
        _chatRooms.value = emptyList()
        saveChatRooms()
        println("💬 Cleared all chat rooms")
    }

    /**
     * Total unread count
     */
    fun getTotalUnreadCount(): Int {
        return _chatRooms.value.sumOf { it.unreadCount }
    }

    /**
     * Add message to chat room
     */
    private fun addMessageToChatRoom(message: ChatMessage) {
        val peerId = if (message.senderId == myPeerId) {
            message.receiverId
        } else {
            message.senderId
        }

        val room = getChatRoom(peerId)
        if (room == null) {
            val peerDisplayName = message.senderDisplayName
                ?: message.receiverDisplayName
                ?: "Unknown"
            val newRoom = ChatRoom(
                peerId = peerId,
                peerDisplayName = peerDisplayName,
                messages = listOf(message)
            )
            _chatRooms.value = _chatRooms.value + newRoom
        } else {
            val updatedMessages = room.messages + message
            val updatedRoom = room.copy(messages = updatedMessages)
            updateChatRoom(updatedRoom)
        }

        saveChatRooms()
    }

    /**
     * Update a message
     */
    private fun updateMessage(message: ChatMessage) {
        _chatRooms.value = _chatRooms.value.map { room ->
            val updatedMessages = room.messages.map {
                if (it.id == message.id) message else it
            }
            if (updatedMessages != room.messages) {
                room.copy(messages = updatedMessages)
            } else {
                room
            }
        }
        saveChatRooms()
    }

    /**
     * Update chat room
     */
    private fun updateChatRoom(chatRoom: ChatRoom) {
        _chatRooms.value = _chatRooms.value.map {
            if (it.peerId == chatRoom.peerId) chatRoom else it
        }
        saveChatRooms()
    }

    /**
     * Send message via Nearby Connections
     */
    private fun sendMessageViaNearby(message: ChatMessage): Boolean {
        val manager = nearbyConnectionsManager
        if (manager == null) {
            println("⚠️ NearbyConnectionsManager not set")
            return false
        }

        return try {
            val json = gson.toJson(message)
            val data = json.toByteArray()
            manager.sendData(data, message.receiverId)
            true
        } catch (e: Exception) {
            println("❌ Failed to send message: ${e.message}")
            false
        }
    }

    /**
     * Load chat rooms from SharedPreferences
     */
    private fun loadChatRooms() {
        val json = prefs.getString("chat_rooms", null) ?: return
        try {
            val type = object : TypeToken<List<ChatRoom>>() {}.type
            _chatRooms.value = gson.fromJson(json, type)
        } catch (e: Exception) {
            println("❌ Failed to load chat rooms: ${e.message}")
        }
    }

    /**
     * Save chat rooms to SharedPreferences
     */
    private fun saveChatRooms() {
        val json = gson.toJson(_chatRooms.value)
        prefs.edit().putString("chat_rooms", json).apply()
    }

    /**
     * Cleanup
     */
    fun cleanup() {
        ephemeralMessageManager.cleanup()
    }
}
