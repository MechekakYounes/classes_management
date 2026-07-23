import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'auth_service.dart';


class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({required this.message, this.statusCode, this.errors});

  @override
  String toString() {
    return 'ApiException: $message (Status code: $statusCode, Errors: $errors)';
  }
}

class ApiService {
  static const String _baseUrl ='http://localhost:8000/api'; //http://10.0.2.2:8000/api/classes
  static const String _classesUrl = '$_baseUrl/classes';
  static const String _groupsUrl = '$_baseUrl/groups';
  static const Duration timeout = Duration(seconds: 30);

  static String get baseUrl => _baseUrl; // Expose the base URL for external use
  static set baseUrl(String newUrl) {
    // This setter is for demonstration; in practice, you might want to handle this differently
    // For example, you could store it in SharedPreferences or a config file
    // Here, we just print the new URL for confirmation
    print('Base URL updated to: $newUrl');
  }




  ///classes/{classId}/groups/{groupId}'

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };
  static Map<String, String> authHeaders(String token) {
    return {
      ..._headers,
      'Authorization': 'Bearer $token',
    };
  }

  // Helper to get headers with current token from AuthService
  static Map<String, String> currentAuthHeaders() {
    final token = AuthService().token;
    print("Current token: $token");
    if (token == null) throw Exception('User not authenticatedddddd');
    return authHeaders(token);
  }
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Main HTTP client
  final http.Client _client = http.Client();

  /// Login API
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/login');

      final response = await _client.post(
        url,
        headers: _headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Logout API
  Future<void> logout(String token) async {
    try {
      final url = Uri.parse('$_baseUrl/logout');

      final response = await _client.post(
        url,
        headers: authHeaders(token),
      ).timeout(timeout);

      _handleResponse(response);
    } catch (e) {
      // Even if logout fails, we still want to clear local data
      rethrow;
    }
  }

  /// Get current user
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final url = Uri.parse('$_baseUrl/user');

      final response = await _client.get(
        url,
        headers: authHeaders(token),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Check if super admin exists (for setup)
  Future<Map<String, dynamic>> checkSuperAdmin() async {
    try {
      final url = Uri.parse('$_baseUrl/check-super-admin');

      final response = await _client.get(url).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  /// Setup super admin (first time only)
  Future<Map<String, dynamic>> setupSuperAdmin({
    required String name,
    required String username,
    required String password,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/setup-super-admin');

      final response = await _client.post(
        url,
        headers: _headers,
        body: json.encode({
          'name': name,
          'username': username,
          'password': password,
          'password_confirmation': password,
          'phone': phone,
        }),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }


  // ================================== CLASSES ===================================================================

  static Future<List<dynamic>> getClasses({int? communeId}) async {
    try {
      final urlStr = communeId != null ? '$_classesUrl?commune_id=$communeId' : _classesUrl;
      final uri = Uri.parse(urlStr);

      final response = await http.get(
        uri,
        headers: currentAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No Internet');
    } catch (e) {
      throw Exception('Failed to fetch classes: $e');
    }
  }

  // ================================== COMMUNES ===================================================================
  static const String _communesUrl = '$_baseUrl/communes';

  static Future<List<dynamic>> getCommunes({int? wilayaId}) async {
    try {
      final url = wilayaId != null ? '$_communesUrl?wilaya_id=$wilayaId' : _communesUrl;
      final response = await http.get(
        Uri.parse(url),
        headers: currentAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch communes: $e');
    }
  }

  static Future<List<dynamic>> getCommunesByWilaya(int wilayaId) async {
    return getCommunes(wilayaId: wilayaId);
  }

  static Future<Map<String, dynamic>> createCommune(Map<String, dynamic> communeData) async {
    try {
      final response = await http.post(
        Uri.parse(_communesUrl),
        headers: currentAuthHeaders(),
        body: json.encode(communeData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create commune: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create commune: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCommune(int communeId, Map<String, dynamic> communeData) async {
    try {
      final response = await http.put(
        Uri.parse('$_communesUrl/$communeId'),
        headers: currentAuthHeaders(),
        body: json.encode(communeData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update commune: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update commune: $e');
    }
  }

  static Future<void> deleteCommune(int communeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_communesUrl/$communeId'),
        headers: currentAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete commune: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete commune: $e');
    }
  }
  static Future<Map<String, dynamic>> createClass(
      Map<String, dynamic> classData) async {
    try {
      final response = await http
          .post(
        Uri.parse(_classesUrl),
        headers: currentAuthHeaders(),
        body: json.encode(classData),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  static Future<Map<String, dynamic>> updateClass(
      int id, Map<String, dynamic> classData) async {
    try {
      final response = await http
          .put(
        Uri.parse('$_classesUrl/$id'),
        headers: currentAuthHeaders(),
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

  static Future<void> deleteClass(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$_classesUrl/$id'),
        headers: currentAuthHeaders(),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete class: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  // ========================== GROUPS=================================

  static Future<List<dynamic>> getGroups() async {
    try {
      final response = await http
          .get(
            Uri.parse(_groupsUrl),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return _handleGroupResponse(response);
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  static Future<List<dynamic>> getGroupsByClass(dynamic classId) async {
    try {
      final stringId = classId.toString();
      final url = '$_baseUrl/classes/$stringId/groups';
      final response = await http
          .get(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      } else {
        throw Exception('Unexpected API response format');
      }
    } catch (e) {
      throw Exception('Failed to load groups for this class: $e');
    }
  }

  static Future<Map<String, dynamic>> createGroup(
      int classId, Map<String, dynamic> groupData) async {
    try {
      final url = '$_baseUrl/classes/$classId/groups';
      print('Creating group at: $url with data: $groupData');

      final response = await http
          .post(
            Uri.parse(url),
            headers: currentAuthHeaders(),
            body: json.encode(groupData),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
            headers: currentAuthHeaders(),
            body: json.encode(groupData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  static Future<void> deleteGroup(int classId, int groupId) async {
    try {
      final url = '$_baseUrl/classes/$classId/groups/$groupId';
      final response = await http
          .delete(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

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
        throw Exception(
            'Status: ${response.statusCode}\nBody: ${response.body}');
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

// In api_service.dart, add these methods:

  ///groups/{groupId}/session

// Get all sessions for a specific group
  static Future<List<dynamic>> getSessionsByGroup(int groupId) async {
    try {
      final url = '$_baseUrl/groups/$groupId/session';
      final response = await http
          .get(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
    }
  }

// Create a session for a group
  static Future<Map<String, dynamic>> createSession(
      int groupId, Map<String, dynamic> sessionData) async {
    try {
      final url = '$_baseUrl/groups/$groupId/session';

      // Ensure keys match your database columns exactly
      final formattedData = {
        's_date': sessionData['s_date'], // Must match DB column
        'end_date': sessionData['end_date'],
        'comment': sessionData['comment'] ?? '',
        'group_id': groupId // Note underscore
      };

      print('Sending data: ${json.encode(formattedData)}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: currentAuthHeaders(),
            body: json.encode(formattedData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Failed to create session (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

// Update a session
  static Future<Map<String, dynamic>> updateSession(
      int groupId, int sessionId, Map<String, dynamic> sessionData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/groups/$groupId/session/$sessionId'),
            headers: currentAuthHeaders(),
            body: json.encode(sessionData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

// Delete a session
  static Future<void> deleteSession(int sessionId, int groupId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/groups/$groupId/session/$sessionId'),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  static Future<List<dynamic>> getWilayas() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/wilayas'),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load wilayas: $e');
    }
  }

  static Future<List<dynamic>> getTeachers({int? wilayaId, int? communeId, int? classId, int? groupId}) async {
    try {
      String url = '$_baseUrl/teachers';
      List<String> queryParams = [];
      if (wilayaId != null) queryParams.add('wilaya_id=$wilayaId');
      if (communeId != null) queryParams.add('commune_id=$communeId');
      if (classId != null) queryParams.add('class_id=$classId');
      if (groupId != null) queryParams.add('group_id=$groupId');

      if (queryParams.isNotEmpty) {
          url += '?' + queryParams.join('&');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load teachers: $e');
    }
  }

  static String get _studentsUrl => '$_baseUrl/students';
  static Future<List<dynamic>> getStudents({int? wilayaId, int? communeId, int? classId, int? groupId}) async {
    try {
      String url = _studentsUrl;
      List<String> queryParams = [];
      if (wilayaId != null) queryParams.add('wilaya_id=$wilayaId');
      if (communeId != null) queryParams.add('commune_id=$communeId');
      if (classId != null) queryParams.add('class_id=$classId');
      if (groupId != null) queryParams.add('group_id=$groupId');

      if (queryParams.isNotEmpty) {
          url += '?' + queryParams.join('&');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load students: $e');
    }
  }

  // Get students by group
  static Future<List<dynamic>> getStudentsByGroup(int groupId) async {
    try {
      // Option 1: Try this format based on how your API might be structured
      final url = '$_baseUrl/students/$groupId';

      // Debug info
      print('Fetching students for group $groupId from URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      // More debug info
      print('Response status: ${response.statusCode}');
      if (response.body.length < 1000) {
        // Limit logging of large responses
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 404) {
        // Fallback: Try a different endpoint format if the first one fails
        final fallbackUrl = '$_baseUrl/students?group_id=$groupId';
        print('First endpoint not found. Trying fallback URL: $fallbackUrl');

        final fallbackResponse = await http
            .get(
              Uri.parse(fallbackUrl),
              headers: currentAuthHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        return _handleResponse(fallbackResponse);
      }

      return _handleResponse(response);
    } catch (e) {
      print('Error fetching students for group $groupId: $e');

      // Try to get all students as a fallback approach
      try {
        print('Attempting to get all students and filter by group ID');
        final allStudents = await getStudents();

        // Filter students by group_id
        return allStudents
            .where((student) =>
        student['group_id'].toString() == groupId.toString())
            .toList();
      } catch (fallbackError) {
        print('Fallback approach also failed: $fallbackError');
        throw Exception('Failed to load students for this group: $e');
      }
    }
  }

  // Get a single student
  static Future<Map<String, dynamic>> getStudent(int studentId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$_studentsUrl/$studentId'),
        headers: currentAuthHeaders(),
      )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load student: $e');
    }
  }

  // Create a student
  static Future<Map<String, dynamic>> createStudent(
      Map<String, dynamic> studentData) async {
    try {
      final response = await http
          .post(
            Uri.parse(_studentsUrl),
            headers: currentAuthHeaders(),
            body: json.encode(studentData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Update a student
  static Future<Map<String, dynamic>> updateStudent(
      int studentId, Map<String, dynamic> studentData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_studentsUrl/$studentId'),
            headers: currentAuthHeaders(),
            body: json.encode(studentData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete a student
  static Future<void> deleteStudent(int studentId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_studentsUrl/$studentId'),
            headers: currentAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Import students from an Excel/CSV file
  static Future<void> bulkCreateStudents(
      List<dynamic> students, int groupId) async {
    final url = '$_studentsUrl/$groupId/import';

    final body = {
      'group_id': groupId,
      'students': students, // students is List <dynamic>
    };

    final response = await http.post(
      Uri.parse(url),
      headers: currentAuthHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Students created successfully');
    } else {
      throw Exception('Failed to create students: ${response.body}');
    }
  }

  // ========== ATTENDANCE ==========

  // Get attendance for a session
  static Future<List<dynamic>> getAttendanceBySession(int sessionId) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendances';
      final response = await http
          .get(
            Uri.parse(url),
            headers: currentAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load attendance: $e');
    }
  }

  // Create attendance record
  static Future<Map<String, dynamic>> createAttendance(
      int sessionId, Map<String, dynamic> attendanceData) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendances';

      final formattedData = {
        'student_id': attendanceData['student_id'],
        'session_id': sessionId,
        'status': attendanceData['status'] ?? 'present', // Default status
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: currentAuthHeaders(),
            body: json.encode(formattedData),
          ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create attendance: $e');
    }
  }

  // Update attendance status
  static Future<Map<String, dynamic>> updateAttendance(int sessionId,
      int attendanceId, Map<String, dynamic> attendanceData) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendances/$attendanceId';
      final response = await http
          .put(
            Uri.parse(url),
            headers: currentAuthHeaders(),
            body: json.encode(attendanceData),
          ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Delete attendance record
  static Future<void> deleteAttendance(int sessionId, int attendanceId) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendances/$attendanceId';
      final response = await http
          .delete(
            Uri.parse(url),
            headers: currentAuthHeaders(),
          ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception('Failed to delete attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }

  // Bulk create attendance records
  static Future<Map<String, dynamic>> bulkCreateAttendance(
      int sessionId, List<Map<String, dynamic>> attendanceList) async {
    try {
      final url = '$_baseUrl/session/$sessionId/attendances';

      final response = await http
          .post(
            Uri.parse(url),
            headers: currentAuthHeaders(),
            body: json.encode({'attendance': attendanceList}),
          ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create bulk attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create bulk attendance: $e');
    }
  }

  // --- USER MANAGEMENT API METHODS ---

  static Future<List<dynamic>> getUnassignedManagers() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/unassigned-managers'), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load unassigned managers: $e');
    }
  }

  static Future<List<dynamic>> getUnassignedSchools({int? communeId}) async {
    try {
      String url = '$_baseUrl/unassigned-classes';
      if (communeId != null) url += '?commune_id=$communeId';
      final response = await http
          .get(Uri.parse(url), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load unassigned schools: $e');
    }
  }

  static Future<List<dynamic>> getManagers({int? communeId, int? classId}) async {
    try {
      String url = '$_baseUrl/managers';
      List<String> params = [];
      if (communeId != null) params.add('commune_id=$communeId');
      if (classId != null) params.add('class_id=$classId');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final response = await http
          .get(Uri.parse(url), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load managers: $e');
    }
  }

  static Future<Map<String, dynamic>> createManager(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/managers'),
            headers: currentAuthHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Failed to create manager');
      }
    } catch (e) {
      throw Exception('Failed to create manager: $e');
    }
  }

  static Future<List<dynamic>> getSupervisors({int? wilayaId, int? communeId}) async {
    try {
      String url = '$_baseUrl/supervisors';
      List<String> params = [];
      if (wilayaId != null) params.add('wilaya_id=$wilayaId');
      if (communeId != null) params.add('commune_id=$communeId');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final response = await http
          .get(Uri.parse(url), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load supervisors: $e');
    }
  }

  static Future<Map<String, dynamic>> createSupervisor(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/supervisors'),
            headers: currentAuthHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Failed to create supervisor');
      }
    } catch (e) {
      throw Exception('Failed to create supervisor: $e');
    }
  }

  static Future<List<dynamic>> getAdmins({int? wilayaId}) async {
    try {
      String url = '$_baseUrl/admins';
      if (wilayaId != null) url += '?wilaya_id=$wilayaId';

      final response = await http
          .get(Uri.parse(url), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load admins: $e');
    }
  }

  static Future<Map<String, dynamic>> createAdmin(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admins'),
            headers: currentAuthHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Failed to create admin');
      }
    } catch (e) {
      throw Exception('Failed to create admin: $e');
    }
  }

  // ─── Teacher CRUD ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/teachers'), headers: currentAuthHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) return json.decode(response.body);
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to create teacher');
    } catch (e) {
      throw Exception('Failed to create teacher: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTeacher(int id, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/teachers/$id'), headers: currentAuthHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to update teacher');
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  static Future<void> deleteTeacher(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/teachers/$id'), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete teacher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  // ─── Manager update / delete ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateManager(int id, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/managers/$id'), headers: currentAuthHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to update manager');
    } catch (e) {
      throw Exception('Failed to update manager: $e');
    }
  }

  static Future<void> deleteManager(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/managers/$id'), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete manager: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete manager: $e');
    }
  }

  // ─── Supervisor update / delete ───────────────────────────────────────────

  static Future<Map<String, dynamic>> updateSupervisor(int id, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/supervisors/$id'), headers: currentAuthHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to update supervisor');
    } catch (e) {
      throw Exception('Failed to update supervisor: $e');
    }
  }

  static Future<void> deleteSupervisor(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/supervisors/$id'), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete supervisor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete supervisor: $e');
    }
  }

  // ─── Admin update / delete ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateAdmin(int id, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/admins/$id'), headers: currentAuthHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to update admin');
    } catch (e) {
      throw Exception('Failed to update admin: $e');
    }
  }

  static Future<void> deleteAdmin(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/admins/$id'), headers: currentAuthHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete admin: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete admin: $e');
    }
  }
}