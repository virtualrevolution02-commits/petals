package com.bharathi.petals

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.time.Instant

/**
 * PetalsWidget — handles all 4 widget types:
 *   1. SmallWidget   (2×2)   — photo/status
 *   2. MediumWidget  (4×2)   — photo + caption
 *   3. LargeWidget   (4×4)   — header tag + photo + full info
 *   4. CompactWidget (4×1)   — banner strip
 */
open class PetalsWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Handled in onReceive directly to support coroutines with goAsync()
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        // Both Android system updates and our manual intent use this action
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            
            // Extract IDs from intent if available, otherwise get all for this class
            val extras = intent.extras
            var widgetIds = extras?.getIntArray(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            if (widgetIds == null || widgetIds.isEmpty()) {
                val componentName = android.content.ComponentName(context, javaClass)
                widgetIds = manager.getAppWidgetIds(componentName)
            }
            
            if (widgetIds != null && widgetIds.isNotEmpty()) {
                val pendingResult = goAsync()
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        for (widgetId in widgetIds) {
                            updateWidget(context, manager, widgetId)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Coroutine error", e)
                    } finally {
                        pendingResult.finish()
                    }
                }
            }
        }
    }

    companion object {
        private const val TAG = "PetalsWidget"

        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun getPrefsString(context: Context, key: String): String? {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getString(key, null)
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            try {
                val widgetInfo = appWidgetManager.getAppWidgetInfo(widgetId) ?: return
                val providerClass = widgetInfo.provider.className

                // Read data saved by Flutter home_widget package
                val imageUrl = getPrefsString(context, "widget_image_url")
                val imagePath = getPrefsString(context, "widget_image_path")
                val myName = getPrefsString(context, "widget_my_name")
                val partnerName = getPrefsString(context, "widget_partner_name")
                val posterName = getPrefsString(context, "widget_poster_name")
                val caption = getPrefsString(context, "widget_caption")
                val timeStr = getPrefsString(context, "widget_time")

                Log.d(TAG, "Widget data — imageUrl=$imageUrl imagePath=$imagePath caption=$caption")

                val hasImage = !imageUrl.isNullOrEmpty() || (!imagePath.isNullOrEmpty() && File(imagePath).exists())
                val defaultPartner = if (!partnerName.isNullOrEmpty()) partnerName else "Partner"

                val displayCaption = when {
                    hasImage && !caption.isNullOrEmpty() -> caption
                    !partnerName.isNullOrEmpty() -> "Connected with $partnerName 💕"
                    else -> "Connected 💕"
                }

                val displayPoster = if (hasImage) {
                    "from ${if (!posterName.isNullOrEmpty()) posterName else defaultPartner}"
                } else {
                    "Waiting for moments... 🌸"
                }

                val timeLabel = if (hasImage && !timeStr.isNullOrEmpty()) {
                    formatRelativeTime(timeStr)
                } else {
                    "tap to open"
                }

                val coupleTitle = when {
                    !myName.isNullOrEmpty() && !partnerName.isNullOrEmpty() -> "$myName & $partnerName"
                    !partnerName.isNullOrEmpty() -> "Connected with $partnerName"
                    else -> "you & $defaultPartner"
                }

                // Determine layout based on provider class name
                val (layoutId, imageViewId) = when {
                    providerClass.contains("Small") ->
                        Pair(R.layout.widget_small, R.id.widget_small_image)
                    providerClass.contains("Medium") ->
                        Pair(R.layout.widget_medium, R.id.widget_medium_image)
                    providerClass.contains("Large") ->
                        Pair(R.layout.widget_large, R.id.widget_large_image)
                    else ->
                        Pair(R.layout.widget_compact, R.id.widget_compact_image)
                }

                val views = RemoteViews(context.packageName, layoutId)

                // Set text fields depending on widget type
                when {
                    providerClass.contains("Small") -> {
                        views.setTextViewText(R.id.widget_small_caption, displayCaption)
                    }
                    providerClass.contains("Medium") -> {
                        views.setTextViewText(R.id.widget_medium_caption, displayCaption)
                        views.setTextViewText(R.id.widget_medium_poster, displayPoster)
                    }
                    providerClass.contains("Large") -> {
                        views.setTextViewText(R.id.widget_large_tag, "🌸 $coupleTitle")
                        views.setTextViewText(R.id.widget_large_caption, displayCaption)
                        views.setTextViewText(R.id.widget_large_poster, displayPoster)
                        views.setTextViewText(R.id.widget_large_time, timeLabel)
                    }
                    else -> {
                        // Compact
                        views.setTextViewText(R.id.widget_compact_caption, displayCaption)
                        views.setTextViewText(
                            R.id.widget_compact_poster,
                            "$displayPoster · $timeLabel"
                        )
                    }
                }

                // Tap to open app - use explicit intent to bypass Package Visibility restrictions
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = android.net.Uri.parse("petals://upload")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, widgetId, launchIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE
                )
                // Set click listener on the entire widget root, not just the image
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // Always set placeholder first
                views.setImageViewResource(imageViewId, R.drawable.widget_placeholder)

                // Load image synchronously (safe because we are inside CoroutineScope(Dispatchers.IO))
                val loadedBitmap = loadBitmapSync(context, imagePath, imageUrl)
                if (loadedBitmap != null) {
                    views.setImageViewBitmap(imageViewId, loadedBitmap)
                }

                // Finally update the widget with all text and bitmap
                appWidgetManager.updateAppWidget(widgetId, views)

            } catch (e: Exception) {
                Log.e(TAG, "Fatal error in updateWidget", e)
            }
        }

        private fun loadBitmapSync(context: Context, imagePath: String?, imageUrl: String?): Bitmap? {
            // 1. Try local file path first
            if (!imagePath.isNullOrEmpty()) {
                val localFile = File(imagePath)
                if (localFile.exists() && localFile.length() > 0) {
                    try {
                        return Glide.with(context.applicationContext)
                            .asBitmap()
                            .load(localFile)
                            .override(400, 400)
                            .centerCrop()
                            .diskCacheStrategy(DiskCacheStrategy.NONE) // File is already local
                            .submit()
                            .get()
                    } catch (e: Exception) {
                        Log.e(TAG, "Glide local file load failed", e)
                    }
                }
            }

            // 2. Try Base64 encoded image
            if (!imageUrl.isNullOrEmpty() && imageUrl.startsWith("data:image")) {
                try {
                    val base64Clean = imageUrl.substringAfter(",")
                    val imageBytes = android.util.Base64.decode(base64Clean, android.util.Base64.DEFAULT)
                    return Glide.with(context.applicationContext)
                        .asBitmap()
                        .load(imageBytes)
                        .override(400, 400)
                        .centerCrop()
                        .submit()
                        .get()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to decode base64 image", e)
                }
            }

            // 3. Try HTTP URL with Glide
            if (!imageUrl.isNullOrEmpty() && (imageUrl.startsWith("http://") || imageUrl.startsWith("https://"))) {
                try {
                    return Glide.with(context.applicationContext)
                        .asBitmap()
                        .load(imageUrl)
                        .override(400, 400)
                        .centerCrop()
                        .diskCacheStrategy(DiskCacheStrategy.ALL)
                        .submit()
                        .get()
                } catch (e: Exception) {
                    Log.e(TAG, "Glide HTTP load failed", e)
                }
            }

            return null
        }

        private fun formatRelativeTime(isoString: String): String {
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val instant = Instant.parse(isoString)
                    val now = Instant.now()
                    val diffSec = now.epochSecond - instant.epochSecond
                    when {
                        diffSec < 60 -> "just now"
                        diffSec < 3600 -> "${diffSec / 60}m ago"
                        diffSec < 86400 -> "${diffSec / 3600}h ago"
                        else -> "${diffSec / 86400}d ago"
                    }
                } else {
                    "recently"
                }
            } catch (e: Exception) {
                "recently"
            }
        }
    }
}

// Four separate provider classes registered in AndroidManifest
class SmallWidget : PetalsWidget()
class MediumWidget : PetalsWidget()
class LargeWidget : PetalsWidget()
class CompactWidget : PetalsWidget()
