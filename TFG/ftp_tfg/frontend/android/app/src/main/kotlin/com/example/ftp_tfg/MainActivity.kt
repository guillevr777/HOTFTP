package com.example.ftp_tfg

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.commons.net.ftp.FTPClient

class MainActivity: FlutterActivity() {

    private val CHANNEL = "ftp_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "listFiles") {
                    val path = call.argument<String>("path") ?: "/"

                    try {
                        val ftp = FTPClient()
                        ftp.connect("ftp.testserver.com", 21)
                        ftp.login("demo", "password")
                        ftp.enterLocalPassiveMode()

                        val files = ftp.listFiles(path)
                        val response = ArrayList<HashMap<String, Any>>()

                        for (file in files) {
                            val map = HashMap<String, Any>()
                            map["name"] = file.name
                            map["path"] = "$path/${file.name}"
                            map["isDirectory"] = file.isDirectory
                            map["size"] = file.size
                            response.add(map)
                        }

                        ftp.logout()
                        ftp.disconnect()

                        result.success(response)

                    } catch (e: Exception) {
                        result.error("FTP_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
