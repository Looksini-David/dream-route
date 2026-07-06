import 'package:flutter/material.dart';
import 'selectskills.dart';

class DomainSelectionScreen extends StatefulWidget {
  final String userType; // Pass userType from previous screen

  const DomainSelectionScreen({super.key, required this.userType});

  @override
  State<DomainSelectionScreen> createState() => _DomainSelectionScreenState();
}

class _DomainSelectionScreenState extends State<DomainSelectionScreen> {
  String? _selectedDomain;

  final Map<String, List<String>> _domainSkills = {
    '🎨 Design': [
      'Adobe Photoshop',
      'Adobe Illustrator',
      'Figma',
      'Canva',
      'Prototyping',
      'Creativity',
    ],
    '🌐 Web Development': [
      'HTML',
      'CSS',
      'JavaScript',
      'React',
      'Angular',
      'Node.js',
      'PHP',
      'Git',
    ],
    '📱 Mobile Development': [
      'Java',
      'Kotlin',
      'Swift',
      'Flutter',
      'React Native',
      'Mobile UI/UX',
    ],
    '💻 Software Development': [
      'Python',
      'Java',
      'C++',
      'C#',
      '.NET',
      'Problem-Solving',
      'OOP',
    ],
    '🗄 Database': [
      'SQL',
      'MySQL',
      'Oracle',
      'MongoDB',
      'Firebase',
      'Data Modeling',
      'Backup & Recovery',
    ],
    '🌐 Networking': [
      'CCNA',
      'TCP/IP',
      'Firewalls',
      'Routers & Switches',
      'Windows/Linux Administration',
    ],
    '🔐 Cybersecurity': [
      'Cybersecurity tools',
      'Cryptography',
      'Firewalls',
      'SIEM',
      'Ethical Hacking',
      'Risk Mgmt',
    ],
    '📊 Data Analytics': [
      'Excel',
      'SQL',
      'Python (Pandas, NumPy)',
      'Power BI',
      'Tableau',
      'Data Visualization',
    ],
    '🤖 AI & Data Science': [
      'Python (TensorFlow, Scikit-learn)',
      'R',
      'Statistics',
      'NLP',
      'Deep Learning',
    ],
    '☁ Cloud & DevOps': [
      'AWS',
      'Azure',
      'GCP',
      'Docker',
      'Kubernetes',
      'Jenkins',
      'CI/CD',
    ],
    '📂 IT Management': [
      'Agile',
      'Scrum',
      'Jira',
      'Project Planning',
      'Leadership',
      'Risk Management',
    ],
  };

  @override
  Widget build(BuildContext context) {
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
            ],
            stops: [0.0, 0.4, 0.8],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Select Domains',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '(Choose one)',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _domainSkills.keys
                        .map((domain) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDomainCard(domain),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDomain == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SkillsSelectionScreen(
                                domain: _selectedDomain!,
                                skills: _domainSkills[_selectedDomain!]!,
                                userType: widget.userType,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2D9EE0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                    disabledForegroundColor:
                        const Color(0xFF2D9EE0).withOpacity(0.5),
                  ),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainCard(String domain) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDomain = domain),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedDomain == domain
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            width: _selectedDomain == domain ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _selectedDomain == domain
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                domain,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
