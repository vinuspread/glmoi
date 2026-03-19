package co.vinus.glmoi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val platformChannel = "co.vinus.glmoi/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidKeyHashes" -> result.success(getAndroidKeyHashes())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        createNotificationChannel()
    }

    @Suppress("DEPRECATION")
    private fun getAndroidKeyHashes(): List<String> {
        return try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES,
                )
                val signingInfo = packageInfo.signingInfo
                val currentSigners = signingInfo?.apkContentsSigners ?: emptyArray()
                val historySigners = signingInfo?.signingCertificateHistory ?: emptyArray()
                (currentSigners + historySigners)
            } else {
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES,
                )
                packageInfo.signatures ?: emptyArray()
            }

            signatures
                .map { signature ->
                    val digest = MessageDigest.getInstance("SHA-1")
                        .digest(signature.toByteArray())
                    Base64.encodeToString(digest, Base64.NO_WRAP)
                }
                .distinct()
                .sorted()
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "glmoi_notifications"
            val channelName = "글모이 알림"
            val channelDescription = "오늘의 글 자동발송 알림"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
