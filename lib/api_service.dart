import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // GET: Fetch all inspection reports for dashboard
  static Future<List<dynamic>> fetchReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    }
    return [];
  }

  // POST: Send report with text fields & optional photo (Supports Web & Mobile)
  static Future<bool> submitSupervisorReport({
    required Map<String, dynamic> reportData,
    XFile? photo,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/reports');
      final request = http.MultipartRequest('POST', uri);

      // 1. Attach text payload values to request fields
      reportData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // 2. Attach evidence photo cleanly (Cross-platform safe)
      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'photo',
              bytes,
              filename: photo.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo',
              photo.path,
            ),
          );
        }
      }

      // 3. Send request to Express server
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Report uploaded successfully: ${response.body}');
        return true;
      } else {
        debugPrint('Server Error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Network Exception submitting report: $e');
      return false;
    }
  }
}