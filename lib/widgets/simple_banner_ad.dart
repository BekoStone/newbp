import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/complete_ad_manager.dart';
import '../services/analytics_service.dart';

class SimpleBannerAd extends StatefulWidget {
  const SimpleBannerAd({super.key});

  @override
  State<SimpleBannerAd> createState() => _SimpleBannerAdState();
}

class _SimpleBannerAdState extends State<SimpleBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String _status = 'Initializing ad...';
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    print('🟡 SimpleBannerAd: Starting initialization');
    _loadBannerAd();
  }

  void _loadBannerAd() {
    print('🟡 SimpleBannerAd: Creating banner ad... (Attempt ${_retryCount + 1})');
    
    setState(() {
      _status = 'Loading ad...';
      _hasError = false;
    });
    
    // Dispose existing ad if any
    _bannerAd?.dispose();
    
    _bannerAd = BannerAd(
      adUnitId: CompleteAdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ SimpleBannerAd: Banner loaded successfully!');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _status = 'Ad loaded successfully';
              _hasError = false;
              _retryCount = 0;
            });
            
            // Analytics: Log ad shown
            AnalyticsService.instance.logAdShown(
              adType: 'banner',
              placement: 'game_bottom',
            );
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ SimpleBannerAd: Failed to load: ${error.message}');
          if (mounted) {
            setState(() {
              _status = 'Failed: ${error.message}';
              _hasError = true;
              _isLoaded = false;
            });
            
            // Retry logic
            _retryCount++;
            if (_retryCount < _maxRetries) {
              Future.delayed(Duration(seconds: _retryCount * 5), () {
                if (mounted) {
                  _loadBannerAd();
                }
              });
            } else {
              setState(() {
                _status = 'Failed after $_maxRetries attempts';
              });
            }
          }
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('🟡 SimpleBannerAd: Ad opened');
          AnalyticsService.instance.logAdClicked(
            adType: 'banner',
            placement: 'game_bottom',
          );
        },
        onAdClosed: (ad) {
          print('🟡 SimpleBannerAd: Ad closed');
        },
        onAdClicked: (ad) {
          print('🟡 SimpleBannerAd: Ad clicked');
          AnalyticsService.instance.logAdClicked(
            adType: 'banner',
            placement: 'game_bottom',
          );
        },
      ),
    );

    print('🟡 SimpleBannerAd: Starting ad load...');
    _bannerAd!.load();
  }

  @override
  void dispose() {
    print('🟡 SimpleBannerAd: Disposing...');
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;
    
    // Calculate responsive dimensions
    final containerHeight = (screenHeight * 0.08).clamp(60.0, 90.0); // 8% of screen height
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width
    final borderRadius = isTablet ? 12.0 : 8.0;
    final fontSize = isTablet ? 12.0 : 10.0;
    final iconSize = isTablet ? 24.0 : 20.0;
    
    return Container(
      width: double.infinity,
      height: containerHeight,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFD5), // PapayaWhip background
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: _isLoaded ? Colors.green : Colors.orange, 
          width: 2,
        ),
      ),
      child: _isLoaded && _bannerAd != null
          ? Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius - 2),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_hasError) ...[
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 2,
                        value: _retryCount > 0 ? _retryCount / _maxRetries : null,
                      ),
                    ),
                    SizedBox(height: containerHeight * 0.1),
                  ],
                  Text(
                    _hasError ? '❌ $_status' : '🔄 $_status',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_hasError && _retryCount < _maxRetries) ...[
                    SizedBox(height: containerHeight * 0.1),
                    ElevatedButton(
                      onPressed: () {
                        _retryCount = 0;
                        _loadBannerAd();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: containerHeight * 0.05,
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: fontSize * 0.9,
                        ),
                      ),
                    ),
                  ],
                  if (_hasError && _retryCount >= _maxRetries) ...[
                    SizedBox(height: containerHeight * 0.05),
                    Text(
                      'Test mode: ${CompleteAdManager.instance.isUsingTestAds ? 'ON' : 'OFF'}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: fontSize * 0.8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}