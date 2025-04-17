# healthyWear


## Introduction

HealthyWear is an IoT flutter application developed for the Android/iOS devices to streaming and capturing various health data from MetaWear (MetaMotions S) sensors,  HBand, and Sensoria Smart Socks wearables. It provides dual-device functionality and is particularly focused on offering real-time feedback on physical activities, aiding in enhancing doctors diagnosis and patient treatment process. The app collects, stores, and transmits real-time vital signs and physical activity data to a server. This enables doctors to remotely keep track of their patients' health, making it an essential tool in the management of their patients.


## Features
- **MetaWear Integration**: Connects to MetaWear sensors worn on each hand to monitor and record movements .
- **HBand Integration**: Utilizes the HBand to track heart rate ,spo2 and blood pressure and providing vital health metrics.
- **Sensoria Smart Socks Integration**: To incorporate data collection from smart socks for comprehensive foot movement analysis.
- **Data Management**: Buffers and writting the data locally before sending it to the server, ensuring efficient transmission and minimal loss.
- **Doctor Dashboard**: A server-side interface (not included in this repository) where doctors can view and analyze patient data.




## Getting Started


### Prerequisites
- Flutter SDK(latest version recommended)  ( https://docs.flutter.dev/get-started/install )
- Android Studio and Xcode for platform-specific SDKs  ( https://developer.android.com/studio/install )
- Access to the required hardware (MetaWear sensors,  HBand, Sensoria Smart Socks)


### Installation (flutter)

##  Install Flutter SDK
- **Download Flutter**:
   - Visit the [Flutter installation page](https://flutter.dev/docs/get-started/install).
   - Download the latest stable Flutter SDK for macOS.
- **Extract Flutter**:
   - Extract the downloaded zip file and move the `flutter` folder to your desired installation location (e.g., `~/flutter`).
- **Update Your Path**:
   - Add Flutter to your path permanently:
      - Open or create the `$HOME/.zshrc` file with a text editor like Nano:
        ```bash
        nano $HOME/.zshrc
        ```
      - Add the following line and replace `[PATH_TO_FLUTTER_GIT_DIRECTORY]` with the actual path to your Flutter SDK:
        ```bash
        export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"
        ```
      - Save and exit the editor. Apply the changes by running:
        ```bash
        source $HOME/.zshrc
        ```
- **Run Flutter Doctor**:
   - Check for any dependencies you might need to install to complete the setup:
     ```bash
     flutter doctor
     ```

2. Clone the repository:

   git clone https://github.com/jordieres/IoT-Flutter-MS.git

3. Navigate to the project directory

4. Install dependencies:

       flutter pub get

5. Connect physical device Android/iOS

6. install flutter and dart plugins in the android studio setting

     <img width="965" alt="Screenshot 2024-03-12 at 15 56 09" src="https://github.com/jordieres/IoT-Flutter-MS/assets/44529458/eae48f08-b261-490b-bc18-d606d5e72a78">

6.Run the app

    flutter run

7.select the Device



# iOS Installation Guide for Flutter App

## Prerequisites
Ensure you have a macOS computer to run Xcode and install all necessary software.

## 1. Install Xcode
- **Download and Install Xcode**:
   - Go to the Mac App Store and search for "Xcode".
   - Click "Install" to download and install Xcode on your Mac.
   - After installation, launch Xcode and agree to its license agreement. It might prompt you to install additional components, accept and continue.

## 2. Configure Xcode
- **Xcode Command Line Tools**:
   - Open Terminal and run the following command to install Xcode Command Line Tools:
     ```bash
     xcode-select --install
     ```
   - Ensure Xcode command line tools are configured to the correct Xcode installation by running:
     ```bash
     sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
     ```
   - Agree to the terms of service when prompted.


## 3. Open the iOS folder with Xcode
- **Navigate to the iOS Folder**:
   - Open the iOS subfolder in your project:
     ```bash
     open ios/Runner.xcworkspace
     ```
   - This command opens the project in Xcode. If the project does not open, make sure you are in the correct directory and that the project includes an `ios/Runner.xcworkspace` file.

## 4. Run the App
- **Connect an iOS Device **:
   - Connect your iPhone via USB and trust the computer.
- **Configure Signing**:
   - In Xcode, navigate to the project settings by selecting the **Runner** from the Project Navigator.
   - Click on the **Signing & Capabilities** tab.
   - Choose your Team under the **Team** dropdown. You may need to add your Apple ID in **Xcode > Preferences > Accounts** if you haven't already.
   - Ensure that the **Bundle Identifier** is unique and matches your provisioning profile if you are preparing for distribution.
   - Xcode may prompt you to fix issues related to provisioning profiles; allow it to do so if required.
- **Run the App**:
   - Click the **Play** button in Xcode or use the keyboard shortcut **Cmd + R** to build and run the app.
   - The app should compile and then run on your selected device or simulator.

## 5. Troubleshooting Common Issues
- **Dependency Errors**:
   - If you encounter errors related to missing packages or dependencies, return to the terminal in your project directory and run:
     ```bash
     flutter pub get
     ```
   - Then try building the project again.
- **Build Errors**:
   - For errors during the build process, ensure all Xcode updates are installed. Check for any error messages in Xcode's console that might indicate what needs to be addressed.
   - Consider running `flutter clean` in your project directory to clean the build and then try running the app again:
     ```bash
     flutter clean
     flutter run
     ```


## Architecture
- **Main.dart**: Entry point of the Flutter application, common across all devices.
- **MetawearApi.dart**: Handles communication with MetaWear sensors via platform channels.
- **SmartBandApi.dart**: Manages data exchange with the Veepoo HBand using its Flutter SDK.
- **SensoriaApi.dart**: Handles communication with Sensoria sensors via platform channels.
- **MainActivity/MainActivity.swift**: Platform-specific entry points for Android and iOS, respectively.



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





