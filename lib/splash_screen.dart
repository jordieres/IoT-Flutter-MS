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
                'Designed by',
                style: TextStyle(
                  fontSize: 18, // Adjust font size to match design
                  color: Color(0xFF7DB6D5), // Light blue color for 'Designed by'
                ),
                textAlign: TextAlign.center,
              ),
              Image.asset(
                'assets/images/upm2.png', // Make sure to use the correct asset
                width: size.width * 0.7, // Logo takes 20% of the screen width
                height: size.height * 0.130, // Adjust the height accordingly
              ),
              SizedBox(height: size.height * 0.05), // Bottom spacing
            ],
          ),
        ],
      ),
    );
  }
}

////--------oldddddd

// class SplashScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue, // Set the background color to blue
//
//       body: Column(
//         mainAxisAlignment:
//             MainAxisAlignment.spaceBetween, // Aligns children vertically with space between them
//         children: [
//           Spacer(), // Pushes everything below it up, making space for the icon
//           // App Icon
//           // Image.asset(
//           //   'assets/images/AppIcon.png', // Make sure this path matches your asset folder structure
//           //   width: 120, // Adjust the size as per your preference
//           // ),
//           Text(
//             'Healthy',
//             style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
//             textAlign: TextAlign.center,
//           ),
//           Text(
//             'Wear',
//             style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
//             textAlign: TextAlign.center,
//           ),
//           Spacer(), // Provides flexible space in between
//           // Logos at the bottom
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Centers the logos horizontally
//             children: [
//               Image.asset(
//                 'assets/images/logogetafe.png',
//                 width: 170, // Adjust the size as per your preference for "larger"
//               ),
//               Image.asset(
//                 'assets/images/upm.png',
//                 width: 100, // Adjust the size as needed
//               ),
//             ],
//           ),
//           SizedBox(height: 20), // Adds some space at the very bottom
//         ],
//       ),
//     );
//   }
// }
