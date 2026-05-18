package com.unisaps.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.unisaps.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** Météo + nombre de looks compatibles + carrousel photo (swipe). Toucher → mode swipe. */
class TodayPickWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_today_pick)

            if (!WidgetDataHelper.isLoggedIn(widgetData)) {
                views.setViewVisibility(R.id.widget_temp, View.GONE)
                views.setViewVisibility(R.id.widget_weather_label, View.GONE)
                views.setViewVisibility(R.id.widget_suitable_line, View.GONE)
                views.setViewVisibility(R.id.widget_pick_flipper, View.GONE)
                views.setTextViewText(R.id.widget_today_title, "")
                views.setTextViewText(
                    R.id.widget_hint,
                    context.getString(R.string.widget_login),
                )
            } else {
                views.setViewVisibility(R.id.widget_temp, View.VISIBLE)
                views.setViewVisibility(R.id.widget_weather_label, View.VISIBLE)
                views.setViewVisibility(R.id.widget_suitable_line, View.VISIBLE)

                views.setTextViewText(
                    R.id.widget_today_title,
                    context.getString(R.string.widget_today_headline),
                )

                val temp = widgetData.getString(WidgetDataHelper.KEY_WEATHER_TEMP, "") ?: ""
                val label = widgetData.getString(WidgetDataHelper.KEY_WEATHER_LABEL, "") ?: ""
                views.setTextViewText(R.id.widget_temp, temp.ifEmpty { "—" })
                views.setTextViewText(
                    R.id.widget_weather_label,
                    label.ifEmpty { context.getString(R.string.widget_today_weather_fallback) },
                )

                val count = widgetData.getInt(WidgetDataHelper.KEY_SUITABLE_COUNT, 0)
                views.setTextViewText(
                    R.id.widget_suitable_line,
                    if (count > 0) {
                        context.getString(R.string.widget_today_suitable, count)
                    } else {
                        context.getString(R.string.widget_today_suitable_zero)
                    },
                )

                val pickPaths = WidgetDataHelper.suitablePickCarouselPaths(widgetData)
                if (pickPaths.isEmpty()) {
                    views.setViewVisibility(R.id.widget_pick_flipper, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_pick_flipper, View.VISIBLE)
                    val svc = Intent(context, CarouselRemoteViewsService::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                        putExtra(
                            CarouselRemoteViewsService.EXTRA_KIND,
                            CarouselRemoteViewsService.KIND_SUITABLE_PICK,
                        )
                        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                    }
                    views.setRemoteAdapter(R.id.widget_pick_flipper, svc)
                }

                val hint =
                    if (WidgetDataHelper.hasChosenToday(widgetData)) {
                        context.getString(R.string.widget_today_hint_change)
                    } else {
                        context.getString(R.string.widget_today_hint_swipe)
                    }
                views.setTextViewText(R.id.widget_hint, hint)
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetDataHelper.clickIntent(context, "unisaps://home?tab=outfits&mode=swipe"),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
            if (WidgetDataHelper.isLoggedIn(widgetData) &&
                WidgetDataHelper.suitablePickCarouselPaths(widgetData).isNotEmpty()
            ) {
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_pick_flipper)
            }
        }
    }
}
