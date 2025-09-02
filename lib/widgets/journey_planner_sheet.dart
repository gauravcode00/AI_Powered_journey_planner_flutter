import 'package:flutter/material.dart';
import 'package:journey_planner/Screen/saved_itinerary_screen.dart';
import 'package:journey_planner/model/models.dart';
import 'package:journey_planner/service/api_services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screen/itinerary_screen.dart';

class JourneyPlannerSheet extends StatefulWidget {
  const JourneyPlannerSheet({super.key});
  @override
  State<JourneyPlannerSheet> createState() => _JourneyPlannerSheetState();
}

class _JourneyPlannerSheetState extends State<JourneyPlannerSheet> {
  final _destinationsController = TextEditingController();
  final _durationController = TextEditingController();
  final Set<String> _selectedInterests = {};
  final List<String> _interests = [
    'Temples', 'History', 'Yoga', 'Food', 'Mountains', 'Beaches', 'Art', 'Culture'
  ];
  bool _isLoading = false;

  Future<void> _generateItinerary() async {
    if (_destinationsController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.planJourney(
        destinations: _destinationsController.text,
        durationInDays: int.tryParse(_durationController.text) ?? 0,
        interests: _selectedInterests.toList(),
      );

      if (response.statusCode == 200 && mounted) {
        final responseBody = jsonDecode(response.body);
        final itineraryJsonString = responseBody['message'];

        await _saveItinerary(itineraryJsonString, _destinationsController.text);

        final itineraryData = jsonDecode(itineraryJsonString);
        final Itinerary itinerary = Itinerary.fromJson(itineraryData);

        Navigator.pop(context); // Close the bottom sheet
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ItineraryScreen(itinerary: itinerary)));
      } else {
        throw Exception(
            'Failed to load itinerary. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to generate plan. Please try again.')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveItinerary(String itineraryJson, String destination) async {
    final prefs = await SharedPreferences.getInstance();
    // Create a unique key using the destination and current timestamp
    final key = 'itinerary_${destination}_${DateTime.now().toIso8601String()}';
    await prefs.setString(key, itineraryJson);
    print('Itinerary saved with key: $key');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.85,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24.0),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)))),

            // This Row holds the title and the "Saved" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Create Your Journey',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.blue),
                  tooltip: 'Saved Journeys',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedItinerariesScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
                'Tell us your preferences, and we\'ll craft the perfect trip.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),

            TextField(
              controller: _destinationsController,
              style: const TextStyle(color: Colors.black), // Text color
              decoration: InputDecoration(
                labelText: 'Destination(s)',
                labelStyle: const TextStyle(color: Colors.grey), // Label color
                hintText: 'e.g., Varanasi, Ayodhya',
                hintStyle: const TextStyle(color: Colors.grey), // Hint color
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black), // Icon color
                filled: true,
                fillColor: Colors.grey.shade100, // Background fill
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey), // Unfocused border color
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4285F4)), // Focused border color
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black), // Input text color
              decoration: InputDecoration(
                labelText: 'Duration (in days)',
                labelStyle: const TextStyle(color: Colors.grey), // Label color
                hintText: 'e.g., 7',
                hintStyle: const TextStyle(color: Colors.grey), // Hint color
                prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.black), // Icon color
                filled: true,
                fillColor: Colors.grey.shade100, // Background fill color
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey), // Default border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4285F4)), // Border on focus
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Interests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) => setState(() {
                    selected
                        ? _selectedInterests.add(interest)
                        : _selectedInterests.remove(interest);
                  }),
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade800,
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateItinerary,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Itinerary' , style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
