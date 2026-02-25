import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<LatLng?> getCoordsFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Geocoding error: $e");
    }
    return null; // 找不到就返回空
  }

  // 获取当前登录用户的用户名
  Future<String> getCurrentUsername() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          // 这里的 'username' 必须和你注册时存入的 Key 一模一样
          return doc.get('username') ?? "User";
        }
      }
      return "Guest";
    } catch (e) {
      print("Error fetching username: $e");
      return "Error";
    }
  }

  // 退出登录逻辑
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 实时更新位置到 Firestore
  Future<void> updateLiveLocation() async {
    // 1. 检查定位服务是否开启
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 2. 持续监听位置变化
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, // 高精度
        distanceFilter: 10, // 用户移动超过 10 米才更新数据库，节省流量和电量
      ),
    ).listen((Position position) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 3. 将经纬度写入 Firebase
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastUpdated': FieldValue.serverTimestamp(), // 记录最后更新时间
        });
        print("位置已更新: ${position.latitude}, ${position.longitude}");
      }
    });
  }

  Stream<List<Map<String, dynamic>>> getNearbyUsersStream() {
  return _firestore.collection('users').snapshots().map((snapshot) {
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