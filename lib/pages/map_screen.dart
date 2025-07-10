import 'dart:convert';

import 'package:easy_vahan/services/alert_service.dart';
import 'package:easy_vahan/services/auth_services.dart';
import 'package:easy_vahan/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  final Location _locationController = Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  final _formKey = GlobalKey<FormState>();
  String _socValue = '';
  final TextEditingController _batteryController = TextEditingController();

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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(LatLng position) {
    const String markerIdVal = 'destination';
    // To allow multiple markers for destination selection
    // Uncomment below line
    // final String markerIdVal = 'destination-${_markers.length}';

    setState(() {
      _destinationLocation = position;
      _markers.add(Marker(
        markerId: const MarkerId(markerIdVal),
        position: position,
        infoWindow: const InfoWindow(title: markerIdVal, snippet: '*'),
        draggable: true,
      ));
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

  void _submitData() async {
    if (_markers.isEmpty) {
      // No destination selected
      // add toast to tell user to add destination
      // if destination is again null send without destination
      // return if you dont want user leave destination blank
      // return;
    }
    final response = await http.post(
      Uri.parse("http://xishan.pythonanywhere.com/send_latlong"),
      // Uri.parse('http://172.17.15.52:5000/send_latlong'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'soc': _socValue,
        'currentLocation': _currentLocation!,
        'destination': _destinationLocation,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      LatLng apiLocation = LatLng(data['latitude'], data['longitude']);
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('apiLocation'),
          position: apiLocation,
          infoWindow: const InfoWindow(title: 'API Location'),
        ));
      });
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: apiLocation,
            zoom: 13.5,
          ),
        ),
      );
    } else {
      print("An error occured while sending data");
    }
  }

  void _showBatteryPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter SOC/Battery State'),
          content: TextField(
            controller: _batteryController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: "Enter battery percentage"),
          ),
          actions: <Widget>[
            MaterialButton(
              child: const Text('Submit'),
              onPressed: () {
                _submitData();
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Easy Vahan 123"),
        actions: [
          IconButton(
            onPressed: () async {
              bool result = await _authService.logout();
              if (result) {
                _alertService.showToast(
                  text: 'Successfully logged out!',
                  icon: Icons.check,
                );
                _navigationService.pushReplacementNamed("/login");
              }
            },
            color: Colors.orange,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu'),
            ),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Enter SOC',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter SOC';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _socValue = value!;
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Save SOC'),
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  // Use setState to rebuild the widget with the new SOC value
                  setState(() {
                    // Save the SOC value to the state
                  });
                  Navigator.pop(context); // Close the drawer
                }
              },
            ),
            ListTile(title: const Text('Car Info'), onTap: () {}),
            ListTile(title: const Text('Profile'), onTap: () {}),
          ],
        ),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 13.5,
              ),
              markers: _markers,
              onTap: _addMarker,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitData,
        tooltip: 'Add Markers',
        child: const Icon(Icons.send),
      ),

      // causes probem in login logout
      // floatingActionButton: Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //   children: [
      //     FloatingActionButton(
      //       onPressed: _clearMarkers,
      //       tooltip: 'Clear Markers',
      //       child: const Icon(Icons.delete),
      //     ),
      //     FloatingActionButton(
      //       // onPressed: _socValue == ''
      //       //     ? () => _showBatteryPrompt(context)
      //       //     : () => _submitData(),
      //       onPressed: _submitData,
      //       tooltip: 'Add Markers',
      //       child: const Icon(Icons.send),
      //     ),
      //   ],
      // ),
    );
  }
}
