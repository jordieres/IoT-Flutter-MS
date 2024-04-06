import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Aligns children vertically with space between them
        children: [
          Spacer(), // Pushes everything below it down
          Text(
            'HealthyWear',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Spacer(), // Provides flexible space in between
          // Logos at the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Centers the logos horizontally
            children: [
              // HUG Logo - Make this larger as requested
              Image.asset(
                'assets/images/logogetafe.png',
                width: 170, // Adjust the size as per your preference for "larger"
              ),
              Image.asset(
                'assets/images/upm.png',
                width: 100, // Adjust the size as needed
              ),

              // UPM Logo - Keep this smaller
            ],
          ),
          SizedBox(height: 20), // Adds some space at the very bottom
        ],
      ),
    );
  }
}
