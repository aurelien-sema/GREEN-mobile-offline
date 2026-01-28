# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Provider
-keep class provider.** { *; }
-keep interface provider.** { *; }

# Go Router
-keep class go_router.** { *; }

# Dio
-keep class io.square.okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-dontwarn retrofit2.**
-dontwarn okio.**
-dontwarn com.google.appengine.api.urlfetch.**

# Shared Preferences
-keep class android.content.SharedPreferences { *; }

# Image Picker & Camera
-keep class com.google.android.material.** { *; }
-keep interface com.google.android.material.** { *; }

# Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items).
-keep,allowobfuscation,allowshrinking interface retrofit2.Call

# With R8 full mode generic signatures are stripped for classes that are not
# explicitly kept. Suspend functions with generic List or Map return types
# decompile but require generic signatures to be parsed by the IDE.
# Retrofit resolves these types via reflection.
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Keep @Parcelize annotated classes
-keep @kotlinx.parcelize.Parcelize class * extends android.os.Parcelable

# General
-keep class **.R$* {
    <fields>;
}
-keepclassmembers class * {
    static <fields>;
    static <methods>;
}
-keepattributes *Annotation*,InnerClasses
-keep class **.BuildConfig { *; }
