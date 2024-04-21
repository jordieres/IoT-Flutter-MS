    package com.upm.healthywear;

    import android.app.Service;
    import android.content.Intent;
    import android.os.IBinder;
    import android.app.Notification;
    import android.app.NotificationChannel;
    import android.app.NotificationManager;
    import androidx.core.app.NotificationCompat;

    import android.os.Build;
    import android.util.Log;

    public class SensorService extends Service {
        private MetaWearHandler metaWearHandler;

        @Override
        public void onCreate() {
            super.onCreate();
            metaWearHandler = new MetaWearHandler(this, null); // Adjust constructor as needed

        }

        @Override
        public int onStartCommand(Intent intent, int flags, int startId) {
            startForegroundServiceWithNotification();

            return START_STICKY;
        }

        private void startForegroundServiceWithNotification() {
            String channelId = "sensor_service_channel";

            NotificationCompat.Builder builder = new NotificationCompat.Builder(this, channelId)
                    .setContentTitle(getString(R.string.service_notification_title))
                    .setContentText(getString(R.string.service_notification_content))
                    .setSmallIcon(R.mipmap.ic_notification)
                    .setPriority(NotificationCompat.PRIORITY_HIGH);

            Notification notification = builder.build();

            startForeground(1, notification);
        }


        @Override
        public IBinder onBind(Intent intent) {
            return null;
        }

        @Override
        public void onDestroy() {
            super.onDestroy();
            // Optional: Stop your sensor data collection here
        }
    }
