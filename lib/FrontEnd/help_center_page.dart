import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQTile('How to book a ride?', 'Select your destination on the map, choose a driver, and confirm your request.'),
          _buildFAQTile('How do I pay for the ride?', 'Currently, we support cash payments directly to the driver or GrabPay/Touch n Go transfers.'),
          _buildFAQTile('Is Uni-Ride Pool safe?', 'Yes, all users are verified students or staff of APU. We recommend checking the driver/passenger ratings.'),
          _buildFAQTile('Can I cancel my ride?', 'You can cancel your ride at any time before it starts, but please inform your partner via chat first.'),
          
          const SizedBox(height: 32),
          const Center(child: Text('Still need help?', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {}, 
              child: const Text('Contact Support', style: TextStyle(color: Color(0xFF00B14F), fontWeight: FontWeight.bold))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Colors.grey[700], height: 1.5)),
        ),
      ],
    );
  }
}