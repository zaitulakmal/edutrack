import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EduTrackApp());
}

class EduTrackApp extends StatelessWidget {
  const EduTrackApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'EduTrack Portal',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const LoginScreen(),
  );
}
