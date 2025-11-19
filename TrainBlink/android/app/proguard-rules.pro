# Add project specific ProGuard rules here.
# TrainBlink ProGuard Configuration

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep data classes
-keep class com.trainblink.app.models.** { *; }

# Keep Compose
-keep class androidx.compose.** { *; }
