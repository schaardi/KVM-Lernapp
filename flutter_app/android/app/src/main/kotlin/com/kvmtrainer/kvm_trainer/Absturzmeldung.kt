package com.kvmtrainer.kvm_trainer

import android.content.Context
import android.net.ConnectivityManager
import android.os.Build
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Schickt Absturzberichte an Supabase (`absturz_melden`, siehe
 * docs/supabase-absturzberichte.sql) – ohne Flutter und ohne Anmeldung, damit
 * sie auch ankommen, wenn die App jedes Mal sofort wieder abstürzt:
 * - [beimStart]: gleich beim Prozessstart alles, was seit dem letzten Senden
 *   angefallen ist – Java-Absturz, gespeicherter Bericht des Startschutzes,
 *   Programmenden laut Android (samt Tombstone) und der Absturzpuffer von logcat;
 * - [ausAbsturz]: bei einem Java-Absturz noch aus dem Absturz heraus.
 * Gesendet wird mit knapper Frist; läuft sie ab, versucht es der nächste Start.
 */
internal object Absturzmeldung {
    private const val ZIEL = "https://iarekdxkutwfidzgvyuy.supabase.co/rest/v1/rpc/absturz_melden"

    // Öffentlicher anon-Key wie in lib/config.dart – die Tabelle schützt RLS.
    private const val ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhcmVrZHhrdXR3Zmlkemd2eXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxNjIxMTgsImV4cCI6MjA5OTczODExOH0.GsQtsioi0epiXiqYAoeFZ_C5r4C0XuHJlCuiK4UsjzQ"

    private const val PREFS = "kvm_absturzmeldung"
    private const val FRIST_MS = 5000L

    /** Beim Prozessstart (KvmApplication): Ausstehendes senden. */
    fun beimStart(context: Context) {
        try {
            val dir = Startschutz.ordner(context)
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val teile = mutableListOf<String>()
            val arten = linkedSetOf<String>()

            val java = File(dir, "absturz.txt")
            val javaStand = if (java.exists()) java.lastModified() else 0L
            if (javaStand != 0L && prefs.getLong("java_gesendet", 0L) != javaStand) {
                Startschutz.lesen(java)?.let {
                    teile += "== Java-/Kotlin-Absturz ==\n$it"
                    arten += "java"
                }
            }
            val bericht = File(dir, "bericht.txt")
            val berichtStand = if (bericht.exists()) bericht.lastModified() else 0L
            if (berichtStand != 0L && prefs.getLong("bericht_gesendet", 0L) != berichtStand) {
                Startschutz.lesen(bericht)?.let {
                    teile += "== Gespeicherter Bericht des Startschutzes ==\n$it"
                    arten += "bericht"
                }
            }
            val seit = prefs.getLong("exit_gesendet_bis", 0L)
            val ausgaenge = if (Build.VERSION.SDK_INT >= 30) Startschutz.ausgaenge(context, seit) else emptyList()
            if (ausgaenge.any { it.absturz }) {
                teile += "== Programmenden laut Android (neueste zuerst) ==\n" +
                    ausgaenge.joinToString("\n") { it.text.trimEnd() }
                arten += "system"
            }
            if (teile.isEmpty()) return

            teile += "== logcat: Absturzpuffer ==\n" + Startschutz.logcat(listOf("crash"), 400, emptyList())
            val text = "Meister-Trainer – Absturzbericht (beim Start gesendet)\n" +
                Startschutz.kopf(context) + "\n" + teile.joinToString("\n\n")
            if (senden(context, arten.joinToString("+"), text)) {
                prefs.edit()
                    .putLong("java_gesendet", javaStand)
                    .putLong("bericht_gesendet", berichtStand)
                    .putLong("exit_gesendet_bis", maxOf(seit, ausgaenge.maxOfOrNull { it.zeit } ?: 0L))
                    .commit()
            }
        } catch (_: Throwable) {
        }
    }

    /** Aus dem UncaughtExceptionHandler: den gerade geschriebenen Absturz senden. */
    fun ausAbsturz(context: Context, datei: File) {
        try {
            val stapel = Startschutz.lesen(datei) ?: return
            val text = "Meister-Trainer – Absturzbericht (im Absturz gesendet)\n" +
                Startschutz.kopf(context) + "\n== Java-/Kotlin-Absturz ==\n" + stapel +
                "\n\n== logcat: diese App ==\n" + Startschutz.logcat(zeilen = 300)
            if (senden(context, "java", text)) {
                context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .putLong("java_gesendet", datei.lastModified())
                    .commit()
            }
        } catch (_: Throwable) {
        }
    }

    /** Sendet im Hintergrund und wartet höchstens [FRIST_MS]. */
    private fun senden(context: Context, art: String, text: String): Boolean {
        if (!online(context)) return false
        val json = JSONObject()
            .put("p_app", "${Startschutz.versionName(context)} (${Startschutz.versionCode(context)})")
            .put("p_geraet", "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
            .put("p_art", art)
            .put("p_bericht", text.take(390_000))
            .toString()
        var ok = false
        val faden = Thread {
            ok = try {
                post(json)
            } catch (_: Throwable) {
                false
            }
        }
        faden.isDaemon = true
        faden.start()
        faden.join(FRIST_MS)
        return ok
    }

    private fun post(json: String): Boolean {
        val c = URL(ZIEL).openConnection() as HttpURLConnection
        return try {
            c.requestMethod = "POST"
            c.connectTimeout = 3500
            c.readTimeout = 4500
            c.doOutput = true
            c.setRequestProperty("apikey", ANON)
            c.setRequestProperty("Authorization", "Bearer $ANON")
            c.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            c.outputStream.use { it.write(json.toByteArray(Charsets.UTF_8)) }
            c.responseCode in 200..299
        } finally {
            c.disconnect()
        }
    }

    private fun online(context: Context): Boolean = try {
        context.getSystemService(ConnectivityManager::class.java)?.activeNetwork != null
    } catch (_: Throwable) {
        true
    }
}
