# Flutter + Play Core: para no romper con shrink resources.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Las clases de play core aparecen por el deferred components aunque no lo
# usemos. Sin esto R8 revienta.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# flutter_secure_storage usa reflection sobre androidx.security.
-keep class androidx.security.crypto.** { *; }

# flutter_blue_plus trae jars viejos que tropiezan con enum checks del shrink.
-keepclassmembers enum * { *; }
-keepnames class com.boskokg.flutter_blue_plus.** { *; }

# Dio / dart_vm_service usan logs que R8 a veces se come.
-dontwarn sun.misc.**
