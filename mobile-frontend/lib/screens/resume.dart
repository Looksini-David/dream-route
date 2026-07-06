import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  const ResumeAnalysisScreen({super.key});

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool isLoading = true;
  List<_PieData> chartData = [];
  List<String> tips = [];
  String? aiFeedback;
  List<String> matchedSkills = [];
  List<String> missingSkills = [];
  String? errorMessage;
  String? uploadedFileName;
  double atsScore = 0.0;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack);

    _loadResumeAnalysis();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadResumeAnalysis() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getResumeResult();
      
      // Check if analysis is pending
      if (data.containsKey('status') && data['status'] == 'pending') {
        setState(() {
          isLoading = false;
          final pendingMessage = data['message'] ?? "Resume uploaded, analysis in progress...";
          errorMessage = pendingMessage;
          atsScore = 0.0;
          chartData = [
            _PieData("Matched Skills", 0, const Color(0xFF4CAF50)),
            _PieData("Missing Skills", 100, const Color(0xFFF44336)),
          ];
          tips = [
            "Your resume has been uploaded and is being analyzed.",
            "Please wait a few moments and refresh to see your analysis results.",
            "The analysis will show your ATS compatibility score and skill matching.",
            if (pendingMessage.contains("quiz"))
              "Complete the quiz first to enable resume analysis."
            else
              "Click the refresh button above to check for updated results."
          ];
          matchedSkills = [];
          missingSkills = [];
        });
        return;
      }

      // Check if no resume found
      if (data.containsKey('status') && data['status'] == 'not_found') {
        // Check if user has resume in users table by checking profile
        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString("role");
        if (role != null) {
          final profile = await ApiService.getUserProfile(role);
          if (profile != null && profile['resume_url'] != null) {
            // User has resume in users table but no ResumeRules
            // Backend should create it, but let's show a helpful message
            setState(() {
              isLoading = false;
              errorMessage = "Resume found but analysis not initialized. Please refresh in a moment.";
              atsScore = 0.0;
              chartData = [
                _PieData("Matched Skills", 0, const Color(0xFF4CAF50)),
                _PieData("Missing Skills", 100, const Color(0xFFF44336)),
              ];
              tips = [
                "Your resume was uploaded during registration.",
                "The analysis is being initialized. Please refresh in a few moments.",
                "If the issue persists, try uploading your resume again."
              ];
              matchedSkills = [];
              missingSkills = [];
            });
            return;
          }
        }
        throw Exception("No resume found");
      }

      if (data.isEmpty) {
        throw Exception("No analysis data available");
      }

      // Handle both list and string formats for matched/missing skills
      List<String> matchedList = [];
      List<String> missingList = [];
      
      if (data.containsKey('matched_skills')) {
        if (data['matched_skills'] is List) {
          matchedList = (data['matched_skills'] as List).map((s) => s.toString()).where((s) => s.isNotEmpty).toList();
        } else if (data['matched_skills'] is String) {
          final matchedStr = data['matched_skills'] as String;
          matchedList = matchedStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }
      
      if (data.containsKey('missing_skills')) {
        if (data['missing_skills'] is List) {
          missingList = (data['missing_skills'] as List).map((s) => s.toString()).where((s) => s.isNotEmpty).toList();
        } else if (data['missing_skills'] is String) {
          final missingStr = data['missing_skills'] as String;
          missingList = missingStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      }

      final matched = matchedList.length;
      final missing = missingList.length;
      final total = matched + missing;
      
      // Use score from API if available, otherwise calculate from skills
      final apiScore = data['score'] != null ? (data['score'] as num).toDouble() : null;
      final calculatedScore = total > 0 ? (matched / total * 100) : 0.0;

      setState(() {
        matchedSkills = matchedList;
        missingSkills = missingList;
        atsScore = apiScore ?? calculatedScore;
        
        chartData = [
          _PieData("Matched Skills", atsScore, const Color(0xFF4CAF50)),
          _PieData("Missing Skills", 100 - atsScore, const Color(0xFFF44336)),
        ];

        aiFeedback = data['ai_feedback'] as String?;
        tips = List<String>.from(data['tips'] ?? []);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      print("Error loading resume analysis: $e");
      setState(() {
        isLoading = false;
        final errorMsg = e.toString();
        
        // Check for connection errors
        if (errorMsg.contains("Failed to fetch") || 
            errorMsg.contains("ClientException") ||
            errorMsg.contains("SocketException") ||
            errorMsg.contains("Connection refused")) {
          errorMessage = "Cannot connect to backend server.\n\n"
              "Please ensure:\n"
              "1. Backend server is running on http://localhost:8000\n"
              "2. You have completed the quiz first\n"
              "3. Your network connection is working\n\n"
              "Error: ${errorMsg.contains('uri=') ? errorMsg.split('uri=').last : errorMsg}";
          tips = [
            "Make sure the backend server is running on port 8000",
            "Check your internet connection",
            "Try refreshing the page or restarting the backend server",
            "If the issue persists, contact support"
          ];
        } else if (errorMsg.contains("No resume found") || errorMsg.contains("not found")) {
          errorMessage = "No resume found. Please upload your resume to get started with analysis.";
          tips = [
            "Upload your resume through the upload button below to get started with resume analysis.",
            "The analysis will show your ATS compatibility score and skill matching.",
            "Make sure you have completed the quiz first for accurate analysis."
          ];
        } else if (errorMsg.contains("No analysis data")) {
          errorMessage = "Resume found but analysis data is incomplete. Please try uploading your resume again.";
          tips = [
            "Try uploading your resume again",
            "Make sure your resume is in PDF, DOC, or DOCX format",
            "Ensure you have completed the quiz first"
          ];
        } else {
          errorMessage = "Unable to load resume analysis.\n\n${errorMsg.replaceAll('Exception: ', '').replaceAll('ClientException: ', '')}";
          tips = [
            "Try refreshing the page",
            "Check if the backend server is running",
            "Make sure you have completed the quiz first",
            "If the issue persists, try uploading your resume again"
          ];
        }
        
        atsScore = 0.0;
        chartData = [
          _PieData("Matched Skills", 0, const Color(0xFF4CAF50)),
          _PieData("Missing Skills", 100, const Color(0xFFF44336)),
        ];
        matchedSkills = [];
        missingSkills = [];
        aiFeedback = null;
      });
    }
  }

  Future<void> _uploadResume() async {
    if (isUploading) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        isUploading = true;
        uploadedFileName = result.files.single.name;
        isLoading = true;
      });

      try {
        final fileBytes = result.files.single.bytes!;
        final ruleId = await ApiService.uploadResume(fileBytes, uploadedFileName!);
        await ApiService.analyzeResume(ruleId);
        
        // Wait a bit for analysis to complete, then reload
        await Future.delayed(const Duration(seconds: 2));
        await _loadResumeAnalysis();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Resume uploaded and analyzed successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
          isUploading = false;
          errorMessage = "Upload failed. Please try again.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    } else {
      setState(() {
        isUploading = false;
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
            stops: [0.0, 0.5, 1.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Analyzing your resume...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : errorMessage != null
                  ? SingleChildScrollView(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Section
                          _buildHeaderSection(),
                          const SizedBox(height: 24),
                          
                          // Error Message Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF2D9EE0),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF091E3A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                if (tips.isNotEmpty) ...[
                                  const Text(
                                    "Tips:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF091E3A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...tips.map((tip) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Color(0xFF2D9EE0),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Section
                          _buildHeaderSection(),
                          const SizedBox(height: 24),
                          
                          // ATS Score Card
                          _buildATSScoreCard(),
                          const SizedBox(height: 24),
                          
                          // Pie Chart
                          _buildPieChartSection(height),
                          const SizedBox(height: 24),
                          
                          // Skills Analysis
                          _buildSkillsAnalysisSection(),
                          const SizedBox(height: 24),
                          
                          // AI Feedback
                          _buildAIFeedbackSection(),
                        ],
                      ),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isUploading ? null : _uploadResume,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF091E3A),
        icon: isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF091E3A),
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(
          isUploading ? "Uploading..." : "Upload Resume",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const Text(
                  "Resume Analysis",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _loadResumeAnalysis,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Get instant feedback on your resume's ATS compatibility",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        if (uploadedFileName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    uploadedFileName!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildATSScoreCard() {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              "Overall ATS Matching Score",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF091E3A),
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: atsScore / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      atsScore >= 70
                          ? const Color(0xFF4CAF50)
                          : atsScore >= 40
                              ? const Color(0xFFFF9800)
                              : const Color(0xFFF44336),
                    ),
                  ),
                ),
                Text(
                  "${atsScore.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF091E3A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              atsScore >= 70
                  ? "Excellent! Your resume is well-optimized for ATS."
                  : atsScore >= 40
                      ? "Good start! Consider adding more relevant skills."
                      : "Needs improvement. Focus on adding missing skills.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection(double height) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        height: height * 0.35,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              "Skills Distribution",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF091E3A),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: const TextStyle(
                    color: Color(0xFF091E3A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                series: <CircularSeries>[
                  PieSeries<_PieData, String>(
                    dataSource: chartData,
                    xValueMapper: (_PieData data, _) => data.skill,
                    yValueMapper: (_PieData data, _) => data.score,
                    pointColorMapper: (_PieData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    explode: true,
                    explodeIndex: 0,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsAnalysisSection() {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Skills Analysis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF091E3A),
              ),
            ),
            const SizedBox(height: 16),
            
            // Matched Skills
            _buildSkillList("Matched Skills", matchedSkills, const Color(0xFF4CAF50)),
            const SizedBox(height: 20),
            
            // Missing Skills
            _buildSkillList("Missing Skills", missingSkills, const Color(0xFFF44336)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillList(String title, List<String> skills, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                skills.length.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: color.withOpacity(0.1),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 12),
        skills.isEmpty
            ? Text(
                "No ${title.toLowerCase()} found",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Chip(
                          label: Text(
                            skill,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: color.withOpacity(0.1),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildAIFeedbackSection() {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF091E3A)),
                SizedBox(width: 8),
                Text(
                  "AI Feedback & Tips",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF091E3A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AI Feedback
            if (aiFeedback != null && aiFeedback!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9EE0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2D9EE0).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF2D9EE0),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        aiFeedback!,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Tips
            if (tips.isNotEmpty) ...[
              const Text(
                "Actionable Tips:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF091E3A),
                ),
              ),
              const SizedBox(height: 12),
              ...tips.asMap().entries.map((entry) {
                final index = entry.key;
                final tip = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D9EE0),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const Text(
                "No tips available. Upload your resume to get personalized feedback.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PieData {
  final String skill;
  final double score;
  final Color color;
  _PieData(this.skill, this.score, this.color);
}

// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'api_service.dart';

// class ResumeAnalysisScreen extends StatefulWidget {
//   const ResumeAnalysisScreen({super.key});

//   @override
//   State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
// }

// class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   bool isLoading = true;
//   List<_PieData> chartData = [];
//   List<String> tips = [];
//   String? errorMessage;
//   String? uploadedFileName;

//   double communication = 0;
//   double technical = 0;
//   double leadership = 0;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     )..forward();
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack);

//     _loadResumeAnalysis();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _loadResumeAnalysis() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       final data = await ApiService.getResumeResult(); // fetches backend result
//       chartData = [
//           _PieData("Matched", data['matched_skills'].length.toDouble(), Colors.green),
//           _PieData("Missing", data['missing_skills'].length.toDouble(), Colors.redAccent),
//       ];
//       if (data.isEmpty) {
//         throw Exception("No analysis");
//       }

//       final matchedList = (data['matched_skills'] as List? ?? []).map((s) => s.toString().toLowerCase()).toList();
//       final missingList = (data['missing_skills'] as List? ?? []).map((s) => s.toString().toLowerCase()).toList();

//       final matched = matchedList.length;
//       final missing = missingList.length;
//       final total = matched + missing;

//       setState(() {
//         chartData = [
//           _PieData("Matched Skills", total > 0 ? (matched / total * 100) : 0, Colors.green),
//           _PieData("Missing Skills", total > 0 ? (missing / total * 100) : 0, Colors.redAccent),
//         ];

//         tips = List<String>.from(data['tips'] ?? []);

//         communication = matchedList.any((s) => s.contains("communication")) ? 1.0 : 0.4;
//         technical = matchedList.any((s) => s.contains("technical") || s.contains("python") || s.contains("java")) ? 1.0 : 0.5;
//         leadership = matchedList.any((s) => s.contains("leadership")) ? 1.0 : 0.3;

//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = "No analysis found";
//         chartData = [
//           _PieData("Matched Skills", 0, Colors.green),
//           _PieData("Missing Skills", 100, Colors.redAccent),
//         ];
//         tips = [errorMessage!];
//         communication = 0.0;
//         technical = 0.0;
//         leadership = 0.0;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMessage!)),
//       );
//     }
//   }

//   Future<void> _uploadResume() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//     );

//     if (result != null && result.files.single.bytes != null) {
//       setState(() {
//         isLoading = true;
//         uploadedFileName = result.files.single.name;
//       });

//       try {
//         final fileBytes = result.files.single.bytes!;
//         final ruleId = await ApiService.uploadResume(fileBytes, uploadedFileName!);
//         await ApiService.analyzeResume(ruleId);
//         await _loadResumeAnalysis();

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Resume uploaded and analyzed successfully!")),
//         );
//       } catch (e) {
//         setState(() {
//           isLoading = false;
//           errorMessage = "Upload or analysis failed. Try again.";
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage!)),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final height = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: const Color(0xFF091E3A),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF091E3A),
//         centerTitle: true,
//         title: const Text(
//           "Resume Analysis",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _uploadResume,
//         child: const Icon(Icons.upload_file),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: EdgeInsets.all(width * 0.06),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   if (uploadedFileName != null)
//                     Text(
//                       "Uploaded: $uploadedFileName",
//                       style: const TextStyle(color: Colors.white70),
//                     ),
//                   const SizedBox(height: 10),
//                   ScaleTransition(
//                     scale: _animation,
//                     child: Container(
//                       height: height * 0.35,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF2D9EE0), Color(0xFF2E8FE7)],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: SfCircularChart(
//                         legend: Legend(
//                           isVisible: true,
//                           textStyle: const TextStyle(color: Colors.white),
//                         ),
//                         series: <CircularSeries>[
//                           PieSeries<_PieData, String>(
//                             dataSource: chartData,
//                             xValueMapper: (_PieData data, _) => data.skill,
//                             yValueMapper: (_PieData data, _) => data.score,
//                             pointColorMapper: (_PieData data, _) => data.color,
//                             dataLabelSettings: const DataLabelSettings(
//                               isVisible: true,
//                               textStyle: TextStyle(color: Colors.white),
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ScaleTransition(
//                     scale: _animation,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: tips
//                           .map((t) => Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 4.0),
//                                 child: Text(
//                                   t,
//                                   style: const TextStyle(color: Colors.white, fontSize: 14),
//                                 ),
//                               ))
//                           .toList(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   _buildSkillProgress("Communication", communication),
//                   const SizedBox(height: 12),
//                   _buildSkillProgress("Technical Skills", technical),
//                   const SizedBox(height: 12),
//                   _buildSkillProgress("Leadership", leadership),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildSkillProgress(String skill, double value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           skill,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 4),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: LinearProgressIndicator(
//             value: value,
//             minHeight: 12,
//             backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
//             valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _PieData {
//   final String skill;
//   final double score;
//   final Color color;
//   _PieData(this.skill, this.score, this.color);
// }
