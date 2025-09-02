import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/journey_planner_sheet.dart';
import '../widgets/top_search_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 4.5,
  );

  @override
  void initState() {
    super.initState();
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

  // MODIFIED: This function now shows a dialog if location services are disabled.
  Future<void> _goToMyLocation() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // If services are disabled, show a dialog to the user
      if (mounted) { // Check if the widget is still in the tree
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text('Please enable location services to use this feature.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // This opens the device's location settings
                    await Geolocator.openLocationSettings();
                  },
                ),
              ],
            );
          },
        );
      }
      return; // Exit the function if services were not enabled
    }

    // 2. If services are enabled, proceed with permission checks
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // 3. Get current position and animate the camera
      Position position =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0),
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
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          const TopSearchBar(),
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
