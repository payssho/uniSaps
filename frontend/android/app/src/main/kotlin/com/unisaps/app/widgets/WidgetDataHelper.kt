package com.unisaps.app.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.exifinterface.media.ExifInterface
import com.unisaps.app.MainActivity
import com.unisaps.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.io.File

object WidgetDataHelper {
    const val KEY_AUTH_UID = "auth_uid"
    const val KEY_HAS_CHOSEN = "has_chosen_outfit_today"
    const val KEY_OUTFIT_NAME = "daily_outfit_name"
    const val KEY_STREAK = "current_streak"
    const val KEY_DAILY_PHOTO = "daily_photo_path"
    const val KEY_GARMENT_THUMBS = "garment_thumb_paths"
    const val KEY_WEATHER_TEMP = "weather_temp"
    const val KEY_WEATHER_LABEL = "weather_label"
    const val KEY_SUITABLE_COUNT = "suitable_outfits_count"
    const val KEY_INSPI_IMAGE = "inspi_image_path"
    const val KEY_INSPI_USERNAME = "inspi_username"
    const val KEY_INSPI_HAS = "inspi_has_content"

    fun isLoggedIn(data: SharedPreferences): Boolean {
        return !data.getString(KEY_AUTH_UID, "").isNullOrEmpty()
    }

    fun hasChosenToday(data: SharedPreferences): Boolean {
        return data.getBoolean(KEY_HAS_CHOSEN, false)
    }

    fun clickIntent(context: Context, deepLink: String): PendingIntent {
        return HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(deepLink),
        )
    }

    fun setImageFromPath(views: RemoteViews, viewId: Int, path: String?) {
        if (path.isNullOrEmpty()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        val file = File(path)
        if (!file.exists()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        val bmp = decodeBitmapWithExifOrientation(file.absolutePath) ?: run {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setImageViewBitmap(viewId, bmp)
    }

    /**
     * [BitmapFactory.decodeFile] ignore l’orientation EXIF : les JPEG portrait
     * apparaissent couchés dans les RemoteViews. On applique la rotation/miroir attendue.
     */
    private fun decodeBitmapWithExifOrientation(path: String): Bitmap? {
        val decoded = BitmapFactory.decodeFile(path) ?: return null
        return applyExifOrientation(decoded, path)
    }

    private fun applyExifOrientation(bitmap: Bitmap, path: String): Bitmap {
        val orientation = try {
            ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_UNDEFINED,
            )
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_UNDEFINED
        }

        if (orientation == ExifInterface.ORIENTATION_UNDEFINED ||
            orientation == ExifInterface.ORIENTATION_NORMAL
        ) {
            return bitmap
        }

        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL ->
                matrix.postScale(-1f, 1f, bitmap.width / 2f, bitmap.height / 2f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL ->
                matrix.postScale(1f, -1f, bitmap.width / 2f, bitmap.height / 2f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postRotate(90f)
                matrix.postScale(-1f, 1f, bitmap.height / 2f, bitmap.width / 2f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postRotate(-90f)
                matrix.postScale(-1f, 1f, bitmap.height / 2f, bitmap.width / 2f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(-90f)
            else -> return bitmap
        }

        return try {
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true).also {
                if (it !== bitmap && !bitmap.isRecycled) bitmap.recycle()
            }
        } catch (_: OutOfMemoryError) {
            bitmap
        }
    }

    fun garmentThumbPaths(data: SharedPreferences): List<String> {
        val raw = data.getString(KEY_GARMENT_THUMBS, "") ?: ""
        if (raw.isEmpty()) return emptyList()
        return raw.split("|").filter { it.isNotEmpty() }
    }
}
