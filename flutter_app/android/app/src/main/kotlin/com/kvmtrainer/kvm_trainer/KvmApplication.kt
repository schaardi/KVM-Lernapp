package com.kvmtrainer.kvm_trainer

import android.app.Application
import android.content.Context

/**
 * Richtet den Absturzschutz ein, bevor irgendetwas anderes läuft – auch vor
 * den Content-Providern der Bibliotheken (WorkManager, Lifecycle usw.).
 */
class KvmApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        Startschutz.absturzFangen(base)
    }
}
