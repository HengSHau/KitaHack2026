import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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


  // Used to get username by login accout
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
        // locatio write into firabase
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