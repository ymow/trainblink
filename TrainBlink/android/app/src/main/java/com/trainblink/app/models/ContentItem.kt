package com.trainblink.app.models

import android.graphics.Bitmap
import java.util.Date
import java.util.UUID

/**
 * Content Item Model
 * Represents shareable content (photos, text)
 * Android equivalent of iOS ContentItem.swift
 */
data class ContentItem(
    val id: String = UUID.randomUUID().toString(),
    val type: ContentType,
    var state: ContentState = ContentState.PENDING,
    val createdAt: Date = Date(),
    var textContent: String? = null,
    var imageData: ByteArray? = null,
    var originalImageSize: Int? = null,
    var compressedImageSize: Int? = null,
    var fileSize: Int = 0,
    var progress: Double = 0.0,
    var aiReviewedAt: Date? = null,
    var aiRejectionReason: AIRejectionReason? = null,
    val senderId: String,
    var recipientId: String? = null
) {
    companion object {
        /**
         * Create a text content item
         */
        fun textContent(text: String, senderId: String): ContentItem {
            return ContentItem(
                type = ContentType.TEXT,
                textContent = text,
                fileSize = text.toByteArray().size,
                senderId = senderId
            )
        }

        /**
         * Create a photo content item
         */
        fun photoContent(imageData: ByteArray, senderId: String): ContentItem {
            return ContentItem(
                type = ContentType.PHOTO,
                imageData = imageData,
                fileSize = imageData.size,
                originalImageSize = imageData.size,
                senderId = senderId
            )
        }
    }

    /**
     * Update state
     */
    fun updateState(newState: ContentState): ContentItem {
        return copy(state = newState)
    }

    /**
     * Update progress
     */
    fun updateProgress(newProgress: Double): ContentItem {
        return copy(progress = newProgress)
    }

    /**
     * Approve by AI
     */
    fun approveByAI(confidence: Double): ContentItem {
        return copy(
            state = ContentState.APPROVED,
            aiReviewedAt = Date()
        )
    }

    /**
     * Reject by AI
     */
    fun rejectByAI(reason: AIRejectionReason): ContentItem {
        return copy(
            state = ContentState.REJECTED,
            aiReviewedAt = Date(),
            aiRejectionReason = reason
        )
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ContentItem) return false
        return id == other.id
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }
}

/**
 * Content Type
 */
enum class ContentType {
    PHOTO,
    TEXT;

    val displayName: String
        get() = when (this) {
            PHOTO -> "Photo"
            TEXT -> "Text"
        }
}

/**
 * Content State
 */
enum class ContentState {
    PENDING,
    REVIEWING,
    APPROVED,
    REJECTED,
    SENDING,
    SENT,
    FAILED;

    val iconName: String
        get() = when (this) {
            PENDING -> "schedule"
            REVIEWING -> "psychology"
            APPROVED -> "check_circle"
            REJECTED -> "cancel"
            SENDING -> "upload"
            SENT -> "done"
            FAILED -> "error"
        }
}

/**
 * AI Rejection Reason
 */
enum class AIRejectionReason {
    NSFW,
    FACE_DETECTED,
    INAPPROPRIATE;

    val displayMessage: String
        get() = when (this) {
            NSFW -> "Content flagged as inappropriate"
            FACE_DETECTED -> "Faces detected in image"
            INAPPROPRIATE -> "Content violates guidelines"
        }
}
