package com.trainblink.app.geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import com.trainblink.app.TrainBlinkApplication

/**
 * Geofence Broadcast Receiver
 * Receives geofence transition events from Android Geofencing API
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)

        if (geofencingEvent == null) {
            println("❌ GeofencingEvent is null")
            return
        }

        if (geofencingEvent.hasError()) {
            println("❌ Geofencing error: ${geofencingEvent.errorCode}")
            return
        }

        // Get the transition type
        val geofenceTransition = geofencingEvent.geofenceTransition

        // Get triggered geofences
        val triggeringGeofences = geofencingEvent.triggeringGeofences

        if (triggeringGeofences.isNullOrEmpty()) {
            println("⚠️ No triggering geofences")
            return
        }

        // Get the geofence manager
        val geofenceManager = TrainBlinkApplication.instance.geofenceManager

        // Handle transition
        when (geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> {
                triggeringGeofences.forEach { geofence ->
                    println("📍 Geofence ENTER: ${geofence.requestId}")
                    geofenceManager.handleStationEntry(geofence.requestId)
                }
            }
            Geofence.GEOFENCE_TRANSITION_EXIT -> {
                triggeringGeofences.forEach { geofence ->
                    println("📍 Geofence EXIT: ${geofence.requestId}")
                    geofenceManager.handleStationExit(geofence.requestId)
                }
            }
            else -> {
                println("⚠️ Unknown geofence transition: $geofenceTransition")
            }
        }
    }
}
