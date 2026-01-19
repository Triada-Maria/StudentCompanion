package studentCompanionUI.ionic.io;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;
import org.json.JSONObject;
import org.json.JSONArray;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class DailyWidgetWorker extends Worker {
    public DailyWidgetWorker(@NonNull Context context,
                             @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        try {
            // 1. Call API
            URL url = new URL("https://api.aristomate.auth.gr/menu");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream())
            );
            StringBuilder jsonBuilder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                jsonBuilder.append(line);
            }
            reader.close();

            // 2. Parse JSON to get the "full" value from first menu item
            JSONObject json = new JSONObject(jsonBuilder.toString());
            JSONObject menu = json.getJSONObject("menu");
            JSONArray days = menu.getJSONArray("days");
            JSONObject firstDay = days.getJSONObject(0);
            String fullValue = firstDay.getString("full");

            // 3. Store value
            SharedPreferences prefs = getApplicationContext()
                    .getSharedPreferences("widget_data", Context.MODE_PRIVATE);
            prefs.edit()
                    .putString("menu_full", fullValue)
                    .apply();

            // 4. Update widget
            updateWidget(getApplicationContext(), fullValue);

            return Result.success();
        } catch (Exception e) {
            e.printStackTrace();
            return Result.retry();
        }
    }

    private void updateWidget(Context context, String value) {
        AppWidgetManager manager = AppWidgetManager.getInstance(context);
        ComponentName widget = new ComponentName(context, DemoWidgetProvider.class);
        RemoteViews views =
                new RemoteViews(context.getPackageName(), R.layout.widget_demo);
        views.setTextViewText(R.id.widgetText, value);
        manager.updateAppWidget(widget, views);
    }
}