import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/selectdomain.dart';
import 'screens/selectskills.dart';
import 'screens/questions.dart';
import 'screens/stu_dashboard.dart';
import 'screens/fresher_dashboard.dart';
import 'screens/splash.dart';
import 'screens/stu_profileview.dart';
import 'screens/fresher_profileview.dart';
import 'screens/stu_quizsummary.dart';
import 'screens/fresher_quizsummary.dart';
import 'screens/careerpath.dart';
import 'screens/careerplatform.dart';
import 'screens/roadmap.dart';
import 'screens/aitask.dart';
import 'screens/feedback.dart';
import 'screens/resume.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/stu_dashboard': (context) => const StuDashboard(),
        '/fresher_dashboard': (context) => const FresDashboard(),
        '/stu_profile': (context) => const StuProfile(),
        '/fresher_profile': (context) => const FresherProfile(),
        '/stu_quiz_summary': (context) => StuQuizsummary(userId: '',),
        '/fresher_quiz_summary': (context) =>  FresherQuizSummary(userId: ''),
        '/career_path': (context) => const RecommendedCareerPathScreen(),
        '/career_platform': (context) => const CareerPlatform(),
        '/road_map': (context) => const RoadMapTimelineScreen(),
        '/ai_task': (context) => const AiTaskChallengeScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/resume_analysis': (context) => const ResumeAnalysisScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/selectdomain':
            if (args != null) {
              return MaterialPageRoute(
                builder: (_) => DomainSelectionScreen(userType: args['userType']),
              );
            }
            return null;

          case '/selectskills':
            if (args != null) {
              return MaterialPageRoute(
                builder: (_) => SkillsSelectionScreen(
                  userType: args['userType'],
                  domain: args['domain'],
                  skills: List<String>.from(args['skills']),
                ),
              );
            }
            return null;

          case '/started':
            if (args != null) {
              return MaterialPageRoute(
                builder: (_) => QuestionsScreen(
                  userType: args['userType'],
                  domain: args['domain'],
                  selectedSkills: List<String>.from(args['selectedSkills']), token: '', userEmail: '',
                ),
              );
            }
            return null;
        }

        return null; // Unknown route
      },
    );
  }
}







// import 'package:flutter/material.dart';
// import 'screens/login.dart';
// import 'screens/selectdomain.dart';
// import 'screens/selectskills.dart';
// import 'screens/questions.dart';
// import 'screens/stu_dashboard.dart';
// import 'screens/fresher_dashboard.dart';
// import 'screens/splash.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/splash',
//       routes: {
//         '/splash': (context) => const SplashScreen(),
//         '/login': (context) => const LoginScreen(),
//         '/stu_dashboard': (context) => const StuDashboard(),
//         '/fresher_dashboard': (context) => const FresDashboard(),
//       },
//       onGenerateRoute: (settings) {
//         switch (settings.name) {
//           case '/selectdomain':
//             final args = settings.arguments as Map<String, dynamic>;
//             return MaterialPageRoute(
//               builder: (_) => DomainSelectionScreen(userType: args['userType']),
//             );

//           case '/selectskills':
//             final args = settings.arguments as Map<String, dynamic>;
//             return MaterialPageRoute(
//               builder: (_) => SkillsSelectionScreen(
//                 userType: args['userType'],
//                 domain: args['domain'],
//                 skills: args['skills'],
//               ),
//             );

//           case '/started':
//             final args = settings.arguments as Map<String, dynamic>;
//             return MaterialPageRoute(
//               builder: (_) => QuestionsScreen(
//                 userType: args['userType'],
//                 domain: args['domain'],
//                 selectedSkills: List<String>.from(args['selectedSkills']),
//               ),
//             );
//         }
//         return null;
//       },
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'screens/splash.dart';
// import 'screens/login.dart';
// import 'screens/selectskills.dart';
// import 'screens/selectdomain.dart';
// import 'screens/quiz_start.dart';
// import 'screens/questions.dart';
// import 'screens/stu_dashboard.dart';
// import 'screens/fresher_dashboard.dart';
// import 'theme/app_theme.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dream Route',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: const SplashScreen(),
//       routes: {
//         '/login': (context) => const LoginScreen(),
//         '/stu_dashboard': (context) => const StuDashboard(),
//         '/fresher_dashboard': (context) => const FresDashboard(),
//       },
//       onGenerateRoute: (settings) {
//         // Dynamic routes with parameters
//         if (settings.name == '/selectskills') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => SkillsSelectionScreen(
//               domain: args['domain'],
//               skills: args['skills'],
//               userType: args['userType'],
//             ),
//           );
//         }
//         if (settings.name == '/quizstart') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => QuizTimeScreen(
//               userType: args['userType'],
//               domain: args['domain'],
//               selectedSkills: args['selectedSkills'],
//             ),
//           );
//         }
//         if (settings.name == '/questions') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => QuestionsScreen(userType: args['userType']),
//           );
//         }
//         if (settings.name == '/selectdomain') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => DomainSelectionScreen(userType: args['userType']),
//           );
//         }
//         return null;
//       },
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'screens/questions.dart';
// import 'screens/splash.dart';
// import 'routes.dart';
// import 'theme/app_theme.dart';
// import 'screens/quiz_start.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dream Route',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: const SplashScreen(),
//       routes: appRoutes, // static routes without parameters
//       onGenerateRoute: (settings) {
//         if (settings.name == '/quickstart') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => QuizTimeScreen(
//               userType: args['userType'],
//               domain: args['domain'],
//               selectedSkills: args['selectedSkills'],
//             ),
//           );
//         }

//         if (settings.name == '/started') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => QuestionsScreen(userType: args['userType']),
//           );
//         }

//         return null;
//       },
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'screens/splash.dart';
// import 'routes.dart';
// import 'theme/app_theme.dart';
// import 'screens/selectskills.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dream Route',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: const SplashScreen(),
//       routes: appRoutes, // static routes (no params)
//       onGenerateRoute: (settings) {
//         // Handle dynamic routes like SkillsSelectionScreen
//         if (settings.name == '/selectskills') {
//           final args = settings.arguments as Map<String, dynamic>;
//           return MaterialPageRoute(
//             builder: (_) => SkillsSelectionScreen(
//               domain: args['domain'],
//               skills: args['skills'],
//             ),
//             settings: settings,
//           );
//         }
//         return null;
//       },
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'screens/splash.dart';
// import 'routes.dart';
// import 'theme/app_theme.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dream Route',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: const SplashScreen(), // Use home property instead of '/' route
//       routes: appRoutes, // This should not include the '/' route
//     );
//   }
// }