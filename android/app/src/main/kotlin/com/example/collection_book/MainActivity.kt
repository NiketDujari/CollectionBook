package com.akash.collection_book

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import androidx.core.content.FileProvider
import android.net.Uri
import android.widget.Toast
import android.os.Bundle
import android.webkit.WebView

class MainActivity:
    FlutterFragmentActivity() {

    private val CHANNEL = "collection_book/pdf"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WebView.setWebContentsDebuggingEnabled(true)
    }

    override fun configureFlutterEngine(
        @NonNull flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "savePdf") {

                val filename =
                    call.argument<String>("filename")!!

                val bytes =
                    call.argument<ByteArray>("bytes")!!

                try {

                    val resolver = contentResolver

                    val values = ContentValues().apply {

                        put(
                            MediaStore.Downloads.DISPLAY_NAME,
                            filename
                        )

                        put(
                            MediaStore.Downloads.MIME_TYPE,
                            "application/pdf"
                        )

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                            put(
                                MediaStore.Downloads.RELATIVE_PATH,
                                Environment.DIRECTORY_DOWNLOADS
                            )

                        }

                    }

                    val uri = resolver.insert(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                        values
                    )

                    resolver.openOutputStream(uri!!)?.use {

                        it.write(bytes)

                    }
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/pdf")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    try {

                        startActivity(intent)

                    } catch (e: Exception) {

                        Toast.makeText(
                            this,
                            "PDF saved to Downloads",
                            Toast.LENGTH_SHORT
                        ).show()

                    }

                    result.success(true)

                } catch (e: Exception) {

                    e.printStackTrace()

                    result.success(false)

                }

            } else {

                result.notImplemented()

            }

        }

    }

}