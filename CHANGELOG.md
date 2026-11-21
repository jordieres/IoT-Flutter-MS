# HealthyWear release history

## Current checkpoint after Google Play 3.0.1

Google Play version **3.0.1** is the last upload reported by the maintainer. The
working package declares `3.0.1+30`. This checkpoint includes later fixes; it is
not an exact reconstruction of the uploaded binary.

- Separate Sensoria connection, local walking trial, calibration, and recording.
- Keep socks idle after connection and calibration; pause at trial completion and Stop.
- Improve two-sock connection, disconnection, configuration verification, and calibration results.
- Add per-sock settings and calibration screens and the password-protected server editor.
- Correct Android permission requests and iOS scene startup and device-card layout.
- Restore the UPM splash credit and improve the trial button and permission dialog.
- Exclude signing credentials and clean the signing files from repository history.

Earlier development steps were not committed consistently. No missing release
commits or release tags have been invented. Make a reviewed commit for each future
change, and tag the exact commit used for each store submission. Increment the
app version and build number before the next store upload.

## Historical notes

The following notes are preserved from the previous README. They are not newly
created release tags or reconstructions of old builds.

### Version 1.0.0
- First release
- Android native is functional

### Version 1.0.1
- UI improvement
- Data handling improvement

### Version 1.0.2
- UI improvement
- Minor bugs Fixed
- Upload data improvement

### Version 1.0.3
- UI improvement
- Minor bugs Fixed
- Status Checker improvement
- Notification handler improvement

### Version 1.0.4
- Uploading data improvement

### version 1.0.5
- Background uploading process
- Battery status checking
- UI improvement
- Icon changed

### version 1.0.6
- Metawear disconnection improvement(Android)
- iOS first release

### version 1.0.7
- UI improvement
- Minor bugs fixed

### version 1.0.8
- Location Disclosure added (Android only)


### version 2.0.0
-Test Recording Feature is added

### version 2.0.1
-Some improvement in UI
-Version is in splash screen

### version 2.1.0
-Android API 36

### version 2.1.1
-Bug fixed
