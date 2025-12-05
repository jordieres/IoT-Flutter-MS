# Errors & Troubleshooting

This section covers common issues that may occur when using the HealthyWear Flutter app, especially while connecting to BLE wearable devices like Sensoria Smart Socks.

---

##  App Crash When Connecting to Sensoria

###  Problem
The app crashes or fails to connect when trying to pair with a **Sensoria sensor**.

### 🧠Cause
This is most likely due to a misconfigured or missing **BLE protocol** on the sensor. If the sensor is not broadcasting with the expected F20 streaming protocol, the app cannot initialize communication and may crash.

---

###  Solution: Reset Sensor to Factory Defaults (F20 Protocol)

You can use the [**LightBlue app**](https://punchthrough.com/lightblue/) to manually reconfigure the sensor.

####  Download LightBlue

- [iOS App Store](https://apps.apple.com/us/app/lightblue/id557428110)
- [Google Play Store](https://play.google.com/store/apps/details?id=com.punchthrough.lightblueexplorer)

---

###  Reconfigure Sensoria Sensor using LightBlue

1. **Launch LightBlue and connect to your sensor**  
   Look for a name like: `Sensoria-C1-XXXX`

2. **Locate BLE Control Points**
   - Scroll down until you see:
     - `Control Point RX`
     - `Control Point TX`

3. **Start Listening for Notifications**
   - Tap on `Control Point RX`
   - Select **“Listen for notifications”**

4. **Send the correct protocol**
   - Tap on `Control Point TX` → **Write new value**
   - Enter this hex command:

     ```
     04-01-04-0F
     ```

   - Press **Done**  
     > This sets the default F20 protocol, which uses 3 analog sensors + 9-axis IMU.

---

###  Reboot the Sensor

To complete the reset:

1. Tap `Control Point TX` again → **Write new value**
2. Enter this hex value to reboot:
01-05
3. Press **Done**  
The sensor will now restart and should be discoverable by the app again.

---

###  After Reset

- Restart the HealthyWear app
- Try connecting to the sensor again
- You should now be able to pair without issues

---

## 🧪 Bonus: Check BLE Status

Make sure your device has:
- Bluetooth enabled
- Location permission granted
- Sensor is charged and within range

---

