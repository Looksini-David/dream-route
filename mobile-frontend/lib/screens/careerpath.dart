import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
//import 'careerplatform.dart';

class RecommendedCareerPathScreen extends StatefulWidget {
  final String? userId;
  
  const RecommendedCareerPathScreen({super.key, this.userId});

  @override
  State<RecommendedCareerPathScreen> createState() => _RecommendedCareerPathScreenState();
}

class _RecommendedCareerPathScreenState extends State<RecommendedCareerPathScreen> {
  Map<String, dynamic>? careerData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchCareerPath();
  }

  Future<void> _fetchCareerPath() async {
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
        Uri.parse("http://localhost:8000/career-path/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          careerData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch career path: ${response.statusCode}";
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
              isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : error != null
                      ? Center(child: Text(error!, style: const TextStyle(color: Colors.white)))
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.06,
                            vertical: height * 0.04,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: height * 0.07),
                              if (careerData != null) ...[
                                _buildJobRolesSection(careerData!),
                                SizedBox(height: height * 0.03),
                                _buildSkillsToolsSection(careerData!),
                                SizedBox(height: height * 0.03),
                                _buildRoadmapSection(careerData!),
                                SizedBox(height: height * 0.03),
                                _buildMarketTrendsSection(careerData!),
                              ],
                              SizedBox(height: height * 0.15),
                            ],
                          ),
                        ),

              // Top AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: const Color(0xFF091E3A),
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    "Recommended Career Path",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

  Widget _buildJobRolesSection(Map<String, dynamic> data) {
    final jobRoles = data['job_roles'] as List<dynamic>? ?? [];
    
    if (jobRoles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: const Text(
          "No job roles found for your domain",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "Job Roles",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...jobRoles.map((role) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              role.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildSkillsToolsSection(Map<String, dynamic> data) {
    final skills = data['required_skills'] as List<dynamic>? ?? [];
    final tools = data['required_tools'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "Required Skills & Tools",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (skills.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Required Skills:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...skills.map((skill) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                skill.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
          const SizedBox(height: 16),
        ],
        if (tools.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Required Tools:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...tools.map((tool) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                tool.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ],
        if (skills.isEmpty && tools.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              "Skills and tools data coming soon...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildRoadmapSection(Map<String, dynamic> data) {
    final roadmap = data['roadmap_suggestions'] as Map<String, dynamic>? ?? {};
    final courses = roadmap['courses'] as List<dynamic>? ?? [];
    final projects = roadmap['projects'] as List<dynamic>? ?? [];
    final certificates = roadmap['certificates'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "Roadmap Suggestions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (courses.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Courses:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...courses.map((course) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                course.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
          const SizedBox(height: 16),
        ],
        if (projects.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Projects:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...projects.map((project) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                project.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
          const SizedBox(height: 16),
        ],
        if (certificates.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Certifications:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...certificates.map((cert) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                cert.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ],
        if (courses.isEmpty && projects.isEmpty && certificates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              "Roadmap suggestions coming soon...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildMarketTrendsSection(Map<String, dynamic> data) {
    final trends = data['market_trends'] as Map<String, dynamic>? ?? {};
    final globalTrends = trends['global'] as Map<String, dynamic>? ?? {};
    final sriLankaTrends = trends['sri_lanka'] as Map<String, dynamic>? ?? {};
    final lastUpdated = trends['last_updated'] ?? "";
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.8), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color.fromARGB(255, 5, 5, 5)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Job Market Trends",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 5, 5, 5),
                  ),
                ),
              ),
              if (lastUpdated.isNotEmpty)
                Text(
                  "Updated: $lastUpdated",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Global Market Trends
          _buildTrendCard(
            "🌍 Global Market",
            globalTrends['salary_min'],
            globalTrends['salary_max'],
            globalTrends['currency'] ?? "USD",
            globalTrends['demand_level'] ?? "Not available",
            globalTrends['demand_percentage'] ?? 0,
            globalTrends['insights'] ?? "",
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Sri Lanka Market Trends
          _buildTrendCard(
            "🇱🇰 Sri Lanka Market",
            sriLankaTrends['salary_min'],
            sriLankaTrends['salary_max'],
            sriLankaTrends['currency'] ?? "LKR",
            sriLankaTrends['demand_level'] ?? "Not available",
            sriLankaTrends['demand_percentage'] ?? 0,
            sriLankaTrends['insights'] ?? "",
            Colors.green,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendCard(String title, dynamic salaryMin, dynamic salaryMax, String currency,
                        String demandLevel, int demandPercentage, String insights, Color accentColor) {
    Color demandColor = Colors.green;
    if (demandLevel.toString().toLowerCase().contains("medium") || 
        (demandPercentage >= 50 && demandPercentage < 70)) {
      demandColor = Colors.orange;
    } else if (demandLevel.toString().toLowerCase().contains("low") || 
               demandPercentage < 50) {
      demandColor = Colors.red;
    } else if (demandLevel.toString().toLowerCase().contains("very high") || 
               demandPercentage >= 85) {
      demandColor = Colors.green.shade700;
    }
    
    // Format salary display
    String salaryMinStr = "Not available";
    String salaryMaxStr = "Not available";
    String salaryPeriod = currency == "LKR" ? "per month" : "per year";
    String currencySymbol = currency == "LKR" ? "Rs. " : "\$";
    
    if (salaryMin != null && salaryMax != null) {
      // Format numbers with commas
      String formatNumber(num value) {
        return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
      
      salaryMinStr = formatNumber(salaryMin as num);
      salaryMaxStr = formatNumber(salaryMax as num);
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          // Minimum Salary
          Row(
            children: [
              const Icon(Icons.arrow_downward, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              const Text(
                "Minimum: ",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$currencySymbol$salaryMinStr",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Maximum Salary
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              const Text(
                "Maximum: ",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$currencySymbol$salaryMaxStr",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Salary Period
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              salaryPeriod,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: demandColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Demand: $demandLevel ($demandPercentage%)",
                  style: TextStyle(
                    fontSize: 13,
                    color: demandColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      insights,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color.fromARGB(255, 5, 5, 5)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 5, 5, 5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
