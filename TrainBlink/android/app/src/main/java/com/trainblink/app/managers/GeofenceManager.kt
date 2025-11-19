package com.trainblink.app.managers

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.geofence.GeofenceBroadcastReceiver
import com.trainblink.app.models.Station
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Geofence Manager
 * Feature 1: Geofencing System
 * Android equivalent of iOS GeofenceManager using Android Geofencing API
 */
class GeofenceManager(private val context: Context) {

    private val geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager

    // State
    private val _isInStation = MutableStateFlow(false)
    val isInStation: StateFlow<Boolean> = _isInStation.asStateFlow()

    private val _currentStation = MutableStateFlow<Station?>(null)
    val currentStation: StateFlow<Station?> = _currentStation.asStateFlow()

    // All stations to monitor (limit: 100 on Android)
    private val stationsToMonitor = Station.samples // In production, use all 34 stations

    // Pending Intent for geofence transitions
    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    init {
        println("📍 GeofenceManager initialized")
    }

    /**
     * Start monitoring geofences
     * Requires location permissions
     */
    fun startMonitoring() {
        if (!hasLocationPermission()) {
            println("❌ Location permission not granted")
            return
        }

        // Remove existing geofences
        geofencingClient.removeGeofences(geofencePendingIntent)

        // Create geofences for all stations
        val geofences = stationsToMonitor.map { station ->
            Geofence.Builder()
                .setRequestId(station.id)
                .setCircularRegion(
                    station.location.latitude,
                    station.location.longitude,
                    station.geofenceRadiusMeters.toFloat()
                )
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                .build()
        }

        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofences)
            .build()

        // Add geofences
        try {
            geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent)
                .addOnSuccessListener {
                    println("📍 Geofence monitoring started for ${geofences.size} stations")
                }
                .addOnFailureListener { e ->
                    println("❌ Failed to start geofence monitoring: ${e.message}")
                }
        } catch (e: SecurityException) {
            println("❌ SecurityException: ${e.message}")
        }
    }

    /**
     * Stop monitoring geofences
     */
    fun stopMonitoring() {
        geofencingClient.removeGeofences(geofencePendingIntent)
            .addOnSuccessListener {
                println("📍 Geofence monitoring stopped")
            }
            .addOnFailureListener { e ->
                println("❌ Failed to stop geofence monitoring: ${e.message}")
            }
    }

    /**
     * Handle station entry
     * Called from GeofenceBroadcastReceiver
     */
    fun handleStationEntry(stationId: String) {
        val station = stationsToMonitor.find { it.id == stationId }
        if (station == null) {
            println("⚠️ Unknown station: $stationId")
            return
        }

        println("🚉 Entered station: ${station.name}")
        _isInStation.value = true
        _currentStation.value = station

        // Log to Firebase Analytics
        analyticsManager.logStationEntered(
            stationName = station.name,
            stationType = station.type.name,
            stationId = station.id
        )

        // TODO: Trigger P2P discovery (will be handled by MainActivity/ViewModel)
    }

    /**
     * Handle station exit
     * Called from GeofenceBroadcastReceiver
     */
    fun handleStationExit(stationId: String) {
        val station = stationsToMonitor.find { it.id == stationId }
        if (station == null) {
            println("⚠️ Unknown station: $stationId")
            return
        }

        println("🚶 Exited station: ${station.name}")
        _isInStation.value = false
        _currentStation.value = null

        // Log to Firebase Analytics
        analyticsManager.logStationExited(stationName = station.name)

        // TODO: Stop P2P discovery, cleanup (will be handled by MainActivity/ViewModel)
    }

    /**
     * Check if location permission is granted
     */
    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Simulate station entry (for testing)
     */
    fun simulateEntry(station: Station) {
        handleStationEntry(station.id)
    }

    /**
     * Simulate station exit (for testing)
     */
    fun simulateExit(station: Station) {
        handleStationExit(station.id)
    }
}
