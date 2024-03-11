package vn.com.tma.ehealth.veepoo_sdk;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * VeepooSdkPlugin
 */
public class VeepooSdkPlugin implements FlutterPlugin, ActivityAware {
    private final static String TAG = VeepooSdkPlugin.class.getSimpleName();

    public static final String COMMAND_CHANNEL = "veepoo/command";
    public static final String EVENT_CHANNEL = "veepoo/event";

    public static final String ACTION_SDK_NEW_EVENT = "vn.com.tma.ehealth.veepoo_sdk.ACTION_SDK_NEW_EVENT";


    private MethodChannel methodChannel;

    @Nullable
    private MethodCallHandlerImpl methodCallHandler;

    // ---------------------------------------------------------------------------------------------
    // Flutter plugin register

    @Override
    public void onAttachedToEngine(@NonNull final FlutterPluginBinding binding) {
        startListening(
                binding.getApplicationContext(),
                binding.getBinaryMessenger() // or getFlutterEngine().getDartExecutor()
        );
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
//        final VeepooSdkPlugin instance = new VeepooSdkPlugin();
//        registrar.addRequestPermissionsResultListener(instance);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        stopListening();
    }

    // ---
    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        startListeningToActivity(
                binding.getActivity()
        );
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        stopListeningToActivity();
    }

    private void startListening(Context applicationContext, BinaryMessenger messenger) {
        methodChannel = new MethodChannel(messenger, COMMAND_CHANNEL);

        methodCallHandler = new MethodCallHandlerImpl(
                applicationContext
        );

        new EventChannel(messenger, EVENT_CHANNEL)
                .setStreamHandler(
                        new EventChannel.StreamHandler() {
                            private BroadcastReceiver broadcastReceiver;

                            @Override
                            public void onListen(Object arguments, EventChannel.EventSink events) {
                                broadcastReceiver = methodCallHandler.createDeviceConnectStateChangeReceiver(events);
                                LocalBroadcastManager.getInstance(applicationContext).registerReceiver(broadcastReceiver, new IntentFilter(ACTION_SDK_NEW_EVENT));
                            }

                            @Override
                            public void onCancel(Object arguments) {
                                LocalBroadcastManager.getInstance(applicationContext).unregisterReceiver(broadcastReceiver);
                                broadcastReceiver = null;
                            }
                        }
                );

        methodChannel.setMethodCallHandler(methodCallHandler);
    }

    private void stopListening() {
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        methodCallHandler = null;
    }

    private void startListeningToActivity(
            Activity activity
    ) {
        if (methodCallHandler != null) {
            methodCallHandler.setActivity(activity);
        }
    }

    private void stopListeningToActivity() {
        if (methodCallHandler != null) {
            methodCallHandler.setActivity(null);
        }
    }
}
