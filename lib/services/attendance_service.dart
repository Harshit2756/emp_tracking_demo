import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../shared/storage_helper.dart';

class AttendanceService {
  final String _baseUrl = 'https://petroprime.info:8442/emp/api';

  // Get attendance records
  Future<List<Map<String, dynamic>>> getAttendance() async {
    try {
      final token = await StorageHelper.getUserToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get attendance: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Save attendance with image
  Future<Map<String, dynamic>?> saveAttendance({
    required Map<String, dynamic> data,
    required img.Image image,
    required File file,
    required bool isEntry,
  }) async {
    try {
      final token = await StorageHelper.getUserToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/attendance/save'),
      );

      // Add headers (remove Content-Type as it's set automatically for multipart)
      request.headers['Authorization'] = 'Bearer $token';

      // Create the JSON data structure as shown in the curl example
      Map<String, dynamic> jsonData = {
        'status': data['status'],
        'transDate': data['transDate'],
        'lat': data['lat'],
        'lang': data['lang'],
      };

      // Add inTime or exitTime based on isEntry
      if (isEntry) {
        jsonData['inTime'] = data['inTime'];
      } else {
        jsonData['exitTime'] = data['exitTime'];
      }

      // Add the JSON data as a form field with type specification
      request.fields['data'] = '${json.encode(jsonData)};type=application/json';

      // Add image file
      request.files.add(
        http.MultipartFile(
          'image',
          file.openRead(),
          await file.length(),
          filename: file.path.split('/').last,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save attendance: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
