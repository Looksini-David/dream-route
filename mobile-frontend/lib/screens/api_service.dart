import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Use localhost hostname to match other ApiService instances in the app
  static const String baseUrl =
      "http://localhost:8000"; // Replace with your backend URL

  /// ------------------ TOKEN ------------------
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Some parts of the app store the token under "token" (login.dart),
    // while others expect "jwt_token". Check both for compatibility.
    return prefs.getString("jwt_token") ?? prefs.getString("token");
  }

  /// ------------------ GET USER PROFILE ------------------
  /// Role should be "fresher" or "student"
  static Future<Map<String, dynamic>?> getUserProfile(String role) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$role/profile/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to fetch profile ($role): ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile ($role): $e");
    }
    return null;
  }

  /// ------------------ UPDATE USER PROFILE ------------------
  /// data is a Map<String, dynamic> containing fields to update
  static Future<bool> updateUserProfile(
    String role,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$role/profile/update/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) return true;

      print("Failed to update profile ($role): ${response.statusCode}");
      return false;
    } catch (e) {
      print("Error updating profile ($role): $e");
      return false;
    }
  }

  /// ------------------ PROFILE IMAGE ------------------
  static Future<Uint8List?> getProfileImage(String userId) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile-image/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) return response.bodyBytes;

      print("Failed to fetch profile image: ${response.statusCode}");
    } catch (e) {
      print("Error fetching profile image: $e");
    }
    return null;
  }

  static Future<bool> uploadProfileImage(Uint8List imageBytes) async {
    final token = await getToken();
    if (token == null) {
      print("Upload profile image: No token found");
      return false;
    }

    try {
      print("Uploading profile image: ${imageBytes.length} bytes");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/profile-image/upload/"),
      );

      request.headers["Authorization"] = "Bearer $token";

      // Add image with explicit content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: "profile_image.png",
          contentType: null, // Let the multipart handler infer it from filename
        ),
      );

      final response = await request.send();
      print("Upload profile image response: ${response.statusCode}");
      print("Upload profile image headers: ${response.headers}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Profile image uploaded successfully");
        return true;
      }

      final responseBody = await response.stream.bytesToString();
      print("Failed to upload profile image: ${response.statusCode}");
      print("Response body: $responseBody");
      return false;
    } catch (e) {
      print("Error uploading profile image: $e");
      return false;
    }
  }

  /// ------------------ GET RESUME (FRESHER ONLY) ------------------
  static Future<Uint8List?> getResume(String userId) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/resume/$userId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) return response.bodyBytes;

      print("Failed to fetch resume: ${response.statusCode}");
    } catch (e) {
      print("Error fetching resume: $e");
    }
    return null;
  }

  // ------------------------------
  // Upload Resume
  // ------------------------------
  static Future<String> uploadResume(
    Uint8List fileBytes,
    String filename,
  ) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/resume/upload"),
    );

    request.headers['Authorization'] = "Bearer $token";
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['rule_id'];
    } else {
      throw Exception('Resume upload failed');
    }
  }

  // ------------------------------
  // Analyze Resume
  // ------------------------------
  static Future<Map<String, dynamic>> analyzeResume(String ruleId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/resume/analyze/$ruleId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Resume analysis failed');
    }
  }

  // ------------------------------
  // Get Resume Analysis Result
  // ------------------------------
  static Future<Map<String, dynamic>> getResumeResult() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    final response = await http.get(
      Uri.parse("$baseUrl/resume/result"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      // Return empty map with status to indicate no resume found
      try {
        final errorData = jsonDecode(response.body);
        return {"status": "not_found", "message": errorData.get('detail', 'No resume found')};
      } catch (e) {
        return {"status": "not_found", "message": "No resume found"};
      }
    } else {
      throw Exception('Fetching resume result failed: ${response.statusCode}');
    }
  }

}
