import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // ------------------- CRITICAL -------------------
  // You MUST replace the IP address with your computer's local IP address.
  // 1. Make sure your phone/emulator and computer are on the SAME Wi-Fi network.
  // 2. Find your computer's IP:
  //    - Windows: Open Command Prompt, type `ipconfig`, find "IPv4 Address".
  //    - macOS/Linux: Open Terminal, type `hostname -I` or `ifconfig`.
  // 3. Replace the IP below. DO NOT USE "localhost" or "127.0.0.1".
  static const String _backendUrl = 'https://journey-planner-backend-1013158436850.asia-south2.run.app/api/v1/journey/plan';
  // -------------------------------------------------

  static Future<http.Response> planJourney({
    required String destinations,
    required int durationInDays,
    required List<String> interests,
  }) async {
    final url = Uri.parse(_backendUrl);

    // This sends the user's preferences to your Spring Boot backend.
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'destinations': destinations,
        'durationInDays': durationInDays,
        'interests': interests,
      }),
    );
  }
}
