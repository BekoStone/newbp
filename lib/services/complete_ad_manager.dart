// ignore_for_file: avoid_print

import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class CompleteAdManager {
  static CompleteAdManager? _instance;
  static CompleteAdManager get instance => _instance ??= CompleteAdManager._();
  CompleteAdManager._();

  // TEST AD IDs (Safe for development)
  static const String _testBannerAdId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdId = 'ca-app-pub-3940256099942544/5224354917';

  // PRODUCTION AD IDs - Set via environment variables for security
  static String get _prodBannerAdId => const String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: _testBannerAdId, // Fallback to test
  );
  
  static String get _prodInterstitialAdId => const String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID', 
    defaultValue: _testInterstitialAdId, // Fallback to test
  );
  
  static String get _prodRewardedAdId => const String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: _testRewardedAdId, // Fallback to test
  );

  // Environment-based test mode toggle
  static bool get _useTestAds => const bool.fromEnvironment(
    'USE_TEST_ADS',
    defaultValue: true, // Default to test mode for safety
  );

  // Ad Unit IDs with platform detection
  static String get bannerAdUnitId {
    if (_useTestAds) return _testBannerAdId;
    return Platform.isAndroid ? _prodBannerAdId : _prodBannerAdId;
  }

  static String get interstitialAdUnitId {
    if (_useTestAds) return _testInterstitialAdId;
    return Platform.isAndroid ? _prodInterstitialAdId : _prodInterstitialAdId;
  }

  static String get rewardedAdUnitId {
    if (_useTestAds) return _testRewardedAdId;
    return Platform.isAndroid ? _prodRewardedAdId : _prodRewardedAdId;
  }

  // ==================== BANNER ADS ====================
  BannerAd? createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('📱 Banner ad opened');
        },
        onAdClosed: (ad) {
          print('❌ Banner ad closed');
        },
        onAdClicked: (ad) {
          print('👆 Banner ad clicked');
        },
      ),
    );
  }

  // ==================== INTERSTITIAL ADS ====================
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _gameCount = 0;
  static const int _interstitialFrequency = 3; // Show every 3 games

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('✅ Interstitial ad loaded successfully');
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  bool shouldShowInterstitialAd() {
    _gameCount++;
    return _gameCount % _interstitialFrequency == 0;
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📺 Interstitial ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('❌ Interstitial ad dismissed');
          ad.dispose();
          _isInterstitialAdReady = false;
          onAdClosed?.call();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial ad failed to show: $error');
          ad.dispose();
          _isInterstitialAdReady = false;
          onAdClosed?.call();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      print('⚠️ Interstitial ad not ready');
      onAdClosed?.call();
    }
  }

  // ==================== REWARDED ADS ====================
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('✅ Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
          Future.delayed(const Duration(seconds: 30), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onAdClosed,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📺 Rewarded ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('❌ Rewarded ad dismissed');
          ad.dispose();
          _isRewardedAdReady = false;
          onAdClosed?.call();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Rewarded ad failed to show: $error');
          ad.dispose();
          _isRewardedAdReady = false;
          onAdClosed?.call();
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('🎁 User earned reward: ${reward.amount} ${reward.type}');
          onRewarded();
        },
      );
      _rewardedAd = null;
    } else {
      print('⚠️ Rewarded ad not ready');
      onAdClosed?.call();
    }
  }

  // ==================== GETTERS ====================
  bool get isInterstitialReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;
  int get gameCount => _gameCount;
  bool get isUsingTestAds => _useTestAds;

  // ==================== UTILITIES ====================
  void resetGameCount() {
    _gameCount = 0;
    print('🔄 Game count reset');
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    print('🗑️ Ad manager disposed');
  }

  void initializeAllAds() {
    print('🚀 Initializing all ads... (Test mode: $_useTestAds)');
    loadInterstitialAd();
    loadRewardedAd();
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'usingTestAds': _useTestAds,
      'gameCount': _gameCount,
      'interstitialReady': _isInterstitialAdReady,
      'rewardedReady': _isRewardedAdReady,
      'bannerAdUnitId': bannerAdUnitId,
      'interstitialAdUnitId': interstitialAdUnitId,
      'rewardedAdUnitId': rewardedAdUnitId,
    };
  }
}