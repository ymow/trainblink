package com.trainblink.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import com.trainblink.app.ui.screens.MainScreen
import com.trainblink.app.ui.theme.TrainBlinkTheme

/**
 * Main Activity
 * Entry point for TrainBlink Android app
 */
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            TrainBlinkTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen()
                }
            }
        }

        // Log screen view
        TrainBlinkApplication.instance.analyticsManager.logScreenView(
            screenName = "MainActivity",
            screenClass = "MainActivity"
        )
    }
}
