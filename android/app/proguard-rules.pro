# OkHttp optional TLS providers (not bundled on Android).
-dontwarn org.bouncycastle.jsse.BCSSLParameters
-dontwarn org.bouncycastle.jsse.BCSSLSocket
-dontwarn org.bouncycastle.jsse.provider.BouncyCastleJsseProvider
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# flutter_webrtc: native code calls these classes via JNI; R8 stripping them makes
# voice/video calls crash in release builds only.
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn org.webrtc.**

# eSewa SDK (esewasdk-release.aar): request/response models are (de)serialized
# reflectively; keep them so wallet top-up works in release.
-keep class com.f1soft.** { *; }
-dontwarn com.f1soft.**
