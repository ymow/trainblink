package com.trainblink.app.models

import java.util.Date
import java.util.UUID

/**
 * Chat Room Model
 * Represents a 1-on-1 chat room between two peers
 * Android equivalent of iOS ChatRoom.swift
 */
data class ChatRoom(
    val id: String = UUID.randomUUID().toString(),
    val peerId: String,
    val peerDisplayName: String,
    val createdAt: Date = Date(),
    var messages: List<ChatMessage> = emptyList(),
    var isActive: Boolean = true,
    var lastMessageAt: Date? = null,
    var unreadCount: Int = 0,
    var encounterCount: Int = 1
) {
    companion object {
        /**
         * Create a new chat room with a peer
         */
        fun createWith(peer: Peer, encounterCount: Int = 1): ChatRoom {
            return ChatRoom(
                peerId = peer.id,
                peerDisplayName = peer.displayName,
                createdAt = Date(),
                encounterCount = encounterCount
            )
        }
    }

    /**
     * Last message in the chat
     */
    val lastMessage: ChatMessage?
        get() = messages.lastOrNull()

    /**
     * Last message text preview
     */
    val lastMessagePreview: String
        get() = lastMessage?.preview ?: "No messages yet"

    /**
     * Time ago for last message
     */
    val lastMessageTimeAgo: String
        get() = lastMessage?.timeAgoString ?: ""

    /**
     * Whether this chat has unread messages
     */
    val hasUnreadMessages: Boolean
        get() = unreadCount > 0

    /**
     * Total message count
     */
    val messageCount: Int
        get() = messages.size

    /**
     * Add a new message to the chat
     */
    fun addMessage(message: ChatMessage): ChatRoom {
        val updatedMessages = messages + message
        val updatedUnreadCount = if (!message.isSentByMe(message.senderId) && !message.isRead) {
            unreadCount + 1
        } else {
            unreadCount
        }

        return copy(
            messages = updatedMessages,
            lastMessageAt = message.timestamp,
            unreadCount = updatedUnreadCount
        )
    }

    /**
     * Mark all messages as read
     */
    fun markAllAsRead(myId: String): ChatRoom {
        val updatedMessages = messages.map { message ->
            if (message.isReceivedByMe(myId) && !message.isRead) {
                message.markAsRead()
            } else {
                message
            }
        }

        return copy(
            messages = updatedMessages,
            unreadCount = 0
        )
    }

    /**
     * Close the chat room
     */
    fun close(): ChatRoom {
        return copy(isActive = false)
    }

    /**
     * Increment encounter count
     */
    fun incrementEncounter(): ChatRoom {
        return copy(encounterCount = encounterCount + 1)
    }
}
