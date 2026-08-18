# R8 only runs on release, and release is what goes to Play, so anything resolved
# reflectively has to be spelled out here. When it is not, the failure is silent at
# runtime rather than at build time.

-keep class com.revenuecat.** { *; }
-keep class com.mixpanel.** { *; }

# --- kotlinx.serialization ---------------------------------------------------
# Generated serializers are reached through a Companion or a $serializer class that
# nothing references directly, so R8 considers them unused. This covers our models,
# Supabase's wire types, and the RPC payloads declared locally inside functions.
-keepattributes *Annotation*, InnerClasses, Signature, RuntimeVisibleAnnotations, AnnotationDefault
-dontnote kotlinx.serialization.**

-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}
-keepclasseswithmembers class ** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class **$$serializer { *; }

# UserProgress and the catalog models are serialized field by field, and the column
# names are the field names: renaming them silently changes the Supabase payload.
-keep class app.rork.sophia.domain.** { *; }

# --- Supabase + Ktor --------------------------------------------------------
# The Google sign-in path is auth-kt -> Ktor -> OkHttp. It is also the one place
# where a stripped serializer surfaced as "nothing happens" instead of a crash.
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**
-keep class io.ktor.** { *; }
-keepclassmembers class io.ktor.** { volatile <fields>; }
-dontwarn io.ktor.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.slf4j.**

# --- Credential Manager / Google ID token -----------------------------------
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**
