import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:dream_route/screens/aitask.dart';
//import 'package:dream_route/screens/feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RoadMapTimelineScreen extends StatefulWidget {
  final String? userId;
  
  const RoadMapTimelineScreen({super.key, this.userId});

  @override
  State<RoadMapTimelineScreen> createState() => _RoadMapTimelineScreenState();
}

class _RoadMapTimelineScreenState extends State<RoadMapTimelineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  Map<String, dynamic>? roadmapData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward();
    _fetchRoadmapData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchRoadmapData() async {
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
        Uri.parse("http://localhost:8000/roadmap/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          roadmapData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          error = errorData['detail'] ?? "Failed to fetch roadmap data: ${response.statusCode}";
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF091E3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091E3A),
        centerTitle: true,
        title: const Text(
          "Road Map Timeline",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  error!,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      isLoading = true;
                                      error = null;
                                    });
                                    _fetchRoadmapData();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Retry"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                              width * 0.06, height * 0.04, width * 0.06, height * 0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (roadmapData != null) ...[
                                _buildSectionHeader("Learning Process"),
                                SizedBox(height: height * 0.02),

                                // Level I: Status, Covered Areas, Areas to Improve
                                if (roadmapData!['levels']?['level_i'] != null)
                                  _buildLevelICard(roadmapData!['levels']['level_i'], height),

                                SizedBox(height: height * 0.02),

                                // Level II: Task Progress
                                if (roadmapData!['levels']?['level_ii'] != null)
                                  _buildLevelIICard(roadmapData!['levels']['level_ii'], height),

                                SizedBox(height: height * 0.02),

                                // Level III: Job Opportunities
                                if (roadmapData!['levels']?['level_iii'] != null)
                                  _buildLevelIIICard(roadmapData!['levels']['level_iii'], height),

                                SizedBox(height: height * 0.12),
                              ] else ...[
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "No roadmap data available. Complete the quiz first!",
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLevelICard(Map<String, dynamic> levelData, double height) {
    final status = levelData['status'] ?? 'pending';
    final userStatus = levelData['user_status'] ?? 'Getting Started';
    final coveredAreas = levelData['covered_areas'] as List<dynamic>? ?? [];
    final areasToImprove = levelData['areas_to_improve'] as List<dynamic>? ?? [];
    final progress = levelData['progress'] ?? 0.0;

    Color getStatusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'in_progress':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getStatusColor().withOpacity(0.7), getStatusColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Level I: Fundamentals & Assessment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white70),
            const SizedBox(height: 8),
            
            // Status
            _buildTimelineItem(Icons.person, "Your Status", userStatus),
            
            // Progress Bar
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Overall Progress:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${progress.toInt()}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              color: Colors.yellowAccent,
              backgroundColor: Colors.white24,
              minHeight: 8,
              borderRadius: BorderRadius.circular(5),
            ),
            
            const SizedBox(height: 16),
            
            // Covered Areas
            if (coveredAreas.isNotEmpty) ...[
              const Text(
                "Covered Areas:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...coveredAreas.map((area) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${area['domain']} (${area['score']}% - ${area['level']})",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            
            const SizedBox(height: 16),
            
            // Areas to Improve
            if (areasToImprove.isNotEmpty) ...[
              const Text(
                "Areas to Learn/Improve:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...areasToImprove.map((area) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.school, size: 18, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${area['domain']} (${area['score']}% - needs improvement)",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIICard(Map<String, dynamic> levelData, double height) {
    final status = levelData['status'] ?? 'pending';
    final totalTasks = levelData['total_tasks'] ?? 0;
    final completedTasks = levelData['completed_tasks'] ?? 0;
    final pendingTasks = levelData['pending_tasks'] ?? 0;
    final inProgressTasks = levelData['in_progress_tasks'] ?? 0;
    final taskProgress = levelData['task_progress_percentage'] ?? 0.0;
    final taskDetails = levelData['task_details'] as List<dynamic>? ?? [];

    Color getStatusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'in_progress':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getStatusColor().withOpacity(0.7), getStatusColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Level II: Task Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white70),
            const SizedBox(height: 8),
            
            // Task Statistics
            _buildTimelineItem(Icons.check_circle, "Completed Tasks", "$completedTasks / $totalTasks"),
            if (pendingTasks > 0)
              _buildTimelineItem(Icons.hourglass_empty, "Pending Tasks", "$pendingTasks"),
            if (inProgressTasks > 0)
              _buildTimelineItem(Icons.play_circle_fill, "In Progress", "$inProgressTasks"),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Task Progress:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${taskProgress.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: taskProgress / 100,
              color: Colors.yellowAccent,
              backgroundColor: Colors.white24,
              minHeight: 8,
              borderRadius: BorderRadius.circular(5),
            ),
            
            // Task Details
            if (taskDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Task Details:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...taskDetails.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            task['status'] == 'completed'
                                ? Icons.check_circle
                                : task['status'] == 'in_progress'
                                    ? Icons.play_circle
                                    : Icons.pending,
                            size: 18,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['task_name'] ?? 'Task',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Status: ${task['status'] ?? 'pending'}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIIICard(Map<String, dynamic> levelData, double height) {
    final status = levelData['status'] ?? 'locked';
    final jobOpportunities = levelData['job_opportunities'] as List<dynamic>? ?? [];
    final message = levelData['message'] ?? '';

    Color getStatusColor() {
      if (status == 'locked') {
        return Colors.grey;
      }
      return Colors.blue;
    }

    final isLocked = status == 'locked';

    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [getStatusColor().withOpacity(0.7), getStatusColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.work,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Level III: Job Opportunities",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white70),
            const SizedBox(height: 8),
            
            if (isLocked) ...[
              Icon(Icons.lock_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              if (message.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.yellowAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (jobOpportunities.isNotEmpty) ...[
                const Text(
                  "Global Opportunities:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...jobOpportunities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final job = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < jobOpportunities.length - 1 ? 12 : 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                job['type'] == 'Intern' ? Icons.school : Icons.work_outline,
                                color: Colors.yellowAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  job['position'] ?? 'Position',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildJobDetail(Icons.business, "Company", job['company'] ?? 'Various Companies'),
                          _buildJobDetail(Icons.location_on, "Location", job['location'] ?? 'Global'),
                          _buildJobDetail(Icons.label, "Type", job['type'] ?? 'Intern/Trainee'),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                const Text(
                  "No job opportunities available yet.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
