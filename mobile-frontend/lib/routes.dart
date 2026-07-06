import 'package:dream_route/screens/register.dart';
import 'package:flutter/material.dart';
import 'screens/aitask.dart';
import 'screens/feedback.dart';
import 'screens/fresher_profileview.dart';
import 'screens/login.dart';
import 'screens/quiz_start.dart';
import 'screens/questions.dart';
import 'screens/resume.dart';
import 'screens/selectdomain.dart';
import 'screens/splash.dart';
import 'screens/stu_dashboard.dart';
import 'screens/stu_profileview.dart';
import 'screens/fresher_dashboard.dart';
// import 'screens/fresher_quizsummary.dart';
// import 'screens/stu_quizsummary.dart';
import 'screens/careerpath.dart';
import 'screens/careerplatform.dart';
import 'screens/roadmap.dart';

final Map<String, WidgetBuilder> appRoutes = <String, WidgetBuilder>{
  '/splash':(context)=> const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/quickstart': (context) => const QuizTimeScreen(userType: '', domain: '', selectedSkills: [], token: '',),
  '/started': (context) => const QuestionsScreen(userType: '', domain: '', selectedSkills: [], token: '', userEmail: '',),
  '/stu_profile': (context) => const StuProfile(),
  '/fresher_profile': (context) => const FresherProfile(),
  '/stu_dashboard': (context) => const StuDashboard(),
  '/fresher_dashboard': (context) => const FresDashboard(),
  //'/stu_quiz_summary': (context) => StuQuizsummary(score: 0, bestDomain: '',),
  // '/fresher_quiz_summary': (context) => FresherQuizSummary(userId: ''),
  '/career_path': (context) => const RecommendedCareerPathScreen(),
  '/career_platform': (context) => const CareerPlatform(),
  '/road_map': (context) => const RoadMapTimelineScreen(),
  '/ai_task': (context) => const AiTaskChallengeScreen(),
  '/feedback': (context) => const FeedbackScreen(),
  '/resume_analysis': (context) => const ResumeAnalysisScreen(),
  '/selectdomain': (context) => const DomainSelectionScreen(userType: '',),
};
