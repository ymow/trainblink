package com.trainblink.app.managers

import android.content.Context
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import com.trainblink.app.TrainBlinkApplication
import com.trainblink.app.models.Peer
import com.trainblink.app.models.PeerConnectionState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date

/**
 * Nearby Connections Manager
 * Feature 2: P2P connectivity using Google Nearby Connections API
 * Android equivalent of iOS MultipeerManager
 */
class NearbyConnectionsManager(private val context: Context) {

    private val connectionsClient = Nearby.getConnectionsClient(context)
    private val analyticsManager get() = TrainBlinkApplication.instance.analyticsManager
    private val encounterTrackingManager get() = TrainBlinkApplication.instance.encounterTrackingManager

    private val _discoveredPeers = MutableStateFlow<List<Peer>>(emptyList())
    val discoveredPeers: StateFlow<List<Peer>> = _discoveredPeers.asStateFlow()

    private val _connectedPeers = MutableStateFlow<List<Peer>>(emptyList())
    val connectedPeers: StateFlow<List<Peer>> = _connectedPeers.asStateFlow()

    private var myDisplayName: String = "Unknown"
    private var myPeerId: String = ""
    private var isAdvertising = false
    private var isDiscovering = false

    // Data handler callbacks
    var onDataReceived: ((ByteArray, String) -> Unit)? = null
    var onPeerConnected: ((Peer) -> Unit)? = null
    var onPeerDisconnected: ((String) -> Unit)? = null

    // Service ID must be unique to your app
    private val serviceId = "com.trainblink.app"

    init {
        println("📡 NearbyConnectionsManager initialized")
    }

    /**
     * Set my display name
     */
    fun setMyDisplayName(name: String) {
        myDisplayName = name
        println("📡 My display name: $name")
    }

    /**
     * Set my peer ID
     */
    fun setMyPeerId(peerId: String) {
        myPeerId = peerId
        println("📡 My peer ID: $peerId")
    }

    /**
     * Start advertising (server mode)
     */
    fun startAdvertising() {
        if (isAdvertising) {
            println("⚠️ Already advertising")
            return
        }

        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startAdvertising(
            myDisplayName,
            serviceId,
            connectionLifecycleCallback,
            advertisingOptions
        )
            .addOnSuccessListener {
                isAdvertising = true
                println("📡 Started advertising as: $myDisplayName")
            }
            .addOnFailureListener { e ->
                println("❌ Failed to start advertising: ${e.message}")
            }
    }

    /**
     * Start discovery (client mode)
     */
    fun startDiscovery() {
        if (isDiscovering) {
            println("⚠️ Already discovering")
            return
        }

        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startDiscovery(
            serviceId,
            endpointDiscoveryCallback,
            discoveryOptions
        )
            .addOnSuccessListener {
                isDiscovering = true
                println("📡 Started discovery")
            }
            .addOnFailureListener { e ->
                println("❌ Failed to start discovery: ${e.message}")
            }
    }

    /**
     * Stop advertising
     */
    fun stopAdvertising() {
        connectionsClient.stopAdvertising()
        isAdvertising = false
        println("📡 Stopped advertising")
    }

    /**
     * Stop discovery
     */
    fun stopDiscovery() {
        connectionsClient.stopDiscovery()
        isDiscovering = false
        println("📡 Stopped discovery")
    }

    /**
     * Stop all connections
     */
    fun stopAll() {
        connectionsClient.stopAllEndpoints()
        stopAdvertising()
        stopDiscovery()
        _discoveredPeers.value = emptyList()
        _connectedPeers.value = emptyList()
        println("📡 Stopped all connections")
    }

    /**
     * Connect to a peer
     */
    fun connectToPeer(endpointId: String) {
        connectionsClient.requestConnection(
            myDisplayName,
            endpointId,
            connectionLifecycleCallback
        )
            .addOnSuccessListener {
                println("📡 Connection requested to: $endpointId")
            }
            .addOnFailureListener { e ->
                println("❌ Failed to request connection: ${e.message}")
            }
    }

    /**
     * Disconnect from a peer
     */
    fun disconnectFromPeer(endpointId: String) {
        connectionsClient.disconnectFromEndpoint(endpointId)
        removePeer(endpointId)
        println("📡 Disconnected from: $endpointId")
    }

    /**
     * Send data to a peer
     */
    fun sendData(data: ByteArray, endpointId: String): Boolean {
        val payload = Payload.fromBytes(data)
        connectionsClient.sendPayload(endpointId, payload)
            .addOnSuccessListener {
                println("📡 Sent ${data.size} bytes to $endpointId")
            }
            .addOnFailureListener { e ->
                println("❌ Failed to send data: ${e.message}")
                return false
            }
        return true
    }

    /**
     * Broadcast data to all connected peers
     */
    fun broadcastData(data: ByteArray) {
        val endpointIds = _connectedPeers.value.mapNotNull { it.endpointId }
        if (endpointIds.isEmpty()) {
            println("⚠️ No connected peers to broadcast to")
            return
        }

        val payload = Payload.fromBytes(data)
        connectionsClient.sendPayload(endpointIds, payload)
        println("📡 Broadcasting ${data.size} bytes to ${endpointIds.size} peers")
    }

