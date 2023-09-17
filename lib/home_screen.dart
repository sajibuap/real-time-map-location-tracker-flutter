import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMapLoadInProgress = true;
  late final GoogleMapController _mapController;
  final List<LatLng> _routes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      PermissionStatus requestPermissionStatus =
          await Location.instance.requestPermission();

      PermissionStatus hasPermissionStatus =
          await Location.instance.hasPermission();

      log(requestPermissionStatus.toString());
      log(hasPermissionStatus.toString());
      if (requestPermissionStatus == PermissionStatus.granted &&
          hasPermissionStatus == PermissionStatus.granted) {
        await configLocationSettings();
        await getCurrentLocation();
        _isMapLoadInProgress = false;
        if (mounted) {
          setState(() {});
        }
      } else {
        log(requestPermissionStatus.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Location Tracker'),
      ),
      body: _isMapLoadInProgress
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_routes.first.latitude, _routes.first.longitude),
                zoom: 15,
                tilt: 20,
                bearing: 10,
              ),
              myLocationEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                currentLocationListener();
              },
              markers: <Marker>{
                Marker(
                  visible: _routes.length > 5,
                  markerId: const MarkerId('initial-location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                  position:
                      LatLng(_routes.first.latitude, _routes.first.longitude),
                  infoWindow: InfoWindow(
                    title: 'Initial Location',
                    snippet:
                        'Lat: ${_routes.first.latitude}, Lng: ${_routes.first.longitude}',
                  ),
                ),
                Marker(
                  markerId: const MarkerId('current-location'),
                  position:
                      LatLng(_routes.last.latitude, _routes.last.longitude),
                  infoWindow: InfoWindow(
                    title: 'My Current Location',
                    snippet:
                        'Lat: ${_routes.last.latitude}, Lng: ${_routes.last.longitude}',
                  ),
                ),
              },
              polylines: <Polyline>{
                Polyline(
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  color: Colors.blue,
                  polylineId: const PolylineId('PolylineId'),
                  points: <LatLng>[
                    ..._routes.map<LatLng>((loc) {
                      return LatLng(loc.latitude, loc.longitude);
                    }).toList(),
                  ],
                ),
              },
            ),
    );
  }

  Future<void> configLocationSettings() async {
    await Location.instance.changeSettings(
      interval: 10000,
      accuracy: LocationAccuracy.high,
    );
  }

  Future<void> getCurrentLocation() async {
    LocationData intitialLocation = await Location.instance.getLocation();
    _routes
        .add(LatLng(intitialLocation.latitude!, intitialLocation.longitude!));
  }

  void currentLocationListener() {
    Location.instance.onLocationChanged.listen((LocationData location) {
      _mapController.moveCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude!, location.longitude!),
        ),
      );
      _routes.add(LatLng(location.latitude!, location.longitude!));
      log('${_routes.length}');
      if (mounted) {
        setState(() {});
      }
    });
  }
}
