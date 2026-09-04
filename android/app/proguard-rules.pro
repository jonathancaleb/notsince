# R8 keep rules.
#
# Only for code reached reflectively or from native, which R8 cannot see. Every
# rule here is a specific need, not a blanket keep — a broad `-keep class **`
# would undo the point of shrinking.

# flutter_local_notifications deserialises scheduled notifications from disk
# through Gson, so its model classes and their generic signatures must survive.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*

# The alarm plugin's receivers and service are named in the manifest and
# instantiated by the system, never by our code.
-keep class com.gdelataillade.alarm.** { *; }

# Flutter's own embedding is already covered by the SDK's rules, but the
# deferred-components stubs generate warnings we do not act on.
-dontwarn io.flutter.embedding.**
