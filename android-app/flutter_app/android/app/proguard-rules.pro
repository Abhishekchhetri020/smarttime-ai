# Flutter-specific ProGuard rules
# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Dart VM (required for Flutter)
-dontwarn io.flutter.**

# Keep Firebase (if used)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
