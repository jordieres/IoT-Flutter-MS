# HealthyWear

HealthyWear collects wearable sensor data for gait studies, including people
with multiple sclerosis walking at their usual pace. The Flutter interface is
shared by Android and iOS; Bluetooth device handling is native to each platform.
Sensoria socks are the current priority.

## Release status

The latest Android version uploaded to Google Play is **3.0.1**, as reported by
the maintainer. `pubspec.yaml` currently declares `3.0.1+30`. The current source
checkpoint contains fixes made after that upload and must not be treated as an
exact copy of the submitted binary. iOS is being tested before App Store submission.
See [release history](CHANGELOG.md) for changes and versioning practice.

## Devices and platforms

| Device | Android | iOS |
| --- | --- | --- |
| Sensoria socks, left and right | Supported | Supported; physical-device validation required |
| MetaWear movement sensors | Supported | Supported |
| HBand | Android integration | Hidden and excluded from the iOS plugin registration |

## Sensoria session flow

1. Connect the left and/or right sock. The app reads the server profile, checks
   device ranges and rates, applies changes, and verifies the values. Connection
   alone does **not** start measurement streaming or recording.
2. Press **Iniciar / Start** to open the walking instructions. The socks still wait.
3. Press **Vamos / Go** to begin the 20-second local walking trial. Measurements
   are used for the trial without creating recording files or uploading trial data.
4. Trial completion, interruption, or leaving the trial pauses measurements. A
   pressure or movement issue asks the user to adjust the sock and repeat.
   A calibration issue opens the guided magnetometer calibration.
5. Calibration reports a result for each sock separately and returns the sock to
   waiting. When ready, the final **Start** begins recording.
6. Walking test selections flag the recording already in progress. **Stop** pauses
   measurements and saves the remaining recorded data. Pending recorded files may
   finish uploading afterward.

The pulse indicator represents fresh data during recording. Intentionally idle
socks must not produce missing-data alerts. Bluetooth debug rows indicate data
received by the phone; they do not by themselves prove that data was uploaded.

The gear menu opens device settings, with connected left and right sock values
and calibration actions. Server settings are applied on connection; changing the
server profile does not modify an active recording in the middle of a session.

## Development setup

Use **Flutter 3.41.7** from `.fvmrc`, **Java 17** for Android, Android SDK 36, and
Xcode with CocoaPods for iOS. Android supports API 24 or later; iOS targets 15 or
later. Use real devices for Bluetooth testing.

```sh
fvm install
fvm flutter pub get
fvm flutter test
fvm flutter run
```

Provide the local `assets/config.txt` expected by `lib/Service/Uploader.dart`
using your deployment configuration. It is deliberately excluded from Git.
Do not put signing passwords or private keys in tracked configuration.

### Android

```sh
fvm flutter build apk --debug
fvm flutter build appbundle --release
```

Release signing reads the local `android/keystore.properties`. Start from
[`android/keystore.properties.example`](android/keystore.properties.example),
set the private keystore path and credentials locally, and keep the real file
and keystore out of Git. Do not replace an existing production signing key
without completing the corresponding Play Console signing procedure.

### iOS

```sh
cd ios
pod install
open Runner.xcworkspace
```

Select the correct team and signing profile in Xcode and run on an iPhone.
The app uses the UIKit scene lifecycle with Flutter's implicit engine delegate.
The iOS build does not register the HBand plugin. A successful build does not
replace testing both socks, the trial, calibration, recording, and Stop on an iPhone.

## Server settings editor

The password-protected editor is at
[apiict03 HealthyWear settings](https://apiict03.etsii.upm.es/healthywear/admin).
It supports accelerometer, gyroscope, and magnetometer range and sampling rate,
the Bluetooth packet period, and administrator password changes.

The app reads `/healthywear/sensoria-settings.json` over HTTPS and falls back to
the last valid cached profile, or built-in ranges of **8 g / 1000 degrees/s /
4 gauss**. An omitted rate or packet period, or a value of zero, keeps that
setting on the device. Those defaults are configuration values, not proof that
a device is calibrated. Firmware support must be verified on real socks; one
Core rejected the 245 degrees/s gyroscope setting during testing.

See [server deployment and protocol notes](server/README.md). The profile JSON
is intended to be public; administrator password hashes and signing credentials
must remain private.

## Source map

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Main screen and session controls |
| `lib/sensoria_setup_screen.dart` | Walking trial and calibration guidance |
| `lib/healthywear_settings_screen.dart` | Connected device settings |
| `lib/Api/SensoriaApi.dart` | Flutter/native Sensoria interface |
| `lib/Api/SensoriaSettings.dart` | Validated server profile and cache |
| `android/app/src/main/java/com/upm/healthywear/SensoriaHandler.java` | Android connection and capture lifecycle |
| `ios/Runner/Sensoria/SensoriaHandler.swift` | iOS connection and capture lifecycle |
| `server/` | Settings editor, profile validation, and deployment templates |
| `test/` | Flutter regression tests |

The Android Sensoria archive includes a compatibility patch for disconnect and
invalid streaming settings. Its patch source is
`android/sdk-tools/PatchSensoriaDisconnect.java`. The MetaWear archive was rebuilt
from MbientLab's 3.8.1 tag; its license is alongside the archive. The iOS Sensoria
interface metadata targets iOS 15 for compatibility with the current toolchain.

## Validation and signing protection

```sh
fvm flutter test
python3 scripts/check_signing_secrets.py --history
```

On 21 November 2026, all 36 Flutter tests passed, Android debug and iOS Profile
builds succeeded, and a live Samsung test verified two socks waiting after
connection, a local trial, both calibrations, recording, Stop, and server upload
confirmation. The equivalent iPhone Bluetooth sequence still needs validation.

The signing-file check also runs in GitHub Actions. It rejects private signing
containers, real signing property files, and hard-coded Gradle signing passwords
in tracked files or reachable history;
it is not a general scanner for every possible secret.

The previously published keystore and passwords must be treated as exposed.
Removing them from Git history cannot revoke downloaded copies. Complete the
appropriate upload-key reset or app-signing-key procedure in Play Console.
After history cleanup, collaborators should clone again rather than merging old
branches that could reintroduce the removed files. GitHub Support may also be
needed to clear cached views or pull-request references.
