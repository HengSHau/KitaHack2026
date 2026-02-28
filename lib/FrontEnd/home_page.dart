import 'package:flutter/material.dart';
import 'package:kitahack2026/FrontEnd/available_rides_page.dart';
import 'package:kitahack2026/backend/home_backend.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import 'package:geocoding/geocoding.dart';
import 'available_rides_page.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import 'matching_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState(); 
}

class RideRequest {
  final String email;
  final String name;
  final String role;
  final String start;
  final String destination;
  final int seats;
  final String personality;
  final double destLat;
  final double destLng;

  RideRequest({
    required this.email,
    required this.name,
    required this.role,
    required this.start,
    required this.destination,
    required this.seats,
    required this.personality,
    required this.destLat,
    required this.destLng,
  });
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  final TextEditingController _destinationController = TextEditingController();
  
  bool _isDriver = false;
  int _maxSeats = 1;
  Set<Marker> _markers = {};
  int _selectedIndex = 0;
  bool _followUserLocation = true;
  LatLng? currentp;
  LatLng? destinationp;
  Set<Polyline> line = {};
  String _estimatedTime = "N/A";
  
  GoogleMapController? _mapController;  

  final UserService _userService = UserService();
  String _currentUsername = "Guest";

  @override
  void initState() {
    super.initState();
    _loadName();
    Future.delayed(const Duration(seconds: 1), () {
      _startLocationTracking();
    });
    Future.delayed(const Duration(seconds: 1), () {
      _nearlyOtherUsers();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
       setOfflineStatus();
    } else if (state == AppLifecycleState.resumed) {
       _userService.updateLiveLocation(); 
    }
  }

  Future<void> _handleSearch(String address) async {
    LatLng? target = await _userService.getCoordsFromAddress(address);

    if (target != null && mounted) {
      setState(() {
        _followUserLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );

      _setDestinationDialog(address, target);

      setState(() {
        _markers.add(Marker(
          markerId: MarkerId(address),
          position: target,
          infoWindow: InfoWindow(title: address),
        ));
      });
    } else {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location not found: $address")),
        );
      }
    }
  }

  void _setDestinationDialog(String address, LatLng target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Destination"),
        content: Text("Confirm '$address' set to destination?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmNavigation(address, target); 
            },
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }

