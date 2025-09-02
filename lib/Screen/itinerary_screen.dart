import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:journey_planner/model/models.dart';
import 'dart:ui' as ui;

class ItineraryScreen extends StatefulWidget {
  final Itinerary itinerary;
  const ItineraryScreen({super.key, required this.itinerary});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late Itinerary _currentItinerary;
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isNavigating = false;

  BitmapDescriptor _navigationIcon = BitmapDescriptor.defaultMarker;

  final String _backendBaseUrl = 'https://journey-planner-backend-1013158436850.asia-south2.run.app/api/v1/journey';

  @override
  void initState() {
    super.initState();
    _currentItinerary = widget.itinerary;
    _determinePosition();
    _createNavigationIcon();
  }

  Future<void> _createNavigationIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blue.shade700;
    const double radius = 25.0;

    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    final Paint arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Path path = Path();
    path.moveTo(radius, radius * 0.4);
    path.lineTo(radius * 1.6, radius * 1.4);
    path.lineTo(radius, radius * 1.1);
    path.lineTo(radius * 0.4, radius * 1.4);
    path.close();
    canvas.drawPath(path, arrowPaint);

    final img = await pictureRecorder.endRecording().toImage((radius * 2).toInt(), (radius * 2).toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      _navigationIcon = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  // NEW: Function to animate the camera back to the user's current location
  Future<void> _recenterMap() async {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0, // A good default zoom level
          ),
        ),
      );
    }
  }

  void _deleteActivity(int dayIndex, int activityIndex) {
    setState(() {
      _currentItinerary.days[dayIndex].plan.removeAt(activityIndex);
    });
  }

  Future<void> _getDirections(String destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')));
      return;
    }
    final String origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/directions'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'origin': origin, 'destination': destination}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String encodedPolyline = data['encodedPolyline'];
        _drawPolyline(encodedPolyline);
      } else {
        throw Exception('Failed to get directions');
      }
    } catch (e) {
      print('Error getting directions: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not fetch directions.')));
    }
  }

  void _drawPolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints(apiKey: '');
    List<PointLatLng> decodedResult = PolylinePoints.decodePolyline(encodedPolyline);
    List<LatLng> polylineCoordinates =
    decodedResult.map((point) => LatLng(point.latitude, point.longitude)).toList();
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ),
      );
    });
    if (polylineCoordinates.isNotEmpty) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          polylineCoordinates.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
          polylineCoordinates.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          polylineCoordinates.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
          polylineCoordinates.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
        ),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    }
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
    });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        _currentPosition = position;
        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              rotation: position.heading,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              icon: _navigationIcon,
            ),
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 17.5,
              bearing: position.heading,
              tilt: 45.0,
            ),
          ),
        );
      },
    );
  }

  void _stopNavigation() {
    _positionStream?.cancel();
    setState(() {
      _isNavigating = false;
      _markers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The initial size of the draggable sheet
    const double initialSheetSize = 0.4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Custom Itinerary'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (_isNavigating)
            TextButton(
              onPressed: _stopNavigation,
              child: const Text('STOP', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(20.5937, 78.9629),
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: !_isNavigating,
            myLocationButtonEnabled: false,
            polylines: _polylines,
            markers: _markers,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // NEW: Positioned widget for the recenter button
          Positioned(
            // Position the button just above the initial position of the draggable sheet
            bottom: MediaQuery.of(context).size.height * initialSheetSize + 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black54),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 100,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent, // ✅ Remove ExpansionTile divider
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _currentItinerary.days.length,
                      itemBuilder: (context, dayIndex) {
                        final dayPlan = _currentItinerary.days[dayIndex];
                        return ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 8), // Optional spacing
                          title: Text(
                            '${dayPlan.day}: ${dayPlan.title}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          initiallyExpanded: dayIndex == 0,
                          children: List.generate(dayPlan.plan.length, (activityIndex) {
                            final activity = dayPlan.plan[activityIndex];
                            return ListTile(
                              splashColor: Colors.transparent, // Optional: remove ripple
                              hoverColor: Colors.transparent,
                              title: Text(
                                activity.placeName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(activity.description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_polylines.isNotEmpty && !_isNavigating)
                                    IconButton(
                                      icon: const Icon(Icons.navigation, color: Colors.green),
                                      tooltip: 'Start Navigation',
                                      onPressed: _startNavigation,
                                    )
                                  else if (!_isNavigating)
                                    IconButton(
                                      icon: const Icon(Icons.directions, color: Colors.blue),
                                      tooltip: 'Get Directions',
                                      onPressed: () => _getDirections(activity.placeName),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                    onPressed: () => _deleteActivity(dayIndex, activityIndex),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              );

            },
          )
        ],
      ),
    );
  }
}
