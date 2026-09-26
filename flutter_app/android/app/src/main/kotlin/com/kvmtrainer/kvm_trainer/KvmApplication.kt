package com.kvmtrainer.kvm_trainer

import android.app.Application
import android.content.Context

/**
 * Richtet den Absturzschutz ein, bevor irgendetwas anderes läuft – auch vor
 * den Content-Providern der Bibliotheken (WorkManager, Lifecycle usw.) – und
 * schickt ausstehende Absturzberichte ab, bevor die App wieder abstürzen kann.
 */
class KvmApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        Startschutz.absturzFangen(base)
        Absturzmeldung.beimStart(base)
    }
}
