import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'theme/app_theme.dart';

import 'package:device_preview/device_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // runApp(
  //   DevicePreview( // WRAP dengan DevicePreview
  //     enabled: true, // Atur false untuk production
  //     builder: (context) => ProviderScope(
  //       child: MyApp(),
  //     ),
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Cek apakah user sudah login di Firebase Auth
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User sudah login, ambil data user dari Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;

          // Cek apakah user memiliki kedai di SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final bool? hasKedai = prefs.getBool('has_kedai_${currentUser.uid}');

          if (mounted) {
            // Navigasi langsung ke HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  username: userData?['username'] ??
                      currentUser.email?.split('@')[0] ?? 'User',
                  email: currentUser.email ?? '',
                  userId: currentUser.uid,
                ),
              ),
            );
            return;
          }
        }
      }

      // Jika tidak ada user login atau data tidak valid, tampilkan LoginPage
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green[700],
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const LoginPage();
  }
}