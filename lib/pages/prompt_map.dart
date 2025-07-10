import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPrompt extends StatefulWidget {
  const MapPrompt({super.key});

  @override
  _MapPromptState createState() => _MapPromptState();
}

class _MapPromptState extends State<MapPrompt> {
  final TextEditingController _batteryController = TextEditingController();
  Location location = Location();
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    var locationData = await location.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    // TODO: Implement map creation logic
    setState(() {
      _mapController = controller;
    });
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
      _showBatteryPrompt(context);
    });
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

  void _submitData() async {
    final response = await http.post(
      Uri.parse('http://172.17.15.52:5000/send_latlong'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'soc': _batteryController.text,
        'currentLocation': _currentLocation.toString(),
        'destination': _destinationLocation.toString(),
      }),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      var data = jsonDecode(response.body);
      LatLng apiLocation = LatLng(data['latitude'], data['longitude']);
      print(apiLocation);
      setState(
        () {
          _markers.add(Marker(
            markerId: const MarkerId('apiLocation'),
            position: apiLocation,
            infoWindow: const InfoWindow(title: 'API Location'),
          ));
          print(_markers);
        },
      );
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: apiLocation,
            zoom: 14.0,
          ),
        ),
      );
    } else {
      print("An error occured while sending data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Prompt Page'),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              ),
              markers: _markers,
              onTap: _onMarkerSelected,
            ),
    );
  }
}
