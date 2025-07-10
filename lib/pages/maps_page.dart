import 'dart:async';

import 'package:easy_vahan/services/alert_service.dart';
import 'package:easy_vahan/services/auth_services.dart';
import 'package:easy_vahan/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:get_it/get_it.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  final _formKey = GlobalKey<FormState>();
  final String _socValue = '';
  final TextEditingController _batteryController = TextEditingController();
  final Location _locationController = Location();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  StreamSubscription<LocationData>? _locationSubscription;
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _requestLocationPermission();
    _getCurrentLocation();
  }

  void _requestLocationPermission() async {
    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    var locationData = await _locationController.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition:
                      CameraPosition(target: _currentLocation!, zoom: 13.5),
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  liteModeEnabled: false,
                  onTap: _onMarkerSelected,
                  markers: _markers,
                ),
          Positioned(
            bottom: 50,
            right: 10,
            child: FloatingActionButton(
              onPressed: () {
                // Add your submit function here
                print("pressed");
              },
              child: const Icon(Icons.check),
            ),
          ),
        ],
      ),
    );
  }

  void _onMarkerSelected(LatLng position) {
    setState(() {
      _destinationLocation = position;
      _markers.add(Marker(
        markerId: const MarkerId('destinationLocation'),
        position: position,
        infoWindow: const InfoWindow(title: 'Destination'),
        draggable: true,
      ));
      // _showBatteryPrompt(context);
      _addMarker();
    });
  }

  void _addMarker() {
    _markers.add(Marker(
      markerId: const MarkerId('new marker'),
      position: _currentLocation!,
      infoWindow: const InfoWindow(title: 'current'),
      draggable: true,
    ));
  }
}
