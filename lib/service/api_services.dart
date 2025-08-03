import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.205.244.11:8080/api/v1'; // Change this IP

  static Future<http.Response> planJourney({
    required String destinations,
    required int durationInDays,
    required List<String> interests,
  }) async {
    final url = Uri.parse('$_baseUrl/journey/plan');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'destinations': destinations,
        'durationInDays': durationInDays,
        'interests': interests,
      }),
    );
  }
}
