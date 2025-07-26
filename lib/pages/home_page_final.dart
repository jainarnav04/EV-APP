import 'dart:async';
import 'dart:math' as math;
import 'package:easy_vahan/services/alert_service.dart';
import 'package:easy_vahan/services/auth_services.dart';
import 'package:easy_vahan/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageFinal extends StatefulWidget {
  const HomePageFinal({super.key});

  @override
  State<HomePageFinal> createState() => _HomePageFinalState();
}

class _HomePageFinalState extends State<HomePageFinal> {
  final _formKey = GlobalKey<FormState>();
  String _socValue = '';
  double _maxRange = 100.0; // Maximum range in km when battery is 100%
  // Get Google Maps API key from environment variables
  late final String _apiKey;

  @override
  void initState() {
    super.initState();

    Timer? _stationRefreshTimer;
    
    // Get API key from build arguments
    _apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    
    if (_apiKey.isEmpty) {
      throw Exception('''
        Google Maps API key not found!\n\n
        Please run the app with:\n        --dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY\n\n
        For development, you can use the run_app.bat script
        after setting up your API key in it.
      ''');
    }

    // Initialize services
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    
    // Request location permissions and get current location
    _requestLocationPermission();
    _getCurrentLocation();
    fetchStationsFromFirestore(); // dynamic station loader
    _stationRefreshTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      fetchStationsFromFirestore();
    });

  }

  static const LatLng _pMNITJaipur = LatLng(26.8644, 75.8109);
  final Location _locationController = Location();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;

  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;

  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final PolylinePoints polylinePoints = PolylinePoints();
  bool _isMapReady = false;
  bool _isWaitTimeDialogShown = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _chargingStations = [];
  void fetchStationsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('charging_stations')
          .get();

      print('Raw docs fetched: ${snapshot.docs.length}');

      final List<Map<String, dynamic>> stations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Doc ID: ${doc.id}, Data: $data');

        final lat = data['latitude'];
        final lng = data['longitude'];

        if (lat != null && lng != null) {
          stations.add({
            'station_id': doc.id,
            'position': LatLng(lat, lng),
            'slots': data['total_slots'] ?? 0,
            'queue': data['latest_wait_time_minutes'] ?? 0,
            'waitTime': 0.0, // You can calculate or update this later
            'name': data['name'] ?? 'Unknown',
            'powerKW': data['charging_rate']?.toDouble() ?? 0.0,
          });
        }
        // _updateMarkers();
        // _addChargingStationMarkers();
      }

      setState(() {
        _chargingStations.clear(); // Clear hardcoded stations if needed
        _chargingStations.addAll(stations);
        _updateMarkers();
      });

    } catch (e) {
      print('Error fetching charging stations: $e');
    }
    print("Fetched ${_chargingStations.length} stations:");
    for (var station in _chargingStations) {
      print(station);
    }
  }

  void _updateMarkers() {
    _markers.clear();
    for (var station in _chargingStations) {
      _markers.add(
        Marker(
          markerId: MarkerId(station['name']),
          position: station['position'],
          infoWindow: InfoWindow(
            title: station['name'],
            snippet: 'Slots: ${station['slots']}, Power: ${station['powerKW']} kW',
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _requestLocationPermission() async {
    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) return;
    }
    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationController.getLocation();
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      });
    } catch (e) {
      print('Error getting location: $e');
      _alertService.showToast(
          text: 'Error getting location', icon: Icons.error);
    }
  }

  void _addChargingStationMarkers() {
    print('Adding charging station markers');
    for (var station in _chargingStations) {
      _markers.add(Marker(
        markerId: MarkerId(station['name']),
        position: station['position'],
        infoWindow: InfoWindow(
          title: station['name'],
          snippet:
              'Slots: ${station['slots']}, Wait: ${station['waitTime']} min, Queue: ${station['queue']}, Power: ${station['powerKW']} kW',
          onTap: () {
            _onChargingStationTapped(station); // <-- Add this function
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    setState(() {});
  }
  void _onChargingStationTapped(Map<String, dynamic> station) {
    print('Charging station clicked');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Book Charger at ${station['name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt),
              label: const Text('Book Now'),
              onPressed: () {
                Navigator.pop(context);
                _showVehicleBookingDialog(station['station_id']);
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showVehicleBookingDialog(String stationId) {
    final _vehicleNumberController = TextEditingController();
    final _initialBatteryController = TextEditingController();
    final _targetBatteryController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Vehicle Details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
              ),
              TextField(
                controller: _initialBatteryController,
                decoration: const InputDecoration(labelText: 'Initial Battery (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _targetBatteryController,
                decoration: const InputDecoration(labelText: 'Target Battery (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Confirm'),
            onPressed: () async {
              Navigator.pop(context);
              final vehicleData = {
                'vehicle_number': _vehicleNumberController.text.trim(),
                'initial_battery_level': int.tryParse(_initialBatteryController.text) ?? 0,
                'target_battery_level': int.tryParse(_targetBatteryController.text) ?? 100,
                'status': 'BOOKED',
                'timestamp': DateTime.now(),
              };
              await FirebaseFirestore.instance
                  .collection('charging_stations')
                  .doc(stationId)
                  .collection('vehicles')
                  .add(vehicleData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Charger booked successfully!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWaitTimeDialog() {
    if (_isWaitTimeDialogShown || !_isMapReady) {
      if (!_isMapReady) {
        Future.delayed(const Duration(seconds: 1), _showWaitTimeDialog);
      }
      return;
    }
    _isWaitTimeDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final waitControllers =
            _chargingStations.map((_) => TextEditingController()).toList();
        final queueControllers = _chargingStations
            .map((s) => TextEditingController(text: s['queue'].toString()))
            .toList();
        return AlertDialog(
          title: const Text('Enter Charging Station Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  _chargingStations.length,
                  (index) => Column(
                        children: [
                          Text(_chargingStations[index]['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: waitControllers[index],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Wait time (minutes)'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: queueControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Vehicles in queue'),
                            ),
                          ),
                          const Divider(),
                        ],
                      )),
            ),
          ),
          actions: [
            MaterialButton(
              child: const Text('Submit'),
              onPressed: () {
                for (int i = 0; i < _chargingStations.length; i++) {
                  final waitTime = double.tryParse(waitControllers[i].text);
                  final queue = int.tryParse(queueControllers[i].text);
                  _chargingStations[i]['waitTime'] = waitTime ?? 0.0;
                  _chargingStations[i]['queue'] = queue ?? 0;
                }
                _updateChargingStationMarkers();
                Navigator.pop(context);
                _isWaitTimeDialogShown = false;
              },
            ),
          ],
        );
      },
    );
  }
  // 🔥 Future Enhancement: Fetch real-time waitTime and queue from Firebase
// Example (assuming Firebase Firestore):
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// Future<void> _fetchStationDataFromFirebase() async {
//   final firestore = FirebaseFirestore.instance;
//   for (int i = 0; i < _chargingStations.length; i++) {
//     final doc = await firestore.collection('charging_stations').doc(_chargingStations[i]['name']).get();
//     if (doc.exists) {
//       final data = doc.data();
//       if (data != null) {
//         _chargingStations[i]['waitTime'] = data['waitTime'] ?? 0.0;
//         _chargingStations[i]['queue'] = data['queue'] ?? 0;
//       }
//     }
//   }
//   _updateChargingStationMarkers();
// }

  void _updateChargingStationMarkers() {
    print('Updating charging station markers');
    _markers.removeWhere((m) => m.markerId.value.contains('charging_station'));
    _addChargingStationMarkers();
  }

  double _calculateRange() {
    if (_socValue.isEmpty) return _maxRange;

    double soc = double.parse(_socValue);

    // Enhanced range calculation based on research papers
    // Battery degradation factor (accounts for non-linear discharge)
    double batteryEfficiency = 0.85 + (0.15 * (soc / 100));

    // Temperature impact (assuming optimal temperature of 25°C for Jaipur)
    double tempFactor = 0.95; // Slight reduction for typical Jaipur climate

    // Peukert's law approximation for battery discharge under load
    num peukertFactor = math.pow(soc / 100, 1.2);

    // Calculate enhanced range
    double enhancedRange =
        _maxRange * batteryEfficiency * tempFactor * peukertFactor;

    return enhancedRange;
  }

  void _filterStationsByRange() {
    print('Filtering stations by range');
    final range = _calculateRange();
    _markers.removeWhere((m) => m.markerId.value.contains('charging_station'));
    for (var station in _chargingStations) {
      final distance =
          _calculateHaversineDistance(_currentLocation!, station['position']);
      if (distance <= range) {
        _markers.add(Marker(
          markerId: MarkerId('charging_station_${station['position']}'),
          position: station['position'],
          infoWindow: InfoWindow(
            title: station['name'],
            snippet:
                'Slots: ${station['slots']}, Wait: ${station['waitTime']} min, Queue: ${station['queue']}',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
    }
    setState(() {});
  }

  double _calculateHaversineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final lon2 = end.longitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<List<LatLng>> _getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK') {
          final List<LatLng> polylineCoordinates = [];
          final routes = data['routes'] as List<dynamic>;

          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            if (route.containsKey('overview_polyline')) {
              final overviewPolyline =
                  route['overview_polyline'] as Map<String, dynamic>;
              if (overviewPolyline.containsKey('points')) {
                final points = overviewPolyline['points'] as String;
                final result = polylinePoints.decodePolyline(points);

                if (result.isNotEmpty) {
                  polylineCoordinates.addAll(result
                      .map((point) => LatLng(point.latitude, point.longitude)));
                  return polylineCoordinates;
                }
              }
            }
          }

          return polylineCoordinates.isNotEmpty
              ? polylineCoordinates
              : [origin, destination];
        } else {
          print(
              'Google API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          throw Exception('Google API Error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Route coordinates error: $e');
      // Don't show toast here - let the calling method handle it
      return [origin, destination]; // Return straight line fallback
    }
  }

  double _calculateChargingTime(
      double currentSOC, double targetSOC, double chargerPowerKW) {
    const batteryCapacityKWh = 40.0;
    final energyNeededKWh = batteryCapacityKWh * (targetSOC - currentSOC) / 100;
    return energyNeededKWh / chargerPowerKW;
  }

  List<Map<String, dynamic>> _findOptimalChargingRoute(
      LatLng start, LatLng end, double initialRange) {
    final totalDistance = _calculateHaversineDistance(start, end);
    if (totalDistance <= initialRange) return [];

    List<Map<String, dynamic>> bestRoute = [];
    double bestScore = double.infinity;
    const maxStops = 3;

    for (var stopCount = 1; stopCount <= maxStops; stopCount++) {
      final allCombinations =
          _generateCombinations(_chargingStations, stopCount);
      for (var combination in allCombinations) {
        var currentRange = initialRange;
        var currentPoint = start;
        var totalTime = 0.0;
        var feasible = true;

        for (var station in combination) {
          final distToStation =
              _calculateHaversineDistance(currentPoint, station['position']);
          if (distToStation > currentRange) {
            feasible = false;
            break;
          }
          final waitTimeHours = station['waitTime'] / 60;
          final queueTimeHours = station['queue'] * 0.5 / 60; // 30 min per car
          final chargingTimeHours =
              _calculateChargingTime(20, 80, station['powerKW']);
          totalTime += distToStation / 60 +
              waitTimeHours +
              queueTimeHours +
              chargingTimeHours;
          currentRange -= distToStation;
          currentPoint = station['position'];
          currentRange = _maxRange * 0.8; // Assume 80% charge after stop
        }

        final distToEnd = _calculateHaversineDistance(currentPoint, end);
        if (distToEnd > currentRange) feasible = false;
        totalTime += distToEnd / 60;

        if (feasible && totalTime < bestScore) {
          bestScore = totalTime;
          bestRoute = combination.toList();
        }
      }
    }
    return bestRoute;
  }

  List<List<Map<String, dynamic>>> _generateCombinations(
      List<Map<String, dynamic>> list, int length) {
    if (length == 0) return [[]];
    if (list.isEmpty) return [];
    List<List<Map<String, dynamic>>> result = [];
    for (var i = 0; i < list.length; i++) {
      final rest = list.sublist(i + 1);
      for (var subCombo in _generateCombinations(rest, length - 1)) {
        result.add([list[i], ...subCombo]);
      }
    }
    return result;
  }

  Future<void> _drawOptimalRoute(
      List<Map<String, dynamic>> optimalRoute) async {
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId.value.contains('bestStation'));

    final allPoints = <LatLng>[_currentLocation!];
    for (var i = 0; i < optimalRoute.length; i++) {
      final station = optimalRoute[i];
      allPoints.add(station['position']);
      _markers.add(Marker(
        markerId: MarkerId('bestStation_$i'),
        position: station['position'],
        infoWindow: InfoWindow(
            title: 'Stop ${i + 1}: ${station['name']}',
            snippet:
                'Wait: ${station['waitTime']} min, Queue: ${station['queue']}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }
    allPoints.add(_destinationLocation!);

    final fullRoute = <LatLng>[];
    bool anyRouteFailed = false;

    for (var i = 0; i < allPoints.length - 1; i++) {
      try {
        print('Getting route segment ${i + 1}/${allPoints.length - 1}');
        final segment =
            await _getRouteCoordinates(allPoints[i], allPoints[i + 1]);

        // Check if we got a real route or just straight line fallback
        if (segment.length > 2) {
          fullRoute.addAll(segment);
        } else {
          // It's a straight line fallback
          fullRoute.addAll(segment);
          anyRouteFailed = true;
        }

        // Add delay between API calls
        if (i < allPoints.length - 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Error getting route segment $i: $e');
        // Add straight line for failed segment
        fullRoute.addAll([allPoints[i], allPoints[i + 1]]);
        anyRouteFailed = true;
      }
    }

    setState(() {
      _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: fullRoute,
          color: Colors.blue,
          width: 5));
    });

    _fitRouteBounds(allPoints);

    // Show appropriate message
    if (anyRouteFailed) {
      _alertService.showToast(
          text: 'Route shown with some straight-line segments',
          icon: Icons.warning);
    } else {
      _alertService.showToast(
          text: 'Route optimized successfully', icon: Icons.check);
    }
  }

  /// Fits the map camera to show all points in the route.
  void _fitRouteBounds(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  void _onMarkerSelected(LatLng position) {
    print('Destination selected: $position');
    setState(() {
      _destinationLocation = position;
      _markers.removeWhere((m) => m.markerId.value == 'destinationLocation');
      _markers.add(Marker(
        markerId: const MarkerId('destinationLocation'),
        position: position,
        infoWindow: const InfoWindow(title: 'Destination'),
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
      _polylines.clear();
    });
  }

  Future<void> _optimizeRoute() async {
    if (_currentLocation == null || _destinationLocation == null) {
      print('Cannot optimize: Missing current or destination location');
      _alertService.showToast(
          text: 'Please set a destination', icon: Icons.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Optimizing route');
      final initialRange = _calculateRange();
      final totalDistance =
          _calculateHaversineDistance(_currentLocation!, _destinationLocation!);

      if (totalDistance <= initialRange) {
        print('Direct route possible, no charging needed');
        final routePoints = await _getRouteCoordinates(
            _currentLocation!, _destinationLocation!);
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('direct_route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ));
          _alertService.showToast(
              text: 'Direct route possible, no charging needed',
              icon: Icons.check);
        });
      } else {
        print('Need charging stations for route');
        final optimalRoute = _findOptimalChargingRoute(
            _currentLocation!, _destinationLocation!, initialRange);

        if (optimalRoute.isEmpty) {
          _alertService.showToast(
              text: 'No viable route found with current battery',
              icon: Icons.error);
          return;
        }

        await _drawOptimalRoute(optimalRoute);
        final stationNames =
            optimalRoute.map((station) => station['name']).join(' → ');
        _alertService.showToast(
            text: 'Route optimized: $stationNames', icon: Icons.check);
      }
    } catch (e) {
      print('Error optimizing route: $e');
      _alertService.showToast(
          text: 'Error optimizing route', icon: Icons.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Easy Vahan"),
        actions: [
          IconButton(
            onPressed: _showWaitTimeDialog,
            tooltip: 'Update Station Info',
            icon: const Icon(Icons.electric_car),
          ),
          IconButton(
            onPressed: () async {
              final result = await _authService.logout();
              if (result) {
                _alertService.showToast(
                    text: 'Successfully logged out!', icon: Icons.check);
                _navigationService.pushReplacementNamed("/login");
              }
            },
            color: Colors.red,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchStationsFromFirestore,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Enter SOC (%)',
                        hintText: 'e.g., 50 for 50%',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter SOC';
                        }
                        final parsedValue = double.tryParse(value);
                        if (parsedValue == null ||
                            parsedValue < 0 ||
                            parsedValue > 100) {
                          return 'Enter a valid percentage (0-100)';
                        }
                        return null;
                      },
                      onSaved: (value) => _socValue = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Maximum Range (km)',
                        hintText: 'e.g., 200 for 200km',
                      ),
                      initialValue: _maxRange.toString(),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter max range';
                        }
                        final parsedValue = double.tryParse(value);
                        if (parsedValue == null || parsedValue <= 0) {
                          return 'Enter a valid range';
                        }
                        return null;
                      },
                      onSaved: (value) => _maxRange = double.parse(value!),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('Save Vehicle Settings'),
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() => _filterStationsByRange());
                  Navigator.pop(context);
                  _alertService.showToast(
                      text: 'Vehicle settings updated!', icon: Icons.check);
                }
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Show All Charging Stations'),
              onTap: () {
                _markers.removeWhere(
                    (m) => m.markerId.value.contains('charging_station'));
                _addChargingStationMarkers();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Clear Routes'),
              onTap: () {
                setState(() {
                  _polylines.clear();
                  _markers.removeWhere(
                      (m) => m.markerId.value.contains('bestStation'));
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _currentLocation == null
              ? const Center(
                  child: Text(
                      'Fetching location... Please enable location services.'))
              : SafeArea(child: _mapUI()),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _isMapReady
          ? FloatingActionButton(
              onPressed: _optimizeRoute,
              tooltip: 'Optimize Route',
              child: const Icon(Icons.navigation),
            )
          : null,
    );
  }

  Widget _mapUI() {
    print('Building map UI');
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() {
          _isMapReady = true;
          _addChargingStationMarkers();
          // Future.delayed(const Duration(seconds: 1), _showWaitTimeDialog);
        });
        print('Map created');
      },
      initialCameraPosition:
          CameraPosition(target: _currentLocation ?? _pMNITJaipur, zoom: 12),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      mapToolbarEnabled: true,
      zoomControlsEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      liteModeEnabled: false,
      onTap: _onMarkerSelected,
      markers: _markers,
      polylines: _polylines,
    );
  }
}
