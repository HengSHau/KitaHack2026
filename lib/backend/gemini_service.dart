import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiMatchService {
  final String _apiKey = 'AIzaSyCq2QdmSEjUN96THcxZawdRNMpsA2AYkns';

  Future<bool> checkMatch({
    required String driverStart,
    required String driverEnd,
    required String passengerStart,
    required String passengerEnd,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = """
      You are the AI for GreenNode carpool app.
      Driver goes from: $driverStart to $driverEnd.
      Passenger goes from: $passengerStart to $passengerEnd.
      Are they going in the same direction?
      Respond ONLY in JSON format: {"match": true} or {"match": false}
    """;

    final requestBody = {
      "contents": [{"parts": [{"text": prompt}]}]
    };

    try {    
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        print("Value Returned: $text"); 
        return text.toLowerCase().contains('true');
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  
}