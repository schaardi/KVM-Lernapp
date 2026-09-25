package com.kvmtrainer.kvm_trainer

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Vor der Engine: Absturz beim letzten Lauf? Dann sicherer Start.
        Startschutz.vorStart(applicationContext)
        super.onCreate(savedInstanceState)
    }

    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        // Nach einem nativen Absturz mit Skia zeichnen statt mit Impeller –
        // falls der Grafiktreiber des Geräts mit Impeller nicht zurechtkommt.
        if (Startschutz.vorStart(applicationContext).skia) args.add("--enable-impeller=false")
        return args
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val app = applicationContext
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kvm/startschutz").setMethodCallHandler { call, result ->
            when (call.method) {
                "stand" -> {
                    val s = Startschutz.vorStart(app)
                    result.success(
                        mapOf(
                            "ordner" to Startschutz.ordner(app).absolutePath,
                            "sicher" to s.sicher,
                            "skia" to s.skia,
                            "neuerBericht" to s.neuerBericht,
                            "berichtVorhanden" to Startschutz.berichtVorhanden(app),
                            "abgebrochenBei" to s.abgebrochenBei,
                        ),
                    )
                    // Nur einmal je Prozess zeigen (auch wenn die Activity neu entsteht).
                    s.neuerBericht = false
                }
                "bericht" -> {
                    val haupt = Handler(Looper.getMainLooper())
                    Thread {
                        val text = try {
                            Startschutz.bericht(app)
                        } catch (t: Throwable) {
                            "Bericht nicht lesbar: $t"
                        }
                        haupt.post { result.success(text) }
                    }.start()
                }
                "fertig" -> {
                    Startschutz.fertig(app)
                    result.success(null)
                }
                "normal" -> {
                    Startschutz.normal(app)
                    result.success(null)
                }
                "berichtLoeschen" -> {
                    Startschutz.berichtLoeschen(app)
                    result.success(null)
                }
                "teilen" -> {
                    val text = call.argument<String>("text") ?: ""
                    val senden = Intent(Intent.ACTION_SEND)
                        .setType("text/plain")
                        .putExtra(Intent.EXTRA_SUBJECT, "Meister-Trainer – Absturzbericht")
                        .putExtra(Intent.EXTRA_TEXT, text)
                    try {
                        startActivity(Intent.createChooser(senden, "Bericht teilen"))
                        result.success(true)
                    } catch (t: Throwable) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
