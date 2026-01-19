package studentCompanionUI.ionic.io;

import android.os.Bundle;

import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;

import com.getcapacitor.BridgeActivity;

import java.util.concurrent.TimeUnit;

import studentCompanionUI.ionic.io.notifications.NotificationServiceDefinition;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(UniversisScraperDefinition.class);
        registerPlugin(ElearningScraperDefinition.class);
        registerPlugin(WebmailInboxScraperDefinition.class);
        registerPlugin(NotificationServiceDefinition.class);
        registerPlugin(RefresherServiceDefinition.class);

        PeriodicWorkRequest request =
                new PeriodicWorkRequest.Builder(
                        DailyWidgetWorker.class,
                        1, TimeUnit.DAYS
                ).build();

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "daily_widget_update",
                ExistingPeriodicWorkPolicy.KEEP,
                request
        );

        super.onCreate(savedInstanceState);
    }
}
