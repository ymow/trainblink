package com.trainblink.app.managers

import android.content.Context
import com.trainblink.app.models.ChatMessage
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap

/**
 * Ephemeral Message Manager
 * Feature 6: Auto-delete messages after expiration
 * Android equivalent of iOS EphemeralMessageManager using Kotlin Coroutines
 */
class EphemeralMessageManager(private val context: Context) {

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val trackedMessages = ConcurrentHashMap<String, Job>()
    
    var onMessageExpired: ((String) -> Unit)? = null

    init {
        println("⏱️ EphemeralMessageManager initialized")
    }

    /**
     * Track an ephemeral message
     */
    fun trackMessage(message: ChatMessage) {
        if (!message.isEphemeral) return
        
        val expiresAt = message.expiresAt ?: return
        val delay = expiresAt.time - System.currentTimeMillis()
        
        if (delay <= 0) {
            // Already expired
            onMessageExpired?.invoke(message.id)
            return
        }

        // Cancel existing job if any
        trackedMessages[message.id]?.cancel()

        // Schedule deletion
        val job = scope.launch {
            delay(delay)
            onMessageExpired?.invoke(message.id)
            trackedMessages.remove(message.id)
            println("⏱️ Message expired: ${message.id}")
        }

        trackedMessages[message.id] = job
        println("⏱️ Tracking ephemeral message: ${message.id}, expires in ${delay}ms")
    }

    /**
     * Stop tracking a message
     */
    fun stopTracking(messageId: String) {
        trackedMessages[messageId]?.cancel()
        trackedMessages.remove(messageId)
    }

    /**
     * Time remaining for a message (in seconds)
     */
    fun timeRemaining(messageId: String): Long? {
        // This would need to be calculated from the message's expiresAt
        return null
    }

    /**
     * Cleanup all tracked messages
     */
    fun cleanup() {
        trackedMessages.values.forEach { it.cancel() }
        trackedMessages.clear()
        scope.cancel()
    }
}
