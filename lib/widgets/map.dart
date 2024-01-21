import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'
    show FlutterMap, MapController, MapOptions, Marker, MarkerLayer, TileLayer;
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isAddingMarker = false;
  final MapController mapController = MapController();
  @override
  void initState() {
    super.initState();
    _userLocationFuture = _getUserLocation();
  }

  XFile? _image;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
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
    TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relate sua ocorrência',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                TextField(
                  minLines: 7,
                  maxLines: 7,
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descrição da ocorrência',
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Anexar foto'),
                ),
                if (_image != null) Image.file(File(_image!.path)),
                ElevatedButton(
                  onPressed: () {
                    if (descriptionController.text.isEmpty ||
                        descriptionController.text.trim().isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Erro'),
                            content: Text('Descrição é obrigatória!'),
                            actions: [
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      print('Descrição: ${descriptionController.text}');

                      int protocolNumber = Random().nextInt(1000000);

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Ocorrência Recebida'),
                            content: Text(
                                'Sua ocorrência foi recebida com o número de protocolo $protocolNumber.'),
                            actions: [
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text('Salvar'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _tempMarker = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: _userLocationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ?? LatLng(0.0, 0.0),
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
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
          if (_isAddingMarker)
            Center(
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              mapController.move(
                  mapController.camera.center, mapController.zoom + 1);
            },
            child: Icon(Icons.zoom_in),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              mapController.move(
                  mapController.camera.center, mapController.zoom - 1);
            },
            child: Icon(Icons.zoom_out),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isAddingMarker = !_isAddingMarker;
                if (!_isAddingMarker) {
                  // O usuário clicou em "Salvar"
                  LatLng center = mapController.camera.center;
                  _showModal(center);
                  print(
                      'Latitude: ${center.latitude}, Longitude: ${center.longitude}');
                  // Adicione um Marker na posição atual do centro do mapa
                }
              });
            },
            child: Icon(_isAddingMarker ? Icons.save : Icons.add),
          ),
        ],
      ),
    );
  }
}
