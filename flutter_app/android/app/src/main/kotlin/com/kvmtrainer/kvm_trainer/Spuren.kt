package com.kvmtrainer.kvm_trainer

/**
 * Spuren eines Absturzes lesbar machen: ANR-Traces (Text) und Tombstones
 * nativer Abstürze (Protobuf nach AOSP `tombstone.proto`). Reines Kotlin ohne
 * Android-Abhängigkeiten – so lässt es sich auf der JVM testen.
 */
internal object Spuren {

    fun anrText(b: ByteArray): String {
        val zeilen = String(b, Charsets.UTF_8).lines()
        val kopf = zeilen.take(12)
        val start = zeilen.indexOfFirst { it.startsWith("\"main\"") }
        val main = if (start < 0) emptyList() else zeilen.drop(start).takeWhile { it.isNotBlank() }.take(60)
        return (kopf + listOf("…") + main).joinToString("\n")
    }

    fun tombstoneText(b: ByteArray): String {
        // Ältere Android-Versionen liefern den Tombstone als Text.
        val probe = b.take(4096)
        val druckbar = probe.count { it in 9..13 || it in 32..126 }
        if (probe.isNotEmpty() && druckbar * 100 >= probe.size * 95) {
            return String(b, Charsets.UTF_8).lines().take(120).joinToString("\n")
        }
        return try {
            Tombstone(b).text()
        } catch (t: Throwable) {
            "(Tombstone nicht lesbar: $t)\n" + zeichenketten(b)
        }
    }

    private fun zeichenketten(b: ByteArray): String {
        val aus = StringBuilder()
        val cur = StringBuilder()
        var n = 0
        for (x in b) {
            val c = x.toInt() and 0xff
            if (c in 32..126) {
                cur.append(c.toChar())
            } else {
                if (cur.length >= 6 && n < 150) {
                    aus.appendLine(cur)
                    n++
                }
                cur.setLength(0)
            }
        }
        return aus.toString()
    }

    /** Minimaler Protobuf-Leser. */
    private class Pb(private val b: ByteArray, var p: Int, private val ende: Int) {
        fun fertig() = p >= ende

        fun varint(): Long {
            var r = 0L
            var s = 0
            while (true) {
                check(p < ende) { "Ende im varint" }
                val x = b[p++].toInt() and 0xff
                r = r or ((x and 0x7f).toLong() shl s)
                if (x < 0x80) return r
                s += 7
                check(s <= 63) { "varint zu lang" }
            }
        }

        fun feld(): Pair<Int, Int> {
            val t = varint()
            return (t ushr 3).toInt() to (t and 7).toInt()
        }

        private fun laenge(): Int {
            val n = varint()
            check(n >= 0 && n <= ende - p) { "Länge $n" }
            return n.toInt()
        }

        fun text(): String {
            val n = laenge()
            val s = String(b, p, n, Charsets.UTF_8)
            p += n
            return s
        }

        fun teil(): Pb {
            val n = laenge()
            val t = Pb(b, p, p + n)
            p += n
            return t
        }

        fun weiter(typ: Int) {
            when (typ) {
                0 -> varint()
                1 -> p += 8
                2 -> {
                    // Erst die Länge lesen (verschiebt p), dann springen.
                    val n = laenge()
                    p += n
                }
                5 -> p += 4
                else -> error("Typ $typ")
            }
            check(p <= ende) { "über das Ende" }
        }
    }

    /** Die wichtigen Teile eines Tombstones als lesbarer Text. */
    private class Tombstone(b: ByteArray) {
        private var tid = -1L
        private var signal = ""
        private var abbruch: String? = null
        private val ursachen = mutableListOf<String>()
        private val faeden = LinkedHashMap<Long, Pair<String, List<String>>>()
        private val log = mutableListOf<String>()

        init {
            val pb = Pb(b, 0, b.size)
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                when {
                    f == 6 && t == 0 -> tid = pb.varint()
                    f == 10 && t == 2 -> signal = signal(pb.teil())
                    f == 14 && t == 2 -> abbruch = pb.text()
                    f == 15 && t == 2 -> ursache(pb.teil())?.let { ursachen += it }
                    f == 16 && t == 2 -> faden(pb.teil())?.let { faeden[it.first] = it.second }
                    f == 18 && t == 2 -> logPuffer(pb.teil())
                    else -> pb.weiter(t)
                }
            }
        }

