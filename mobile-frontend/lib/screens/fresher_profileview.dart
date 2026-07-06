import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class FresherProfile extends StatefulWidget {
  const FresherProfile({super.key});

  @override
  State<FresherProfile> createState() => _FresherProfileState();
}

class _FresherProfileState extends State<FresherProfile> {
  // User fields
  String name = "";
  String email = "";
  String password = "";
  String qualification = "";
  String location = "";
  String joinDate = "";
  String resumeUrl = "";
  List<String> skills = [];
  bool loading = true;

  Uint8List? profileImage;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final token = await ApiService.getToken();
      // Debug: print token presence (don't log tokens in production)
      debugPrint('fetchProfile: token present=${token != null}');
      final data = await ApiService.getUserProfile("fresher");
      if (data == null) {
        debugPrint('fetchProfile: getUserProfile returned null');
      }
      if (data != null && mounted) {
        setState(() {
          name = data["name"] ?? "";
          email = data["email"] ?? "";
          password = data["password"] ?? "";
          qualification = data["qualification"] ?? "";
          location = data["location"] ?? "";
          joinDate = data["join_date"] ?? "";
          resumeUrl = data["resume_url"] != null ? "${ApiService.baseUrl}${data["resume_url"]}" : "";
          skills = List<String>.from(data["skills"] ?? []);
        });

        // Fetch profile image if exists
        final imageResponse = await ApiService.getProfileImage(data["user_id"]);
        if (imageResponse != null && mounted) {
          setState(() => profileImage = imageResponse);
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveField(String field, dynamic value) async {
    final success = await ApiService.updateUserProfile("fresher", {field: value});
    if (success) fetchProfile();
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print("Could not launch $url");
    }
  }

  void _editField(String fieldName, Function(String) onSave, [String currentValue = ""]) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter $fieldName'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSkill() {
    _editField("Skill", (value) {
      if (value.isNotEmpty) {
        setState(() => skills.add(value));
        saveField("skills", skills);
      }
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => profileImage = bytes);
      // Show a snackbar to prompt saving
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image selected. Tap "Save Profile Image" to upload.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<void> saveProfileImage() async {
    if (profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    
    final success = await ApiService.uploadProfileImage(profileImage!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile image saved successfully!' : 'Failed to save profile image'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        fetchProfile(); // Refresh profile to show updated image
      }
    }
  }

  Widget _buildEditableField(double width, String label, String value, IconData icon, Function(String) onSave) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: width * 0.03, horizontal: width * 0.04),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(onTap: () => _editField(label, onSave, value), child: const Icon(Icons.edit, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildResumeField(double width) {
    if (resumeUrl.isEmpty) {
      return _buildEditableField(width, "Resume", "Not uploaded", Icons.description, (value) {
        setState(() => resumeUrl = value);
        saveField("resume_url", value);
      });
    }
    return GestureDetector(
      onTap: () => _launchURL(resumeUrl),
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 8),
            Text("View Resume", style: TextStyle(color: Colors.white)),
            Spacer(),
            Icon(Icons.open_in_new, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(double width, String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: width * 0.04, horizontal: width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2D9EE0)),
          SizedBox(width: width * 0.03),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF091E3A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final horizontalPadding = width * 0.08;

    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF091E3A),
        title: const Text("Profile Overview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF091E3A), Color(0xFF2D9EE0), Color(0xFF2E8FE7), Color(0xFFFFFFFF)],
            stops: [0.0, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: height * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      image: profileImage != null ? DecorationImage(image: MemoryImage(profileImage!), fit: BoxFit.cover) : null,
                    ),
                    child: profileImage == null ? const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Color(0xFF2D9EE0))) : null,
                  ),
                ),
                SizedBox(height: height * 0.015),
                
                // Save Profile Image Button
                GestureDetector(
                  onTap: saveProfileImage,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: height * 0.015, horizontal: width * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload, color: Color(0xFF2D9EE0)),
                        SizedBox(width: 8),
                        Text("Save Profile Image", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF091E3A))),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025),

                // Editable fields
                _buildEditableField(width, "Name", name, Icons.person, (value) => saveField("name", value)),
                _buildEditableField(width, "Email", email, Icons.email, (value) => saveField("email", value)),
                // _buildEditableField(width, "Password", password, Icons.lock, (value) => saveField("password", value)),
                _buildEditableField(width, "Qualification", qualification, Icons.school, (value) => saveField("qualification", value)),
                _buildEditableField(width, "Location", location, Icons.location_on, (value) => saveField("location", value)),
                // _buildEditableField(width, "Join Date", joinDate, Icons.date_range, (value) => saveField("join_date", value)),
                _buildResumeField(width),

                SizedBox(height: height * 0.015),

                // Skills
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text("Skills", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          GestureDetector(onTap: _addSkill, child: const Icon(Icons.add, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((skill) {
                          return Chip(
                            label: Text(skill, style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.blue.withOpacity(0.5),
                            onDeleted: () {
                              setState(() => skills.remove(skill));
                              saveField("skills", skills);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.015),

                // Resume & Portfolio Buttons
                GestureDetector(onTap: () => _launchURL("https://bettercv.com/resume/choose-template"), child: _buildActionButton(width, "Resume Maker", Icons.description)),
                SizedBox(height: height * 0.015),
                GestureDetector(onTap: () => _launchURL("https://www.portfoliobox.com/"), child: _buildActionButton(width, "Portfolio Maker", Icons.work)),
                SizedBox(height: height * 0.015),

                // Account Connector Links
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: height * 0.02, horizontal: width * 0.04),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Color(0xFF2D9EE0)),
                      const SizedBox(width: 8),
                      const Text("Account Connector", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF091E3A))),
                      const Spacer(),
                      IconButton(icon: const FaIcon(FontAwesomeIcons.linkedin, color: Colors.blue), onPressed: () => _launchURL("https://www.linkedin.com/login")),
                      IconButton(icon: const FaIcon(FontAwesomeIcons.github, color: Colors.black), onPressed: () => _launchURL("https://github.com/login")),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
