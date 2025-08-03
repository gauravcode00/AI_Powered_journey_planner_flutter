import 'package:flutter/material.dart';
import 'package:journey_planner/service/api_services.dart'; // Import the service

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
    if (_destinationsController.text.isEmpty || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.planJourney(
        destinations: _destinationsController.text,
        durationInDays: int.tryParse(_durationController.text) ?? 0,
        interests: _selectedInterests.toList(),
      );

      if (response.statusCode == 200) {
        print('SUCCESS: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary requested successfully!')),
        );
      } else {
        print('ERROR: ${response.statusCode} — ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('NETWORK ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Check backend or IP.')),
      );
    } finally {
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _destinationsController.dispose();
    _durationController.dispose();
    super.dispose();
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text('Create Your Journey',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Tell us your preferences, and we\'ll craft the perfect trip.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _destinationsController,
              decoration: const InputDecoration(
                labelText: 'Destination(s)',
                hintText: 'e.g., Varanasi, Ayodhya',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (in days)',
                hintText: 'e.g., 7',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              keyboardType: TextInputType.number,
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
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _selectedInterests.add(interest)
                          : _selectedInterests.remove(interest);
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade800,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateItinerary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Itinerary'),
            ),
          ],
        ),
      ),
    );
  }
}
