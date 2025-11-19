package com.trainblink.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.trainblink.app.viewmodels.MainViewModel

/**
 * Main Screen
 * Root screen with bottom navigation tabs
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(viewModel: MainViewModel = viewModel()) {
    var selectedTab by remember { mutableIntStateOf(0) }

    val tabs = listOf(
        TabItem("Nearby", Icons.Default.Radar),
        TabItem("Chat", Icons.Default.Chat),
        TabItem("Content", Icons.Default.Photo),
        TabItem("Settings", Icons.Default.Settings)
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("🚄 TrainBlink") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        },
        bottomBar = {
            NavigationBar {
                tabs.forEachIndexed { index, tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                        selected = selectedTab == index,
                        onClick = { selectedTab = index }
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when (selectedTab) {
                0 -> NearbyScreen(viewModel)
                1 -> ChatListScreen(viewModel)
                2 -> ContentScreen(viewModel)
                3 -> SettingsScreen(viewModel)
            }
        }
    }
}

/**
 * Tab item data class
 */
private data class TabItem(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
)

/**
 * Nearby Screen (P2P Discovery)
 */
@Composable
fun NearbyScreen(viewModel: MainViewModel) {
    val isP2PActive by viewModel.isP2PActive.collectAsState()
    val statusMessage by viewModel.statusMessage.collectAsState()
    val isInStation by viewModel.isInStation.collectAsState()
    val currentStation by viewModel.currentStation.collectAsState()
    val discoveredPeers by viewModel.discoveredPeers.collectAsState()
    val connectedPeers by viewModel.connectedPeers.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Station Status
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = if (isInStation) {
                    MaterialTheme.colorScheme.primaryContainer
                } else {
                    MaterialTheme.colorScheme.surfaceVariant
                }
            )
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = if (isInStation) "📍 At Station" else "🚶 Not at Station",
                    style = MaterialTheme.typography.titleMedium
                )
                if (currentStation != null) {
                    Text(
                        text = currentStation!!.name,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // P2P Control
        Button(
            onClick = {
                if (isP2PActive) viewModel.stopP2P() else viewModel.startP2P()
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (isP2PActive) "Stop P2P" else "Start P2P")
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Status Message
        Text(
            text = statusMessage,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.secondary
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Connected Peers
        if (connectedPeers.isNotEmpty()) {
            Text(
                text = "Connected (${connectedPeers.size})",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(8.dp))
            connectedPeers.forEach { peer ->
                PeerCard(
                    peer = peer,
                    isConnected = true,
                    onConnect = {},
                    onDisconnect = { viewModel.disconnectFromPeer(peer) },
                    onBlock = { viewModel.blockPeer(peer) }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }

        // Discovered Peers
        if (discoveredPeers.isNotEmpty()) {
            Text(
                text = "Discovered (${discoveredPeers.size})",
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(modifier = Modifier.height(8.dp))
            discoveredPeers.forEach { peer ->
                PeerCard(
                    peer = peer,
                    isConnected = false,
                    onConnect = { viewModel.connectToPeer(peer) },
                    onDisconnect = {},
                    onBlock = { viewModel.blockPeer(peer) }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

/**
 * Peer Card Component
 */
@Composable
fun PeerCard(
    peer: com.trainblink.app.models.Peer,
    isConnected: Boolean,
    onConnect: () -> Unit,
    onDisconnect: () -> Unit,
    onBlock: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = peer.displayName,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = peer.connectionState.name,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.secondary
                )
            }

            Row {
                if (isConnected) {
                    IconButton(onClick = onDisconnect) {
                        Icon(Icons.Default.Close, contentDescription = "Disconnect")
                    }
                } else {
                    IconButton(onClick = onConnect) {
                        Icon(Icons.Default.Add, contentDescription = "Connect")
                    }
                }
                IconButton(onClick = onBlock) {
                    Icon(Icons.Default.Block, contentDescription = "Block")
                }
            }
        }
    }
}

/**
 * Chat List Screen (stub)
 */
@Composable
fun ChatListScreen(viewModel: MainViewModel) {
    val chatRooms by viewModel.chatRooms.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "Chat Rooms (${chatRooms.size})",
            style = MaterialTheme.typography.titleLarge
        )

        Spacer(modifier = Modifier.height(16.dp))

        if (chatRooms.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No conversations yet",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.secondary
                )
            }
        } else {
            chatRooms.forEach { room ->
                ChatRoomCard(room = room)
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

/**
 * Chat Room Card Component
 */
@Composable
fun ChatRoomCard(room: com.trainblink.app.models.ChatRoom) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = room.peerDisplayName,
                    style = MaterialTheme.typography.bodyLarge
                )
                room.lastMessage?.let { message ->
                    Text(
                        text = message.text,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.secondary,
                        maxLines = 1
                    )
                }
            }

            if (room.unreadCount > 0) {
                Badge {
                    Text(room.unreadCount.toString())
                }
            }
        }
    }
}

/**
 * Content Screen (stub)
 */
@Composable
fun ContentScreen(viewModel: MainViewModel) {
    val contentItems by viewModel.contentItems.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Content Sharing",
            style = MaterialTheme.typography.titleLarge
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "${contentItems.size} items",
            style = MaterialTheme.typography.bodyMedium
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = { /* TODO: Implement photo picker */ },
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(Icons.Default.Photo, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Share Photo")
        }

        Spacer(modifier = Modifier.height(8.dp))

        Button(
            onClick = { /* TODO: Implement text sharing */ },
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(Icons.Default.TextFields, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Share Text")
        }
    }
}

/**
 * Settings Screen (stub)
 */
@Composable
fun SettingsScreen(viewModel: MainViewModel) {
    val blockedPeers by viewModel.blockedPeers.collectAsState()
    val encounterHistories by viewModel.encounterHistories.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "Settings",
            style = MaterialTheme.typography.titleLarge
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Statistics
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Statistics",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text("Total encounters: ${encounterHistories.size}")
                Text("Blocked peers: ${blockedPeers.size}")
                Text("Frequent encounters: ${viewModel.getFrequentEncounters().size}")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // About
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "About",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text("TrainBlink Android")
                Text("Version 1.0.0")
                Text("Built with Jetpack Compose")
            }
        }
    }
}
