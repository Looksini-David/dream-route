import 'fresher_quizsummary.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:8000";

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to fetch data: ${response.body}");
  }
}

class FresDashboard extends StatefulWidget {
  const FresDashboard({super.key});

  @override
  State<FresDashboard> createState() => _FresDashboardState();
}

class _FresDashboardState extends State<FresDashboard> {
  bool showProfileMenu = false;
  Map<String, dynamic>? profileData;
  Uint8List? profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void toggleProfileMenu() => setState(() => showProfileMenu = !showProfileMenu);

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.get("/fresher/profile/"); // Backend route
      setState(() => profileData = data);
      
      // Fetch profile image if user_id exists
      if (data['user_id'] != null) {
        final imageBytes = await _getProfileImage(data['user_id']);
        if (imageBytes != null && mounted) {
          setState(() => profileImage = imageBytes);
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }
  
  Future<Uint8List?> _getProfileImage(String userId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        print("Profile image fetch: No token found");
        return null;
      }
      
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/profile-image/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );
      
      print("Profile image fetch status: ${response.statusCode}");
      if (response.statusCode == 200) {
        print("Profile image fetch: Success, size: ${response.bodyBytes.length} bytes");
        return response.bodyBytes;
      } else {
        print("Profile image fetch failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading profile image: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF091E3A), Color(0xFF2D9EE0), Color(0xFF2E8FE7), Colors.white],
            stops: [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text("${profileData?['name'] ?? 'Fresher 👋'}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        GestureDetector(
                          onTap: toggleProfileMenu,
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImage != null
                                ? MemoryImage(profileImage!)
                                : null,
                            child: profileImage == null
                                ? const Icon(Icons.person, color: Color(0xFF2D9EE0), size: 28)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Image.asset('assets/logo.png'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: width > 300 ? 3 : 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      children: [
                        _buildMenuCard(Icons.person, "Profile Overview", () => Navigator.pushNamed(context, '/fresher_profile')),
                        _buildMenuCard(
                          Icons.assignment,
                          "Quiz Result",
                          () {
                            final userId = profileData != null && profileData!['user_id'] != null
                                ? profileData!['user_id'].toString()
                                : '';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FresherQuizSummary(userId: userId),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(Icons.description, "Resume Analysis", () => Navigator.pushNamed(context, '/resume_analysis')),
                        _buildMenuCard(Icons.work, "Career Path", () => Navigator.pushNamed(context, '/career_path')),
                        _buildMenuCard(Icons.school, "Growth Platforms", () => Navigator.pushNamed(context, '/career_platform')),
                        _buildMenuCard(Icons.psychology, "AI Task", () => Navigator.pushNamed(context, '/ai_task')),
                        _buildMenuCard(Icons.timeline, "Roadmap", () => Navigator.pushNamed(context, '/road_map')),
                        _buildMenuCard(Icons.feedback, "Feedback", () => Navigator.pushNamed(context, '/feedback')),
                      ],
                    ),
                  ],
                ),
              ),
              if (showProfileMenu)
                Positioned(
                  top: 80,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("👤 ${profileData?['name'] ?? 'Fresher'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF091E3A))),
                          const SizedBox(height: 6),
                          Text("✉ ${profileData?['email'] ?? 'fresher@example.com'}", style: const TextStyle(color: Colors.black54)),
                          const Divider(),
                          GestureDetector(onTap: logout, child: const Text("🚪 Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE3F2FD)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: const Color(0xFF091E3A)),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF091E3A))),
          ],
        ),
      ),
    );
  }
}