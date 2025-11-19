package com.trainblink.app.analytics

import android.content.Context
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.analytics.ktx.logEvent
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.firebase.ktx.Firebase

/**
 * Analytics Manager
 * Centralized Firebase Analytics, Crashlytics, and Performance tracking
 * Android equivalent of iOS AnalyticsManager
 */
class AnalyticsManager(private val context: Context) {

    private val analytics: FirebaseAnalytics = Firebase.analytics
    private val crashlytics: FirebaseCrashlytics = FirebaseCrashlytics.getInstance()

    init {
        println("📊 AnalyticsManager initialized")
    }

    // MARK: - User Properties

    fun setUserProperty(key: String, value: String?) {
        analytics.setUserProperty(key, value)
        crashlytics.setCustomKey(key, value ?: "null")
    }

    // MARK: - Lifecycle Events

    fun logAppLaunched() {
        logEvent("app_launched", null)
        crashlytics.log("App launched")
    }

    fun logScreenView(screenName: String, screenClass: String? = null) {
        analytics.logEvent(FirebaseAnalytics.Event.SCREEN_VIEW) {
            param(FirebaseAnalytics.Param.SCREEN_NAME, screenName)
            screenClass?.let { param(FirebaseAnalytics.Param.SCREEN_CLASS, it) }
        }
    }

    // MARK: - Geofencing Events

    fun logStationEntered(stationName: String, stationType: String, stationId: String) {
        analytics.logEvent("station_entered") {
            param("station_name", stationName)
            param("station_type", stationType)
            param("station_id", stationId)
        }
        crashlytics.log("Station entered: $stationName")
        crashlytics.setCustomKey("current_station", stationName)
    }

    fun logStationExited(stationName: String, durationSeconds: Int? = null) {
        analytics.logEvent("station_exited") {
            param("station_name", stationName)
            durationSeconds?.let { param("duration_seconds", it.toLong()) }
        }
        crashlytics.log("Station exited: $stationName")
        crashlytics.setCustomKey("current_station", "none")
    }

    // MARK: - P2P Discovery Events

    fun logPeerDiscovered(peerCount: Int) {
        analytics.logEvent("peer_discovered") {
            param("peer_count", peerCount.toLong())
        }
    }

    fun logPeerConnected(encounterCount: Int) {
        analytics.logEvent("peer_connected") {
            param("encounter_count", encounterCount.toLong())
        }
        crashlytics.log("Peer connected (encounter #$encounterCount)")
    }

    // MARK: - Chat Events

    fun logChatRoomCreated(peerId: String, encounterCount: Int) {
        analytics.logEvent("chat_room_created") {
            param("peer_id", peerId.hashCode().toLong())
            param("encounter_count", encounterCount.toLong())
        }
    }

    fun logMessageSent(peerId: String, isEphemeral: Boolean, messageLength: Int) {
        analytics.logEvent("message_sent") {
            param("peer_id", peerId.hashCode().toLong())
            param("is_ephemeral", if (isEphemeral) "true" else "false")
            param("message_length", messageLength.toLong())
        }
    }

    fun logMessageReceived(peerId: String, isEphemeral: Boolean, messageLength: Int) {
        analytics.logEvent("message_received") {
            param("peer_id", peerId.hashCode().toLong())
            param("is_ephemeral", if (isEphemeral) "true" else "false")
            param("message_length", messageLength.toLong())
        }
    }

    // MARK: - Content Sharing Events

    fun logContentShared(contentType: String, fileSizeBytes: Int, peerId: String) {
        analytics.logEvent("content_shared") {
            param("content_type", contentType)
            param("file_size_bytes", fileSizeBytes.toLong())
            param("peer_id", peerId.hashCode().toLong())
        }
    }

    fun logContentReceived(contentType: String, fileSizeBytes: Int, peerId: String) {
        analytics.logEvent("content_received") {
            param("content_type", contentType)
            param("file_size_bytes", fileSizeBytes.toLong())
            param("peer_id", peerId.hashCode().toLong())
        }
    }

    // MARK: - Safety Events

    fun logPeerBlocked(reason: String) {
        analytics.logEvent("peer_blocked") {
            param("reason", reason)
        }
    }

    fun logPeerReported(reason: String) {
        analytics.logEvent("peer_reported") {
            param("reason", reason)
        }
    }

    // MARK: - Generic Event Logging

    fun logEvent(eventName: String, params: Map<String, Any?>?) {
        if (params.isNullOrEmpty()) {
            analytics.logEvent(eventName, null)
        } else {
            analytics.logEvent(eventName) {
                params.forEach { (key, value) ->
                    when (value) {
                        is String -> param(key, value)
                        is Long -> param(key, value)
                        is Int -> param(key, value.toLong())
                        is Double -> param(key, value)
                        is Boolean -> param(key, if (value) "true" else "false")
                        else -> param(key, value.toString())
                    }
                }
            }
        }
    }

    // MARK: - Error Tracking

    fun recordError(throwable: Throwable, context: Map<String, String>? = null) {
        context?.forEach { (key, value) ->
            crashlytics.setCustomKey(key, value)
        }
        crashlytics.recordException(throwable)
    }

    fun logError(message: String) {
        crashlytics.log("ERROR: $message")
    }
}
