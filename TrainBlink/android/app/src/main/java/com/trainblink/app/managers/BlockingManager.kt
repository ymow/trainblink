package com.trainblink.app.managers

import android.content.Context

/**
 * Blocking Manager (Stub)
 * Android equivalent of iOS BlockingManager
 * TODO: Implement peer blocking with DataStore persistence
 */
class BlockingManager(private val context: Context) {

    init {
        println("🚫 BlockingManager initialized (stub)")
    }

    // TODO: Implement blocking functionality
    fun blockPeer(peerId: String, reason: String? = null) {
        println("🚫 Blocked peer (stub): $peerId")
    }

    fun isBlocked(peerId: String): Boolean {
        return false
    }
}
