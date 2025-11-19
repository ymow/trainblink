package com.trainblink.app.managers

import android.content.Context

/**
 * Chat Manager (Stub)
 * Android equivalent of iOS ChatManager
 * TODO: Implement full chat functionality with DataStore persistence
 */
class ChatManager(private val context: Context) {

    init {
        println("💬 ChatManager initialized (stub)")
    }

    // TODO: Implement chat functionality
    fun sendMessage(text: String, to: String, isEphemeral: Boolean = false) {
        println("💬 Sending message (stub): $text")
    }
}
