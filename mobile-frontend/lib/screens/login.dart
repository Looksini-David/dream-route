import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_start.dart';
import 'stu_dashboard.dart';
import 'fresher_dashboard.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // Toggle for password visibility
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Removed auto-redirect - let users see the login page when they navigate to /login
    // Auto-redirect should only happen from splash screen, not when explicitly navigating to login
  }

  Future<bool> _checkQuizCompletion(String token, String role) async {
    try {
      // First, get user ID from profile
      String userId = '';
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
        return false;
      }

      if (userId.isEmpty) {
        return false;
      }

      // Check if quiz result exists
      final quizResultResponse = await http.get(
        Uri.parse("http://localhost:8000/quiz-result/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // If quiz result exists (200), user has completed quiz
      // If 404, user hasn't completed quiz
      return quizResultResponse.statusCode == 200;
    } catch (e) {
      // If there's an error, assume quiz not completed
      print("Error checking quiz completion: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF091E3A), Color(0xFF2D9EE0), Color(0xFF2E8FE7)],
            stops: [0.0, 0.4, 0.8],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            child: Column(
              children: [
                Text(
                  "LOGIN",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/login.png',
                  height: 280,
                  width: 280,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),

                // EMAIL FIELD
                _buildTextField("EMAIL ADDRESS", controller: emailController),

                const SizedBox(height: 15),

                // PASSWORD FIELD with eye icon toggle
                _buildTextField(
                  "PASSWORD",
                  controller: passwordController,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _buildButton("LOGIN", onPressed: _handleLogin),

                const SizedBox(height: 15),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text(
                    "Create New Account",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkBackendConnection() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/health"),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      print("Backend connection check failed: $e");
      return false;
    }
  }

  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email address and password"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // Check if backend is running
    final backendAvailable = await _checkBackendConnection();
    if (!backendAvailable) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Backend server is not running!\n\nPlease start the backend server:\n1. Open terminal\n2. cd backend\n3. py -m uvicorn main:app --reload --host localhost --port 8000"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    try {
      final url = "http://localhost:8000/login";
      print("Attempting login to: $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final role = data['role'];
        final token = data['access_token'] ?? "";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("role", role);
        await prefs.setString("token", token);

        // Check if user has completed quiz by checking backend
        bool hasCompletedQuiz = await _checkQuizCompletion(token, role);

        if ((role == "student" || role == "fresher") && !hasCompletedQuiz) {
          // User hasn't completed quiz, show quiz screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => QuizTimeScreen(
                userType: role,
                domain: "default",
                selectedSkills: [],
                token: token,
              ),
            ),
          );
        } else {
          // User has completed quiz or is not student/fresher, show dashboard
          if (role == "student") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StuDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FresDashboard()),
            );
          }
        }
      } else {
        // Parse error message for better user feedback
        String errorMessage = "Login failed";
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else {
            errorMessage = response.body.isNotEmpty 
                ? response.body 
                : "Server returned status ${response.statusCode}";
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : "Server returned status ${response.statusCode}. Please check if backend is running.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network/Connection Error: $e\nPlease ensure the backend server is running on http://localhost:8000"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController forgotEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: forgotEmailController,
          decoration: const InputDecoration(hintText: "Enter your email"),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                if (forgotEmailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email is required")),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reset link sent to email")),
                  );
                }
              },
              child: const Text("Reset"),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: add optional suffixIcon for eye toggle
  Widget _buildTextField(
    String label, {
    bool obscure = false,
    TextEditingController? controller,
    Widget? suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
          filled: true,
          fillColor: Colors.white24,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildButton(
    String text, {
    bool enabled = true,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.white : Colors.white24,
          foregroundColor: enabled ? Colors.blue : Colors.white54,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}