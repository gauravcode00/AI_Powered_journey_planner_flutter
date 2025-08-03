// --- Main Map Screen Widget ---
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:journey_planner/main.dart';
import 'package:journey_planner/widgets/journey_planner_sheet.dart';
import 'package:journey_planner/widgets/top_search_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Center of India
    zoom: 4.5,
  );

  @override
  void initState() {
    super.initState();
    // Try to get the user's location when the app starts
    _goToMyLocation();
  }

  void _openJourneyPlanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JourneyPlannerSheet(),
    );
  }

  // MODIFIED: Re-introduced a robust "Go To My Location" function
  Future<void> _goToMyLocation() async {
    try {
      // Step 1: Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location services are disabled. Please enable them.')));
        return;
      }

      // Step 2: Check for location permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are permanently denied, we cannot request permissions.')));
        return;
      }

      // Step 3: Get the current position.
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Step 4: Animate the camera to the new position.
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true, // This will show the blue dot
            myLocationButtonEnabled: false, // We use our own button
            zoomControlsEnabled: false,
          ),
          const TopSearchBar(),
          // MODIFIED: Added back the My Location button
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'myLocation',
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'journeyPlanner',
                  onPressed: _openJourneyPlanner,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade700,
                  tooltip: 'Plan Journey',
                  child: const Icon(Icons.assistant_navigation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