    /**
     * Get peer by endpoint ID
     */
    fun getPeer(endpointId: String): Peer? {
        return _connectedPeers.value.find { it.endpointId == endpointId }
            ?: _discoveredPeers.value.find { it.endpointId == endpointId }
    }

    // MARK: - Endpoint Discovery Callback

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            println("📡 Discovered peer: ${info.endpointName} ($endpointId)")

            val peer = Peer(
                id = endpointId,
                displayName = info.endpointName,
                connectionState = PeerConnectionState.NOT_CONNECTED,
                lastSeenAt = Date(),
                endpointId = endpointId
            )

            _discoveredPeers.value = _discoveredPeers.value.filter { it.endpointId != endpointId } + peer

            // Log analytics
            analyticsManager.logPeerDiscovered(_discoveredPeers.value.size)

            // Auto-connect (optional - can be made user-initiated)
            // connectToPeer(endpointId)
        }

        override fun onEndpointLost(endpointId: String) {
            println("📡 Lost peer: $endpointId")
            _discoveredPeers.value = _discoveredPeers.value.filter { it.endpointId != endpointId }
        }
    }

    // MARK: - Connection Lifecycle Callback

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            println("📡 Connection initiated: ${connectionInfo.endpointName} ($endpointId)")

            // Auto-accept all connections (can be made selective)
            connectionsClient.acceptConnection(endpointId, payloadCallback)

            // Update peer state
            val peer = Peer(
                id = endpointId,
                displayName = connectionInfo.endpointName,
                connectionState = PeerConnectionState.CONNECTING,
                lastSeenAt = Date(),
                endpointId = endpointId
            )
            updateOrAddPeer(peer)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            when (result.status.statusCode) {
                ConnectionsStatusCodes.STATUS_OK -> {
                    println("📡 Connected to: $endpointId")

                    // Update peer state
                    val peer = getPeer(endpointId)
                    if (peer != null) {
                        val connectedPeer = peer.copy(
                            connectionState = PeerConnectionState.CONNECTED,
                            lastSeenAt = Date()
                        )
                        updateOrAddPeer(connectedPeer)

                        // Move from discovered to connected
                        _discoveredPeers.value = _discoveredPeers.value.filter { it.endpointId != endpointId }
                        _connectedPeers.value = _connectedPeers.value.filter { it.endpointId != endpointId } + connectedPeer

                        // Record encounter
                        encounterTrackingManager.recordEncounter(
                            peer = connectedPeer,
                            interactionType = com.trainblink.app.models.InteractionType.DISCOVERY
                        )

                        // Log analytics
                        val history = encounterTrackingManager.getHistory(connectedPeer.id)
                        analyticsManager.logPeerConnected(history?.encounterCount ?: 1)

                        // Notify callback
                        onPeerConnected?.invoke(connectedPeer)
                    }
                }
                ConnectionsStatusCodes.STATUS_CONNECTION_REJECTED -> {
                    println("⚠️ Connection rejected: $endpointId")
                    removePeer(endpointId)
                }
                ConnectionsStatusCodes.STATUS_ERROR -> {
                    println("❌ Connection error: $endpointId")
                    removePeer(endpointId)
                }
            }
        }

        override fun onDisconnected(endpointId: String) {
            println("📡 Disconnected from: $endpointId")

            // Update peer state
            val peer = getPeer(endpointId)
            if (peer != null) {
                val disconnectedPeer = peer.copy(
                    connectionState = PeerConnectionState.NOT_CONNECTED
                )
                updateOrAddPeer(disconnectedPeer)

                // Move from connected to discovered
                _connectedPeers.value = _connectedPeers.value.filter { it.endpointId != endpointId }
                _discoveredPeers.value = _discoveredPeers.value + disconnectedPeer
            }

            // Notify callback
            onPeerDisconnected?.invoke(endpointId)
        }
    }

    // MARK: - Payload Callback

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val data = payload.asBytes()
                if (data != null) {
                    println("📡 Received ${data.size} bytes from $endpointId")
                    onDataReceived?.invoke(data, endpointId)
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            if (update.status == PayloadTransferUpdate.Status.SUCCESS) {
                println("📡 Payload transfer complete: $endpointId")
            } else if (update.status == PayloadTransferUpdate.Status.FAILURE) {
                println("❌ Payload transfer failed: $endpointId")
            }
        }
    }

    // MARK: - Helper Methods

    private fun updateOrAddPeer(peer: Peer) {
        val endpointId = peer.endpointId ?: return

        // Update in discovered peers
        _discoveredPeers.value = _discoveredPeers.value.map {
            if (it.endpointId == endpointId) peer else it
        }

        // Update in connected peers
        _connectedPeers.value = _connectedPeers.value.map {
            if (it.endpointId == endpointId) peer else it
        }
    }

    private fun removePeer(endpointId: String) {
        _discoveredPeers.value = _discoveredPeers.value.filter { it.endpointId != endpointId }
        _connectedPeers.value = _connectedPeers.value.filter { it.endpointId != endpointId }
    }

    /**
     * Cleanup
     */
    fun cleanup() {
        stopAll()
    }
}
