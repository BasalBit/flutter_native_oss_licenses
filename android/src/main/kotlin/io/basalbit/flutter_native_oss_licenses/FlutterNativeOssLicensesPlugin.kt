package io.basalbit.flutter_native_oss_licenses

import android.content.Context
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterNativeOssLicensesPlugin */
class FlutterNativeOssLicensesPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_native_oss_licenses")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "loadNativeLicensePayload" -> loadNativeLicensePayload(result)
            else -> result.notImplemented()
        }
    }

    private fun loadNativeLicensePayload(result: Result) {
        try {
            result.success(
                readNativeLicensePayload {
                    applicationContext.assets.open("flutter_native_oss_licenses/licenses.json")
                },
            )
        } catch (error: IOException) {
            result.error(
                "native_license_payload_read_failed",
                "Could not read the generated native-license payload.",
                error.message,
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

internal fun readNativeLicensePayload(openAsset: () -> InputStream): String =
    try {
        openAsset()
            .bufferedReader(Charsets.UTF_8)
            .use { it.readText() }
    } catch (_: FileNotFoundException) {
        "[]"
    }
