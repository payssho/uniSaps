package com.unisaps.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.unisaps.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget B — Choisir / changer son outfit du jour. */
class PickOutfitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_pick_outfit)

            val deepLink: String
            if (!WidgetDataHelper.isLoggedIn(widgetData)) {
                views.setTextViewText(R.id.widget_pick_title, context.getString(R.string.widget_login))
                views.setTextViewText(R.id.widget_pick_subtitle, "")
                views.setViewVisibility(R.id.widget_pick_preview, View.GONE)
                views.setViewVisibility(R.id.widget_pick_weather, View.GONE)
                deepLink = "unisaps://home"
            } else if (WidgetDataHelper.hasChosenToday(widgetData)) {
                val name = widgetData.getString(WidgetDataHelper.KEY_OUTFIT_NAME, "") ?: ""
                views.setTextViewText(
                    R.id.widget_pick_title,
                    context.getString(R.string.widget_pick_change_title),
                )
                views.setTextViewText(R.id.widget_pick_subtitle, name.ifEmpty { "—" })
                val photo = widgetData.getString(WidgetDataHelper.KEY_DAILY_PHOTO, "")
                if (!photo.isNullOrEmpty()) {
                    views.setViewVisibility(R.id.widget_pick_preview, View.VISIBLE)
                    WidgetDataHelper.setImageFromPath(views, R.id.widget_pick_preview, photo)
                } else {
                    val thumbs = WidgetDataHelper.garmentThumbPaths(widgetData)
                    if (thumbs.isNotEmpty()) {
                        views.setViewVisibility(R.id.widget_pick_preview, View.VISIBLE)
                        WidgetDataHelper.setImageFromPath(views, R.id.widget_pick_preview, thumbs[0])
                    } else {
                        views.setViewVisibility(R.id.widget_pick_preview, View.GONE)
                    }
                }
                views.setViewVisibility(R.id.widget_pick_weather, View.GONE)
                deepLink = "unisaps://home?tab=outfits"
            } else {
                views.setTextViewText(
                    R.id.widget_pick_title,
                    context.getString(R.string.widget_pick_choose_title),
                )
                val temp = widgetData.getString(WidgetDataHelper.KEY_WEATHER_TEMP, "") ?: ""
                val label = widgetData.getString(WidgetDataHelper.KEY_WEATHER_LABEL, "") ?: ""
                val count = widgetData.getInt(WidgetDataHelper.KEY_SUITABLE_COUNT, 0)
                val weatherLine = when {
                    temp.isNotEmpty() && label.isNotEmpty() -> "$temp · $label"
                    temp.isNotEmpty() -> temp
                    label.isNotEmpty() -> label
                    else -> ""
                }
                val countLine = if (count > 0) {
                    context.getString(R.string.widget_suitable_count, count)
                } else {
                    context.getString(R.string.widget_pick_choose_subtitle)
                }
                views.setTextViewText(
                    R.id.widget_pick_subtitle,
                    if (weatherLine.isNotEmpty()) "$weatherLine\n$countLine" else countLine,
                )
                views.setViewVisibility(R.id.widget_pick_preview, View.GONE)
                views.setViewVisibility(R.id.widget_pick_weather, View.VISIBLE)
                views.setTextViewText(R.id.widget_pick_weather, weatherLine.ifEmpty { "☀" })
                deepLink = "unisaps://home?tab=outfits&mode=swipe"
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetDataHelper.clickIntent(context, deepLink),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
