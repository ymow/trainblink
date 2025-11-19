package com.trainblink.app.models

import java.util.Date
import java.util.UUID

/**
 * Encounter Model
 * Represents a single encounter with a peer
 * Android equivalent of iOS Encounter.swift
 */
data class Encounter(
    val id: String = UUID.randomUUID().toString(),
    val peerId: String,
    val peerDisplayName: String,
    val timestamp: Date = Date(),
    val stationId: String? = null,
    val stationName: String? = null,
    var interactionType: InteractionType = InteractionType.DISCOVERY
) {
    companion object {
        /**
         * Create a discovery encounter
         */
        fun discovery(peer: Peer, station: Station?): Encounter {
            return Encounter(
                peerId = peer.id,
                peerDisplayName = peer.displayName,
                stationId = station?.id,
                stationName = station?.name,
                interactionType = InteractionType.DISCOVERY
            )
        }

        /**
         * Create a content sharing encounter
         */
        fun contentSharing(peerId: String, peerDisplayName: String, station: Station?): Encounter {
            return Encounter(
                peerId = peerId,
                peerDisplayName = peerDisplayName,
                stationId = station?.id,
                stationName = station?.name,
                interactionType = InteractionType.CONTENT_SHARING
            )
        }

        /**
         * Create a chat encounter
         */
        fun chat(peerId: String, peerDisplayName: String, station: Station?): Encounter {
            return Encounter(
                peerId = peerId,
                peerDisplayName = peerDisplayName,
                stationId = station?.id,
                stationName = station?.name,
                interactionType = InteractionType.CHAT
            )
        }
    }
}

/**
 * Encounter History Model
 * Aggregates all encounters with a specific peer
 * Android equivalent of iOS EncounterHistory.swift
 */
data class EncounterHistory(
    val id: String = UUID.randomUUID().toString(),
    val peerId: String,
    val peerDisplayName: String,
    var encounters: List<Encounter> = emptyList()
) {
    /**
     * Total encounter count
     */
    val encounterCount: Int
        get() = encounters.size

    /**
     * First encounter
     */
    val firstEncounter: Encounter?
        get() = encounters.minByOrNull { it.timestamp }

    /**
     * Last encounter
     */
    val lastEncounter: Encounter?
        get() = encounters.maxByOrNull { it.timestamp }

    /**
     * Most common station
     */
    val mostCommonStation: Triple<String, String, Int>?
        get() {
            val stationCounts = encounters
                .filter { it.stationId != null && it.stationName != null }
                .groupBy { it.stationId!! to it.stationName!! }
                .mapValues { it.value.size }

            val mostCommon = stationCounts.maxByOrNull { it.value }
            return mostCommon?.let { (station, count) ->
                Triple(station.first, station.second, count)
            }
        }

    /**
     * Station breakdown
     */
    val stationBreakdown: List<Triple<String, String, Int>>
        get() {
            return encounters
                .filter { it.stationId != null && it.stationName != null }
                .groupBy { it.stationId!! to it.stationName!! }
                .mapValues { it.value.size }
                .map { (station, count) -> Triple(station.first, station.second, count) }
                .sortedByDescending { it.third }
        }

    /**
     * Interaction type breakdown
     */
    val interactionTypeBreakdown: Map<InteractionType, Int>
        get() = encounters.groupingBy { it.interactionType }.eachCount()

    /**
     * Recent encounters (last 7 days)
     */
    val recentEncounters: List<Encounter>
        get() {
            val sevenDaysAgo = Date(System.currentTimeMillis() - 7 * 24 * 60 * 60 * 1000)
            return encounters.filter { it.timestamp >= sevenDaysAgo }
        }

    /**
     * Whether this is a frequent encounter (3+ in 7 days)
     */
    val isFrequentEncounter: Boolean
        get() = recentEncounters.size >= 3

    /**
     * Frequency label
     */
    val frequencyLabel: String
        get() {
            val recent = recentEncounters.size
            return when {
                recent >= 7 -> "Daily"
                recent >= 3 -> "Frequent"
                recent >= 1 -> "Weekly"
                encounterCount >= 5 -> "Occasional"
                else -> "Rare"
            }
        }

    /**
     * Summary string
     */
    val summary: String
        get() {
            val station = mostCommonStation
            return if (station != null) {
                "Met $encounterCount times, mostly at ${station.second}"
            } else {
                "Met $encounterCount times"
            }
        }

    /**
     * Add encounter
     */
    fun addEncounter(encounter: Encounter): EncounterHistory {
        return copy(encounters = encounters + encounter)
    }
}

/**
 * Interaction Type
 */
enum class InteractionType {
    DISCOVERY,
    CONTENT_SHARING,
    CHAT,
    CONNECTION;

    val displayName: String
        get() = when (this) {
            DISCOVERY -> "Discovery"
            CONTENT_SHARING -> "Content Sharing"
            CHAT -> "Chat"
            CONNECTION -> "Connection"
        }
}
