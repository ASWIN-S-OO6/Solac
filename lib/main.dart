
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:solac/page/main_screen.dart';
import 'package:solac/permission.dart';
import 'package:solac/trans.dart';
import 'package:solac/ts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'face.dart';

void main() {
  runApp(Solac());
}

class Solac extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solac' ,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor:Color(0xFF212121) , // Indigo
        hintColor: Color(0xFF2196F3), // Vibrant Blue
        scaffoldBackgroundColor: Color(0xFF212121), // Sleek Black
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ).apply(
          fontSizeFactor: 1.1,
        ),
        appBarTheme: AppBarTheme(
          color: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          selectedIconTheme: IconThemeData(size: 28),
          unselectedIconTheme: IconThemeData(size: 24),
          elevation: 0,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF2E2E2E), // Dark Gray
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2E2E2E),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          hintStyle: TextStyle(color: Colors.white54),
          labelStyle: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3F51B5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 5,
            shadowColor: Colors.black26,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            animationDuration: Duration(milliseconds: 200),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeTransitionBuilder(),
            TargetPlatform.iOS: FadeTransitionBuilder(),
          },
        ),
      ),
      home: MainScreen(),
    );
  }
}

// Custom page transition for fade effect
class FadeTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}









