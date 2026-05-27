import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'screens/phone_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AgentOnboardingApp());
}

class AgentOnboardingApp extends StatelessWidget {
  const AgentOnboardingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Agent Onboarding',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const PhoneScreen(),
  );
}
