import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geo;

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use to get address to find it in google map
  Future<LatLng?> getCoordsFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Geocoding error: $e");
    }
    return null; 
  }

  // Use to get the destination of user set
  Future<void> updateDestination(String address, double lat, double lng) async {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'destinationName': address,
          'destLatitude': lat,
          'destLongitude': lng,
          'isNavigating': true, 
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  
  // use to clear polyline when arried or cancel
  Future<void> clearDestination() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'destinationName': FieldValue.delete(),
        'destLatitude': FieldValue.delete(),
        'destLongitude': FieldValue.delete(),
        'isNavigating': false,
      });
    }
  }

  final String _googleApiKey = "AIzaSyBiGMWJftV-4oBnV0MNQmPbxUybDHaUagQ";

  // Google Firaction API for polylines and duration
  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {
  List<LatLng> polylineCoordinates = [];
  String duration = "N/A";
  
  String url = "https://maps.googleapis.com/maps/api/directions/json?" +
      "origin=${origin.latitude},${origin.longitude}" +
      "&destination=${destination.latitude},${destination.longitude}" +
      "&mode=driving" +
      "&key=$_googleApiKey";

  try {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
        duration = data['routes'][0]['legs'][0]['duration']['text'];

        PolylinePoints polylinePoints = PolylinePoints(apiKey: _googleApiKey); 
        List<PointLatLng> result = PolylinePoints.decodePolyline(encodedPolyline);


        if (result.isNotEmpty) {
          for (var point in result) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
      } else {
        print("Directions API Error Status: ${data['status']}");
        if(data['error_message'] != null) print("Error Message: ${data['error_message']}");
      }
    }
  } catch (e) {
    print("Error fetching directions: $e");
  }
  return {
    "Lines" : polylineCoordinates,
    "Durations" : duration
  };
}

  // Used to get username by login account
  Future<String> getCurrentUsername() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          // validate the username is correctly by login account
          return doc.get('username') ?? "User";
        }
      }
      return "Guest";
    } catch (e) {
      print("Error fetching username: $e");
      return "Error";
    }
  }

  // logout
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null){
      await _firestore.collection("user").doc(user.uid).update({
        'OnlineStatus' : false,
        'LastOnlineTime' : FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }
  
  // update user location
  Future<void> updateLiveLocation() async {
    // Check GPS is open in user device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // real-time update location
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 10, 
      ),
    ).listen((Position position) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // location write into firabase
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'OnlineStatus': true,
          'lastUpdated': FieldValue.serverTimestamp(), // record updated time
        });
        print("location updated: ${position.latitude}, ${position.longitude}");
      }
    });
  }

  Stream<List<Map<String, dynamic>>> getNearbyUsersStream() {
  return _firestore.collection('users').where('OnlineStatus', isEqualTo: true).snapshots().map((snapshot) {
    return snapshot.docs
        .where((doc) => doc.id != _auth.currentUser?.uid) // filter yourself to get other location
        .map((doc) => {
              'id': doc.id,
              'username': doc.get('username') ?? 'User',
              'lat': doc.get('latitude') ?? 0.0,
              'lng': doc.get('longitude') ?? 0.0,
            })
        .toList();
    });
  }
}