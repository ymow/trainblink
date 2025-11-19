package com.trainblink.app

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.firebase.perf.FirebasePerformance
import com.trainblink.app.analytics.AnalyticsManager
import com.trainblink.app.managers.*

/**
 * TrainBlink Application Class
 * Initializes Firebase and singleton managers
 */
class TrainBlinkApplication : Application() {

    companion object {
        lateinit var instance: TrainBlinkApplication
            private set
    }

    // Singleton managers
    lateinit var analyticsManager: AnalyticsManager
        private set

    lateinit var geofenceManager: GeofenceManager
        private set

    lateinit var nearbyConnectionsManager: NearbyConnectionsManager
        private set

    lateinit var chatManager: ChatManager
        private set

    lateinit var blockingManager: BlockingManager
        private set

    lateinit var encounterTrackingManager: EncounterTrackingManager
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this

        // Initialize Firebase
        FirebaseApp.initializeApp(this)

        // Initialize Firebase services
        FirebaseAnalytics.getInstance(this)
        FirebaseCrashlytics.getInstance()
        FirebasePerformance.getInstance()

        // Initialize managers
        analyticsManager = AnalyticsManager(this)
        geofenceManager = GeofenceManager(this)
        nearbyConnectionsManager = NearbyConnectionsManager(this)
        chatManager = ChatManager(this)
        blockingManager = BlockingManager(this)
        encounterTrackingManager = EncounterTrackingManager(this)

        // Log app launch
        analyticsManager.logAppLaunched()

        println("🚄 TrainBlink Application initialized")
    }
}
