package com.trainblink.app.models

import java.util.Date
import java.util.UUID

/**
 * Report Model
 * Represents a safety report submitted by user
 * Android equivalent of iOS Report.swift
 */
data class Report(
    val id: String = UUID.randomUUID().toString(),
    val reportedPeerId: String,
    val reportedDisplayName: String,
    val reason: ReportReason,
    val description: String? = null,
    val timestamp: Date = Date(),
    var status: ReportStatus = ReportStatus.PENDING,
    var contextType: ReportContextType? = null,
    var evidenceContentId: String? = null
) {
    companion object {
        /**
         * Create a report
         */
        fun create(
            peer: Peer,
            reason: ReportReason,
            description: String? = null,
            contextType: ReportContextType? = null
        ): Report {
            return Report(
                reportedPeerId = peer.id,
                reportedDisplayName = peer.displayName,
                reason = reason,
                description = description,
                contextType = contextType
            )
        }
    }

    /**
     * Mark as submitted
     */
    fun markAsSubmitted(): Report {
        return copy(status = ReportStatus.SUBMITTED)
    }

    /**
     * Mark as reviewed
     */
    fun markAsReviewed(): Report {
        return copy(status = ReportStatus.REVIEWED)
    }
}

/**
 * Report Reason
 */
enum class ReportReason {
    HARASSMENT,
    SPAM,
    INAPPROPRIATE_CONTENT,
    HATE_SPEECH,
    VIOLENCE,
    SEXUAL_CONTENT,
    IMPERSONATION,
    SCAM,
    OTHER;

    val displayName: String
        get() = when (this) {
            HARASSMENT -> "Harassment or Bullying"
            SPAM -> "Spam"
            INAPPROPRIATE_CONTENT -> "Inappropriate Content"
            HATE_SPEECH -> "Hate Speech"
            VIOLENCE -> "Violence or Threats"
            SEXUAL_CONTENT -> "Sexual Content"
            IMPERSONATION -> "Impersonation"
            SCAM -> "Scam or Fraud"
            OTHER -> "Other"
        }
}

/**
 * Report Status
 */
enum class ReportStatus {
    PENDING,
    SUBMITTED,
    REVIEWED;

    val displayName: String
        get() = when (this) {
            PENDING -> "Pending"
            SUBMITTED -> "Submitted"
            REVIEWED -> "Reviewed"
        }
}

/**
 * Report Context Type
 */
enum class ReportContextType {
    CHAT,
    CONTENT,
    DISCOVERY;

    val displayName: String
        get() = when (this) {
            CHAT -> "Chat"
            CONTENT -> "Content"
            DISCOVERY -> "Discovery"
        }
}
