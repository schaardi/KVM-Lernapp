package com.kvmtrainer.kvm_trainer

import android.annotation.TargetApi
import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Process
import java.io.File
import java.io.InputStream
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Startschutz: hält Abstürze fest und entscheidet vor dem Start der
 * Flutter-Engine, ob die App sicher starten soll.
 *
 * - Java-/Kotlin-Abstürze schreibt [absturzFangen] nach
 *   `startschutz/absturz.txt`; danach übernimmt Android wie gewohnt.
 * - Native Abstürze, ANR und Kills meldet Android ab Version 11 über
 *   ApplicationExitInfo, bei nativen Abstürzen samt Tombstone.
 * - Den laufenden Startschritt schreibt Dart nach `startschutz/schritt.txt`.
 *   Steht dort beim nächsten Start nicht „fertig“, ist der Start abgebrochen.
 *
 * Nach einem Absturz beim Start läuft die App im sicheren Modus (ohne
 * Anmeldung und Cloud, Vorlesen, Erinnerungen und Werbung); nach einem
 * nativen Absturz zeichnet sie mit Skia statt Impeller. Beides gilt bis zum
 * nächsten Update oder bis „Normal starten“ auf der Konto-Seite.
 *
 * Es zählen nur Abstürze der installierten Version: Ein Update kann die
 * Ursache behoben haben. Frühere Abstürze gehen trotzdem mit der
 * automatischen Meldung raus ([Absturzmeldung]).
 */
object Startschutz {
    private const val ORDNER = "startschutz"
    private const val PREFS = "kvm_startschutz"

    class Stand(
        val sicher: Boolean,
        val skia: Boolean,
        var neuerBericht: Boolean,
        val abgebrochenBei: String?,
    )

    @Volatile private var stand: Stand? = null
    @Volatile private var protokoll: Thread? = null
    private const val PROTOKOLL_KOPF = "== Systemprotokoll (nur diese App, Warnungen und Fehler) =="

    fun ordner(context: Context): File = File(context.filesDir, ORDNER).apply { mkdirs() }

    // ------------------------------------------------------------------
    // Java-/Kotlin-Abstürze

    fun absturzFangen(context: Context) {
        val vorher = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { faden, fehler ->
            try {
                val dir = ordner(context)
                val text = buildString {
                    appendLine("Zeit: ${zeit(System.currentTimeMillis())}")
                    appendLine("Thread: ${faden.name}")
                    appendLine("Startschritt: ${lesen(File(dir, "schritt.txt")) ?: "-"}")
                    append(stapel(fehler))
                }
                val datei = File(dir, "absturz.txt")
                datei.writeText(text.take(60_000))
                // Gleich an Supabase – der Prozess endet ohnehin.
                Absturzmeldung.ausAbsturz(context, datei)
            } catch (_: Throwable) {
            }
            if (vorher != null) {
                vorher.uncaughtException(faden, fehler)
            } else {
                Process.killProcess(Process.myPid())
                System.exit(10)
            }
        }
    }

    // ------------------------------------------------------------------
    // Vor dem Start der Engine (einmal je Prozess)

    fun vorStart(context: Context): Stand {
        stand?.let { return it }
        val s = try {
            pruefen(context)
        } catch (_: Throwable) {
            Stand(sicher = false, skia = false, neuerBericht = false, abgebrochenBei = null)
        }
        stand = s
        return s
    }

