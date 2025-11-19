package com.trainblink.app.models

import java.util.Date
import java.util.UUID

/**
 * Blocked Peer Model
 * Represents a blocked peer
 * Android equivalent of iOS BlockedPeer.swift
 */
data class BlockedPeer(
    val id: String = UUID.randomUUID().toString(),
    val peerId: String,
    val displayName: String,
    val blockedAt: Date = Date(),
    var reason: BlockReason? = null
) {
    companion object {
        /**
         * Block a peer
         */
        fun block(peer: Peer, reason: BlockReason? = null): BlockedPeer {
            return BlockedPeer(
                peerId = peer.id,
                displayName = peer.displayName,
                reason = reason
            )
        }
    }
}

/**
 * Block Reason
 */
enum class BlockReason {
    HARASSMENT,
    SPAM,
    INAPPROPRIATE_CONTENT,
    FAKE,
    OTHER;

    val displayName: String
        get() = when (this) {
            HARASSMENT -> "Harassment"
            SPAM -> "Spam"
            INAPPROPRIATE_CONTENT -> "Inappropriate Content"
            FAKE -> "Fake Profile"
            OTHER -> "Other"
        }
}
