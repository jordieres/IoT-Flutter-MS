import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF4091E6),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: size.height * 0.1),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
          Column(
            children: [
              Text(
                'Designed by:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7DB6D5),
                ),
                textAlign: TextAlign.center,
              ),
              Image.asset(
                'assets/images/upm2.png',
                width: size.width * 0.7,
                height: size.height * 0.130,
              ),
              SizedBox(height: size.height * 0.02),
              if (_version.isNotEmpty)
                Text(
                  'Version $_version',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 8),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ],
      ),
    );
  }
}
