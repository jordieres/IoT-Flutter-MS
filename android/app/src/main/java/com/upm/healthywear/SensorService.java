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
            // Initialize MetaWearHandler here
            metaWearHandler = new MetaWearHandler(this, null); // Adjust constructor as needed
            // Start your sensor data collection here, or in onStartCommand

        }

        @Override
        public int onStartCommand(Intent intent, int flags, int startId) {
            // Ensure you use the same channel ID when creating the notification
            startForegroundServiceWithNotification();

            return START_STICKY;
        }

        private void startForegroundServiceWithNotification() {
            // Ensure you use the same channel ID that was used for channel creation in MainActivity
            String channelId = "sensor_service_channel";

            // Build the notification with compatibility in mind
            NotificationCompat.Builder builder = new NotificationCompat.Builder(this, channelId)
                    .setContentTitle(getString(R.string.service_notification_title)) // Set your notification title here
                    .setContentText(getString(R.string.service_notification_content)) // Set your notification content here
                    .setSmallIcon(R.mipmap.ic_notification) // Set your notification icon here
                    .setPriority(NotificationCompat.PRIORITY_HIGH);

            Notification notification = builder.build();

            // Start foreground service with the created notification
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
