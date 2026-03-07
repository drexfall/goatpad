package com.drexfall.goatpad.goatpad

import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.drexfall.goatpad/file_io"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "writeFile" -> {
                    val path = call.argument<String>("path")
                    val content = call.argument<String>("content")
                    if (path == null || content == null) {
                        result.error("INVALID_ARGS", "path and content are required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val bytes = content.toByteArray(Charsets.UTF_8)
                        if (path.startsWith("content://")) {
                            // Write via ContentResolver for content:// URIs
                            contentResolver.openOutputStream(Uri.parse(path), "wt")?.use { it.write(bytes) }
                        } else {
                            // Write directly for plain file paths
                            File(path).writeBytes(bytes)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("WRITE_FAILED", e.message, null)
                    }
                }
                "hasManageStoragePermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        Environment.isExternalStorageManager()
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "requestManageStoragePermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val intent = android.content.Intent(
                            android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
