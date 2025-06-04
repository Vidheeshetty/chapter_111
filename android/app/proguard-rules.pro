# Add project specific ProGuard rules here.

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom classes used by Firebase
-keep class * extends com.google.firebase.auth.FirebaseUser { *; }

# Prevent obfuscation of model classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}