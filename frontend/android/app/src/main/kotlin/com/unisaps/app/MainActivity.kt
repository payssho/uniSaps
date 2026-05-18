package com.unisaps.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun getInitialRoute(): String {
        val data = intent?.data
        // Sans ça, Flutter envoie l’URI brute (ex. unisaps://home?tab=outfits) comme route :
        // GoRouter ne matche pas → « page not found ». Le plugin home_widget garde l’URI pour le listener Dart.
        if (data != null && data.scheme == "unisaps") {
            return "/home"
        }
        return super.getInitialRoute() ?: "/login"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.scheme == "unisaps") {
            // home_widget transmet l’URI via intent ; le listener Flutter gère la navigation.
        }
    }
}
