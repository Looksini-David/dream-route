import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _feedbackController = TextEditingController();
  
  Map<String, dynamic>? feedbackData;
  bool isLoading = true;
  String? error;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fetchFeedback();
  }
  
  Future<void> _fetchFeedback() async {
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

      String userId = '';
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

      if (userId.isEmpty) {
        setState(() {
          error = "Could not find user ID";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("http://localhost:8000/feedback/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          feedbackData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch feedback: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error connecting to server: $e";
        isLoading = false;
      });
    }
  }
  
  Future<void> _submitUserFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your feedback")),
      );
      return;
    }
    
    setState(() {
      isSubmitting = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No authentication token found")),
        );
        return;
      }

      String userId = '';
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

      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not find user ID")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse("http://localhost:8000/feedback/$userId/submit"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"content": feedback}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback submitted successfully! Thank you.")),
        );
        _feedbackController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit feedback: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting feedback: $e")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.06, vertical: height * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AppBar replacement inside gradient
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Feedback",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // to balance back button space
                  ],
                ),
                SizedBox(height: height * 0.04),

                // Loading or Error State
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchFeedback,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                else if (feedbackData != null) ...[
                  // AI Performance Analysis Card
                  _buildPerformanceAnalysisCard(width, height),
                  SizedBox(height: height * 0.03),
                  
                  // AI Motivational Feedback Card
                  _buildMotivationalFeedbackCard(width, height),
                  
                  // Funny Feedback (only for average/below average)
                  if (feedbackData!['funny_feedback'] != null) ...[
                    SizedBox(height: height * 0.03),
                    _buildFunnyFeedbackCard(width, height),
                  ],
                  
                  SizedBox(height: height * 0.03),
                  
                  // Career Path Suggestion Card
                  _buildCareerPathCard(width, height),
                  
                  SizedBox(height: height * 0.03),
                ],

                // User Feedback Input
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: width * 0.04, horizontal: width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    style: const TextStyle(color: Color(0xFF091E3A)),
                    decoration: const InputDecoration(
                      hintText: "Enter your feedback here...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.06),

                // Animated Send Button
                Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : _submitUserFeedback,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(isSubmitting ? "Submitting..." : "Send Feedback"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.1, vertical: height * 0.02),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPerformanceAnalysisCard(double width, double height) {
    final analysis = feedbackData!['performance_analysis'] as Map<String, dynamic>?;
    final score = feedbackData!['quiz_score'] ?? 0;
    final domain = feedbackData!['best_domain'] ?? 'Your Domain';
    
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D9EE0), Color(0xFF2E8FE7)],
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
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "AI Performance Analysis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis?['overall_assessment'] ?? "Analyzing your performance...",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (analysis != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Score", "$score%", Colors.yellowAccent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    "Tasks",
                    "${analysis['task_completion_rate'] ?? 0}%",
                    Colors.greenAccent,
                  ),
                ),
              ],
            ),
            if (analysis['recommendations'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                "Recommendations:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              ...(analysis['recommendations'] as List<dynamic>).map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMotivationalFeedbackCard(double width, double height) {
    final motivational = feedbackData!['motivational_feedback'] ?? '';
    
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D9EE0), Color(0xFF2E8FE7)],
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
          const Row(
            children: [
              Icon(Icons.favorite, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                "AI Motivational Feedback",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            motivational,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFunnyFeedbackCard(double width, double height) {
    final funny = feedbackData!['funny_feedback'] ?? '';
    
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
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
          const Row(
            children: [
              Icon(Icons.celebration, color: Colors.yellow, size: 24),
              SizedBox(width: 8),
              Text(
                "Funny & Motivational",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            funny,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCareerPathCard(double width, double height) {
    final careerPath = feedbackData!['career_path_suggestion'] as Map<String, dynamic>?;
    
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work, color: Color(0xFF2D9EE0), size: 24),
              SizedBox(width: 8),
              Text(
                "Recommended Career Path",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF091E3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (careerPath != null) ...[
            Text(
              careerPath['message'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF091E3A),
                height: 1.4,
              ),
            ),
            if (careerPath['job_roles'] != null && (careerPath['job_roles'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "Job Roles:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF091E3A),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (careerPath['job_roles'] as List<dynamic>).map((role) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D9EE0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2D9EE0).withOpacity(0.3)),
                    ),
                    child: Text(
                      role.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF091E3A),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (careerPath['required_skills'] != null && (careerPath['required_skills'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "Key Skills:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF091E3A),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (careerPath['required_skills'] as List<dynamic>).take(5).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      skill.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF091E3A),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}