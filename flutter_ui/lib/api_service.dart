import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String _baseUrl =
      'http://127.0.0.1:8000/api/classes'; //http://10.0.2.2:8000/api/classes
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };

  // Get all classes
  static Future<List<dynamic>> getClasses() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No Internet');
    } on HttpException {
      throw Exception('Couldnot reach the server');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      throw Exception('Failed to fetch: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        if (response.body.isNotEmpty) {
          return json.decode(response.body);
        } else {
          return [];
        }
      case 400:
        throw Exception('Bad request');
      case 401:
      case 403:
        throw Exception('Unauthorized');
      case 404:
        throw Exception('Not found');
      case 500:
        throw Exception('Server error');
      default:
        throw Exception(
            'Request failed\nStatus: ${response.statusCode}\nBody: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createClass(
      Map<String, dynamic> classData) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: json.encode(classData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        getClasses();
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  // Update class uses put method
  static Future<Map<String, dynamic>> updateClass(
      int id, Map<String, dynamic> classData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/$id'),
            headers: _headers,
            body: json.encode(classData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  // Delete a class uses destroy method
  static Future<void> deleteClass(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }
}
