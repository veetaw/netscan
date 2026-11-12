package dev.netscan.netscan

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private val permission = "android.permission.ACCESS_LOCAL_NETWORK"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.netscan/permissions")
            .setMethodCallHandler { call, result ->
                if (call.method != "requestLocalNetwork") {
                    result.notImplemented()
                } else if (Build.VERSION.SDK_INT < 37 || checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
                    result.success(true)
                } else if (pending != null) {
                    result.error("busy", "Richiesta già in corso", null)
                } else {
                    pending = result
                    requestPermissions(arrayOf(permission), 7001)
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 7001) {
            pending?.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            pending = null
        }
    }
}
