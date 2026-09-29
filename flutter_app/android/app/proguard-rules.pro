# R8-Regeln für den Release-Build – das Flutter-Gradle-Plugin bindet diese
# Datei automatisch ein (android/app/proguard-rules.pro).
#
# R8 läuft seit AGP 8 im Vollmodus: „-keep class X“ hält dort den
# parameterlosen Konstruktor NICHT mehr mit. Ältere Bibliotheken verlassen
# sich aber darauf und legen Objekte per Reflexion an.

# WorkManager 2.7 (kommt mit AdMob) startet über androidx.startup bei JEDEM
# Prozessstart und legt dabei seine Room-Datenbank per Reflexion an. Ohne den
# Konstruktor von WorkDatabase_Impl stürzt die App sofort ab – noch bevor
# Flutter startet: „Unable to get provider androidx.startup.InitializationProvider
# … Failed to create an instance of androidx.work.impl.WorkDatabase“.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
# Dasselbe Muster: WorkManager legt Input-Merger über den Klassennamen an.
-keep class * extends androidx.work.InputMerger { <init>(); }

# Lern-Erinnerung (flutter_local_notifications) speichert geplante
# Mitteilungen per Gson unter den Feldnamen ihrer Modellklassen und liest sie
# nach Neustart oder Update wieder ein – Namen und generische Typen müssen
# über Builds hinweg gleich bleiben.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
