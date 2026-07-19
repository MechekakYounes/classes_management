import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();

  // User data
  Map<String, dynamic>? _user;
  String? _token;
  List<String>? _permissions;
  String? _roleName;
  int? _wilayaId;
  int? _communeId;
  int? _classId;
  int? _groupId;
  String? _wilayaName;
  String? _communeName;

  // Getters
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  List<String>? get permissions => _permissions;
  String? get roleName => _roleName;
  bool get isLoggedIn => _token != null;
  int? get wilayaId => _wilayaId;
  int? get communeId => _communeId;
  int? get classId => _classId;
  int? get groupId => _groupId;
  String? get wilayaName => _wilayaName;
  String? get communeName => _communeName;

  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _permissionsKey = 'user_permissions';
  static const String _roleNameKey = 'user_role_name';
  static const String _wilayaIdKey = 'user_wilaya_id';
  static const String _communeIdKey = 'user_commune_id';
  static const String _classIdKey = 'user_class_id';
  static const String _groupIdKey = 'user_group_id';
  static const String _wilayaNameKey = 'user_wilaya_name';
  static const String _communeNameKey = 'user_commune_name';

  /// Initialize auth service
  Future<void> init() async {
    await _loadFromStorage();
  }

  /// Load data from SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString(_tokenKey);
    final userString = prefs.getString(_userKey);
    final permissionsString = prefs.getString(_permissionsKey);
    _roleName = prefs.getString(_roleNameKey);
    _wilayaId = prefs.getInt(_wilayaIdKey);
    _communeId = prefs.getInt(_communeIdKey);
    _classId = prefs.getInt(_classIdKey);
    _groupId = prefs.getInt(_groupIdKey);
    _wilayaName = prefs.getString(_wilayaNameKey);
    _communeName = prefs.getString(_communeNameKey);

    if (userString != null) {
      _user = Map<String, dynamic>.from(json.decode(userString));
      _extractScopingInfo();
    }

    if (permissionsString != null) {
      _permissions = List<String>.from(json.decode(permissionsString));
    }

    notifyListeners();
  }

  void _extractScopingInfo() {
    if (_user != null) {
      _wilayaId = _user!['wilaya_id'] != null ? int.tryParse(_user!['wilaya_id'].toString()) : null;
      _communeId = _user!['commune_id'] != null ? int.tryParse(_user!['commune_id'].toString()) : null;
      _classId = _user!['class_id'] != null ? int.tryParse(_user!['class_id'].toString()) : null;
      _groupId = _user!['group_id'] != null ? int.tryParse(_user!['group_id'].toString()) : null;
      _wilayaName = _user!['wilaya_name']?.toString();
      _communeName = _user!['commune_name']?.toString();
      if (_user!['role_name'] != null) {
        _roleName = _user!['role_name'];
      }
    }
  }

  /// Save data to SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }

    if (_user != null) {
      await prefs.setString(_userKey, json.encode(_user));
    }

    if (_permissions != null) {
      await prefs.setString(_permissionsKey, json.encode(_permissions));
    }

    if (_roleName != null) {
      await prefs.setString(_roleNameKey, _roleName!);
    }

    if (_wilayaId != null) {
      await prefs.setInt(_wilayaIdKey, _wilayaId!);
    } else {
      await prefs.remove(_wilayaIdKey);
    }

    if (_communeId != null) {
      await prefs.setInt(_communeIdKey, _communeId!);
    } else {
      await prefs.remove(_communeIdKey);
    }

    if (_classId != null) {
      await prefs.setInt(_classIdKey, _classId!);
    } else {
      await prefs.remove(_classIdKey);
    }

    if (_groupId != null) {
      await prefs.setInt(_groupIdKey, _groupId!);
    } else {
      await prefs.remove(_groupIdKey);
    }

    if (_wilayaName != null) {
      await prefs.setString(_wilayaNameKey, _wilayaName!);
    } else {
      await prefs.remove(_wilayaNameKey);
    }

    if (_communeName != null) {
      await prefs.setString(_communeNameKey, _communeName!);
    } else {
      await prefs.remove(_communeNameKey);
    }
  }

  /// Clear all stored data
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_permissionsKey);
    await prefs.remove(_roleNameKey);
    await prefs.remove(_wilayaIdKey);
    await prefs.remove(_communeIdKey);
    await prefs.remove(_classIdKey);
    await prefs.remove(_groupIdKey);
    await prefs.remove(_wilayaNameKey);
    await prefs.remove(_communeNameKey);

    _user = null;
    _token = null;
    _permissions = null;
    _roleName = null;
    _wilayaId = null;
    _communeId = null;
    _classId = null;
    _groupId = null;
    _wilayaName = null;
    _communeName = null;

    notifyListeners();
  }

  /// Login with username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(
        username: username,
        password: password,
      );
      print('Login response: $response');

      // تأمين جلب البيانات سواء كانت داخل حقل data أو في جذر الـ response مباشرة
      final responseData = response['data'] ?? response;

      // استخراج التوكن بشكل مرن وحفظه فوراً في الذاكرة
      _token = responseData['token'];
      print("NEW TOKEN ASSIGNED IN RAM = $_token");

      if (_token == null && response['success'] == true && response['data'] != null) {
        _token = response['data']['token'];
      }

      if (_token != null) {
        _user = Map<String, dynamic>.from(responseData['user'] ?? {});
        _permissions = List<String>.from(responseData['permissions'] ?? []);
        _roleName = responseData['role_name'];
        _extractScopingInfo();

        await _saveToStorage();
        notifyListeners(); // تنبيه كافة الكلاسات (بما فيها ApiService) بالتوكن الجديد
      } else {
        throw ApiException(message: response['message'] ?? 'Login failed: Token not found in response');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      if (_token != null) {
        await _apiService.logout(_token!);
      }
    } catch (e) {
      print('Logout API error (ignoring to clear local): $e');
    } finally {
      // التنظيف يتم دائماً في النهاية لضمان تصفير الذاكرة فوراً
      await _clearStorage();
      notifyListeners();
    }
    return true;
  }

  /// Get current user from API (refresh)
  Future<void> refreshUser() async {
    if (_token == null) return;

    try {
      final response = await _apiService.getCurrentUser(_token!);
      final responseData = response['data'] ?? response;

      _user = Map<String, dynamic>.from(responseData['user'] ?? {});
      _permissions = List<String>.from(responseData['permissions'] ?? []);
      _roleName = responseData['role_name'];
      _extractScopingInfo();

      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      print('Failed to refresh user: $e');
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return _permissions?.contains(permission) ?? false;
  }

  /// Check if user is super admin
  bool isSuperAdmin() {
    return _roleName == 'super-admin' || _roleName == 'super_admin' || _user?['role'] == 'super_admin';
  }

  /// Check if user is admin
  bool isAdmin() {
    return _roleName == 'admin' || _user?['role'] == 'admin';
  }

  /// Check if user is manager
  bool isManager() {
    return _roleName == 'manager' || _user?['role'] == 'manager';
  }

  /// Check if user is supervisor   
  bool isSupervisor() {
    return _roleName == 'supervisor' || _user?['role'] == 'supervisor';
  }

  /// Check if user is Teacher
  bool isTeacher() {
    return _roleName == 'teacher' || _user?['role'] == 'teacher';
  }

  /// Get user's display name
  String getDisplayName() {
    return _user?['name'] ?? 'User';
  }

  /// Get user's username
  String getUsername() {
    return _user?['username'] ?? '';
  }

  /// Get user's phone
  String getPhone() {
    return _user?['phone'] ?? '';
  }
}