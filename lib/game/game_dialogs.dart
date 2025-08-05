import 'package:flutter/material.dart';
import '../services/complete_ad_manager.dart';
import '../services/game_storage.dart';
import '../widgets/tutorial_dialog.dart';
import 'game_logic.dart';

mixin GameDialogs<T extends StatefulWidget> on State<T>, GameLogic<T> {

  void showSettingsDialog() async {
    final gameStats = await GameStorage.instance.getGameStats();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('Restart Game'),
              subtitle: const Text('Reset score and power-ups'),
              onTap: () {
                Navigator.pop(context);
                _showRestartConfirmation();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Statistics'),
              subtitle: Text('Games: ${gameStats['totalGames']}, High: ${gameStats['highScore']}'),
              onTap: () => _showStatsDialog(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.green),
              title: const Text('Show Tutorial'),
              subtitle: const Text('Learn how to play'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const TutorialDialog(),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.purple),
              title: const Text('Game Info'),
              subtitle: Text('Block Puzzle v1.0${CompleteAdManager.instance.isUsingTestAds ? ' (Test Ads)' : ''}'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() async {
    final stats = await GameStorage.instance.getGameStats();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Games', '${stats['totalGames']}'),
            _buildStatRow('High Score', '${stats['highScore']}'),
            _buildStatRow('Average Score', '${stats['averageScore']}'),
            _buildStatRow('Total Score', '${stats['totalScore']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Game?'),
        content: const Text(
          'This will reset your score and all power-ups. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
              showScorePopup("🔄 GAME RESTARTED!\nGood luck!");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showGameOverDialog() {
    // Save game data
    endGame();

    // INTERSTITIAL AD: Show occasionally before game over dialog
    if (CompleteAdManager.instance.shouldShowInterstitialAd()) {
      CompleteAdManager.instance.showInterstitialAd(
        onAdClosed: () => _showGameOverDialog(),
      );
    } else {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Final Score: $score'),
              if (score == highScore)
                const Text(
                  '🏆 NEW HIGH SCORE!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text('High Score: $highScore'),
              Text('Games Played: ${CompleteAdManager.instance.gameCount}'),
              const SizedBox(height: 10),
              const Text('No more space for any piece.'),
            ],
          ),
          actions: [
            // REWARDED AD BUTTON: Get extra power-ups
            if (CompleteAdManager.instance.isRewardedAdReady)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  watchAdForExtraPowerUps();
                },
                icon: const Icon(Icons.play_circle_filled, color: Colors.green),
                label: const Text(
                  'Watch Ad\n+1 Power-ups',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }
}