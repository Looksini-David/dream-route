import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FresherQuizSummary extends StatefulWidget {
  final String userId;

  const FresherQuizSummary({super.key, required this.userId});

  @override
  State<FresherQuizSummary> createState() => _FresherQuizSummaryState();
}

class _FresherQuizSummaryState extends State<FresherQuizSummary> {
  Map<String, dynamic>? quizData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchQuizResult();
  }

  Future<void> _fetchQuizResult() async {
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

      // If userId is empty, fetch it from profile
      String userId = widget.userId;
      if (userId.isEmpty) {
        try {
          final profileResponse = await http.get(
            Uri.parse("http://localhost:8000/fresher/profile/"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          );
          
          if (profileResponse.statusCode == 200) {
            final profileData = jsonDecode(profileResponse.body);
            userId = profileData['user_id']?.toString() ?? '';
            if (userId.isEmpty) {
              setState(() {
                error = "Could not find user ID in profile";
                isLoading = false;
              });
              return;
            }
          } else {
            setState(() {
              error = "Failed to fetch profile: ${profileResponse.statusCode}";
              isLoading = false;
            });
            return;
          }
        } catch (e) {
          setState(() {
            error = "Error fetching profile: $e";
            isLoading = false;
          });
          return;
        }
      }

      final response = await http.get(
        Uri.parse("http://localhost:8000/quiz-result/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          quizData = jsonDecode(response.body);
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          error = "No quiz result found. Please complete the quiz first.";
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch quiz result: ${response.statusCode}\n${response.body}";
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
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF091E3A), Color(0xFF2D9EE0), Color(0xFF2E8FE7)],
            stops: [0.0, 0.4, 0.8],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : error != null
                      ? Center(child: Text(error!, style: const TextStyle(color: Colors.white)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (quizData != null) ...[
                                _buildScoreCard(quizData!),
                                const SizedBox(height: 20),
                                _buildBestDomainCard(quizData!),
                                const SizedBox(height: 20),
                                _buildRolesList(quizData!),
                                const SizedBox(height: 20),
                                _buildDomainScores(quizData!),
                              ],
                            ],
                          ),
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
                  "Quiz Summary",
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
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Your Score",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            "${data['score'] ?? 0}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDomainCard(Map<String, dynamic> data) {
    final bestDomain = data['best_domain'] ?? '';
    final bestDomainDetails = data['best_domain_details'] ?? {};
    final description = bestDomainDetails['description'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Best Domain",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            bestDomain,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDomainScores(Map<String, dynamic> data) {
    final domains = data['domains'] ?? [];
    
    if (domains.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort domains by score (highest first)
    final sortedDomains = List<Map<String, dynamic>>.from(domains);
    sortedDomains.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Domain Scores",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...sortedDomains.asMap().entries.map((entry) {
          final index = entry.key;
          final domain = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: (domain['score'] ?? 0) / 100.0),
            duration: Duration(milliseconds: 800 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return _buildDomainScoreCard(domain, value);
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDomainScoreCard(Map<String, dynamic> domain, double progressValue) {
    final domainName = domain['domain'] ?? '';
    final score = domain['score'] ?? 0.0;
    final level = domain['level'] ?? 'beginner';
    
    Color getProgressColor() {
      switch (level) {
        case 'high':
          return Colors.green;
        case 'medium':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    domainName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  "${score.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(getProgressColor()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesList(Map<String, dynamic> data) {
    final bestDomainDetails = data['best_domain_details'] ?? {};
    final titles = bestDomainDetails['titles'] ?? [];

    if (titles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommended Roles",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...titles.map((title) {
          return _buildRoleCard({"title": title, "desc": ""});
        }).toList(),
      ],
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role["title"] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              role["desc"] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
