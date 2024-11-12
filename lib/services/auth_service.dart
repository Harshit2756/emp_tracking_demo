import 'dart:convert';

import 'package:http/http.dart' as http;

import '../shared/storage_helper.dart';

class AuthService {
  final String _baseUrl = 'https://petroprime.info:8442/emp/api';

  // Sign in with email and password
  Future<Map<String, dynamic>?> login(String userName, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userName': userName,
          'password': password,
        }),
      );

      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String? token = data['token'];
        final String? userName = data['username'];

        if (token != null) {
          await StorageHelper.storeUserToken(token);
        }
        if (userName != null) {
          await StorageHelper.storeUserId(userName);
        }

        return data;
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> logout() async {
    try {
      final token = await StorageHelper.getUserToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await StorageHelper.deleteUserData();
      } else {
        throw Exception('Failed to logout: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign up new user
  // Future<Map<String, dynamic>?> signup(
  //     {required String email,
  //     required String password,
  //     required String name}) async {
  //   try {
  //     // Check if user already exists
  //     final DatabaseService db = DatabaseService();
  //     final existingUser = await db.getUserByEmail(email);

  //     if (existingUser != null) {
  //       throw Exception(
  //           'The email address is already in use by another account.');
  //     }

  //     // Create new user
  //     final response = await http.post(
  //       Uri.parse('$_baseUrl/signup'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({
  //         'email': email,
  //         'password': password,
  //         'name': name,
  //       }),
  //     );

  //     if (response.statusCode == 201) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       final String? token = data['token'];
  //       final String? userId = data['userId'];

  //       if (token != null) {
  //         await StorageHelper.storeUserToken(token);
  //       }
  //       if (userId != null) {
  //         await StorageHelper.storeUserId(userId);
  //       }

  //       // Create and store user in local database
  //       final newUser = {
  //         'id': userId,
  //         'name': name,
  //         'email': email,
  //       };
  //       await db.addUser(newUser);

  //       return data;
  //     } else {
  //       throw Exception('Failed to sign up: ${response.body}');
  //     }
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
}