  void _confirmNavigation(String address, LatLng target) async {
    if (currentp == null) return;

    var routeData = await _userService.getDirections(currentp!, target);

    List<LatLng> points = routeData["Lines"] as List<LatLng>;
    String duration = routeData["Durations"] as String;

    if (points.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not find a road route.")),
        );
      }
      return;
    }
    
    setState(() {
      destinationp = target;
      _estimatedTime = duration; 

      _markers.add(Marker(
        markerId: const MarkerId("destination"),
        position: target,
        infoWindow: InfoWindow(title: "Destination: $address"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      line.clear();
      line.add(Polyline(
        polylineId: const PolylineId("road_route"),
        points: points,
        color: Colors.blueAccent,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
    });

    String standardizedAddress = address; 
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(target.latitude, target.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        standardizedAddress = "${place.street}, ${place.locality}";
      }
    } catch (e) {
      print("Standardization failed: $e");
    }

    await _userService.updateDestination(standardizedAddress, target.latitude, target.longitude);
  }

  void _loadName() async {
    String name = await _userService.getCurrentUsername();
    if (mounted) {
      setState(() {
        _currentUsername = name;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadName();
  }

  void _startLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _userService.updateLiveLocation();
      Geolocator.getPositionStream().listen((Position position) {
        currentp = LatLng(position.latitude, position.longitude);

        if (_followUserLocation) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      });
    } else {
      print("User has already rejected tracking request!");
    }
  }

  void _nearlyOtherUsers() {
    try {
      _userService.getNearbyUsersStream().listen((users) {
        if (!mounted) return;
        setState(() {
          _markers = users.map((u) {
            return Marker(
              markerId: MarkerId(u['id']),
              position: LatLng(u['lat'] ?? 0.0, u['lng'] ?? 0.0),
              infoWindow: InfoWindow(title: u['username']),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            );
          }).toSet();
        });
      }, onError: (error) {
        print("Stream Error: $error");
      });
    } catch (e) {
      print("NearlyOtherUsers Catch: $e");
    }
  }

  void setOfflineStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'OnlineStatus': false,
      });
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Match Now or Later",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      String destination = _destinationController.text.trim();
                      
                      if (destination.isEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a destination first!")),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(color: Color(0xFF2ECC71))
                        ),
                      );

                      String actualStartLocation = "Unknown Location";
                      if (currentp != null) {
                        try {
                          List<Placemark> placemarks = await placemarkFromCoordinates(currentp!.latitude, currentp!.longitude);
                          if (placemarks.isNotEmpty) {
                            Placemark place = placemarks.first;
                            String street = place.street ?? place.name ?? "";
                            String area = place.locality ?? place.subLocality ?? "";
                            actualStartLocation = street.isNotEmpty && area.isNotEmpty ? "$street, $area" : (street.isNotEmpty ? street : area);
                            if(actualStartLocation.isEmpty) {
                                actualStartLocation = "Current Location";
                            }
                          }
                        } catch (e) {
                          print("Address translation failed, using coordinates: $e");
                          actualStartLocation = "${currentp!.latitude.toStringAsFixed(4)}, ${currentp!.longitude.toStringAsFixed(4)}";
                        }
                      }

                      // Read firebase user details
                      String email = FirebaseAuth.instance.currentUser?.email ?? "example@gmail.com";
                      String personality = "Introverted";
                      String name = _currentUsername;

                      if (email != "example@gmail.com") {
                        try {
                          var userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();

                          if (userQuery.docs.isNotEmpty) {
                            var data = userQuery.docs.first.data();
                            personality = data['personality'] ?? "Introverted";
                            name = data['username'] ?? _currentUsername;
                          }
                        } catch (e) {
                          print("Error fetching user data from Firebase: $e");
                        }
                      }

                      // Send data to MatchingPage
                      final currentUserData = RideRequest(
                        email: email,
                        name: name,
                        role: _isDriver ? "driver" : "passenger",
                        start: actualStartLocation,
                        destination: destination,
                        seats: _isDriver ? _maxSeats : 1,
                        personality: personality,
                        destLat: destinationp?.latitude ?? 0.0, 
                        destLng: destinationp?.longitude ?? 0.0,
                      );

                      // Upload to Firebase
                      try {
                        await FirebaseFirestore.instance.collection('ride_requests').doc(email).set({
                          'email': email,
                          'name': name,
                          'role': _isDriver ? "driver" : "passenger",
                          'start': actualStartLocation,
                          'destination': destination,
                          'seats': _isDriver ? _maxSeats : 1,
                          'personality': personality,
                          'destLat': destinationp?.latitude ?? 0.0, 
                          'destLng': destinationp?.longitude ?? 0.0,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        print("✅ Successfully uploaded ride request: $actualStartLocation to $destination");
                      } catch (e) {
                        print("❌ Failed to upload ride request: $e");
                      }

                      Navigator.pop(context);
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchingPage(currentUser: currentUserData), 
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Match Now", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      String destination = _destinationController.text.trim();
                      if (destination.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a destination first!")),
                        );
                        return;
                      }

                      String email = FirebaseAuth.instance.currentUser?.email ?? "example@gmail.com";
                      final currentUserData = RideRequest(
                        email: email,
                        name: _currentUsername,
                        role: _isDriver ? "driver" : "passenger",
                        start: "Current Location", 
                        destination: destination,
                        seats: _isDriver ? _maxSeats : 1,
                        personality: "Introverted", 
                        destLat: destinationp?.latitude ?? 0.0, 
                        destLng: destinationp?.longitude ?? 0.0,
                      );

                      Navigator.pop(context); 
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvailableRidesPage(currentUser: currentUserData)
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAAAAAA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Match in Advance", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.65,
                child: GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(3.055, 101.69), 
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: line,
                  mapType: MapType.normal, 
                  myLocationEnabled: true, 
                  myLocationButtonEnabled: false, 
                  zoomControlsEnabled: false, 
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    border: const Border(top: BorderSide(color: Color(0xFF2ECC71), width: 1.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String displayName = _currentUsername;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            var data = snapshot.data!.data() as Map<String, dynamic>;
                            displayName = data['username'] ?? "Guest";
                          }
                          return Text(
                            "Where to go, $displayName?",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 10),

                            Expanded(
                              child: TextField(
                                controller: _destinationController,
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _handleSearch(value); 
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: "Search",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const Icon(Icons.mic, color: Colors.grey),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12.0, 
                        runSpacing: 10.0,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  _buildRoleButton("Passenger", Icons.person, !_isDriver),
                                  _buildRoleButton("Driver", Icons.directions_car, _isDriver),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          if (_isDriver)
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8F3),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.event_seat, size: 18, color: Color(0xFF2ECC71)),
                                    DropdownButton<int>(
                                      value: _maxSeats,
                                      underline: const SizedBox(),
                                      items: [1, 2, 3, 4].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() => _maxSeats = val!);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              flex: 2,
                              child: _buildDetailBox(Icons.access_time_filled_rounded, "EST. TIME", _estimatedTime, Colors.blue.shade50, Colors.blue,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _showMatchDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text("Match", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const ChatSelectionPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDetailBox(IconData icon, String label, String value, Color bgColor, Color iconColor) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: iconColor.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String title, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isDriver = (title == "Driver");
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] 
              : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF2ECC71) : Colors.grey),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}