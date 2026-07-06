import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'questions.dart';

class QuizTimeScreen extends StatelessWidget {
  final String userType;
  final String domain;
  final List<String> selectedSkills;
  final String token;

  const QuizTimeScreen({
    super.key,
    required this.userType,
    required this.domain,
    required this.selectedSkills,
    required this.token,
  });

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: height * 0.05),
                  // Quiz Time Title in one line
                  Text(
                    "QUIZ TIME",
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: height * 0.04),

                  // Q2 Image
                  Image.asset(
                    'assets/q2.png',
                    height: height * 0.2,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: height * 0.04),

                  // Instructions Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions Title
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.yellow[300],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Exam Instructions",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Instruction Items
                        _buildInstructionItem(
                          Icons.format_list_numbered_rounded,
                          "The exam contains 33 questions",
                          context,
                        ),
                        // _buildInstructionItem(
                        //   Icons.timer_rounded,
                        //   "You have 22 minutes to complete the exam",
                        //   context,
                        // ),
                        _buildInstructionItem(
                          Icons.warning_amber_rounded,
                          "Do not use AI or external help during the exam",
                          context,
                        ),
                        _buildInstructionItem(
                          Icons.auto_awesome_rounded,
                          "After finishing, the app will suggest your career path based on your answers",
                          context,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  // Start Quiz Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestionsScreen(
                            userType: userType,
                            token: token,
                            domain: domain,
                            selectedSkills: selectedSkills, userEmail: '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Colors.blue[900],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Start Quiz Now",
                          style: GoogleFonts.inriaSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.02),

                  // Good Luck Text
                  Text(
                    "Good Luck!",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    IconData icon,
    String text,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
