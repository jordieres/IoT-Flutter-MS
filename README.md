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
- Flutter (latest version recommended)  ( https://docs.flutter.dev/get-started/install )
- Android Studio and Xcode for platform-specific SDKs  ( https://developer.android.com/studio/install )
- Access to the required hardware (MetaWear sensors,  HBand, Sensoria Smart Socks)


### Installation

1. Clone the repository:

   git clone https://github.com/jordieres/IoT-Flutter-MS.git

2. Navigate to the project directory

3. Install dependencies:

       flutter pub get

5. Connect physical device Android/iOS

6. install flutter and dart plugins in the android studio setting

     <img width="965" alt="Screenshot 2024-03-12 at 15 56 09" src="https://github.com/jordieres/IoT-Flutter-MS/assets/44529458/eae48f08-b261-490b-bc18-d606d5e72a78">

6.Run the app

    flutter run

7.select the Device


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
- 