        private fun signal(pb: Pb): String {
            var nr = 0L
            var name = ""
            var code = 0L
            var codeName = ""
            var adresse: Long? = null
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                when {
                    f == 1 && t == 0 -> nr = pb.varint()
                    f == 2 && t == 2 -> name = pb.text()
                    f == 3 && t == 0 -> code = pb.varint()
                    f == 4 && t == 2 -> codeName = pb.text()
                    f == 9 && t == 0 -> adresse = pb.varint()
                    else -> pb.weiter(t)
                }
            }
            return "Signal $nr ($name), Code ${code.toInt()} ($codeName)" +
                (adresse?.let { ", Adresse 0x" + java.lang.Long.toHexString(it) } ?: "")
        }

        private fun ursache(pb: Pb): String? {
            var text: String? = null
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                if (f == 1 && t == 2) text = pb.text() else pb.weiter(t)
            }
            return text
        }

        private fun faden(eintrag: Pb): Pair<Long, Pair<String, List<String>>>? {
            var schluessel = -1L
            var wert: Pair<String, List<String>>? = null
            while (!eintrag.fertig()) {
                val (f, t) = eintrag.feld()
                when {
                    f == 1 && t == 0 -> schluessel = eintrag.varint()
                    f == 2 && t == 2 -> wert = fadenInhalt(eintrag.teil())
                    else -> eintrag.weiter(t)
                }
            }
            return wert?.let { schluessel to it }
        }

        private fun fadenInhalt(pb: Pb): Pair<String, List<String>> {
            var name = ""
            val rahmen = mutableListOf<String>()
            val notizen = mutableListOf<String>()
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                when {
                    f == 2 && t == 2 -> name = pb.text()
                    f == 4 && t == 2 -> if (rahmen.size < 48) rahmen += rahmen(pb.teil(), rahmen.size) else pb.weiter(t)
                    f == 7 && t == 2 -> notizen += pb.text()
                    else -> pb.weiter(t)
                }
            }
            return name to (notizen.map { "Hinweis: $it" } + rahmen)
        }

        private fun rahmen(pb: Pb, nr: Int): String {
            var relPc = 0L
            var funktion = ""
            var versatz = 0L
            var datei = ""
            var buildId = ""
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                when {
                    f == 1 && t == 0 -> relPc = pb.varint()
                    f == 4 && t == 2 -> funktion = pb.text()
                    f == 5 && t == 0 -> versatz = pb.varint()
                    f == 6 && t == 2 -> datei = pb.text()
                    f == 8 && t == 2 -> buildId = pb.text()
                    else -> pb.weiter(t)
                }
            }
            val kurz = if (datei.startsWith("/data/app/")) datei.substringAfterLast('/') else datei
            return "#%02d pc %016x  %s".format(nr, relPc, kurz) +
                (if (funktion.isNotEmpty()) " ($funktion+$versatz)" else "") +
                (if (buildId.isNotEmpty()) " (BuildId: $buildId)" else "")
        }

        private fun logPuffer(pb: Pb) {
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                if (f == 2 && t == 2) logZeile(pb.teil()) else pb.weiter(t)
            }
        }

        private fun logZeile(pb: Pb) {
            var zeit = ""
            var tid = 0L
            var prio = 0L
            var tag = ""
            var text = ""
            while (!pb.fertig()) {
                val (f, t) = pb.feld()
                when {
                    f == 1 && t == 2 -> zeit = pb.text()
                    f == 3 && t == 0 -> tid = pb.varint()
                    f == 4 && t == 0 -> prio = pb.varint()
                    f == 5 && t == 2 -> tag = pb.text()
                    f == 6 && t == 2 -> text = pb.text()
                    else -> pb.weiter(t)
                }
            }
            val p = "??VDIWEF".getOrElse(prio.toInt()) { '?' }
            log += "$zeit $tid $p/$tag: ${text.trimEnd()}"
        }

        fun text(): String = buildString {
            appendLine(signal)
            abbruch?.let { appendLine("Abbruchmeldung: $it") }
            ursachen.forEach { appendLine("Ursache: $it") }
            val absturz = faeden[tid]
            if (absturz != null) {
                appendLine("Thread $tid (${absturz.first}):")
                absturz.second.forEach { appendLine("  $it") }
            }
            val andere = faeden.filterKeys { it != tid }
            if (andere.isNotEmpty()) {
                appendLine("Weitere Threads: " + andere.values.joinToString { it.first }.take(600))
            }
            if (log.isNotEmpty()) {
                appendLine("Letzte Protokollzeilen:")
                log.sorted().takeLast(80).forEach { appendLine("  ${it.take(400)}") }
            }
        }
    }
}
