package com.example.scamshield

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "scamshield/share"
    private var methodChannel: MethodChannel? = null
    private var pendingSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedText" -> {
                        val text = pendingSharedText ?: extractSharedText(intent)
                        pendingSharedText = null
                        result.success(text)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        pendingSharedText = extractSharedText(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val text = extractSharedText(intent)
        if (text.isNullOrBlank()) return

        val channel = methodChannel
        if (channel == null) {
            pendingSharedText = text
        } else {
            channel.invokeMethod("sharedText", text)
        }
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null

        return intent.getStringExtra(Intent.EXTRA_TEXT)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
    }
}
