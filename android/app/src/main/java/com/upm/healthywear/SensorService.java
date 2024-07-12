    package com.upm.healthywear;

    import android.app.Service;
    import android.content.Intent;
    import android.os.IBinder;
    import android.app.Notification;
    import android.app.NotificationChannel;
    import android.app.NotificationManager;
    import androidx.core.app.NotificationCompat;
    import android.content.res.Configuration;
    import java.util.Locale;
    import android.content.SharedPreferences;
    import android.preference.PreferenceManager;
    import androidx.core.content.ContextCompat;
    import android.Manifest;
    import android.content.pm.PackageManager;


    import android.os.Build;
    import android.util.Log;

    public class SensorService extends Service {
        private MetaWearHandler metaWearHandler;

        private static final String TAG = "SensorService";


        @Override
        public void onCreate() {
            super.onCreate();
            metaWearHandler = new MetaWearHandler(this, null); // Adjust constructor as needed

        }

        @Override
        public int onStartCommand(Intent intent, int flags, int startId) {

            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "Location permission not granted");
                stopSelf(); // Stop the service if required permissions are not granted
            }

            if (intent != null && intent.hasExtra("LANGUAGE_CODE")) {
                String languageCode = intent.getStringExtra("LANGUAGE_CODE");
                Log.d(TAG, "Service started with LANGUAGE_CODE:AMIR " + languageCode);
                setLocale(languageCode);
            } else {
                Log.d(TAG, "No LANGUAGE_CODE provided, using default.AMIR");
            }



            startForegroundServiceWithNotification();

            return START_STICKY;
        }

        private void applySavedLocale() {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
            String languageCode = prefs.getString("languageCode", "es");
            setLocale(languageCode);
        }

        public void setLocale(String languageCode) {
            Locale locale = new Locale(languageCode);
            android.util.Log.d(TAG, "setLocale: issssssssssssss AMIR"+locale);
            Locale.setDefault(locale);
            Configuration config = new Configuration(getResources().getConfiguration());
            config.setLocale(locale);
            getResources().updateConfiguration(config, getResources().getDisplayMetrics());
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
