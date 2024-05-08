import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; // Screen size for responsive layout

    return Scaffold(
      backgroundColor: Color(0xFF4091E6), // Blue background color
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Main axis alignment
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch across the screen width
        children: [
          SizedBox(height: size.height * 0.1), // Adjust top spacing
          // Healthy Wear text in the middle
          Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
            children: [
              Text(
                'Healthy',
                style: GoogleFonts.poppins(
                    fontSize: 60, fontWeight: FontWeight.w500, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              Text(
                'Wear',
                style: GoogleFonts.poppins(
                    fontSize: 60, fontWeight: FontWeight.w500, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          // Designed by text and UPM logo at the bottom
          Column(
            children: [
              Text(
                'Designed by:',
                style: TextStyle(
                  fontSize: 16, // Adjust font size to match design
                  color: Color(0xFF7DB6D5), // Light blue color for 'Designed by'
                ),
                textAlign: TextAlign.center,
              ),
              Image.asset(
                'assets/images/upm2.png',
                width: size.width * 0.7,
                height: size.height * 0.130,
              ),
              SizedBox(height: size.height * 0.05), // Bottom spacing
            ],
          ),
        ],
      ),
    );
  }
}
