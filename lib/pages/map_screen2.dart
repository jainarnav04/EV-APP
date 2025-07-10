import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreenTest extends StatefulWidget {
  const MapScreenTest({super.key});

  @override
  _MapScreenTestState createState() => _MapScreenTestState();
}

class _MapScreenTestState extends State<MapScreenTest> {
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(LatLng position) {
    final String markerIdVal = 'marker_id_$_markers.length';
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(markerIdVal),
        position: position,
        infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      ));
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
    });
  }

  void _addMarker2() {
    setState(() {
      _markers.add(const Marker(
        markerId: MarkerId("jhjkhkhkhj"),
        position: LatLng(37.77483, -122.41942),
        infoWindow: InfoWindow(title: "jhkjhkjhk", snippet: '*'),
      ));
    });
  }

  void _submitData() async {
    final response = await http.post(
      Uri.parse('http://172.17.15.52:5000/send_latlong'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'soc': "ee",
        'currentLocation': "dsd",
        'destination': "dsd",
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      LatLng apiLocation = LatLng(data['latitude'], data['longitude']);
      print("Sucesssssss----------------------------");
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('apiLocation'),
          position: apiLocation,
          infoWindow: const InfoWindow(title: 'API Location'),
        ));
      });
    } else {
      print("An error occured while sending data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Markers'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.77483, -122.41942), // San Francisco coordinates
          zoom: 13,
        ),
        markers: _markers,
        onTap: _addMarker,
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _clearMarkers,
            tooltip: 'Clear Markers',
            child: const Icon(Icons.delete),
          ),
          FloatingActionButton(
            onPressed: _submitData,
            tooltip: 'Add Markers',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
