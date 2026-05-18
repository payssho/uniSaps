package com.unisaps.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.unisaps.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget A — Outfit du jour (affichage). */
class DailyOutfitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_outfit)

            if (!WidgetDataHelper.isLoggedIn(widgetData)) {
                views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_login))
                views.setTextViewText(R.id.widget_subtitle, "")
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setViewVisibility(R.id.widget_streak, View.GONE)
                views.setViewVisibility(R.id.widget_thumbs_row, View.GONE)
            } else if (!WidgetDataHelper.hasChosenToday(widgetData)) {
                views.setTextViewText(
                    R.id.widget_title,
                    context.getString(R.string.widget_no_outfit_title),
                )
                views.setTextViewText(
                    R.id.widget_subtitle,
                    context.getString(R.string.widget_no_outfit_subtitle),
                )
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setViewVisibility(R.id.widget_streak, View.GONE)
                views.setViewVisibility(R.id.widget_thumbs_row, View.GONE)
            } else {
                val name = widgetData.getString(WidgetDataHelper.KEY_OUTFIT_NAME, "") ?: ""
                val streak = widgetData.getInt(WidgetDataHelper.KEY_STREAK, 0)
                views.setTextViewText(
                    R.id.widget_title,
                    context.getString(R.string.widget_daily_title),
                )
                views.setTextViewText(R.id.widget_subtitle, name.ifEmpty { "—" })
                views.setViewVisibility(R.id.widget_streak, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_streak,
                    context.getString(R.string.widget_streak_format, streak),
                )

                val photo = widgetData.getString(WidgetDataHelper.KEY_DAILY_PHOTO, "")
                if (!photo.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                    WidgetDataHelper.setImageFromPath(views, R.id.widget_image, photo)
                    views.setViewVisibility(R.id.widget_thumbs_row, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_image, View.GONE)
                    val thumbs = WidgetDataHelper.garmentThumbPaths(widgetData)
                    if (thumbs.isNotEmpty()) {
                        views.setViewVisibility(R.id.widget_thumbs_row, View.VISIBLE)
                        val ids = intArrayOf(
                            R.id.widget_thumb_1,
                            R.id.widget_thumb_2,
                            R.id.widget_thumb_3,
                            R.id.widget_thumb_4,
                        )
                        for (i in ids.indices) {
                            if (i < thumbs.size) {
                                WidgetDataHelper.setImageFromPath(views, ids[i], thumbs[i])
                            } else {
                                views.setViewVisibility(ids[i], View.GONE)
                            }
                        }
                    } else {
                        views.setViewVisibility(R.id.widget_thumbs_row, View.GONE)
                    }
                }
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetDataHelper.clickIntent(context, "unisaps://home?tab=outfits"),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
