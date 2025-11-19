package com.trainblink.app.models

import java.util.Date
import java.util.UUID

/**
 * Peer Model
 * Represents a nearby peer discovered via Nearby Connections API
 * Android equivalent of iOS Peer.swift
 */
data class Peer(
    val id: String = UUID.randomUUID().toString(),
    val displayName: String,
    val connectionState: PeerConnectionState = PeerConnectionState.NOT_CONNECTED,
    val discoveredAt: Date = Date(),
    var lastSeenAt: Date = Date(),
    var signalStrength: Double? = null,
    var metadata: Map<String, String>? = null,
    var endpointId: String? = null // Nearby Connections endpoint ID
) {
    companion object {
        val samples = listOf(
            Peer(id = "peer-1", displayName = "Alice", connectionState = PeerConnectionState.CONNECTED),
            Peer(id = "peer-2", displayName = "Bob", connectionState = PeerConnectionState.NOT_CONNECTED),
            Peer(id = "peer-3", displayName = "Charlie", connectionState = PeerConnectionState.CONNECTING)
        )
    }

    /**
     * Whether the peer is currently connected
     */
    val isConnected: Boolean
        get() = connectionState == PeerConnectionState.CONNECTED

    /**
     * Whether the peer is in the process of connecting
     */
    val isConnecting: Boolean
        get() = connectionState == PeerConnectionState.CONNECTING

    /**
     * Whether the peer can be connected to
     */
    val canConnect: Boolean
        get() = connectionState == PeerConnectionState.NOT_CONNECTED

    /**
     * How long ago the peer was last seen (in seconds)
     */
    val secondsSinceLastSeen: Long
        get() = (Date().time - lastSeenAt.time) / 1000

    /**
     * Whether the peer is considered "stale" (not seen in 60 seconds)
     */
    val isStale: Boolean
        get() = secondsSinceLastSeen > 60

    /**
     * Update last seen timestamp
     */
    fun updateLastSeen(): Peer {
        return copy(lastSeenAt = Date())
    }

    /**
     * Update connection state
     */
    fun updateConnectionState(newState: PeerConnectionState): Peer {
        return copy(connectionState = newState)
    }

    /**
     * Update signal strength
     */
    fun updateSignalStrength(strength: Double): Peer {
        return copy(signalStrength = strength)
    }
}

/**
 * Peer Connection State
 */
enum class PeerConnectionState {
    NOT_CONNECTED,
    CONNECTING,
    CONNECTED;

    val iconName: String
        get() = when (this) {
            NOT_CONNECTED -> "circle"
            CONNECTING -> "sync"
            CONNECTED -> "check_circle"
        }
}
