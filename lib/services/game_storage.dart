// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static GameStorage? _instance;
  static GameStorage get instance => _instance ??= GameStorage._();
  GameStorage._();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Storage Keys
  static const String _highScoreKey = 'high_score';
  static const String _totalGamesKey = 'total_games';
  static const String _totalScoreKey = 'total_score';
  static const String _lastPlayDateKey = 'last_play_date';
  static const String _tutorialShownKey = 'tutorial_shown';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _gameStatsKey = 'game_stats';

  // Initialize storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      print('✅ Game storage initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize game storage: $e');
    }
  }

  // ==================== HIGH SCORE ====================
  Future<int> getHighScore() async {
    await _ensureInitialized();
    return _prefs.getInt(_highScoreKey) ?? 0;
  }

  Future<bool> setHighScore(int score) async {
    await _ensureInitialized();
    final currentHigh = await getHighScore();
    if (score > currentHigh) {
      await _prefs.setInt(_highScoreKey, score);
      print('🏆 New high score: $score (previous: $currentHigh)');
      return true; // New high score achieved
    }
    return false;
  }

  // ==================== GAME STATISTICS ====================
  Future<void> recordGamePlayed(int score) async {
    await _ensureInitialized();
    
    // Update total games
    final totalGames = (_prefs.getInt(_totalGamesKey) ?? 0) + 1;
    await _prefs.setInt(_totalGamesKey, totalGames);
    
    // Update total score
    final totalScore = (_prefs.getInt(_totalScoreKey) ?? 0) + score;
    await _prefs.setInt(_totalScoreKey, totalScore);
    
    // Update last play date
    await _prefs.setString(_lastPlayDateKey, DateTime.now().toIso8601String());
    
    print('📊 Game recorded - Score: $score, Total games: $totalGames');
  }

  Future<Map<String, dynamic>> getGameStats() async {
    await _ensureInitialized();
    
    final totalGames = _prefs.getInt(_totalGamesKey) ?? 0;
    final totalScore = _prefs.getInt(_totalScoreKey) ?? 0;
    final highScore = await getHighScore();
    final averageScore = totalGames > 0 ? (totalScore / totalGames).round() : 0;
    
    return {
      'totalGames': totalGames,
      'totalScore': totalScore,
      'highScore': highScore,
      'averageScore': averageScore,
      'lastPlayDate': _prefs.getString(_lastPlayDateKey),
    };
  }

  // ==================== TUTORIAL & FIRST TIME ====================
  Future<bool> isTutorialShown() async {
    await _ensureInitialized();
    return _prefs.getBool(_tutorialShownKey) ?? false;
  }

  Future<void> setTutorialShown() async {
    await _ensureInitialized();
    await _prefs.setBool(_tutorialShownKey, true);
    print('✅ Tutorial marked as shown');
  }

  // ==================== SETTINGS ====================
  Future<bool> isSoundEnabled() async {
    await _ensureInitialized();
    return _prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_soundEnabledKey, enabled);
    print('🔊 Sound ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<bool> isVibrationEnabled() async {
    await _ensureInitialized();
    return _prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_vibrationEnabledKey, enabled);
    print('📳 Vibration ${enabled ? 'enabled' : 'disabled'}');
  }

  // ==================== UTILITIES ====================
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _prefs.clear();
    print('🗑️ All game data cleared');
  }

  Future<void> resetStats() async {
    await _ensureInitialized();
    await _prefs.remove(_highScoreKey);
    await _prefs.remove(_totalGamesKey);
    await _prefs.remove(_totalScoreKey);
    await _prefs.remove(_lastPlayDateKey);
    print('📊 Game statistics reset');
  }

  // ==================== PRIVATE METHODS ====================
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ==================== BACKUP/RESTORE ====================
  Future<Map<String, dynamic>> exportData() async {
    await _ensureInitialized();
    
    return {
      'highScore': await getHighScore(),
      'gameStats': await getGameStats(),
      'soundEnabled': await isSoundEnabled(),
      'vibrationEnabled': await isVibrationEnabled(),
      'tutorialShown': await isTutorialShown(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      if (data.containsKey('highScore')) {
        await _prefs.setInt(_highScoreKey, data['highScore']);
      }
      if (data.containsKey('soundEnabled')) {
        await setSoundEnabled(data['soundEnabled']);
      }
      if (data.containsKey('vibrationEnabled')) {
        await setVibrationEnabled(data['vibrationEnabled']);
      }
      if (data.containsKey('tutorialShown')) {
        await _prefs.setBool(_tutorialShownKey, data['tutorialShown']);
      }
      
      print('✅ Game data imported successfully');
    } catch (e) {
      print('❌ Failed to import game data: $e');
    }
  }
}