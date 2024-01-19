import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'
    show FlutterMap, MapOptions, Marker, MarkerLayer, TileLayer;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/foundation.dart'; // for FutureBuilder

class LeafletMapWidget extends StatefulWidget {
  @override
  _LeafletMapWidgetState createState() => _LeafletMapWidgetState();
}

class _LeafletMapWidgetState extends State<LeafletMapWidget> {
  loc.Location _location = loc.Location();
  LatLng? _currentPosition;
  Future<void>? _userLocationFuture;

  @override
  void initState() {
    super.initState();
    _userLocationFuture = _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    print(_currentPosition);
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }
    loc.LocationData locationData = await _location.getLocation();
    setState(() {
      _currentPosition =
          LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _userLocationFuture,
      builder: (context, snapshot) {
        print(snapshot.connectionState);
        if (snapshot.connectionState == ConnectionState.done) {
          return FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition ?? LatLng(0.0, 0.0),
              initialZoom: 12,
              onTap: (tapPosition, point) => {
                print(point.toString()),
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition ?? LatLng(0.0, 0.0),
                    child:
                        Icon(Icons.location_on, size: 35, color: Colors.blue),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Center(
              child: CircularProgressIndicator()); // Loading indicator
        }
      },
    );
  }
}
