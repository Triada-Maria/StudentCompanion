package studentCompanionUI.ionic.io;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

public class DemoWidgetProvider extends AppWidgetProvider {

    @Override
    public void onUpdate(Context context,
                         AppWidgetManager appWidgetManager,
                         int[] appWidgetIds) {

        // Trigger immediate fetch when widget is added/updated
        OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(DailyWidgetWorker.class).build();
        WorkManager.getInstance(context).enqueue(workRequest);

        SharedPreferences prefs =
                context.getSharedPreferences("widget_data", Context.MODE_PRIVATE);

        // Retrieve the stored menu full value
        String menuFull = prefs.getString("menu_full", "Loading menu...");

        for (int widgetId : appWidgetIds) {
            RemoteViews views =
                    new RemoteViews(context.getPackageName(), R.layout.widget_demo);

            // Set the menu content to the widget text view
            views.setTextViewText(R.id.widgetText, menuFull);

            // Optional: Add click listener to refresh the widget
            Intent intent = new Intent(context, DemoWidgetProvider.class);
            intent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds);
            PendingIntent pendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widgetText, pendingIntent);

            appWidgetManager.updateAppWidget(widgetId, views);
        }
    }
}