    private fun pruefen(context: Context): Stand {
        val dir = ordner(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val version = versionCode(context)
        val versionNeu = prefs.getLong("version", -1L) != version
        var sicher = !versionNeu && prefs.getBoolean("sicher", false)
        var skia = !versionNeu && prefs.getBoolean("skia", false)
        var abbrueche = if (versionNeu) 0 else prefs.getInt("abbrueche", 0)

        // Es zählen nur Abstürze dieser Version (seit Installation bzw.
        // Update); auch der Startschritt der Vorgängerversion zählt nicht.
        val seit = installiert(context)
        val schritt = lesen(File(dir, "schritt.txt"))
        val abgebrochen = !versionNeu && schritt != null && schritt != "fertig"
        if (abgebrochen) abbrueche++
        val javaDatei = File(dir, "absturz.txt")
        val java = lesen(javaDatei)?.takeIf { javaDatei.lastModified() >= seit }

        val gesehenBis = prefs.getLong("exit_gesehen_bis", 0L)
        val ausgaenge = if (Build.VERSION.SDK_INT >= 30) ausgaenge(context, maxOf(gesehenBis, seit)) else emptyList()
        val abstuerze = ausgaenge.filter { it.absturz }
        val nativ = abstuerze.any { it.nativ } || (Build.VERSION.SDK_INT < 30 && java == null)

        // Abbruch beim Start: belegt durch einen Absturz – oder zweimal in
        // Folge (etwa ein Hänger, den jemand weggewischt hat).
        val startAbsturz = abgebrochen &&
            (java != null || abstuerze.isNotEmpty() || Build.VERSION.SDK_INT < 30 || abbrueche >= 2)
        if (startAbsturz) {
            sicher = true
            if (nativ || (abbrueche >= 2 && java == null)) skia = true
        }

        val neuerBericht = java != null || abstuerze.isNotEmpty() || startAbsturz
        if (neuerBericht) {
            val text = berichtKern(
                context, version, abgebrochen, schritt, java, ausgaenge,
                sicher, skia,
            )
            File(dir, "bericht.txt").writeText(text)
            protokollAnhaengen(File(dir, "bericht.txt"))
        }
        if (java != null) javaDatei.delete()

        val maxZeit = ausgaenge.maxOfOrNull { it.zeit } ?: 0L
        prefs.edit()
            .putLong("version", version)
            .putBoolean("sicher", sicher)
            .putBoolean("skia", skia)
            .putInt("abbrueche", abbrueche)
            .putLong("exit_gesehen_bis", maxOf(gesehenBis, maxZeit, 1L))
            .commit()
        // Ab hier startet die Engine; Dart überschreibt den Schritt.
        schreiben(File(dir, "schritt.txt"), "engine")
        return Stand(sicher, skia, neuerBericht, if (abgebrochen) schritt else null)
    }

    /** Der Start ist durch: Schritt „fertig“, Abbruchzähler zurück. */
    fun fertig(context: Context) {
        schreiben(File(ordner(context), "schritt.txt"), "fertig")
        prefs(context).edit().putInt("abbrueche", 0).apply()
    }

    /** Nächster Start wieder mit allem (sicherer Modus und Skia aus). */
    fun normal(context: Context) {
        prefs(context).edit().putBoolean("sicher", false).putBoolean("skia", false).putInt("abbrueche", 0).commit()
    }

    fun berichtVorhanden(context: Context) = File(ordner(context), "bericht.txt").exists()

    fun berichtLoeschen(context: Context) {
        File(ordner(context), "bericht.txt").delete()
    }

    /** Gespeicherter Bericht samt Systemprotokoll – nicht auf dem UI-Thread aufrufen. */
    fun bericht(context: Context): String? {
        protokoll?.join(5000)
        val text = lesen(File(ordner(context), "bericht.txt")) ?: return null
        // Fehlt das Protokoll (Lauf vorher zu früh beendet), jetzt eines holen.
        return if (text.contains(PROTOKOLL_KOPF)) text else "$text\n\n$PROTOKOLL_KOPF\n${logcat()}"
    }

    internal fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // ------------------------------------------------------------------
    // Bericht

    /** Kopfzeilen jedes Berichts: App, Gerät, Android, Zeit, Startschutz. */
    internal fun kopf(context: Context): String = buildString {
        appendLine("App ${versionName(context)} (${versionCode(context)}) · Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
        appendLine("Gerät: ${Build.MANUFACTURER} ${Build.MODEL} (${Build.DEVICE}) · ${Build.SUPPORTED_ABIS.joinToString()}")
        appendLine("Build: ${Build.FINGERPRINT}")
        appendLine("Erstellt: ${zeit(System.currentTimeMillis())}")
        val p = prefs(context)
        appendLine(
            "Startschutz: Schritt ${lesen(File(ordner(context), "schritt.txt")) ?: "-"} · sicher=${p.getBoolean("sicher", false)}" +
                " · skia=${p.getBoolean("skia", false)} · Abbrüche=${p.getInt("abbrueche", 0)}",
        )
    }

    private fun berichtKern(
        context: Context,
        version: Long,
        abgebrochen: Boolean,
        schritt: String?,
        java: String?,
        ausgaenge: List<Ausgang>,
        sicher: Boolean,
        skia: Boolean,
    ): String = buildString {
        appendLine("Meister-Trainer – Absturzbericht")
        appendLine("App ${versionName(context)} ($version) · Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
        appendLine("Gerät: ${Build.MANUFACTURER} ${Build.MODEL} (${Build.DEVICE}) · ${Build.SUPPORTED_ABIS.joinToString()}")
        appendLine("Build: ${Build.FINGERPRINT}")
        appendLine("Erstellt: ${zeit(System.currentTimeMillis())}")
        appendLine(
            if (abgebrochen) "Letzter Start abgebrochen bei Schritt: $schritt"
            else "Letzter Start: vollständig (oder erster Lauf dieser Version)",
        )
        appendLine("Jetzt: ${if (sicher) "sicherer Modus" else "normaler Start"} · Grafik ${if (skia) "Skia (Impeller aus)" else "Impeller"}")
        if (java != null) {
            appendLine()
            appendLine("== Java-/Kotlin-Absturz ==")
            appendLine(java.trimEnd())
        }
        if (ausgaenge.isNotEmpty()) {
            appendLine()
            appendLine("== Vom System gemeldete Programmenden (neueste zuerst) ==")
            for (a in ausgaenge) appendLine(a.text.trimEnd())
        } else if (Build.VERSION.SDK_INT < 30) {
            appendLine()
            appendLine("(Android vor Version 11 meldet keine Programmenden.)")
        }
    }

    /**
     * Holt im Hintergrund das Systemprotokoll und hängt es an den Bericht –
     * gleich beim Start, solange die Zeilen zum Absturz noch im Puffer stehen.
     */
    private fun protokollAnhaengen(datei: File) {
        if (protokoll != null) return
        protokoll = Thread {
            val log = logcat()
            try {
                datei.appendText("\n$PROTOKOLL_KOPF\n$log")
            } catch (_: Throwable) {
            }
        }.apply {
            isDaemon = true
            start()
        }
    }

    /**
     * Eigene Protokollzeilen (Android zeigt Apps nur ihre eigenen) – auch die
     * früherer Prozesse, solange sie noch im Puffer stehen.
     */
    internal fun logcat(
        puffer: List<String> = listOf("main", "system", "crash"),
        zeilen: Int = 700,
        filter: List<String> = listOf("flutter:I", "*:W"),
    ): String = try {
        val befehl = mutableListOf("logcat", "-d", "-v", "threadtime")
        puffer.forEach { befehl += listOf("-b", it) }
        befehl += listOf("-t", zeilen.toString())
        befehl += filter
        val p = ProcessBuilder(befehl).redirectErrorStream(true).start()
        val text = p.inputStream.bufferedReader().use { it.readText() }
        p.waitFor()
        if (text.isBlank()) "(leer)\n" else text.takeLast(60_000)
    } catch (t: Throwable) {
        "(nicht lesbar: $t)\n"
    }

    // ------------------------------------------------------------------
    // ApplicationExitInfo (Android 11+)

    internal class Ausgang(val zeit: Long, val absturz: Boolean, val nativ: Boolean, val text: String)

    @TargetApi(30)
    internal fun ausgaenge(context: Context, seit: Long): List<Ausgang> {
        val am = context.getSystemService(ActivityManager::class.java) ?: return emptyList()
        val liste = try {
            am.getHistoricalProcessExitReasons(context.packageName, 0, 12)
        } catch (_: Throwable) {
            return emptyList()
        }
        var spuren = 0
        return liste.filter { it.timestamp > seit }.mapIndexed { i, info ->
            val absturz = istAbsturz(info)
            val mitSpur = absturz && spuren < 3 &&
                (info.reason == ApplicationExitInfo.REASON_CRASH_NATIVE || info.reason == ApplicationExitInfo.REASON_ANR)
            if (mitSpur) spuren++
            Ausgang(
                info.timestamp, absturz, info.reason == ApplicationExitInfo.REASON_CRASH_NATIVE,
                ausgangText(context, info, i + 1, absturz, mitSpur),
            )
        }
    }

    @TargetApi(30)
    private fun istAbsturz(i: ApplicationExitInfo): Boolean {
        val sichtbar = i.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE
        return when (i.reason) {
            ApplicationExitInfo.REASON_CRASH,
            ApplicationExitInfo.REASON_CRASH_NATIVE,
            ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> true
            ApplicationExitInfo.REASON_ANR,
            ApplicationExitInfo.REASON_LOW_MEMORY,
            ApplicationExitInfo.REASON_SIGNALED,
            ApplicationExitInfo.REASON_OTHER,
            ApplicationExitInfo.REASON_DEPENDENCY_DIED,
            ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE,
            ApplicationExitInfo.REASON_FREEZER -> sichtbar
            ApplicationExitInfo.REASON_EXIT_SELF -> sichtbar && i.status != 0
            else -> false
        }
    }

    @TargetApi(30)
    private fun ausgangText(context: Context, i: ApplicationExitInfo, nr: Int, absturz: Boolean, mitSpur: Boolean): String =
        buildString {
            append("$nr) ${zeit(i.timestamp)} · ${grundName(i.reason)}")
            if (absturz) append(" [Absturz]")
            appendLine(" · ${wichtigkeit(i.importance)} · Status ${i.status} · PSS ${i.pss / 1024} MB · RSS ${i.rss / 1024} MB")
            i.description?.takeIf { it.isNotBlank() }?.let { appendLine("   Beschreibung: ${it.take(500)}") }
            if (i.processName != context.packageName) appendLine("   Prozess: ${i.processName}")
            if (mitSpur) {
                val daten = try {
                    i.traceInputStream?.use { lesenBegrenzt(it, 8 shl 20) }
                } catch (t: Throwable) {
                    appendLine("   (Spur nicht lesbar: $t)")
                    null
                }
                if (daten != null && daten.isNotEmpty()) {
                    val spur = if (i.reason == ApplicationExitInfo.REASON_ANR) Spuren.anrText(daten) else Spuren.tombstoneText(daten)
                    spur.lineSequence().forEach { appendLine("   $it") }
                }
            }
        }

    private fun grundName(r: Int) = when (r) {
        ApplicationExitInfo.REASON_EXIT_SELF -> "EXIT_SELF"
        ApplicationExitInfo.REASON_SIGNALED -> "SIGNALED"
        ApplicationExitInfo.REASON_LOW_MEMORY -> "LOW_MEMORY"
        ApplicationExitInfo.REASON_CRASH -> "CRASH (Java)"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "CRASH_NATIVE"
        ApplicationExitInfo.REASON_ANR -> "ANR"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "INITIALIZATION_FAILURE"
        ApplicationExitInfo.REASON_PERMISSION_CHANGE -> "PERMISSION_CHANGE"
        ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "EXCESSIVE_RESOURCE_USAGE"
        ApplicationExitInfo.REASON_USER_REQUESTED -> "USER_REQUESTED"
        ApplicationExitInfo.REASON_USER_STOPPED -> "USER_STOPPED"
        ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "DEPENDENCY_DIED"
        ApplicationExitInfo.REASON_OTHER -> "OTHER"
        ApplicationExitInfo.REASON_FREEZER -> "FREEZER"
        ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE -> "PACKAGE_STATE_CHANGE"
        ApplicationExitInfo.REASON_PACKAGE_UPDATED -> "PACKAGE_UPDATED"
        else -> "UNKNOWN($r)"
    }

    private fun wichtigkeit(w: Int) = when {
        w <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND -> "Vordergrund"
        w <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE -> "sichtbar"
        w <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE -> "Dienst"
        else -> "Hintergrund"
    }

    // ------------------------------------------------------------------
    // Hilfen

    internal fun lesen(f: File): String? = try {
        if (f.exists()) f.readText().trim().ifEmpty { null } else null
    } catch (_: Throwable) {
        null
    }

    private fun schreiben(f: File, text: String) {
        try {
            f.writeText(text)
        } catch (_: Throwable) {
        }
    }

    private fun lesenBegrenzt(s: InputStream, grenze: Int): ByteArray {
        val puffer = java.io.ByteArrayOutputStream()
        val b = ByteArray(64 * 1024)
        while (puffer.size() < grenze) {
            val n = s.read(b)
            if (n < 0) break
            puffer.write(b, 0, n)
        }
        return puffer.toByteArray()
    }

    private fun stapel(t: Throwable): String {
        val w = StringWriter()
        t.printStackTrace(PrintWriter(w))
        return w.toString()
    }

    internal fun zeit(ms: Long): String = SimpleDateFormat("dd.MM.yyyy HH:mm:ss", Locale.GERMANY).format(Date(ms))

    @Suppress("DEPRECATION")
    internal fun versionCode(context: Context): Long = try {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    } catch (_: Throwable) {
        -2L
    }

    /** Wann diese Version installiert bzw. zuletzt aktualisiert wurde. */
    internal fun installiert(context: Context): Long = try {
        context.packageManager.getPackageInfo(context.packageName, 0).lastUpdateTime
    } catch (_: Throwable) {
        0L
    }

    internal fun versionName(context: Context): String = try {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "?"
    } catch (_: Throwable) {
        "?"
    }
}
