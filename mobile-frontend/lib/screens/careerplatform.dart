import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:dream_route/screens/roadmap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CareerPlatform extends StatefulWidget {
  final String? userId;
  
  const CareerPlatform({super.key, this.userId});

  @override
  State<CareerPlatform> createState() => _CareerPlatformState();
}

class _CareerPlatformState extends State<CareerPlatform> {
  Map<String, dynamic>? platformData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchGrowthPlatforms();
  }

  Future<void> _fetchGrowthPlatforms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      
      if (token == null) {
        setState(() {
          error = "No authentication token found";
          isLoading = false;
        });
        return;
      }

      // Get userId from widget or fetch from profile
      String userId = widget.userId ?? '';
      if (userId.isEmpty) {
        final role = prefs.getString("role") ?? "student";
        try {
          final profileResponse = await http.get(
            Uri.parse("http://localhost:8000/$role/profile/"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          );
          
          if (profileResponse.statusCode == 200) {
            final profileData = jsonDecode(profileResponse.body);
            userId = profileData['user_id']?.toString() ?? '';
          }
        } catch (e) {
          print("Error fetching profile: $e");
        }
      }

      if (userId.isEmpty) {
        setState(() {
          error = "Could not find user ID";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("http://localhost:8000/growth-platforms/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          platformData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch growth platforms: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch URL")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching URL: $e")),
        );
      }
    }
  }

  String _getSkillLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '🟢';
      case 'intermediate':
        return '🟡';
      case 'advanced':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'free':
        return '🆓 Free';
      case 'free_certificate':
        return '🎓 Free Certificate';
      case 'online_course':
        return '💻 Online Course';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF091E3A),
              Color(0xFF2D9EE0),
              Color(0xFF2E8FE7),
              Colors.white,
            ],
            stops: [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable content
              isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : error != null
                      ? Center(child: Text(error!, style: const TextStyle(color: Colors.white)))
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            width * 0.06,
                            height * 0.10,
                            width * 0.06,
                            height * 0.12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (platformData != null) ...[
                                // Domain info header
                                _buildDomainHeader(platformData!['best_domain'] ?? 'Your Domain'),
                                SizedBox(height: height * 0.03),
                                
                                // YouTube Section - English & Tamil
                                if (platformData!['platforms']?['YouTube'] != null)
                                  _buildYouTubeSection(platformData!['platforms']!['YouTube']),
                                
                                SizedBox(height: height * 0.03),
                                
                                // Free Courses & Certificates Section
                                _buildSectionHeader("Free Courses & Certificates", Icons.school),
                                SizedBox(height: height * 0.02),
                                ..._buildPlatformCardsByType(platformData!['platforms'] ?? {}, ['free', 'free_certificate']),
                                
                                SizedBox(height: height * 0.03),
                                
                                // Online Courses Section
                                _buildSectionHeader("Online Courses", Icons.computer),
                                SizedBox(height: height * 0.02),
                                ..._buildPlatformCardsByType(platformData!['platforms'] ?? {}, ['online_course']),
                                
                                SizedBox(height: height * 0.03),
                                
                                // Other Professional Platforms
                                _buildSectionHeader("Other Professional Platforms", Icons.language),
                                SizedBox(height: height * 0.02),
                                ..._buildOtherPlatforms(platformData!['platforms'] ?? {}),
                              ],
                            ],
                          ),
                        ),

              // Transparent AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: const Color(0xFF091E3A),
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    "Career Growth Platform",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainHeader(String domain) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recommended Platforms for:",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  domain,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeSection(Map<String, dynamic> youtubeData) {
    final height = MediaQuery.of(context).size.height;
    final List<Widget> widgets = [];
    
    // English YouTube channels
    if (youtubeData['English'] != null) {
      widgets.add(_buildSectionHeader("YouTube - English", Icons.language));
      widgets.add(SizedBox(height: height * 0.02));
      final englishLinks = youtubeData['English'] as List;
      for (var link in englishLinks) {
        if (link is Map && link.containsKey('url')) {
          widgets.add(_buildYouTubeCard(
            title: link['title'] ?? 'YouTube',
            url: link['url'],
            skillLevel: link['skill_level'] ?? 'beginner',
            language: 'English',
          ));
          widgets.add(SizedBox(height: height * 0.02));
        }
      }
    }
    
    // Tamil YouTube channels
    if (youtubeData['Tamil'] != null) {
      widgets.add(_buildSectionHeader("YouTube - Tamil", Icons.language));
      widgets.add(SizedBox(height: height * 0.02));
      final tamilLinks = youtubeData['Tamil'] as List;
      for (var link in tamilLinks) {
        if (link is Map && link.containsKey('url')) {
          widgets.add(_buildYouTubeCard(
            title: link['title'] ?? 'YouTube',
            url: link['url'],
            skillLevel: link['skill_level'] ?? 'beginner',
            language: 'Tamil',
          ));
          widgets.add(SizedBox(height: height * 0.02));
        }
      }
    }
    
    return Column(children: widgets);
  }

  Widget _buildYouTubeCard({
    required String title,
    required String url,
    required String skillLevel,
    required String language,
  }) {
    final width = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: width * 0.04,
          horizontal: width * 0.06,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 245, 63, 63).withOpacity(0.8),
              const Color.fromARGB(255, 245, 63, 63),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: const Icon(Icons.video_library, color: Color.fromARGB(255, 245, 63, 63)),
            ),
            SizedBox(width: width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _getSkillLevelColor(skillLevel),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        skillLevel.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          language,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlatformCardsByType(Map<String, dynamic> platforms, List<String> types) {
    final height = MediaQuery.of(context).size.height;
    final List<Widget> cards = [];
    
    for (var platformName in platforms.keys) {
      if (platformName == 'YouTube') continue; // YouTube handled separately
      
      final platform = platforms[platformName];
      if (platform is Map && platform.containsKey('url')) {
        final type = platform['type'] ?? '';
        if (types.contains(type)) {
          cards.add(_buildPlatformCard(
            platformName: platformName,
            title: platform['title'] ?? platformName,
            url: platform['url'],
            skillLevel: platform['skill_level'] ?? 'beginner',
            type: type,
          ));
          cards.add(SizedBox(height: height * 0.02));
        }
      }
    }
    
    if (cards.isNotEmpty && cards.last is SizedBox) {
      cards.removeLast();
    }
    
    return cards;
  }

  List<Widget> _buildOtherPlatforms(Map<String, dynamic> platforms) {
    final height = MediaQuery.of(context).size.height;
    final List<Widget> cards = [];
    
    final platformIcons = {
      'FreeCodeCamp': Icons.code_rounded,
      'Coursera': Icons.school,
      'Alison': Icons.menu_book,
      'Udemy': Icons.video_library,
      'edX': Icons.cast_for_education,
      'MDN Web Docs': Icons.article,
      'W3Schools': Icons.web,
      'Kaggle': Icons.analytics,
    };
    
    final platformColors = {
      'FreeCodeCamp': const Color.fromARGB(255, 100, 247, 105),
      'Coursera': Colors.blueAccent,
      'Alison': Colors.deepPurpleAccent,
      'Udemy': Colors.purple,
      'edX': Colors.blue,
      'MDN Web Docs': Colors.orange,
      'W3Schools': Colors.green,
      'Kaggle': Colors.teal,
    };
    
    for (var platformName in platforms.keys) {
      if (platformName == 'YouTube') continue;
      
      final platform = platforms[platformName];
      if (platform is Map && platform.containsKey('url')) {
        cards.add(_buildPlatformCard(
          platformName: platformName,
          title: platform['title'] ?? platformName,
          url: platform['url'],
          skillLevel: platform['skill_level'] ?? 'beginner',
          type: platform['type'] ?? '',
          icon: platformIcons[platformName] ?? Icons.link,
          iconColor: platformColors[platformName] ?? Colors.blue,
        ));
        cards.add(SizedBox(height: height * 0.02));
      }
    }
    
    if (cards.isNotEmpty && cards.last is SizedBox) {
      cards.removeLast();
    }
    
    return cards;
  }

  Widget _buildPlatformCard({
    required String platformName,
    required String title,
    required String url,
    required String skillLevel,
    required String type,
    IconData? icon,
    Color? iconColor,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    // Default icons and colors
    final defaultIcons = {
      'FreeCodeCamp': Icons.code_rounded,
      'Coursera': Icons.school,
      'Alison': Icons.menu_book,
    };
    
    final defaultColors = {
      'FreeCodeCamp': const Color.fromARGB(255, 100, 247, 105),
      'Coursera': Colors.blueAccent,
      'Alison': Colors.deepPurpleAccent,
    };
    
    final cardIcon = icon ?? defaultIcons[platformName] ?? Icons.link;
    final cardColor = iconColor ?? defaultColors[platformName] ?? Colors.blue;
    
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: width * 0.04,
          horizontal: width * 0.06,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.8), cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(cardIcon, color: cardColor),
            ),
            SizedBox(width: width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _getSkillLevelColor(skillLevel),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        skillLevel.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500),
                      ),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getTypeLabel(type),
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
