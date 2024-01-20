import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'
    show FlutterMap, MapOptions, Marker, MarkerLayer, TileLayer;
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
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
  LatLng? _selectedPosition;
  Marker? _tempMarker;

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

  void _showModal(LatLng point) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latitude: ${point.latitude}'),
              Text('Longitude: ${point.longitude}'),
              // Adicione mais campos ou widgets aqui
            ],
          ),
        );
      },
    ).then((_) {
      // Quando o modal é fechado, remova o marcador temporário
      setState(() {
        _tempMarker = null;
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _userLocationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition ?? LatLng(0.0, 0.0),
                initialZoom: 12,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedPosition = point;
                    _tempMarker = Marker(
                      width: 80.0,
                      height: 80.0,
                      point: point,
                      child: Icon(Icons.location_on),
                    );
                  });
                  _showModal(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_tempMarker != null) MarkerLayer(markers: [_tempMarker!]),
                CurrentLocationLayer(
                  followOnLocationUpdate: FollowOnLocationUpdate.always,
                  positionStream: LocationMarkerDataStreamFactory()
                      .fromGeolocatorPositionStream(
                    stream: Geolocator.getPositionStream(),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            ); // Loading indicator
          }
        },
      ),
    );
  }
}
