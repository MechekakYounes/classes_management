// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
<<<<<<< HEAD
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  static const String _classesUrl = '$_baseUrl/classes';
  static const String _groupsUrl = '$_baseUrl/grp'; // Directly targets the 'grp' table
=======
  static const String _baseUrl =
      'http://localhost:8000/api'; //http://10.0.2.2:8000/api/classes
  static const String _classesUrl = '$_baseUrl/classes';
  static const String _groupsUrl = '$_baseUrl/groups';

  ///classes/{classId}/groups/{groupId}'
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };

<<<<<<< HEAD
  // ========== CLASSES ==========
=======
  // ================================== CLASSES ===================================================================
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

  static Future<List<dynamic>> getClasses() async {
    try {
      final uri = Uri.parse(_classesUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No Internet');
    } catch (e) {
      throw Exception('Failed to fetch classes: $e');
    }
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> createClass(Map<String, dynamic> classData) async {
    try {
      final response = await http.post(
        Uri.parse(_classesUrl),
        headers: _headers,
        body: json.encode(classData),
      ).timeout(const Duration(seconds: 10));
=======
  static Future<Map<String, dynamic>> createClass(
      Map<String, dynamic> classData) async {
    try {
      final response = await http
          .post(
            Uri.parse(_classesUrl),
            headers: _headers,
            body: json.encode(classData),
          )
          .timeout(const Duration(seconds: 10));
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> updateClass(int id, Map<String, dynamic> classData) async {
    try {
      final response = await http.put(
        Uri.parse('$_classesUrl/$id'),
        headers: _headers,
        body: json.encode(classData),
      ).timeout(const Duration(seconds: 10));
=======
  static Future<Map<String, dynamic>> updateClass(
      int id, Map<String, dynamic> classData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_classesUrl/$id'),
            headers: _headers,
            body: json.encode(classData),
          )
          .timeout(const Duration(seconds: 10));
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  static Future<void> deleteClass(int id) async {
    try {
<<<<<<< HEAD
      final response = await http.delete(
        Uri.parse('$_classesUrl/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
=======
      final response = await http
          .delete(
            Uri.parse('$_classesUrl/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

      if (response.statusCode != 204) {
        throw Exception('Failed to delete class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

<<<<<<< HEAD
  // ========== GROUPS (grp TABLE) ==========

  static Future<List<dynamic>> getAllGroups() async {
    try {
      final response = await http.get(
        Uri.parse(_groupsUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
=======
  // ========================== GROUPS=================================

  static Future<List<dynamic>> getGroups() async {
    try {
      final response = await http
          .get(
            Uri.parse(_groupsUrl),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

      return _handleGroupResponse(response);
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

<<<<<<< HEAD
  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> groupData) async {
  try {
    print('Creating group with data: $groupData'); // Debug log
    
    final response = await http.post(
      Uri.parse(_groupsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(groupData),
    ).timeout(const Duration(seconds: 10));

    print('Response status: ${response.statusCode}'); // Debug log
    print('Response body: ${response.body}'); // Debug log

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Try to parse error message from response
      try {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 
                       'Failed to create group (Status: ${response.statusCode})');
      } catch (_) {
        throw Exception('Failed to create group (Status: ${response.statusCode})');
      }
    }
  } on SocketException {
    throw Exception('No internet connection');
  } catch (e) {
    throw Exception('Failed to create group: ${e.toString()}');
  }
}

  static Future<Map<String, dynamic>> updateGroup(int groupId, Map<String, dynamic> groupData) async {
    try {
      final response = await http.put(
        Uri.parse('$_groupsUrl/$groupId'),
        headers: _headers,
        body: json.encode(groupData),
      ).timeout(const Duration(seconds: 10));
=======
  static Future<Map<String, dynamic>> createGroup(
      int classId, Map<String, dynamic> groupData) async {
    try {
      final url = '$_baseUrl/classes/$classId/groups';
      //print('Creating group at: $url with data: $groupData');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(groupData),
          )
          .timeout(const Duration(seconds: 10));

      //print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Failed to create group (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  static Future<Map<String, dynamic>> updateGroup(
      int classId, int groupId, Map<String, dynamic> groupData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/classes/$classId/groups/$groupId'),
            headers: _headers,
            body: json.encode(groupData),
          )
          .timeout(const Duration(seconds: 10));
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

<<<<<<< HEAD
  static Future<void> deleteGroup(int groupId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_groupsUrl/$groupId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
=======
  static Future<void> deleteGroup(int classId, int groupId) async {
    try {
      final url = '$_baseUrl/classes/$classId/groups/$groupId';
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318

      if (response.statusCode != 204) {
        throw Exception('Failed to delete group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // ========== RESPONSE HANDLERS ==========

  static dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return response.body.isNotEmpty ? json.decode(response.body) : [];
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
<<<<<<< HEAD
        throw Exception('Status: ${response.statusCode}\nBody: ${response.body}');
=======
        throw Exception(
            'Status: ${response.statusCode}\nBody: ${response.body}');
>>>>>>> 3c641c4b476c5178c927d14691c05ec676d1b318
    }
  }

  static dynamic _handleGroupResponse(http.Response response) {
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        return decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) {
          return data;
        }
        throw Exception('Expected List in "data" field');
      }

      throw Exception('Unexpected response format');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }
}
