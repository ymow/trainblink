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
 * Reporting Manager
 * Feature 7: Safety reporting functionality
 * Android equivalent of iOS ReportingManager with SharedPreferences persistence
 */
class ReportingManager(private val context: Context) {

    private val prefs = context.getSharedPreferences("trainblink_reporting", Context.MODE_PRIVATE)
    private val gson = Gson()
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager

    private val _reports = MutableStateFlow<List<Report>>(emptyList())
    val reports: StateFlow<List<Report>> = _reports.asStateFlow()

    private val cooldownMillis = 5 * 60 * 1000L // 5 minutes
    private val maxReportsPerPeer = 10

    init {
        loadReports()
        println("📝 ReportingManager initialized - ${_reports.value.size} reports")
    }

    /**
     * Report a peer
     */
    fun reportPeer(
        peer: Peer,
        reason: ReportReason,
        description: String? = null,
        contextType: ReportContextType? = null
    ): Result<Report, String> {
        // Check cooldown
        val lastReport = _reports.value
            .filter { it.reportedPeerId == peer.id }
            .maxByOrNull { it.timestamp }

        if (lastReport != null) {
            val timeSinceLastReport = Date().time - lastReport.timestamp.time
            if (timeSinceLastReport < cooldownMillis) {
                val remaining = (cooldownMillis - timeSinceLastReport) / 1000
                return Result.failure("Please wait ${remaining}s before reporting again")
            }
        }

        // Check max reports per peer
        val reportsForPeer = _reports.value.count { it.reportedPeerId == peer.id }
        if (reportsForPeer >= maxReportsPerPeer) {
            return Result.failure("Maximum reports reached for this peer")
        }

        val report = Report.create(peer, reason, description, contextType)
        _reports.value = _reports.value + report
        saveReports()

        println("📝 Reported peer: ${peer.displayName} for ${reason.displayName}")
        analyticsManager.logPeerReported(reason.name)

        return Result.success(report)
    }

    /**
     * Get all reports
     */
    fun getAllReports(): List<Report> {
        return _reports.value
    }

    /**
     * Get reports for a specific peer
     */
    fun getReportsForPeer(peerId: String): List<Report> {
        return _reports.value.filter { it.reportedPeerId == peerId }
    }

    private fun loadReports() {
        val json = prefs.getString("reports", null) ?: return
        try {
            val type = object : TypeToken<List<Report>>() {}.type
            _reports.value = gson.fromJson(json, type)
        } catch (e: Exception) {
            println("❌ Failed to load reports: ${e.message}")
        }
    }

    private fun saveReports() {
        val json = gson.toJson(_reports.value)
        prefs.edit().putString("reports", json).apply()
    }
}
