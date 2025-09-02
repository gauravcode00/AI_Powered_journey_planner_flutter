import 'package:flutter/material.dart';
import 'package:journey_planner/model/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'itinerary_screen.dart';

class SavedItinerariesScreen extends StatefulWidget {
  const SavedItinerariesScreen({super.key});

  @override
  State<SavedItinerariesScreen> createState() => _SavedItinerariesScreenState();
}

class _SavedItinerariesScreenState extends State<SavedItinerariesScreen> {
  // MODIFIED: The list now stores the key as well, which is needed for deletion.
  List<Map<String, String>> _savedItineraries = [];

  @override
  void initState() {
    super.initState();
    _loadSavedItineraries();
  }

  Future<void> _loadSavedItineraries() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<Map<String, String>> loadedItineraries = [];

    for (String key in keys) {
      if (key.startsWith('itinerary_')) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          final destination = key.split('_')[1];
          loadedItineraries.add({
            'key': key, // Store the key for deletion
            'title': destination,
            'json': jsonString,
          });
        }
      }
    }

    // Sort the list to show the most recent saves first
    loadedItineraries.sort((a, b) => b['key']!.compareTo(a['key']!));

    setState(() {
      _savedItineraries = loadedItineraries;
    });
  }

  // NEW: Function to handle the deletion from SharedPreferences and state
  Future<void> _deleteItinerary(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    // Reload the list from storage to update the UI
    _loadSavedItineraries();
  }

  // NEW: Function to show a confirmation dialog before deleting
  Future<void> _confirmDelete(String key, String title) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the itinerary for "$title"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteItinerary(key);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Journeys'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _savedItineraries.isEmpty
          ? const Center(
        child: Text(
          'No saved journeys yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _savedItineraries.length,
        itemBuilder: (context, index) {
          final savedItem = _savedItineraries[index];
          final title = savedItem['title']!;
          final key = savedItem['key']!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.bookmark_border, color: Colors.grey),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tap to view'),
              // MODIFIED: Added a trailing delete button
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Itinerary',
                onPressed: () {
                  _confirmDelete(key, title);
                },
              ),
              onTap: () {
                final itineraryData = jsonDecode(savedItem['json']!);
                final Itinerary itinerary = Itinerary.fromJson(itineraryData);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItineraryScreen(itinerary: itinerary),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
