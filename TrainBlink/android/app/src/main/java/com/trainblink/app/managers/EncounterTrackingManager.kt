package com.trainblink.app.managers

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date

/**
 * Encounter Tracking Manager
 * Feature 8: Track repeated encounters with peers
 * Android equivalent of iOS EncounterTrackingManager
 */
class EncounterTrackingManager(private val context: Context) {

    private val prefs = context.getSharedPreferences("trainblink_encounters", Context.MODE_PRIVATE)
    private val gson = Gson()
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager

    private val _encounterHistories = MutableStateFlow<List<EncounterHistory>>(emptyList())
    val encounterHistories: StateFlow<List<EncounterHistory>> = _encounterHistories.asStateFlow()

    private var currentStation: Station? = null
    private val deduplicationWindowMillis = 5 * 60 * 1000L // 5 minutes
    private val retentionDays = 90
    private val maxEncountersPerPeer = 100

    init {
        loadEncounterHistories()
        println("📊 EncounterTrackingManager initialized - ${_encounterHistories.value.size} peer histories")
    }

    /**
     * Update current station
     */
    fun updateCurrentStation(station: Station?) {
        currentStation = station
        println("📊 Current station: ${station?.name ?: "none"}")
    }

    /**
     * Record an encounter with a peer
     */
    fun recordEncounter(
        peer: Peer,
        interactionType: InteractionType,
        station: Station? = currentStation
    ): Encounter? {
        // Check deduplication
        val history = _encounterHistories.value.find { it.peerId == peer.id }
        if (history != null) {
            val lastEncounter = history.encounters
                .filter { it.interactionType == interactionType }
                .maxByOrNull { it.timestamp }

            if (lastEncounter != null) {
                val timeSinceLast = Date().time - lastEncounter.timestamp.time
                if (timeSinceLast < deduplicationWindowMillis) {
                    println("⏭️ Skipping duplicate encounter (within 5min window)")
                    return null
                }
            }
        }

        // Create encounter
        val encounter = Encounter(
            peerId = peer.id,
            peerDisplayName = peer.displayName,
            stationId = station?.id,
            stationName = station?.name,
            interactionType = interactionType
        )

        // Update or create history
        if (history == null) {
            val newHistory = EncounterHistory(
                peerId = peer.id,
                peerDisplayName = peer.displayName,
                encounters = listOf(encounter)
            )
            _encounterHistories.value = _encounterHistories.value + newHistory
        } else {
            var updatedEncounters = history.encounters + encounter
            // Limit encounters per peer
            if (updatedEncounters.size > maxEncountersPerPeer) {
                updatedEncounters = updatedEncounters.takeLast(maxEncountersPerPeer)
            }
            val updatedHistory = history.copy(encounters = updatedEncounters)
            _encounterHistories.value = _encounterHistories.value.map {
                if (it.peerId == peer.id) updatedHistory else it
            }
        }

        saveEncounterHistories()

        println("📊 Recorded encounter: ${peer.displayName} (${interactionType.displayName})")
        
        // Log to Firebase
        val updatedHistory = _encounterHistories.value.find { it.peerId == peer.id }
        if (updatedHistory?.isFrequentEncounter == true) {
            println("🔥 Frequent encounter detected!")
        }

        return encounter
    }

    /**
     * Get encounter history for a peer
     */
    fun getHistory(peerId: String): EncounterHistory? {
        return _encounterHistories.value.find { it.peerId == peerId }
    }

    /**
     * Get all encounter histories sorted by count
     */
    fun getSortedByEncounterCount(): List<EncounterHistory> {
        return _encounterHistories.value.sortedByDescending { it.encounterCount }
    }

    /**
     * Get frequent encounters (3+ in 7 days)
     */
    fun getFrequentEncounters(): List<EncounterHistory> {
        return _encounterHistories.value.filter { it.isFrequentEncounter }
    }

    /**
     * Cleanup old encounters (90 days)
     */
    fun cleanup() {
        val cutoffDate = Date(System.currentTimeMillis() - retentionDays * 24 * 60 * 60 * 1000L)
        
        _encounterHistories.value = _encounterHistories.value.mapNotNull { history ->
            val validEncounters = history.encounters.filter { it.timestamp >= cutoffDate }
            if (validEncounters.isEmpty()) {
                null
            } else {
                history.copy(encounters = validEncounters)
            }
        }

        saveEncounterHistories()
        println("📊 Cleaned up old encounters, ${_encounterHistories.value.size} peers remaining")
    }

    private fun loadEncounterHistories() {
        val json = prefs.getString("encounter_histories", null) ?: return
        try {
            val type = object : TypeToken<List<EncounterHistory>>() {}.type
            _encounterHistories.value = gson.fromJson(json, type)
        } catch (e: Exception) {
            println("❌ Failed to load encounter histories: ${e.message}")
        }
    }

    private fun saveEncounterHistories() {
        val json = gson.toJson(_encounterHistories.value)
        prefs.edit().putString("encounter_histories", json).apply()
    }
}
