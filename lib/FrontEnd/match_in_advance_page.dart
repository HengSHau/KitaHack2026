import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack2026/backend/match_in_advance_backend.dart.dart';
import 'home_page.dart'; 
import 'chat_page.dart';

class MatchInAdvancePage extends StatefulWidget {
  final RideRequest currentUser;
  const MatchInAdvancePage({super.key, required this.currentUser});

  @override
  State<MatchInAdvancePage> createState() => _MatchInAdvancePageState();
}

class _MatchInAdvancePageState extends State<MatchInAdvancePage> {
  final AdvanceData _advanceDate = AdvanceData(); 
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 30)), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2ECC71), onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2ECC71)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) setState(() => _selectedTime = picked);
  }

  Widget _buildPickerField({required String label, required String hint, required IconData icon, required String? value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value ?? hint, style: TextStyle(color: value == null ? Colors.grey.shade400 : Colors.black87, fontSize: 16)),
                Icon(icon, size: 20, color: Colors.black87),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context)
        )
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Match in Advance", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPickerField(
                      label: "Date",
                      hint: "Select Date",
                      icon: Icons.calendar_today,
                      value: _selectedDate != null ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}" : null,
                      onTap: () => _pickDate(context),
                    ),
                    const SizedBox(height: 20),
                    _buildPickerField(
                      label: "Time",
                      hint: "Select Time",
                      icon: Icons.access_time,
                      value: _selectedTime?.format(context),
                      onTap: () => _pickTime(context),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedDate == null || _selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select both date and time!")));
                            return;
                          }

                          showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71))));

                          try {
                            await _advanceDate.createadvancedata(
                              datetime: _selectedDate!,
                              hour: _selectedTime!.hour.toDouble(),
                              min: _selectedTime!.minute.toDouble(),
                            );

                            final String dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
                            final String timeStr = _selectedTime!.format(context);

                            DocumentReference rideRef = await FirebaseFirestore.instance.collection('scheduled_rides').add({
                              'email': widget.currentUser.email,
                              'name': widget.currentUser.name,
                              'role': widget.currentUser.role,
                              'date': dateStr,
                              'time': timeStr,
                              'start': widget.currentUser.start,
                              'destination': widget.currentUser.destination, 
                              'seats': widget.currentUser.seats,
                              'personality': widget.currentUser.personality,
                              'destLat': widget.currentUser.destLat, 
                              'destLng': widget.currentUser.destLng,    
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            List<String> mergedEmails = [widget.currentUser.email]; 
                            String groupTitle = "Carpool to ${widget.currentUser.destination}_${dateStr}_${timeStr}";

                            DocumentReference groupRef = await FirebaseFirestore.instance.collection('Groups').add({
                              'groupName': groupTitle,
                              'participants': mergedEmails,
                              'lastMessage': "Carpool group created! Say Hi 👋",
                              'timestamp': FieldValue.serverTimestamp(),
                              'rideId': rideRef.id,
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Carpool & Group created!"), backgroundColor: Colors.green)
                              );
                              
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupMessagingPage(
                                    groupId: groupRef.id,
                                    groupName: groupTitle,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context); 
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text("Create Carpool", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}