import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dream_route/screens/feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class AiTaskChallengeScreen extends StatefulWidget {
  final String? userId;
  
  const AiTaskChallengeScreen({super.key, this.userId});

  @override
  State<AiTaskChallengeScreen> createState() => _AiTaskChallengeScreenState();
}

class _AiTaskChallengeScreenState extends State<AiTaskChallengeScreen> {
  List<Map<String, dynamic>>? tasks;
  bool isLoading = true;
  String? error;
  String? bestDomain;
  List<dynamic>? jobRoles;
  List<dynamic>? requiredSkills;
  List<dynamic>? requiredTools;
  String? userType;
  String? skillLevel;
  Map<String, Timer?> taskTimers = {};
  Map<String, Duration> taskRemainingTime = {};
  Map<String, bool> taskTimeFinished = {};
  Map<String, String?> uploadedFiles = {};
  Map<String, bool> uploadInProgress = {};
  Map<String, String?> aiFeedback = {};
  Map<String, bool> taskStarted = {}; // Track if task timer has been started

  @override
  void initState() {
    super.initState();
    _fetchAITasks();
  }

  @override
  void dispose() {
    // Cancel all timers
    for (var timer in taskTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  Future<void> _fetchAITasks() async {
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
        Uri.parse("http://localhost:8000/ai-tasks/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
          bestDomain = data['best_domain'] as String?;
          jobRoles = data['job_roles'] as List<dynamic>?;
          requiredSkills = data['required_skills'] as List<dynamic>?;
          requiredTools = data['required_tools'] as List<dynamic>?;
          userType = data['user_type'] as String?;
          skillLevel = data['skill_level'] as String?;
          isLoading = false;
        });
        
        // Initialize timers for all tasks
        if (tasks != null && tasks!.isNotEmpty) {
          _initializeTaskTimers();
          // Check if all tasks are already completed
          _checkAllTasksCompleted();
        }
      } else if (response.statusCode == 404) {
        String errorMessage = "No tasks found. Please complete the quiz first.";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (e) {
          // If JSON parsing fails, use default message
        }
        setState(() {
          error = errorMessage;
          isLoading = false;
        });
      } else {
        String errorMessage = "Failed to fetch AI tasks: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (e) {
          // If JSON parsing fails, use default message
          errorMessage = "Server error: ${response.statusCode}\n${response.body}";
        }
        setState(() {
          error = errorMessage;
          isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = "Error connecting to server: $e";
      
      // Check if it's a connection error
      if (e.toString().contains("Failed to fetch") || 
          e.toString().contains("ClientException")) {
        errorMessage = "Cannot connect to backend server.\n\n"
            "Please ensure:\n"
            "1. Backend server is running on http://localhost:8000\n"
            "2. You have completed the quiz first\n"
            "3. Your network connection is working\n\n"
            "Error: $e";
      } else if (e.toString().contains("404")) {
        errorMessage = "No quiz result found. Please complete the quiz first!";
      }
      
      setState(() {
        error = errorMessage;
        isLoading = false;
      });
    }
  }

  void _initializeTaskTimers() {
    if (tasks == null) return;
    
    for (var task in tasks!) {
      final taskId = task['task_id'] as String? ?? '';
      final durationHours = task['duration_hours'] as int? ?? 2;
      final status = task['status'] as String? ?? 'pending';
      
      // Initialize remaining time but DON'T start timer automatically
      Duration remaining = Duration(hours: durationHours);
      taskRemainingTime[taskId] = remaining;
      taskTimeFinished[taskId] = false;
      taskStarted[taskId] = false; // Task not started by default
      
      // Only mark as finished if already completed
      if (status == 'completed') {
        taskTimeFinished[taskId] = true;
        // Don't mark as started if completed - let user see it was completed
      }
    }
  }

  void _startTask(String taskId) {
    if (taskStarted[taskId] == true) return; // Already started
    
    setState(() {
      taskStarted[taskId] = true;
    });
    
    final duration = taskRemainingTime[taskId] ?? Duration(hours: 2);
    _startTaskTimer(taskId, duration);
  }

  void _startTaskTimer(String taskId, Duration duration) {
    // Cancel existing timer if anyc
    taskTimers[taskId]?.cancel();
    
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (taskRemainingTime[taskId] == null || taskRemainingTime[taskId]!.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          taskTimeFinished[taskId] = true;
        });
        _showTimeUpDialog(taskId);
      } else {
        setState(() {
          taskRemainingTime[taskId] = Duration(seconds: taskRemainingTime[taskId]!.inSeconds - 1);
        });
      }
    });
    
    taskTimers[taskId] = timer;
  }

  void _showTimeUpDialog(String taskId) {
    final task = tasks?.firstWhere((t) => t['task_id'] == taskId, orElse: () => {});
    final taskName = task?['task_name'] ?? 'Task';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("⏰ Time's Up!"),
        content: Text(
          "Time has finished for: $taskName\n\nYou can still upload your work for AI feedback!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadTask(String taskId) async {
    if (uploadInProgress[taskId] == true) return;
    
    setState(() {
      uploadInProgress[taskId] = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No authentication token found")),
        );
        setState(() {
          uploadInProgress[taskId] = false;
        });
        return;
      }

      // Pick file - allow custom file types for PDF and DOCX
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          uploadInProgress[taskId] = false;
        });
        return;
      }

      final pickedFile = result.files.single;
      final fileName = pickedFile.name;
      
      // Validate file extension
      final fileExtension = fileName.toLowerCase().split('.').last;
      if (fileExtension != 'pdf' && fileExtension != 'docx') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Only PDF and DOCX files are allowed"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          uploadInProgress[taskId] = false;
        });
        return;
      }

      // Get file bytes - this works on both web and mobile
      Uint8List? fileBytes = pickedFile.bytes;
      
      // If bytes are not available (shouldn't happen, but handle gracefully)
      if (fileBytes == null) {
        // Try to read from path if available (mobile platforms)
        if (pickedFile.path != null) {
          try {
            // For mobile, we can read from path
            final file = await http.MultipartFile.fromPath(
              'file',
              pickedFile.path!,
              filename: fileName,
            );
            
            final request = http.MultipartRequest(
              'POST',
              Uri.parse('http://localhost:8000/ai-tasks/$taskId/upload'),
            );
            
            request.headers['Authorization'] = 'Bearer $token';
            request.files.add(file);
            
            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);
            
            await _handleUploadResponse(response, taskId, fileName, token);
            return;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error reading file: $e"),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              uploadInProgress[taskId] = false;
            });
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to read file. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            uploadInProgress[taskId] = false;
          });
          return;
        }
      }

      // Use bytes directly (works on all platforms including web)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/ai-tasks/$taskId/upload'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      await _handleUploadResponse(response, taskId, fileName, token);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading task: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        uploadInProgress[taskId] = false;
      });
    }
  }

  Future<void> _handleUploadResponse(
    http.Response response,
    String taskId,
    String fileName,
    String token,
  ) async {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        uploadedFiles[taskId] = fileName;
      });
      
      // Stop timer for this task
      taskTimers[taskId]?.cancel();
      
      // Get AI feedback
      await _fetchAIFeedback(taskId);
      
      // Update task status in local state
      setState(() {
        if (tasks != null) {
          for (var task in tasks!) {
            if (task['task_id'] == taskId) {
              task['status'] = 'completed';
              break;
            }
          }
        }
        uploadInProgress[taskId] = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task uploaded successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Check if all tasks are completed
      _checkAllTasksCompleted();
    } else {
      String errorMessage = "Upload failed: ${response.statusCode}";
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['detail'] ?? errorMessage;
      } catch (e) {
        // If JSON parsing fails, use default message
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        uploadInProgress[taskId] = false;
      });
    }
  }

  Future<void> _fetchAIFeedback(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:8000/ai-tasks/$taskId/ai-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiFeedback[taskId] = data['feedback'] ?? '';
        });
        
        // Show feedback dialog
        _showFeedbackDialog(taskId, data['feedback'] ?? '', data['suggestions'] ?? []);
      }
    } catch (e) {
      print("Error fetching AI feedback: $e");
    }
  }

  void _showFeedbackDialog(String taskId, String feedback, List<dynamic> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue),
            SizedBox(width: 8),
            Text("AI Feedback"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feedback,
                style: const TextStyle(fontSize: 14),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Suggestions:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• "),
                      Expanded(child: Text(s.toString())),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _checkAllTasksCompleted() {
    if (tasks == null || tasks!.isEmpty) return;
    
    // Check if all tasks are completed
    bool allCompleted = tasks!.every((task) {
      final status = task['status'] as String? ?? 'pending';
      final uploadedFile = uploadedFiles[task['task_id'] as String? ?? ''];
      return status == 'completed' || uploadedFile != null;
    });
    
    if (allCompleted) {
      // Show completion dialog and navigate to feedback
      _showAllTasksCompletedDialog();
    }
  }
  
  void _showAllTasksCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 32),
            SizedBox(width: 8),
            Text("🎉 Congratulations!"),
          ],
        ),
        content: const Text(
          "Amazing work! You've completed all AI tasks!\n\n"
          "Let's see your personalized feedback and performance analysis.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Stay Here"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D9EE0),
              foregroundColor: Colors.white,
            ),
            child: const Text("View Feedback"),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  double _getProgress(String taskId, int totalHours) {
    final remaining = taskRemainingTime[taskId];
    if (remaining == null || totalHours == 0) return 0.0;
    
    final totalSeconds = totalHours * 3600;
    final elapsedSeconds = totalSeconds - remaining.inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF091E3A),
        centerTitle: true,
        title: const Text(
          "AI Task Challenge",
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
      body: Container(
        width: width,
        height: height,
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
                                    _fetchAITasks();
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
                padding: EdgeInsets.all(width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Domain and Career Path Header
                    if (bestDomain != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: height * 0.02),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.yellowAccent,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "AI Task Challenge",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Based on your recommended career path:",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.work_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Domain: $bestDomain",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (jobRoles != null && jobRoles!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Recommended Roles: ${jobRoles!.join(', ')}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                            if (userType != null || skillLevel != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (userType != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            userType!.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (skillLevel != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getSkillLevelColor(skillLevel!).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getSkillLevelIcon(skillLevel!),
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            skillLevel!.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            if ((requiredSkills != null && requiredSkills!.isNotEmpty) ||
                                (requiredTools != null && requiredTools!.isNotEmpty)) ...[
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (requiredSkills != null && requiredSkills!.isNotEmpty) ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Key Skills:",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: requiredSkills!.take(5).map((skill) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  skill.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (requiredTools != null && requiredTools!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Tools:",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: requiredTools!.take(5).map((tool) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  tool.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (tasks != null && tasks!.isNotEmpty) ...[
                                ...tasks!.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final task = entry.value;
                                  final taskId = task['task_id'] as String? ?? '';
                                  final taskName = task['task_name'] as String? ?? 'Task ${index + 1}';
                                  final durationHours = task['duration_hours'] as int? ?? 2;
                                  final status = task['status'] as String? ?? 'pending';
                                  final guidelines = task['guidelines'] as String? ?? '';
                                  final remaining = taskRemainingTime[taskId] ?? Duration(hours: durationHours);
                                  final timeFinished = taskTimeFinished[taskId] ?? false;
                                  final uploadedFile = uploadedFiles[taskId];
                                  final isUploading = uploadInProgress[taskId] ?? false;
                                  final feedback = aiFeedback[taskId];
                                  final isStarted = taskStarted[taskId] ?? false;
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: height * 0.03),
                                    child: _buildTaskCard(
                                      taskId: taskId,
                                      taskName: taskName,
                                      durationHours: durationHours,
                                      status: status,
                                      guidelines: guidelines,
                                      remainingTime: remaining,
                                      timeFinished: timeFinished,
                                      uploadedFile: uploadedFile,
                                      isUploading: isUploading,
                                      feedback: feedback,
                                      isStarted: isStarted,
                                    ),
                                  );
                                }),
                              ] else if (tasks != null && tasks!.isEmpty) ...[
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "No tasks available. Complete the quiz first!",
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                    SizedBox(height: height * 0.15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String taskId,
    required String taskName,
    required int durationHours,
    required String status,
    required String guidelines,
    required Duration remainingTime,
    required bool timeFinished,
    required String? uploadedFile,
    required bool isUploading,
    required String? feedback,
    required bool isStarted,
  }) {
    final progress = _getProgress(taskId, durationHours);
    final isCompleted = status == 'completed' || uploadedFile != null;
    final showStartButton = !isStarted && !isCompleted;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted 
              ? [Colors.green.shade300, Colors.green.shade600]
              : timeFinished
                  ? [Colors.orange.shade300, Colors.orange.shade600]
                  : [Colors.blue.shade300, Colors.blue.shade600],
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
              Expanded(
                child: Text(
                  taskName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          
          // Progress bar (only show if task is started)
          if (isStarted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  color: Colors.yellowAccent,
                  backgroundColor: Colors.white24,
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeFinished ? "Time Finished!" : _formatDuration(remainingTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // Show placeholder when not started
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Ready to start - Click 'Start Task' button below",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Task details
          _TaskRow(label: "Duration", value: "$durationHours hours"),
          _TaskRow(label: "Status", value: isCompleted 
              ? "Completed" 
              : (isStarted 
                  ? (timeFinished ? "Time Up" : "In Progress") 
                  : "Ready to Start")),
          
          // Show remaining time even when not started
          if (!isStarted)
            _TaskRow(label: "Time Remaining", value: _formatDuration(Duration(hours: durationHours))),
          
          if (guidelines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Instructions:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guidelines,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Start button (show before task is started)
          if (showStartButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startTask(taskId),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Task"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          // Upload button (show after task is started)
          if (!isCompleted && isStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : () => _uploadTask(taskId),
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isUploading ? "Uploading..." : "Upload Task"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          // Uploaded file info
          if (uploadedFile != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Uploaded: $uploadedFile",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // AI Feedback
          if (feedback != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showFeedbackDialog(taskId, feedback, []),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white54),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.yellowAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "AI Feedback Available - Tap to View",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSkillLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'beginner':
      default:
        return Colors.blue;
    }
  }

  IconData _getSkillLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Icons.trending_up;
      case 'medium':
        return Icons.trending_flat;
      case 'beginner':
      default:
        return Icons.trending_down;
    }
  }
}

class _TaskRow extends StatelessWidget {
  final String label;
  final String value;

  const _TaskRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
