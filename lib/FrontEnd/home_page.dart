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
  final String id;
  final String name;
  final String role;
  final String start;
  final String destination;
  final int seats;
  final String personality;

  RideRequest({
    required this.id,
    required this.name,
    required this.role,
    required this.start,
    required this.destination,
    required this.seats,
    required this.personality,
  });
}

class _HomePageState extends State<HomePage> {
  bool _isDriver = false;
  int _maxSeats = 1;

  final TextEditingController _destinationController = TextEditingController();
  
  Set<Marker> _markers = {};
  int _selectedIndex = 0;
  bool _followUserLocation = true;
  
  GoogleMapController? _mapController;  
  final LatLng _defaultLocation = const LatLng(3.055, 101.69);

  final UserService _userService = UserService();
  String _currentUsername = "Guest";

  @override
  void initState() {
    super.initState();
    _loadName();
    _startLocationTracking();
    Future.delayed(const Duration(seconds: 1), () {
      _NearlyOtherUsers();
    });
  }

  Future<void> _handleSearch(String address) async {
    // 1. 叫后台去查坐标 (纯数据)
    LatLng? target = await _userService.getCoordsFromAddress(address);

    if (target != null && mounted) {
      // 2. 前台负责操作控制器 (纯 UI)
      setState(() {
        _followUserLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );
      
      // 更新 Marker
      setState(() {
        _markers.add(Marker(
          markerId: MarkerId(address),
          position: target,
          infoWindow: InfoWindow(title: address),
        ));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not found: $address")),
      );
    }
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
    var status = await Permission.location.request();
    if (status.isGranted) {
      _userService.updateLiveLocation();
      Geolocator.getPositionStream().listen((Position position) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      });
    } else {
      print("User has already reject tracking request!");
    }
  }

  void _NearlyOtherUsers() {
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
                    onPressed: () {
                      String destination = _destinationController.text.trim();
                      
                      if (destination.isEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a destination first!")),
                        );
                        return;
                      }

                      // Get firebase data
                      final currentUserData = RideRequest(
                        id: FirebaseAuth.instance.currentUser?.uid ?? "guest_id",
                        name: _currentUsername,
                        role: _isDriver ? "driver" : "passenger",
                        start: "Current Location", // 演示时可以写死，或替换为真实反编译的地址
                        destination: destination,
                        seats: _isDriver ? _maxSeats : 1,
                        personality: "Introverted", // 暂时代替，以后你可以在设置页加一个性格选择器
                      );

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
                    onPressed: () {
                      Navigator.pop(context); 
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AvailableRidesPage()),
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
                      // FIXED REAL-TIME STREAM
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.email)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String displayName = _currentUsername;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            var data = snapshot.data!.data() as Map<String, dynamic>;
                            // FIXED: Changed '+' to '=' for assignment
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
                                    _handleSearch(value); //Enter address to search
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Search",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            Icon(Icons.mic, color: Colors.grey),
                            SizedBox(width: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12.0, 
                        runSpacing: 10.0,
                        children: [
                          _buildLocationChip("Pavilion Bukit Jalil"),
                          _buildLocationChip("APU"),
                          _buildLocationChip("Parkhill"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Driver or passenger
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
                          
                          // If isDriver, show capacity combobox
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
                            // If passenger, show eta ui
                            Expanded(
                              flex: 2,
                              child: _buildDetailBox(Icons.access_time_filled_rounded, "EST. TIME", "15-20m", Colors.blue.shade50, Colors.blue,
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

  Widget _buildLocationChip(String fullLocationName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _destinationController.text = fullLocationName;
        });
        _handleSearch(fullLocationName);
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 95),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        )  
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