# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Keep Dart/Flutter generated code
-keep class io.flutter.plugins.** { *; }

# HTTP client
-keep class okhttp3.** { *; }
-keep class com.google.gson.** { *; }

# Shared preferences
-keep class com.tekartik.sqflite.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Share plus
-keep class com.flutter.share_plus.** { *; }

# PDF
-keep class com.itextpdf.** { *; }
-keep class org.slf4j.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter JNI classes
-keep class io.flutter.embedding.engine.dart.** { *; }

# Play Core / SplitCompat (not bundled, referenced by Flutter)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task