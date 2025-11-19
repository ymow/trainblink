package com.trainblink.app.services

import android.content.Context
import android.location.Location
import com.google.android.gms.maps.model.LatLng
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.trainblink.app.models.Station
import com.trainblink.app.models.StationType

/**
 * Station Database
 * Feature 4: Station database manager
 * Provides query capabilities for Taiwan train stations (TRA, THSR, MRT)
 * Android equivalent of iOS StationDatabase
 */
class StationDatabase private constructor(private val context: Context) {

    // Singleton
    companion object {
        @Volatile
        private var instance: StationDatabase? = null

        fun getInstance(context: Context): StationDatabase {
            return instance ?: synchronized(this) {
                instance ?: StationDatabase(context.applicationContext).also { instance = it }
            }
        }

        val shared: StationDatabase
            get() = instance ?: throw IllegalStateException("StationDatabase not initialized")
    }

    // Properties
    private val _allStations = mutableListOf<Station>()
    val allStations: List<Station> get() = _allStations.toList()

    private val stationsByID = mutableMapOf<String, Station>()
    private val gson = Gson()

    init {
        loadStations()
    }

    // MARK: - Loading

    /**
     * Load stations from JSON file in assets
     */
    private fun loadStations() {
        try {
            val stations = loadStationsFromAssets()
            if (stations != null) {
                _allStations.addAll(stations)
                stations.forEach { stationsByID[it.id] = it }
                println("✅ Loaded ${_allStations.size} stations from database")
            } else {
                // Fallback to sample data
                println("⚠️ Failed to load stations from JSON, using sample data")
                loadSampleStations()
            }
        } catch (e: Exception) {
            println("❌ Failed to load stations: ${e.message}")
            loadSampleStations()
        }
    }

    /**
     * Load stations from assets/stations.json
     */
    private fun loadStationsFromAssets(): List<Station>? {
        return try {
            val json = context.assets.open("stations.json").bufferedReader().use { it.readText() }
            val type = object : TypeToken<List<StationJson>>() {}.type
            val stationJsons: List<StationJson> = gson.fromJson(json, type)

            // Convert JSON to Station model
            stationJsons.map { it.toStation() }
        } catch (e: Exception) {
            println("⚠️ stations.json not found or invalid: ${e.message}")
            null
        }
    }

    /**
     * Load sample stations for development
     */
    private fun loadSampleStations() {
        // Use sample data from Station model
        val samples = listOf(
            Station(
                id = "1001",
                name = "台北車站",
                nameEn = "Taipei",
                type = StationType.TRA,
                location = LatLng(25.0478, 121.5170),
                geofenceRadiusMeters = 500.0,
                lines = listOf("西部幹線", "東部幹線")
            ),
            Station(
                id = "2000",
                name = "台北站",
                nameEn = "Taipei",
                type = StationType.THSR,
                location = LatLng(25.0478, 121.5170),
                geofenceRadiusMeters = 500.0,
                lines = listOf("高鐵")
            ),
            Station(
                id = "1004",
                name = "板橋車站",
                nameEn = "Banqiao",
                type = StationType.TRA,
                location = LatLng(25.0141, 121.4635),
                geofenceRadiusMeters = 500.0,
                lines = listOf("西部幹線")
            )
        )
        _allStations.addAll(samples)
        samples.forEach { stationsByID[it.id] = it }
        println("✅ Loaded ${_allStations.size} sample stations")
    }

    // MARK: - Queries

    /**
     * Find station by ID
     */
    fun station(withID id: String): Station? {
        return stationsByID[id]
    }

    /**
     * Find stations by type
     */
    fun stations(ofType type: StationType): List<Station> {
        return _allStations.filter { it.type == type }
    }

    /**
     * Find station by name (fuzzy search)
     */
    fun stations(matching query: String): List<Station> {
        val lowercased = query.lowercase()
        return _allStations.filter {
            it.name.lowercase().contains(lowercased) ||
            it.nameEn.lowercase().contains(lowercased)
        }
    }

