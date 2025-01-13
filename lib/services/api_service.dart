import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/resi.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String tokenKey = 'auth_token';
  
  final SharedPreferences prefs;

  ApiService(this.prefs);

  // Auth Methods
  Future<User> register(
    String name,
    String email,
    String username,
    String password,
  ) async {
    print('Registering user: $username'); // Debug log
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    print('Register response: ${response.statusCode} - ${response.body}'); // Debug log

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token == null) throw Exception('No token received');
      
      await prefs.setString(tokenKey, token);
      return User.fromJson(data['user'], token);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to register');
    }
  }

  Future<User> login(String identifier, String password) async {
    print('Logging in with identifier: $identifier'); // Debug log
    
    // Clear existing token before login
    await prefs.remove(tokenKey);
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    print('Login response: ${response.statusCode} - ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token == null) throw Exception('No token received');
      
      await prefs.setString(tokenKey, token);
      return User.fromJson(data['user'], token);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to login');
    }
  }

  Future<void> logout() async {
    try {
      final token = await prefs.getString(tokenKey);
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        await prefs.remove(tokenKey);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to logout');
      }
    } finally {
      await prefs.remove(tokenKey);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await prefs.getString(tokenKey);
    if (token == null) return false;
    
    try {
      // Verify token by making a profile request
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getAuthHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<User?> autoLogin() async {
    try {
      final token = await prefs.getString(tokenKey);
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data, token);
      } else {
        await prefs.remove(tokenKey);
        return null;
      }
    } catch (e) {
      await prefs.remove(tokenKey);
      return null;
    }
  }

  Future<String?> getToken() async {
    return prefs.getString(tokenKey);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    print('Changing password'); // Debug log

    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    print('Change password response: ${response.statusCode} - ${response.body}'); // Debug log

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to change password');
    }
  }

  Future<void> resetToken() async {
    try {
      final token = await prefs.getString(tokenKey);
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-token'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        await prefs.remove(tokenKey);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reset token');
      }
    } finally {
      await prefs.remove(tokenKey);
    }
  }

  // Profile Methods
  Future<Map<String, dynamic>> getProfile() async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    print('Getting profile with token: $token'); // Debug log

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getAuthHeaders(token),
    );

    print('Profile response status: ${response.statusCode}'); // Debug log
    print('Profile response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        print('Profile data received: $data'); // Debug log
        return {
          ...data,
          'token': token,  // Include token in the response
        };
      } else {
        throw Exception('Invalid profile data format');
      }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get profile');
    }
  }

  Future<void> updateProfile(String name, String email, String username) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    print('Updating profile - Name: $name, Email: $email, Username: $username'); // Debug log

    final response = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'username': username,
      }),
    );

    print('Update profile response: ${response.statusCode} - ${response.body}'); // Debug log

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update profile');
    }
  }

  Future<String> uploadProfileImage(dynamic imageFile) async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    var uri = Uri.parse('$baseUrl/auth/profile/image');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    try {
      if (kIsWeb && imageFile != null) {
        // Handle web file upload
        final bytes = await imageFile.readAsBytes();
        final filename = imageFile.name ?? 'profile_image.jpg';
        final contentType = imageFile.type != null 
            ? MediaType(imageFile.type!.split('/')[0], imageFile.type!.split('/')[1])
            : MediaType('image', 'jpeg');
            
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      } else if (imageFile is File) {
        // Handle mobile file upload
        final extension = imageFile.path.split('.').last.toLowerCase();
        final contentType = extension == 'png' 
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');
            
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: contentType,
          ),
        );
      } else {
        throw Exception('Invalid image file');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return responseData['imageUrl'] ?? '';
      } else {
        throw Exception(responseData['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Resi Methods
  Future<List<Resi>> getResis() async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    try {
      print('Getting resis with token: $token'); // Debug log

      final response = await http.get(
        Uri.parse('$baseUrl/resi'),
        headers: _getAuthHeaders(token),
      );

      print('GetResis response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Resi.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get resis');
      }
    } catch (e) {
      print('GetResis error: $e'); // Debug log
      rethrow;
    }
  }

  Future<Resi> addResi(String noResi, String title, String courier) async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    try {
      print('Adding resi: $noResi, $title, $courier'); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl/resi'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'noResi': noResi,
          'title': title,
          'courier': courier.toLowerCase(), // Ensure courier is lowercase
        }),
      );

      print('AddResi response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Resi.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to add resi');
      }
    } catch (e) {
      print('AddResi error: $e'); // Debug log
      rethrow;
    }
  }

  Future<Resi> updateResi(String id, String noResi, String title, String courier) async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    try {
      print('Updating resi $id: $noResi, $title, $courier'); // Debug log

      final response = await http.put(
        Uri.parse('$baseUrl/resi/$id'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'noResi': noResi,
          'title': title,
          'courier': courier.toLowerCase(), // Ensure courier is lowercase
        }),
      );

      print('UpdateResi response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Resi.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update resi');
      }
    } catch (e) {
      print('UpdateResi error: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> deleteResi(String id) async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    try {
      print('Deleting resi: $id'); // Debug log

      final response = await http.delete(
        Uri.parse('$baseUrl/resi/$id'),
        headers: _getAuthHeaders(token),
      );

      print('DeleteResi response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete resi');
      }
    } catch (e) {
      print('DeleteResi error: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final token = await prefs.getString(tokenKey);
    if (token == null) throw Exception('Not authenticated');

    try {
      print('Deleting user account'); // Debug log

      final response = await http.delete(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getAuthHeaders(token),
      );

      print('DeleteAccount response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode != 200) {
        if (response.headers['content-type']?.contains('application/json') == true) {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Failed to delete account');
        } else {
          throw Exception('Failed to delete account: ${response.statusCode}');
        }
      }

      // Clear ALL local storage
      await _clearAllData();
    } catch (e) {
      print('DeleteAccount error: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> _clearAllData() async {
    // Clear all data from SharedPreferences
    await prefs.clear();
  }

  Map<String, String> _getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'auth-token': token,
    };
  }
}
