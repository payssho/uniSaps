package com.unisaps.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.unisaps.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget C — Inspi du jour (dernier post d’un ami). */
class InspiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_inspi)

            if (!WidgetDataHelper.isLoggedIn(widgetData)) {
                views.setTextViewText(R.id.widget_inspi_title, context.getString(R.string.widget_login))
                views.setTextViewText(R.id.widget_inspi_username, "")
                views.setViewVisibility(R.id.widget_inspi_image, View.GONE)
            } else if (!widgetData.getBoolean(WidgetDataHelper.KEY_INSPI_HAS, false)) {
                views.setTextViewText(
                    R.id.widget_inspi_title,
                    context.getString(R.string.widget_inspi_empty_title),
                )
                views.setTextViewText(
                    R.id.widget_inspi_username,
                    context.getString(R.string.widget_inspi_empty_subtitle),
                )
                views.setViewVisibility(R.id.widget_inspi_image, View.GONE)
            } else {
                views.setTextViewText(
                    R.id.widget_inspi_title,
                    context.getString(R.string.widget_inspi_title),
                )
                val username = widgetData.getString(WidgetDataHelper.KEY_INSPI_USERNAME, "") ?: ""
                views.setTextViewText(R.id.widget_inspi_username, username)
                val path = widgetData.getString(WidgetDataHelper.KEY_INSPI_IMAGE, "")
                WidgetDataHelper.setImageFromPath(views, R.id.widget_inspi_image, path)
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetDataHelper.clickIntent(context, "unisaps://home?tab=inspo"),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
