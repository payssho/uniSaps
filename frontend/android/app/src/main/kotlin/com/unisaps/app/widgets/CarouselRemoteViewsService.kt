package com.unisaps.app.widgets

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.unisaps.app.R
import es.antonborri.home_widget.HomeWidgetPlugin

/** Alimente les [AdapterViewFlipper] (tenues / dressing / choix du jour), flip ~7 s dans le XML. */
class CarouselRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        CarouselViewsFactory(applicationContext, intent)

    companion object {
        const val EXTRA_KIND = "carousel_kind"
        const val KIND_OUTFIT = "outfit"
        const val KIND_DRESSING = "dressing"
        const val KIND_SUITABLE_PICK = "suitable_pick"
    }
}

private class CarouselViewsFactory(
    private val context: Context,
    private val intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {

    private var paths: List<String> = emptyList()
    private var names: List<String> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = HomeWidgetPlugin.getData(context)
        val kind = intent.getStringExtra(CarouselRemoteViewsService.EXTRA_KIND)
            ?: CarouselRemoteViewsService.KIND_OUTFIT
        val pathsKey = when (kind) {
            CarouselRemoteViewsService.KIND_DRESSING ->
                WidgetDataHelper.KEY_GARMENT_CAROUSEL_PATHS
            CarouselRemoteViewsService.KIND_SUITABLE_PICK ->
                WidgetDataHelper.KEY_SUITABLE_PICK_CAROUSEL_PATHS
            else -> WidgetDataHelper.KEY_OUTFIT_CAROUSEL_PATHS
        }
        val namesKey = when (kind) {
            CarouselRemoteViewsService.KIND_DRESSING ->
                WidgetDataHelper.KEY_GARMENT_CAROUSEL_NAMES
            CarouselRemoteViewsService.KIND_SUITABLE_PICK ->
                WidgetDataHelper.KEY_SUITABLE_PICK_CAROUSEL_NAMES
            else -> WidgetDataHelper.KEY_OUTFIT_CAROUSEL_NAMES
        }
        val praw = prefs.getString(pathsKey, "") ?: ""
        val nraw = prefs.getString(namesKey, "") ?: ""
        paths = praw.split("|").filter { it.isNotEmpty() }
        val nameParts = nraw.split("|").map { it.trim() }
        names = paths.indices.map { i -> nameParts.getOrElse(i) { "" } }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = paths.size

    override fun getViewAt(position: Int): RemoteViews {
        val rv = RemoteViews(context.packageName, R.layout.widget_carousel_item)
        val path = paths.getOrNull(position) ?: return rv
        val bmp = WidgetDataHelper.loadBitmapForWidget(path)
        if (bmp != null) {
            rv.setImageViewBitmap(R.id.carousel_image, bmp)
            val label = names.getOrNull(position)?.takeIf { it.isNotBlank() } ?: ""
            rv.setTextViewText(R.id.carousel_label, label)
            rv.setViewVisibility(
                R.id.carousel_label,
                if (label.isEmpty()) View.GONE else View.VISIBLE,
            )
        } else {
            rv.setImageViewResource(R.id.carousel_image, android.R.drawable.ic_menu_gallery)
            rv.setViewVisibility(R.id.carousel_label, View.GONE)
        }
        return rv
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
