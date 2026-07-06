import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'stu_dashboard.dart';
import 'fresher_dashboard.dart';

class QuestionsScreen extends StatefulWidget {
  final String userType; // student or fresher
  final String token; // JWT token
  final String domain;
  final List<String> selectedSkills;
  final String userEmail;

  const QuestionsScreen({
    super.key,
    required this.userType,
    required this.token,
    required this.domain,
    required this.selectedSkills,
    required this.userEmail,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<dynamic> questions = [];
  Map<String, String> answers = {}; // question_id -> selected option
  bool isLoading = true;
  bool finishEnabled = false;
  bool isTiebreaker = false;
  List<String> tiebreakerDomains = [];
  int tiebreakerRound = 0;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.http("127.0.0.1:8000", "/questions/", {
        "userType": widget.userType,
      });

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = data;
          answers = {for (var q in questions) q['question_id']: ''};
          isLoading = false;
          finishEnabled = false;
        });
      } else {
        throw Exception("Failed to fetch questions");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void updateAnswer(String questionId, String option) {
    setState(() {
      answers[questionId] = option;
      // Check if all questions have been answered
      finishEnabled = answers.values.every((ans) => ans.isNotEmpty);
      print("Updated answer for $questionId: $option");
      print("Finish enabled: $finishEnabled");
      print("Answers: $answers");
    });
  }

  Future<void> submitQuiz() async {
    try {
      if (isTiebreaker) {
        await submitTiebreakerQuiz(tiebreakerDomains);
        return;
      }

      // Make sure to pass user_email here
      final payload = {
        "user_email": widget.userEmail, // <-- Pass actual user email
        "answers": answers.entries
            .map((e) => {"question_id": e.key, "selected_option": e.value})
            .toList(),
      };

      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/questions/submit-quiz"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int score = data['score'] ?? 0;
        final List<dynamic> domainScoresList = data['domain_scores'] ?? [];

        final bool tiebreakerRequired = data['tiebreaker_required'] ?? false;
        final String? bestDomain = data['best_domain'];
        final topDomainsRaw = data['top_domains'];
        final List<String> topDomains = topDomainsRaw is String
            ? [topDomainsRaw]
            : List<String>.from(topDomainsRaw ?? []);

        if (tiebreakerRequired && topDomains.length > 1) {
          await fetchTiebreakerQuiz(topDomains);
          return;
        }

        if (!mounted) return;

        // Show results
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Quiz Completed"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your total score: $score%",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  if (bestDomain != null) ...[
                    Text(
                      "Recommended Career Path:",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        bestDomain,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  const Text(
                    "Domain-wise Performance:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...domainScoresList.map<Widget>((e) {
                    final domain = e['domain'] ?? '';
                    final domainScore = (e['score'] ?? 0).toDouble();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              domain,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            "${domainScore.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: domainScore >= 70 ? Colors.green : 
                                     domainScore >= 50 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                if (score < 30)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      fetchQuestions();
                    },
                    child: const Text("Retry"),
                  ),
                if (score >= 30)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.userType == "student") {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StuDashboard(),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FresDashboard(),
                          ),
                        );
                      }
                    },
                    child: const Text("Next"),
                  ),
              ],
            );
          },
        );
      } else {
        final body = response.body;
        throw Exception(
          "Failed to submit quiz: ${response.statusCode} ${body.isNotEmpty ? '- $body' : ''}",
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> fetchTiebreakerQuiz(List<String> tiedDomains) async {
    setState(() {
      tiebreakerRound++;
    });

    // Show tiebreaker round notification
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('🔄 Tiebreaker Round $tiebreakerRound!'),
          content: Text(
            'Multiple domains have the same score. Let\'s resolve this tie with additional questions!\n\nTied domains: ${tiedDomains.join(", ")}'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Let\'s Go!'),
            ),
          ],
        ),
      );
    }

    try {
      final domains = tiedDomains.where((d) => d.isNotEmpty).toList();
      if (domains.isEmpty) {
        throw Exception("No valid domains for tiebreaker");
      }

      final payload = {
        "tied_domains": domains,
        "userType": widget.userType,
      };

      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/questions/tiebreaker-questions"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;

        setState(() {
          questions = (data['tiebreaker_questions'] as List<dynamic>?) ?? [];
          answers = {for (var q in questions) q['question_id']: ''};
          finishEnabled = false;
          isTiebreaker = true;
          tiebreakerDomains = domains;
        });
      } else {
        final body = response.body;
        throw Exception(
          "Failed to fetch tiebreaker quiz: ${response.statusCode} ${body.isNotEmpty ? '- $body' : ''}",
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> submitTiebreakerQuiz(List<String> tiedDomains) async {
    try {
      final payload = {
        "submission": {
          "user_email": widget.userEmail,
          "answers": answers.entries
              .map((e) => {"question_id": e.key, "selected_option": e.value})
              .toList(),
        },
        "tied_domains": tiedDomains,
      };

      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/questions/tiebreaker"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;

        final String? bestDomain = data['best_domain'];
        final List<dynamic> domainScores = data['domain_scores'] ?? [];
        final bool stillTied = data['still_tied'] ?? false;
        final List<String> newTiedDomains = List<String>.from(data['tied_domains'] ?? []);
        final int round = data['round'] ?? 1;
        final bool maxRoundsReached = data['max_rounds_reached'] ?? false;

        if (maxRoundsReached && stillTied) {
          // Show user preference dialog
          showUserPreferenceDialog(newTiedDomains);
        } else if (stillTied && round < 3) {
          // Show current round results and prepare for next round
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('🔄 Round $round Results'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Still tied! Current scores:'),
                  SizedBox(height: 8),
                  ...domainScores.map((score) => Text(
                    '${score['domain']}: ${score['score']}%'
                  )).toList(),
                  SizedBox(height: 16),
                  Text('Starting next tiebreaker round...'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    fetchTiebreakerQuiz(newTiedDomains);
                  },
                  child: Text('Continue'),
                ),
              ],
            ),
          );
        } else {
          // Tiebreaker resolved!
          showFinalResultDialog(bestDomain!, domainScores);
        }
      } else {
        throw Exception(
          "Failed to submit tiebreaker quiz: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showUserPreferenceDialog(List<String> tiedDomains) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🤔 Your Choice Matters!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'After 3 tiebreaker rounds, these domains still have the same score:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              tiedDomains.join(' and '),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Which one interests you more?',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: tiedDomains.map((domain) => 
          TextButton(
            onPressed: () => submitUserPreference(domain),
            child: Text(domain),
          )
        ).toList(),
      ),
    );
  }

  Future<void> submitUserPreference(String chosenDomain) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/questions/user-preference'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chosen_domain': chosenDomain,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close preference dialog
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('🎯 Perfect Match!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your chosen domain: $chosenDomain',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('This choice reflects your personal interest and preference!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  navigateToDashboard();
                },
                child: Text('Continue'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to save user preference');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showFinalResultDialog(String bestDomain, List<dynamic> domainScores) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("🎯 Tiebreaker Resolved!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Final Result:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  "Best Career Path: $bestDomain",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Final Scores:"),
              ...domainScores.map<Widget>((e) {
                final domain = e['domain'] ?? '';
                final score = (e['score'] ?? 0).toDouble();
                return Text(
                  "$domain: ${score.toStringAsFixed(1)}%",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                navigateToDashboard();
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void navigateToDashboard() {
    if (widget.userType == "student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StuDashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FresDashboard(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTiebreaker ? "Tiebreaker Quiz" : "Quiz"),
        backgroundColor: isTiebreaker ? Colors.orange : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: questions
                    .map(
                      (q) => QuestionCard(
                        question: q,
                        selectedOption: answers[q['question_id']] ?? '',
                        onSelect: (opt) => updateAnswer(q['question_id'], opt),
                      ),
                    )
                    .toList(),
              ),
            ),
      floatingActionButton: ElevatedButton(
        onPressed: finishEnabled ? submitQuiz : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: finishEnabled
              ? Colors.green
              : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "FINISH",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: finishEnabled ? Colors.white : Colors.black54,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class QuestionCard extends StatelessWidget {
  final Map question;
  final String selectedOption;
  final Function(String) onSelect;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      "A": question['option_a'],
      "B": question['option_b'],
      "C": question['option_c'],
      "D": question['option_d'],
    };

    return Card(
      color: Colors.blue[700],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question_text'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...options.entries.map(
              (e) => RadioListTile<String>(
                title: Text(
                  e.value,
                  style: const TextStyle(color: Colors.white),
                ),
                value: e.key,
                groupValue: selectedOption,
                activeColor: Colors.white,
                onChanged: (val) {
                  if (val != null) onSelect(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
