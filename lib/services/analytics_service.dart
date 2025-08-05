// ignore_for_file: avoid_print

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  bool _isInitialized = false;

  // Initialize analytics
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Set analytics collection enabled
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      _isInitialized = true;
      print('✅ Analytics initialized successfully');
      
      // Log app start
      await logEvent('app_start', {});
    } catch (e) {
      print('❌ Failed to initialize analytics: $e');
    }
  }

  // ==================== GAME EVENTS ====================
  
  Future<void> logGameStart() async {
    await logEvent('game_start', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logGameEnd({
    required int score,
    required int duration,
    required bool isHighScore,
  }) async {
    await logEvent('game_end', {
      'score': score,
      'duration_seconds': duration,
      'is_high_score': isHighScore,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logLevelComplete({
    required int score,
    required int linesCleared,
    required int comboCount,
  }) async {
    await logEvent('level_complete', {
      'score': score,
      'lines_cleared': linesCleared,
      'combo_count': comboCount,
    });
  }

  Future<void> logPowerUpUsed({
    required String powerUpType,
    required int remainingCount,
  }) async {
    await logEvent('power_up_used', {
      'power_up_type': powerUpType,
      'remaining_count': remainingCount,
    });
  }

  Future<void> logPiecePlace({
    required int pieceSize,
    required bool isCornerPlacement,
    required int gridFillPercentage,
  }) async {
    await logEvent('piece_placed', {
      'piece_size': pieceSize,
      'corner_placement': isCornerPlacement,
      'grid_fill_percentage': gridFillPercentage,
    });
  }

  // ==================== AD EVENTS ====================
  
  Future<void> logAdShown({
    required String adType,
    required String placement,
  }) async {
    await logEvent('ad_shown', {
      'ad_type': adType,
      'placement': placement,
    });
  }

  Future<void> logAdClicked({
    required String adType,
    required String placement,
  }) async {
    await logEvent('ad_clicked', {
      'ad_type': adType,
      'placement': placement,
    });
  }

  Future<void> logRewardedAdCompleted({
    required String rewardType,
    required int rewardAmount,
  }) async {
    await logEvent('rewarded_ad_completed', {
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
    });
  }

  // ==================== USER BEHAVIOR ====================
  
  Future<void> logTutorialCompleted() async {
    await logEvent('tutorial_completed', {});
  }

  Future<void> logSettingsChanged({
    required String setting,
    required dynamic value,
  }) async {
    await logEvent('settings_changed', {
      'setting': setting,
      'value': value.toString(),
    });
  }

  Future<void> logScreenView(String screenName) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      print('📱 Screen view logged: $screenName');
    } catch (e) {
      print('❌ Failed to log screen view: $e');
    }
  }

  // ==================== CUSTOM EVENTS ====================
  
  Future<void> logEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_isInitialized) return;
    
    try {
      // Convert parameters to proper types for Firebase
      final Map<String, Object> firebaseParams = {};
      parameters.forEach((key, value) {
        if (value is String || value is int || value is double || value is bool) {
          firebaseParams[key] = value;
        } else {
          firebaseParams[key] = value.toString();
        }
      });
      
      await _analytics.logEvent(
        name: eventName,
        parameters: firebaseParams,
      );
      
      print('📊 Event logged: $eventName with ${firebaseParams.length} parameters');
    } catch (e) {
      print('❌ Failed to log event $eventName: $e');
    }
  }

  // ==================== USER PROPERTIES ====================
  
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setUserProperty(name: name, value: value);
      print('👤 User property set: $name = $value');
    } catch (e) {
      print('❌ Failed to set user property: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
      print('👤 User ID set: $userId');
    } catch (e) {
      print('❌ Failed to set user ID: $e');
    }
  }

  // ==================== CRASH REPORTING ====================
  
  Future<void> logError({
    required dynamic exception,
    required StackTrace stackTrace,
    String? reason,
    Map<String, dynamic>? customData,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: customData?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      );
      print('💥 Error logged to Crashlytics: $exception');
    } catch (e) {
      print('❌ Failed to log error to Crashlytics: $e');
    }
  }

  Future<void> logMessage(String message) async {
    try {
      await _crashlytics.log(message);
      print('📝 Message logged: $message');
    } catch (e) {
      print('❌ Failed to log message: $e');
    }
  }

  // ==================== UTILITIES ====================
  
  bool get isInitialized => _isInitialized;
  
  FirebaseAnalytics get analytics => _analytics;
  FirebaseCrashlytics get crashlytics => _crashlytics;
}