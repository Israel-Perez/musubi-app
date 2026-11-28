package com.musubi.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CalendarContract
import com.google.android.play.core.review.ReviewManagerFactory
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
        // SCRUM-127 (lineamiento 16): el aviso de privacidad y los terminos en
        // la landing. Solo https://musubiapp.com.mx, en el navegador.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "musubi/web")
            .setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    result.success(openLandingPage(call.argument<String>("url") ?: ""))
                } else {
                    result.notImplemented()
                }
            }
        // HU-62: "Agregar al calendario" abre la app de calendario con la
        // entrega ya llena. Sin permiso de calendario: la persona la guarda.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "musubi/calendar")
            .setMethodCallHandler { call, result ->
                if (call.method == "addEvent") {
                    result.success(
                        addEvent(
                            call.argument<String>("title") ?: "",
                            call.argument<Number>("begin")?.toLong() ?: 0L,
                            call.argument<Number>("end")?.toLong() ?: 0L,
                            call.argument<String>("location") ?: "",
                            call.argument<String>("description") ?: "",
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
        // HU-61: "Compartir" un producto abre la hoja del sistema con el
        // texto y el enlace. Sin permisos: la persona elige la app.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "musubi/share")
            .setMethodCallHandler { call, result ->
                if (call.method == "shareText") {
                    result.success(
                        shareText(
                            call.argument<String>("text") ?: "",
                            call.argument<String>("subject") ?: "",
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
        // HU-67: la reseña de la app en Google Play (In-App Review).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "musubi/review")
            .setMethodCallHandler { call, result ->
                if (call.method == "requestReview") {
                    requestReview(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun requestReview(result: MethodChannel.Result) {
        try {
            val manager = ReviewManagerFactory.create(this)
            manager.requestReviewFlow().addOnCompleteListener { request ->
                if (!request.isSuccessful) {
                    result.success(false)
                    return@addOnCompleteListener
                }
                try {
                    manager.launchReviewFlow(this, request.result)
                        .addOnCompleteListener { flow ->
                            result.success(flow.isSuccessful)
                        }
                } catch (_: Exception) {
                    result.success(false)
                }
            }
        } catch (_: Exception) {
            // Sin Play Store (emulador o sideload): la app sigue sin avisar.
            result.success(false)
        }
    }

    private fun shareText(text: String, subject: String): Boolean {
        val send = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, text)
            .putExtra(Intent.EXTRA_SUBJECT, subject)
        return try {
            startActivity(Intent.createChooser(send, "Compartir producto"))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private fun addEvent(title: String, begin: Long, end: Long, location: String, description: String): Boolean {
        val intent = Intent(Intent.ACTION_INSERT)
            .setData(CalendarContract.Events.CONTENT_URI)
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, begin)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
            .putExtra(CalendarContract.Events.TITLE, title)
            .putExtra(CalendarContract.Events.EVENT_LOCATION, location)
            .putExtra(CalendarContract.Events.DESCRIPTION, description)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private fun openLandingPage(url: String): Boolean {
        val uri = Uri.parse(url)
        if (uri.scheme != "https" || uri.host != "musubiapp.com.mx" || uri.userInfo != null || uri.port != -1) {
            return false
        }
        val intent = Intent(Intent.ACTION_VIEW, uri)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
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
