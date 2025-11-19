package com.trainblink.app.managers

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.google.gson.Gson
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.models.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.ByteArrayOutputStream

/**
 * Content Sharing Manager
 * Feature 3: Content sharing with AI review
 * Android equivalent of iOS ContentSharingManager using ML Kit
 */
class ContentSharingManager(private val context: Context) {

    private val gson = Gson()
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager
    private val encounterTrackingManager get() = TrainBlinkApplication.instance.encounterTrackingManager

    private val _contentItems = MutableStateFlow<List<ContentItem>>(emptyList())
    val contentItems: StateFlow<List<ContentItem>> = _contentItems.asStateFlow()

    private var myPeerId: String = ""
    private var nearbyConnectionsManager: NearbyConnectionsManager? = null

    // ML Kit detectors
    private val faceDetector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .build()
    )
    private val imageLabeler = ImageLabeling.getClient(ImageLabelerOptions.DEFAULT)

    init {
        println("📤 ContentSharingManager initialized")
    }

    /**
     * Set my peer ID
     */
    fun setMyPeerId(peerId: String) {
        myPeerId = peerId
    }

    /**
     * Set Nearby Connections Manager
     */
    fun setNearbyConnectionsManager(manager: NearbyConnectionsManager) {
        nearbyConnectionsManager = manager
    }

    /**
     * Create text content
     */
    fun createTextContent(text: String): ContentItem {
        val contentItem = ContentItem.textContent(text, myPeerId)
        _contentItems.value = _contentItems.value + contentItem

        // Text content auto-approved
        val approved = contentItem.approveByAI(1.0)
        updateContentItem(approved)

        println("📤 Created text content: ${contentItem.id}")
        return approved
    }

    /**
     * Create photo content
     */
    fun createPhotoContent(imageData: ByteArray, onResult: (ContentItem) -> Unit) {
        val contentItem = ContentItem.photoContent(imageData, myPeerId)
        _contentItems.value = _contentItems.value + contentItem

        println("📤 Created photo content: ${contentItem.id}")

        // Review with AI
        reviewContent(contentItem) { reviewedItem ->
            onResult(reviewedItem)
        }
    }

    /**
     * Send content to peer
     */
    fun sendContent(contentItem: ContentItem, recipientId: String) {
        if (contentItem.state != ContentState.APPROVED) {
            println("⚠️ Cannot send unapproved content")
            return
        }

        // Update state
        val sending = contentItem.copy(
            recipientId = recipientId,
            state = ContentState.SENDING,
            progress = 0.0
        )
        updateContentItem(sending)

        // Send via Nearby Connections
        scope.launch {
            val success = sendContentViaNearby(sending)

            val finalItem = if (success) {
                sending.copy(state = ContentState.SENT, progress = 1.0)
            } else {
                sending.copy(state = ContentState.FAILED, progress = 0.0)
            }
            updateContentItem(finalItem)

            // Record encounter
            if (success) {
                val peer = Peer(
                    id = recipientId,
                    displayName = "Unknown",
                    connectionState = PeerConnectionState.CONNECTED,
                    lastSeenAt = java.util.Date()
                )
                encounterTrackingManager.recordEncounter(
                    peer = peer,
                    interactionType = InteractionType.CONTENT_SHARING
                )

                // Log analytics
                analyticsManager.logContentShared(
                    contentType = finalItem.type.displayName,
                    fileSizeBytes = finalItem.fileSize,
                    peerId = recipientId
                )
            }

            println("📤 Content ${if (success) "sent" else "failed"}: ${finalItem.id}")
        }
    }

    /**
     * Handle received content
     */
    fun handleReceivedContent(data: ByteArray, from: String) {
        try {
            val contentItem = gson.fromJson(String(data), ContentItem::class.java)
            _contentItems.value = _contentItems.value + contentItem

            println("📥 Content received: ${contentItem.id} from $from")

            // Record encounter
            val peer = Peer(
                id = from,
                displayName = "Unknown",
                connectionState = PeerConnectionState.CONNECTED,
                lastSeenAt = java.util.Date()
            )
            encounterTrackingManager.recordEncounter(
                peer = peer,
                interactionType = InteractionType.CONTENT_SHARING
            )

            // Log analytics
            analyticsManager.logContentReceived(
                contentType = contentItem.type.displayName,
                fileSizeBytes = contentItem.fileSize,
                peerId = from
            )
        } catch (e: Exception) {
            println("❌ Failed to handle received content: ${e.message}")
        }
    }

    /**
     * Get content by ID
     */
    fun getContent(contentId: String): ContentItem? {
        return _contentItems.value.find { it.id == contentId }
    }

    /**
     * Get sent content
     */
    fun getSentContent(): List<ContentItem> {
        return _contentItems.value.filter {
            it.senderId == myPeerId && it.state == ContentState.SENT
        }
    }

    /**
     * Get received content
     */
    fun getReceivedContent(): List<ContentItem> {
        return _contentItems.value.filter {
            it.senderId != myPeerId
        }
    }

    /**
     * Delete content
     */
    fun deleteContent(contentId: String) {
        _contentItems.value = _contentItems.value.filter { it.id != contentId }
        println("📤 Deleted content: $contentId")
    }

    /**
     * Review content with AI
     */
    private fun reviewContent(contentItem: ContentItem, onResult: (ContentItem) -> Unit) {
        val reviewing = contentItem.updateState(ContentState.REVIEWING)
        updateContentItem(reviewing)

        scope.launch {
            try {
                val imageData = contentItem.imageData ?: run {
                    onResult(reviewing.rejectByAI(AIRejectionReason.INAPPROPRIATE))
                    return@launch
                }

                val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
                val inputImage = InputImage.fromBitmap(bitmap, 0)

                // Check for faces
                val faceResult = faceDetector.process(inputImage).await()
                if (faceResult.isNotEmpty()) {
                    val rejected = reviewing.rejectByAI(AIRejectionReason.FACE_DETECTED)
                    updateContentItem(rejected)
                    onResult(rejected)
                    println("🚫 Content rejected: face detected")
                    return@launch
                }

                // Check for inappropriate content
                val labelResult = imageLabeler.process(inputImage).await()
                val inappropriateLabels = listOf("violence", "weapon", "blood", "nudity")
                val hasInappropriate = labelResult.any { label ->
                    inappropriateLabels.any { label.text.contains(it, ignoreCase = true) }
                }

                if (hasInappropriate) {
                    val rejected = reviewing.rejectByAI(AIRejectionReason.NSFW)
                    updateContentItem(rejected)
                    onResult(rejected)
                    println("🚫 Content rejected: inappropriate")
                    return@launch
                }

                // Approved
                val approved = reviewing.approveByAI(0.9)
                updateContentItem(approved)
                onResult(approved)
                println("✅ Content approved")

            } catch (e: Exception) {
                println("❌ AI review failed: ${e.message}")
                val rejected = reviewing.rejectByAI(AIRejectionReason.INAPPROPRIATE)
                updateContentItem(rejected)
                onResult(rejected)
            }
        }
    }

    /**
     * Send content via Nearby Connections
     */
    private suspend fun sendContentViaNearby(contentItem: ContentItem): Boolean {
        return withContext(Dispatchers.IO) {
            val manager = nearbyConnectionsManager
            if (manager == null) {
                println("⚠️ NearbyConnectionsManager not set")
                return@withContext false
            }

            try {
                val json = gson.toJson(contentItem)
                val data = json.toByteArray()

                // Simulate progress updates
                for (i in 1..10) {
                    delay(100)
                    val progress = i / 10.0
                    val updated = contentItem.updateProgress(progress)
                    updateContentItem(updated)
                }

                manager.sendData(data, contentItem.recipientId ?: "")
                true
            } catch (e: Exception) {
                println("❌ Failed to send content: ${e.message}")
                false
            }
        }
    }

    /**
     * Update content item
     */
    private fun updateContentItem(contentItem: ContentItem) {
        _contentItems.value = _contentItems.value.map {
            if (it.id == contentItem.id) contentItem else it
        }
    }

    /**
     * Cleanup
     */
    fun cleanup() {
        scope.cancel()
    }
}
