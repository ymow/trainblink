package com.trainblink.app.models

import com.google.android.gms.maps.model.LatLng

/**
 * Station Model
 * Represents a train station (TRA or THSR)
 * Android equivalent of iOS Station.swift
 */
data class Station(
    val id: String,
    val name: String,
    val type: StationType,
    val location: LatLng,
    val geofenceRadiusMeters: Double = 500.0,
    val address: String? = null,
    val isActive: Boolean = true
) {
    companion object {
        // Sample TRA stations
        val taipeiMain = Station(
            id = "TRA-1000",
            name = "Taipei Main Station",
            type = StationType.TRA,
            location = LatLng(25.0478, 121.5170),
            address = "No. 3, Section 1, Zhongxiao West Road, Zhongzheng District, Taipei"
        )

        val banqiao = Station(
            id = "TRA-1020",
            name = "Banqiao Station",
            type = StationType.TRA,
            location = LatLng(25.0140, 121.4627)
        )

        val songshan = Station(
            id = "TRA-1001",
            name = "Songshan Station",
            type = StationType.TRA,
            location = LatLng(25.0494, 121.5778)
        )

        // Sample THSR stations
        val taipeiTHSR = Station(
            id = "THSR-01",
            name = "Taipei THSR Station",
            type = StationType.THSR,
            location = LatLng(25.0478, 121.5170)
        )

        val banqiaoTHSR = Station(
            id = "THSR-02",
            name = "Banqiao THSR Station",
            type = StationType.THSR,
            location = LatLng(25.0140, 121.4627)
        )

        val taichungTHSR = Station(
            id = "THSR-06",
            name = "Taichung THSR Station",
            type = StationType.THSR,
            location = LatLng(24.1129, 120.6166)
        )

        // All sample stations
        val samples = listOf(
            taipeiMain, banqiao, songshan,
            taipeiTHSR, banqiaoTHSR, taichungTHSR
        )
    }

    /**
     * Distance from given location in meters
     */
    fun distanceFrom(lat: Double, lng: Double): Double {
        val results = FloatArray(1)
        android.location.Location.distanceBetween(
            lat, lng,
            location.latitude, location.longitude,
            results
        )
        return results[0].toDouble()
    }

    /**
     * Whether a location is within geofence radius
     */
    fun isWithinGeofence(lat: Double, lng: Double): Boolean {
        return distanceFrom(lat, lng) <= geofenceRadiusMeters
    }
}

/**
 * Station Type
 */
enum class StationType(val displayName: String) {
    TRA("TRA"),
    THSR("THSR");

    companion object {
        fun fromString(value: String): StationType {
            return values().find { it.name.equals(value, ignoreCase = true) } ?: TRA
        }
    }
}
