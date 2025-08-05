// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'services/complete_ad_manager.dart';
import 'services/game_storage.dart';
import 'services/analytics_service.dart';
import 'splash_screen.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GAME STORAGE: Initialize first
  try {
    await GameStorage.instance.initialize();
    print('✅ Game storage initialized successfully!');
  } catch (e) {
    print('❌ Game storage initialization failed: $e');
  }

  // FIREBASE: Initialize with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
    
    // Initialize analytics after Firebase
    await AnalyticsService.instance.initialize();
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // ADMOB: Initialize
  try {
    await MobileAds.instance.initialize();
    print('✅ AdMob initialized successfully!');

    // Initialize all ads
    CompleteAdManager.instance.initializeAllAds();
  } catch (e) {
    print('❌ AdMob initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Block Puzzle',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const GameScreen(),
      },
    );
  }
}