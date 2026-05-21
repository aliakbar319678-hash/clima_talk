// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final apiKey = 'AIzaSyBJ54hsocuI0mDGDJM8VA4jNDGmGdbiGdw';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  
  try {
    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List;
      print('Available models:');
      for (var model in models) {
        print(' - ${model['name']} (${model['supportedGenerationMethods']})');
      }
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Failed to fetch models: $e');
  }
}
