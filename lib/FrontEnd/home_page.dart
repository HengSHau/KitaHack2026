import 'package:flutter/material.dart';
import 'package:kitahack2026/backend/home_backend.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import 'package:geocoding/geocoding.dart';
import 'match_in_advance_page.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import 'package:kitahack2026/backend/notification_service.dart';
import 'matching_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
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
    _startLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
    _initNotificationSetting(); 
    AppNotificationListener().startListening();
  });
  
    Future.delayed(const Duration(seconds: 1), () {
      _NearlyOtherUsers();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() { 
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void ChangingonlineState(AppLifecycleState state) {
    // When user quit the app will set to offline
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
       setOfflineStatus();
    } else if (state == AppLifecycleState.resumed) {
      // while back to the app updated status to online
       _userService.updateLiveLocation(); 
    }
  }

  Future<void> _handleSearch(String address) async {
  // Check location 
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

    SetDestinationDialog(address, target);

    // Updated Marker
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

  void SetDestinationDialog(String address, LatLng target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Destination"),
        content: Text("Comfirm '$address' set to destination?"),
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

// Use to get the user conformation for set destination to get estimated time and polylines
void _confirmNavigation(String address, LatLng target) async {
  if (currentp == null) return;

  // Direction Api
  var routeData = await _userService.getDirections(currentp!, target);

  // Get polylines and duration data
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
  
  //Updated polylines and duration data
  setState(() {
    destinationp = target;
    _estimatedTime = duration; 

    // Updated marker
    _markers.add(Marker(
      markerId: const MarkerId("destination"),
      position: target,
      infoWindow: InfoWindow(title: "Destination: $address"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    // Updated polylines
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

  await _userService.updateDestination(address, target.latitude, target.longitude);
}

  void _loadName() async {
    String name = await _userService.getCurrentUsername();
    if (mounted) {
      setState(() {
        _currentUsername = name;
      });
    }
  }

  //ensure that the username will be showing correctly while profile changing
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadName();
  }

  void _initNotificationSetting() async {
    bool granted = await NotificationService.requestNotificationPermission(context);
    
    if (granted) {
      print("Notification permission has been obtained");
      AppNotificationListener().startListening();
    } else {
      print("The user denied notification permissions.");
    }
  }

  void _startLocationTracking() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _userService.updateLiveLocation();
      Geolocator.getPositionStream().listen((Position position) {
        currentp = LatLng(position.latitude, position.longitude);

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
                    onPressed: () {
                      String destination = _destinationController.text.trim();
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchingPage(destination: destination),
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
                        MaterialPageRoute(builder: (context) => const MatchInAdvancePage()),
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
                      // FIXED REAL-TIME STREAM
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
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