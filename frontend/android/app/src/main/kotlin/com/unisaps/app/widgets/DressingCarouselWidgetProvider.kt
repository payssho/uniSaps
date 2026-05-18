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

/** Carrousel des pièces du dressing (~7 s). Toucher → onglet Dressing. */
class DressingCarouselWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_carousel_frame)
            views.setTextViewText(
                R.id.widget_header_title,
                context.getString(R.string.widget_carousel_dressing_title),
            )

            if (!WidgetDataHelper.isLoggedIn(widgetData)) {
                views.setViewVisibility(R.id.flipper, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setTextViewText(R.id.widget_empty, context.getString(R.string.widget_login))
            } else {
                val paths = WidgetDataHelper.garmentCarouselPaths(widgetData)
                if (paths.isEmpty()) {
                    views.setViewVisibility(R.id.flipper, View.GONE)
                    views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_empty,
                        context.getString(R.string.widget_carousel_dressing_empty),
                    )
                } else {
                    views.setViewVisibility(R.id.flipper, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_empty, View.GONE)
                    val svc = Intent(context, CarouselRemoteViewsService::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                        putExtra(
                            CarouselRemoteViewsService.EXTRA_KIND,
                            CarouselRemoteViewsService.KIND_DRESSING,
                        )
                        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                    }
                    views.setRemoteAdapter(R.id.flipper, svc)
                    views.setEmptyView(R.id.flipper, R.id.widget_empty)
                }
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                WidgetDataHelper.clickIntent(context, "unisaps://home?tab=dressing"),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
            if (WidgetDataHelper.isLoggedIn(widgetData) &&
                WidgetDataHelper.garmentCarouselPaths(widgetData).isNotEmpty()
            ) {
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.flipper)
            }
        }
    }
}
