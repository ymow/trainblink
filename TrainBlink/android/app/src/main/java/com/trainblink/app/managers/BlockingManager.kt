package com.trainblink.app.managers

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.models.BlockReason
import com.trainblink.app.models.BlockedPeer
import com.trainblink.app.models.Peer
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Blocking Manager
 * Feature 7: Peer blocking functionality
 * Android equivalent of iOS BlockingManager with SharedPreferences persistence
 */
class BlockingManager(private val context: Context) {

    private val prefs = context.getSharedPreferences("trainblink_blocking", Context.MODE_PRIVATE)
    private val gson = Gson()
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager

    private val _blockedPeers = MutableStateFlow<List<BlockedPeer>>(emptyList())
    val blockedPeers: StateFlow<List<BlockedPeer>> = _blockedPeers.asStateFlow()

    init {
        loadBlockedPeers()
        println("🚫 BlockingManager initialized - ${_blockedPeers.value.size} blocked peers")
    }

    /**
     * Block a peer
     */
    fun blockPeer(peer: Peer, reason: BlockReason? = null): BlockedPeer {
        // Check if already blocked
        if (isBlocked(peer.id)) {
            println("⚠️ Peer already blocked: ${peer.id}")
            return _blockedPeers.value.first { it.peerId == peer.id }
        }

        val blockedPeer = BlockedPeer.block(peer, reason)
        _blockedPeers.value = _blockedPeers.value + blockedPeer
        saveBlockedPeers()

        println("🚫 Blocked peer: ${peer.displayName}")
        analyticsManager.logPeerBlocked(reason?.name ?: "NONE")

        return blockedPeer
    }

    /**
     * Unblock a peer
     */
    fun unblockPeer(peerId: String): Boolean {
        val blocked = _blockedPeers.value.find { it.peerId == peerId }
        if (blocked == null) {
            println("⚠️ Peer not blocked: $peerId")
            return false
        }

        _blockedPeers.value = _blockedPeers.value.filter { it.peerId != peerId }
        saveBlockedPeers()

        println("✅ Unblocked peer: ${blocked.displayName}")
        return true
    }

    /**
     * Check if a peer is blocked
     */
    fun isBlocked(peerId: String): Boolean {
        return _blockedPeers.value.any { it.peerId == peerId }
    }

    /**
     * Filter out blocked peers from a list
     */
    fun filterBlockedPeers(peers: List<Peer>): List<Peer> {
        return peers.filter { !isBlocked(it.id) }
    }

    /**
     * Get all blocked peers
     */
    fun getAllBlockedPeers(): List<BlockedPeer> {
        return _blockedPeers.value
    }

    private fun loadBlockedPeers() {
        val json = prefs.getString("blocked_peers", null) ?: return
        try {
            val type = object : TypeToken<List<BlockedPeer>>() {}.type
            _blockedPeers.value = gson.fromJson(json, type)
        } catch (e: Exception) {
            println("❌ Failed to load blocked peers: ${e.message}")
        }
    }

    private fun saveBlockedPeers() {
        val json = gson.toJson(_blockedPeers.value)
        prefs.edit().putString("blocked_peers", json).apply()
    }
}
