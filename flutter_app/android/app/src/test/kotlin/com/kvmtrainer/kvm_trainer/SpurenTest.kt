package com.kvmtrainer.kvm_trainer

import java.io.ByteArrayOutputStream
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Tombstone- und ANR-Spuren so, wie Android sie über ApplicationExitInfo liefert. */
class SpurenTest {
    // --- kleiner Protobuf-Schreiber für Testdaten ---
    private class Msg {
        val out = ByteArrayOutputStream()

        private fun varint(v: Long) {
            var x = v
            while (x and 0x7fL.inv() != 0L) {
                out.write(((x and 0x7f) or 0x80).toInt())
                x = x ushr 7
            }
            out.write(x.toInt())
        }

        fun zahl(feld: Int, v: Long) = apply {
            varint((feld shl 3).toLong())
            varint(v)
        }

        fun bytes(feld: Int, b: ByteArray) = apply {
            varint(((feld shl 3) or 2).toLong())
            varint(b.size.toLong())
            out.write(b)
        }

        fun text(feld: Int, s: String) = bytes(feld, s.toByteArray())
        fun msg(feld: Int, m: Msg) = bytes(feld, m.out.toByteArray())
        fun fest64(feld: Int) = apply {
            varint(((feld shl 3) or 1).toLong())
            out.write(ByteArray(8))
        }

        fun fertig(): ByteArray = out.toByteArray()
    }

    private fun rahmen(pc: Long, datei: String, funktion: String = "", versatz: Long = 0, buildId: String = "") =
        Msg().zahl(1, pc).zahl(2, pc + 0x7000_0000L).apply {
            if (funktion.isNotEmpty()) text(4, funktion).zahl(5, versatz)
        }.text(6, datei).apply { if (buildId.isNotEmpty()) text(8, buildId) }

    private fun tombstone(): ByteArray {
        val absturz = Msg().zahl(1, 4242).text(2, "1.raster")
            .msg(3, Msg().text(1, "x0").zahl(2, 0)) // Register – wird übersprungen
            .msg(4, rahmen(0x1234, "/data/app/~~a==/com.kvmtrainer.kvm_trainer-b==/lib/arm64/libflutter.so", buildId = "abc123"))
            .msg(4, rahmen(0x10, "/apex/com.android.runtime/lib64/bionic/libc.so", "abort", 8))
        val main = Msg().zahl(1, 4200).text(2, "main").msg(4, rahmen(0x20, "/system/lib64/libc.so"))
        val log = Msg().text(1, "main")
            .msg(2, Msg().text(1, "2026-09-25 10:00:01.000").zahl(2, 4200).zahl(3, 4242).zahl(4, 6).text(5, "flutter").text(6, "Fehler beim Zeichnen\n"))
            .msg(2, Msg().text(1, "2026-09-25 10:00:00.500").zahl(2, 4200).zahl(3, 4200).zahl(4, 4).text(5, "Startschutz").text(6, "engine"))
        return Msg()
            .zahl(1, 3) // arch ARM64
            .text(2, "google/device/device:16/BP1A/1:user/release-keys")
            .zahl(5, 4200)
            .zahl(6, 4242)
            .text(9, "com.kvmtrainer.kvm_trainer")
            .msg(10, Msg().zahl(1, 11).text(2, "SIGSEGV").zahl(3, 1).text(4, "SEGV_MAPERR").zahl(8, 1).zahl(9, 0))
            .text(14, "Impeller: Vulkan device lost")
            .msg(15, Msg().text(1, "null pointer dereference"))
            .msg(16, Msg().zahl(1, 4242).msg(2, absturz))
            .msg(16, Msg().zahl(1, 4200).msg(2, main))
            .msg(17, Msg().zahl(1, 0x1000).text(7, "/system/lib64/libc.so")) // memory_mappings – übersprungen
            .msg(18, log)
            .fest64(30) // unbekanntes Feld mit fester Länge
            .zahl(22, 16384)
            .fertig()
    }

    @Test
    fun tombstone_wird_lesbar() {
        val t = Spuren.tombstoneText(tombstone())
        assertTrue(t, t.contains("Signal 11 (SIGSEGV), Code 1 (SEGV_MAPERR), Adresse 0x0"))
        assertTrue(t, t.contains("Abbruchmeldung: Impeller: Vulkan device lost"))
        assertTrue(t, t.contains("Ursache: null pointer dereference"))
        assertTrue(t, t.contains("Thread 4242 (1.raster):"))
        assertTrue(t, t.contains("#00 pc 0000000000001234  libflutter.so (BuildId: abc123)"))
        assertTrue(t, t.contains("#01 pc 0000000000000010  /apex/com.android.runtime/lib64/bionic/libc.so (abort+8)"))
        assertTrue(t, t.contains("Weitere Threads: main"))
        // Protokoll zeitlich sortiert, Priorität als Buchstabe
        val a = t.indexOf("I/Startschutz: engine")
        val b = t.indexOf("E/flutter: Fehler beim Zeichnen")
        assertTrue(t, a in 0 until b)
        // Rahmen anderer Threads nicht im Bericht
        assertFalse(t, t.contains("0000000000000020"))
    }

    @Test
    fun kaputter_tombstone_faellt_auf_zeichenketten_zurueck() {
        val daten = tombstone().copyOf(300) // mitten im Feld abgeschnitten
        val t = Spuren.tombstoneText(daten)
        assertTrue(t, t.startsWith("(Tombstone nicht lesbar"))
        assertTrue(t, t.contains("google/device/device:16"))
    }

    @Test
    fun text_tombstone_bleibt_text() {
        val text = "*** *** *** *** *** *** ***\nBuild fingerprint: 'x'\nsignal 6 (SIGABRT), code -1 (SI_QUEUE)\n".repeat(3)
        assertEquals(text.trimEnd().lines().take(120).joinToString("\n"), Spuren.tombstoneText(text.toByteArray()).trimEnd())
    }

    @Test
    fun anr_zeigt_kopf_und_main_thread() {
        val trace = buildString {
            appendLine("----- pid 4200 at 2026-09-25 10:00:00 -----")
            appendLine("Cmd line: com.kvmtrainer.kvm_trainer")
            appendLine()
            appendLine("\"Signal Catcher\" daemon prio=10 tid=2 Runnable")
            appendLine("  native: #00 pc 1234 libart.so")
            appendLine()
            appendLine("\"main\" prio=5 tid=1 Native")
            appendLine("  at java.lang.Object.wait(Native method)")
            appendLine("  at io.flutter.embedding.engine.FlutterJNI.nativeRunBundleAndSnapshotFromLibrary")
            appendLine()
            appendLine("\"1.raster\" prio=5 tid=20 Native")
        }
        val t = Spuren.anrText(trace.toByteArray())
        assertTrue(t, t.contains("Cmd line: com.kvmtrainer.kvm_trainer"))
        assertTrue(t, t.contains("\"main\" prio=5 tid=1 Native"))
        assertTrue(t, t.contains("FlutterJNI.nativeRunBundleAndSnapshotFromLibrary"))
        assertFalse(t, t.substringAfter("…").contains("1.raster"))
    }
}
