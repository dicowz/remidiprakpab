import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final SessionService sessionService = SessionService(prefs);

  AuthService authService;
  FirestoreService firestoreService;

  try {
    // Attempt Firebase initialization
    // This will fail safely if google-services.json or GoogleService-Info.plist is missing.
    await Firebase.initializeApp();
    authService = FirebaseAuthService();
    firestoreService = FirebaseFirestoreService();
    debugPrint("Firebase initialized successfully. Running in Cloud Mode.");
  } catch (e) {
    // Fallback to local storage mock services in case configuration is missing or invalid
    authService = MockAuthService(prefs);
    firestoreService = MockFirestoreService(prefs);
    debugPrint("Firebase initialization failed ($e). Falling back to Mock Mode.");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionService>.value(value: sessionService),
        Provider<AuthService>.value(value: authService),
        Provider<FirestoreService>.value(value: firestoreService),
      ],
      child: const SpaceNewsApp(),
    ),
  );
}

class SpaceNewsApp extends StatelessWidget {
  const SpaceNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceNews Core',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
