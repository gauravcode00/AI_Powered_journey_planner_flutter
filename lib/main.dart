import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:journey_planner/Screen/map_screen.dart';

Future<void> main() async {
  // Load the .env file
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'GoogleSans',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


