package com.musubi.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // HU-31: el canal "musubi" de los avisos push (la API los manda con channel_id "musubi").
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("musubi", "Avisos de Musubi", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Mensajes, pedidos y solicitudes"
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "Abrir mi correo" (maqueta Verificacion): abre la bandeja de la app
        // de correo del telefono. Sin permisos ni datos: solo un Intent.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "musubi/email")
            .setMethodCallHandler { call, result ->
                if (call.method == "openInbox") {
                    result.success(openInbox())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openInbox(): Boolean {
        val intent = Intent.makeMainSelectorActivity(
            Intent.ACTION_MAIN,
            Intent.CATEGORY_APP_EMAIL,
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
