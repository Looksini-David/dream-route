import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? position;
  bool termsAccepted = false;
  bool isLoading = false;
  String? selectedResumeName;
  PlatformFile? pickedFile;
  Uint8List? pickedBytes;

  // Password visibility toggles
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  // final TextEditingController firstNameController = TextEditingController();
  // final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController regPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController eduLevelController = TextEditingController();

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;
      pickedFile = file;
      pickedBytes = file.bytes;

      setState(() {
        selectedResumeName = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
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

  Future<void> _handleRegister() async {
    if (!_validateRegisterForm()) return;

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
      final url = "http://localhost:8000/register";
      print("Attempting registration to: $url");
      final uri = Uri.parse(url);
      final request = http.MultipartRequest("POST", uri);

      // request.fields["name"] = "${firstNameController.text} ${lastNameController.text}";
      request.fields["name"] = usernameController.text;
      request.fields["email"] = emailController.text;
      request.fields["password"] = regPasswordController.text;
      request.fields["role"] = position!.toLowerCase();
      request.fields["qualification"] = position == "student"
          ? schoolController.text
          : eduLevelController.text;
      request.fields["location"] = "";

      if (position == "fresher" && pickedFile != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              "resume",
              pickedBytes!,
              filename: pickedFile!.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath("resume", pickedFile!.path!),
          );
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      
      print("Registration response status: ${response.statusCode}");
      print("Registration response body: $responseBody");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("role", position!);
        await prefs.setBool("first_login", true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Please login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        if (!mounted) return;
        // Parse error message for better user feedback
        String errorMessage = "Registration failed";
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else {
            errorMessage = responseBody;
          }
        } catch (e) {
          errorMessage = responseBody.isNotEmpty 
              ? responseBody 
              : "Server returned status ${response.statusCode}";
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network/Connection Error: $e\nPlease ensure the backend server is running on http://localhost:8000"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _validateRegisterForm() {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        regPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        position == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return false;
    }
    if (regPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return false;
    }
    if (regPasswordController.text.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 12 characters"),
        ),
      );
      return false;
    }
    if (position == "student" && schoolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School/College name required")),
      );
      return false;
    }
    if (position == "fresher" && eduLevelController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Education level required")));
      return false;
    }
    if (position == "fresher" && pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your resume")),
      );
      return false;
    }
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept terms & conditions")),
      );
      return false;
    }
    return true;
  }

  Widget _buildTextField(
    String label, {
    bool obscure = false,
    TextEditingController? controller,
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
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // New: Password field with eye icon
  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isConfirm,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: isConfirm ? !confirmPasswordVisible : !passwordVisible,
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
          suffixIcon: IconButton(
            icon: Icon(
              (isConfirm ? confirmPasswordVisible : passwordVisible)
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  confirmPasswordVisible = !confirmPasswordVisible;
                } else {
                  passwordVisible = !passwordVisible;
                }
              });
            },
          ),
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
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
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
            padding: const EdgeInsets.only(top: 20, bottom: 30),
            child: Column(
              children: [
                Text(
                  "REGISTER",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'assets/login.png',
                  height: 220,
                  width: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 5),
                _buildTextField("USERNAME", controller: usernameController),
                const SizedBox(height: 15),
                // _buildTextField("FIRST NAME / USERNAME", controller: firstNameController),
                // const SizedBox(height: 15),
                // _buildTextField("LAST NAME", controller: lastNameController),
                // const SizedBox(height: 15),
                _buildTextField("EMAIL", controller: emailController),
                const SizedBox(height: 15),
                _buildPasswordField("PASSWORD", regPasswordController, false),
                const SizedBox(height: 15),
                _buildPasswordField(
                  "CONFIRM PASSWORD",
                  confirmPasswordController,
                  true,
                ),
                const SizedBox(height: 20),

                // Position Dropdown
                FractionallySizedBox(
                  widthFactor: 0.93,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: position,
                      dropdownColor: const Color(0xFF2D9EE0),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      hint: const Text(
                        "SELECT YOUR POSITION",
                        style: TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: "student",
                          child: Text("Student"),
                        ),
                        DropdownMenuItem(
                          value: "fresher",
                          child: Text("Fresher / Job Seeker"),
                        ),
                      ],
                      onChanged: (val) => setState(() => position = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Conditional fields
                if (position == "student")
                  _buildTextField(
                    "SCHOOL / COLLEGE NAME",
                    controller: schoolController,
                  ),
                if (position == "fresher") ...[
                  _buildTextField(
                    "EDUCATION LEVEL",
                    controller: eduLevelController,
                  ),
                  const SizedBox(height: 15),
                  FractionallySizedBox(
                    widthFactor: 0.93,
                    child: ElevatedButton.icon(
                      onPressed: _pickResume,
                      icon: Icon(
                        Icons.upload_file,
                        color: pickedFile != null ? Colors.green : Colors.blue,
                      ),
                      label: Text(
                        pickedFile != null ? "Change Resume" : "Upload Resume",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  if (selectedResumeName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Selected: $selectedResumeName",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 20),
                // TERMS & CONDITIONS
                Row(
                  children: [
                    Checkbox(
                      value: termsAccepted,
                      onChanged: (val) =>
                          setState(() => termsAccepted = val ?? false),
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(MaterialState.selected))
                          return Colors.blue;
                        return Colors.white24;
                      }),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => termsAccepted = !termsAccepted),
                        child: const Text(
                          "I accept terms & conditions",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _buildButton(
                  "REGISTER",
                  enabled: termsAccepted && !isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