    /**
     * Find nearest station to given location
     */
    fun nearestStation(to location: Location): Station? {
        return _allStations.minByOrNull { station ->
            station.distanceFrom(location.latitude, location.longitude)
        }
    }

    /**
     * Find nearest station to given LatLng
     */
    fun nearestStation(to latLng: LatLng): Station? {
        return _allStations.minByOrNull { station ->
            station.distanceFrom(latLng.latitude, latLng.longitude)
        }
    }

    /**
     * Find all stations within radius of location
     */
    fun stations(within radius: Double, of location: Location): List<Station> {
        return _allStations
            .filter { station ->
                station.distanceFrom(location.latitude, location.longitude) <= radius
            }
            .sortedBy { station ->
                station.distanceFrom(location.latitude, location.longitude)
            }
    }

    /**
     * Find all stations within radius of LatLng
     */
    fun stations(within radius: Double, of latLng: LatLng): List<Station> {
        return _allStations
            .filter { station ->
                station.distanceFrom(latLng.latitude, latLng.longitude) <= radius
            }
            .sortedBy { station ->
                station.distanceFrom(latLng.latitude, latLng.longitude)
            }
    }

    /**
     * Find stations currently containing the location
     */
    fun stations(containing location: Location): List<Station> {
        return _allStations.filter {
            it.isWithinGeofence(location.latitude, location.longitude)
        }
    }

    /**
     * Find stations currently containing the LatLng
     */
    fun stations(containing latLng: LatLng): List<Station> {
        return _allStations.filter {
            it.isWithinGeofence(latLng.latitude, latLng.longitude)
        }
    }

    /**
     * Get top N nearest stations (for dynamic geofence monitoring)
     * Android limit: 100 geofences per app (vs iOS 20)
     */
    fun topNearestStations(to location: Location, limit: Int = 100): List<Station> {
        return _allStations
            .sortedBy { it.distanceFrom(location.latitude, location.longitude) }
            .take(limit)
    }

    /**
     * Get top N nearest stations (LatLng version)
     */
    fun topNearestStations(to latLng: LatLng, limit: Int = 100): List<Station> {
        return _allStations
            .sortedBy { it.distanceFrom(latLng.latitude, latLng.longitude) }
            .take(limit)
    }

    // MARK: - Statistics

    /**
     * Total number of stations
     */
    val totalCount: Int
        get() = _allStations.size

    /**
     * Count by type
     */
    fun count(ofType type: StationType): Int {
        return stations(ofType: type).size
    }

    /**
     * Database statistics
     */
    val statistics: String
        get() = """
            Station Database Statistics:
            - Total: $totalCount stations
            - TRA: ${count(ofType = StationType.TRA)} stations
            - THSR: ${count(ofType = StationType.THSR)} stations
            - MRT: ${count(ofType = StationType.MRT)} stations
        """.trimIndent()

    /**
     * Print statistics to console
     */
    fun printStatistics() {
        println(statistics)
    }

    // MARK: - JSON Models

    /**
     * JSON representation of station (matches iOS format)
     */
    private data class StationJson(
        val id: String,
        val name: String,
        val name_en: String,
        val lat: Double,
        val lng: Double,
        val type: String,
        val radius: Double = 500.0,
        val lines: List<String>? = null
    ) {
        fun toStation(): Station {
            val stationType = when (type.uppercase()) {
                "TRA" -> StationType.TRA
                "THSR" -> StationType.THSR
                "MRT" -> StationType.MRT
                else -> StationType.TRA
            }

            return Station(
                id = id,
                name = name,
                nameEn = name_en,
                type = stationType,
                location = LatLng(lat, lng),
                geofenceRadiusMeters = radius,
                lines = lines ?: emptyList()
            )
        }
    }
}
