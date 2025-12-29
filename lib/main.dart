import 'dart:async';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/club_admin_dashboard.dart';
import 'pages/home_page.dart';
import 'pages/feed_page.dart';
import 'pages/ai_chat_page.dart';
import 'pages/club_requests_page.dart';
import 'package:flutter/services.dart';

void main() async {
  try {
    await rootBundle.loadString('assets/.env');
  } catch (e) {
    // Running in web — no local env — use backend instead
  }
  await dotenv.load(fileName: 'assets/.env');
  WidgetsFlutterBinding.ensureInitialized();

  // Debugging: log initialize start and handle errors/timeouts
  debugPrint('Starting Firebase.initializeApp() with DefaultFirebaseOptions');
  try {
    // Use platform-specific options (generate with `flutterfire configure`)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    debugPrint('Firebase initialized successfully');
  } on TimeoutException catch (e) {
    debugPrint('Firebase.initializeApp() timed out: $e');
  } catch (e, st) {
    debugPrint('Firebase.initializeApp() threw: $e\n$st');
  }

  runApp(const OneCumminsApp());
}

class OneCumminsApp extends StatelessWidget {
  const OneCumminsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneCummins AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/club_dashboard': (context) => const ClubAdminDashboardPage(),
        '/ai_chat': (context) => const AiChatPage(),
        '/feed': (context) => const FeedPage(),
        // '/dashboard/notices': (context) => const SuperAdminCampusItemsPage(),
        '/dashboard/club_requests': (context) => const ClubRequestsPage(),
      },
    );
  }
}
