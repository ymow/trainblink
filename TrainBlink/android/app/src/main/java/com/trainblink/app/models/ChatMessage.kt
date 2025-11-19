package com.trainblink.app.models

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

/**
 * Chat Message Model
 * Represents a chat message sent between peers
 * Android equivalent of iOS ChatMessage.swift
 */
data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val senderId: String,
    val receiverId: String,
    val timestamp: Date = Date(),
    var isEncrypted: Boolean = false,
    var isRead: Boolean = false,
    var deliveryStatus: MessageDeliveryStatus = MessageDeliveryStatus.PENDING,
    var deliveredAt: Date? = null,
    var readAt: Date? = null,
    // Ephemeral (Feature 6)
    var isEphemeral: Boolean = false,
    var expiresAt: Date? = null,
    var isExpired: Boolean = false
) {
    companion object {
        /**
         * Create a text message
         */
        fun textMessage(text: String, from: String, to: String): ChatMessage {
            return ChatMessage(
                text = text,
                senderId = from,
                receiverId = to,
                deliveryStatus = MessageDeliveryStatus.PENDING
            )
        }

        /**
         * Create an ephemeral message (auto-deletes after 10 seconds)
         */
        fun ephemeralMessage(
            text: String,
            from: String,
            to: String,
            lifetimeSeconds: Long = 10
        ): ChatMessage {
            val now = Date()
            val expiresAt = Date(now.time + lifetimeSeconds * 1000)

            return ChatMessage(
                text = text,
                senderId = from,
                receiverId = to,
                timestamp = now,
                deliveryStatus = MessageDeliveryStatus.PENDING,
                isEphemeral = true,
                expiresAt = expiresAt
            )
        }
    }

    /**
     * Whether this message was sent by me
     */
    fun isSentByMe(myId: String): Boolean = senderId == myId

    /**
     * Whether this message was received by me
     */
    fun isReceivedByMe(myId: String): Boolean = receiverId == myId

    /**
     * Time ago string (e.g., "2m ago", "1h ago")
     */
    val timeAgoString: String
        get() {
            val interval = (Date().time - timestamp.time) / 1000 // seconds

            return when {
                interval < 60 -> "Just now"
                interval < 3600 -> "${interval / 60}m ago"
                interval < 86400 -> "${interval / 3600}h ago"
                else -> "${interval / 86400}d ago"
            }
        }

    /**
     * Formatted time string
     */
    val formattedTime: String
        get() {
            val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
            return formatter.format(timestamp)
        }

    /**
     * Message preview (truncated)
     */
    val preview: String
        get() = if (text.length > 50) text.take(50) + "..." else text

    /**
     * Time remaining until message expires (in seconds)
     */
    val timeRemainingSeconds: Long?
        get() {
            if (!isEphemeral || expiresAt == null) return null
            val remaining = (expiresAt.time - Date().time) / 1000
            return if (remaining > 0) remaining else 0
        }

    /**
     * Whether the message should be deleted now
     */
    val shouldDelete: Boolean
        get() {
            if (!isEphemeral) return false
            val expiry = expiresAt ?: return false
            return Date() >= expiry || isExpired
        }

    /**
     * Countdown string for ephemeral messages (e.g., "5s")
     */
    val countdownString: String
        get() {
            val remaining = timeRemainingSeconds ?: return ""
            return "${remaining}s"
        }

    /**
     * Mark message as delivered
     */
    fun markAsDelivered(): ChatMessage {
        return copy(
            deliveryStatus = MessageDeliveryStatus.DELIVERED,
            deliveredAt = Date()
        )
    }

    /**
     * Mark message as read
     */
    fun markAsRead(): ChatMessage {
        return copy(
            isRead = true,
            readAt = Date(),
            deliveryStatus = if (deliveryStatus == MessageDeliveryStatus.DELIVERED) {
                MessageDeliveryStatus.READ
            } else {
                deliveryStatus
            }
        )
    }

    /**
     * Mark message as failed
     */
    fun markAsFailed(): ChatMessage {
        return copy(deliveryStatus = MessageDeliveryStatus.FAILED)
    }

    /**
     * Mark message as expired (for ephemeral messages)
     */
    fun markAsExpired(): ChatMessage {
        return copy(isExpired = true)
    }
}

/**
 * Message Delivery Status
 */
enum class MessageDeliveryStatus {
    PENDING,
    SENDING,
    SENT,
    DELIVERED,
    READ,
    FAILED;

    val iconName: String
        get() = when (this) {
            PENDING -> "schedule"
            SENDING -> "upload"
            SENT -> "check"
            DELIVERED -> "done_all"
            READ -> "done_all" // Could be a different color
            FAILED -> "error"
        }
}
