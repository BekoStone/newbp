import 'package:flutter/material.dart';
import '../utils/block_data.dart';
import '../services/complete_ad_manager.dart';
import '../services/game_storage.dart';
import '../services/analytics_service.dart';

const int gridSize = 8;

mixin GameLogic<T extends StatefulWidget> on State<T> {
  // Game state variables
  List<List<int>> grid = List.generate(
    gridSize,
    (_) => List.generate(gridSize, (_) => 0),
  );
  List<List<List<int>>> availablePieces = [];
  int score = 0;
  int highScore = 0;
  bool isPaused = false;
  int comboCount = 0;
  int lastClearedLines = 0;
  DateTime? gameStartTime;

  // POWER-UP USAGE LIMITS (All start with 2)
  int undoCount = 2;
  int bombCount = 2;
  int shuffleCount = 2;

  void generateNewPieces() {
    setState(() {
      availablePieces = List.generate(3, (_) => getRandomPiece());
    });
  }

  bool canPlacePieceAt(int row, int col, List<List<int>> piece) {
    for (int i = 0; i < piece.length; i++) {
      for (int j = 0; j < piece[i].length; j++) {
        if (piece[i][j] == 1) {
          int newRow = row + i;
          int newCol = col + j;
          if (newRow >= gridSize ||
              newCol >= gridSize ||
              grid[newRow][newCol] == 1) {
            return false;
          }
        }
      }
    }
    return true;
  }

  List<int>? findClosestValidPosition(
    double globalX,
    double globalY,
    List<List<int>> piece,
    double cellSize,
    double gridStartY,
    double gridStartX,
  ) {
    int targetRow = ((globalY - gridStartY) / (cellSize + 3)).round().clamp(
      0,
      gridSize - 1,
    );
    int targetCol = ((globalX - gridStartX) / (cellSize + 3)).round().clamp(
      0,
      gridSize - 1,
    );

    if (canPlacePieceAt(targetRow, targetCol, piece)) {
      return [targetRow, targetCol];
    }

    for (int radius = 1; radius <= 3; radius++) {
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          if (dr.abs() == radius || dc.abs() == radius) {
            int row = targetRow + dr;
            int col = targetCol + dc;
            if (row >= 0 && col >= 0 && row < gridSize && col < gridSize) {
              if (canPlacePieceAt(row, col, piece)) {
                return [row, col];
              }
            }
          }
        }
      }
    }
    return null;
  }

  void placePieceAt(int row, int col, List<List<int>> piece) {
    int piecePoints = 0;
    for (int i = 0; i < piece.length; i++) {
      for (int j = 0; j < piece[i].length; j++) {
        if (piece[i][j] == 1) {
          grid[row + i][col + j] = 1;
          piecePoints++;
        }
      }
    }

    bool isCornerPlacement =
        (row <= 1 && col <= 1) ||
        (row <= 1 && col >= gridSize - 2) ||
        (row >= gridSize - 2 && col <= 1) ||
        (row >= gridSize - 2 && col >= gridSize - 2);

    int placementBonus = isCornerPlacement ? 5 : 0;

    setState(() {
      score += piecePoints + placementBonus;
    });

    // Analytics: Log piece placement
    int gridFillPercentage = _calculateGridFillPercentage();
    AnalyticsService.instance.logPiecePlace(
      pieceSize: piecePoints,
      isCornerPlacement: isCornerPlacement,
      gridFillPercentage: gridFillPercentage,
    );

    clearFullLines();
  }

  int _calculateGridFillPercentage() {
    int filledCells = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 1) filledCells++;
      }
    }
    return ((filledCells / (gridSize * gridSize)) * 100).round();
  }

  void clearFullLines() {
    int clearedLines = 0;

    for (int row = gridSize - 1; row >= 0; row--) {
      if (grid[row].every((cell) => cell == 1)) {
        for (int col = 0; col < gridSize; col++) {
          grid[row][col] = 0;
        }
        clearedLines++;
      }
    }

    for (int col = 0; col < gridSize; col++) {
      bool isFullColumn = true;
      for (int row = 0; row < gridSize; row++) {
        if (grid[row][col] == 0) {
          isFullColumn = false;
          break;
        }
      }
      if (isFullColumn) {
        for (int row = 0; row < gridSize; row++) {
          grid[row][col] = 0;
        }
        clearedLines++;
      }
    }

    if (clearedLines > 0) {
      int basePoints = 0;

      switch (clearedLines) {
        case 1:
          basePoints = 10;
          break;
        case 2:
          basePoints = 25;
          break;
        case 3:
          basePoints = 50;
          break;
        default:
          basePoints = 100;
          break;
      }

      if (lastClearedLines > 0) {
        comboCount++;
      } else {
        comboCount = 1;
      }

      int comboMultiplier = 1;
      switch (comboCount) {
        case 2:
          comboMultiplier = 2;
          break;
        case 3:
          comboMultiplier = 3;
          break;
        case 4:
        default:
          comboMultiplier = 5;
          break;
      }

      int finalPoints = basePoints * comboMultiplier;
      lastClearedLines = clearedLines;

      setState(() {
        score += finalPoints;
      });

      // Analytics: Log level complete
      AnalyticsService.instance.logLevelComplete(
        score: finalPoints,
        linesCleared: clearedLines,
        comboCount: comboCount,
      );

      if (comboMultiplier > 1) {
        showScorePopup("COMBO x$comboMultiplier\n+$finalPoints points!");
      } else if (clearedLines >= 3) {
        showScorePopup("AWESOME!\n+$finalPoints points!");
      }
    } else {
      lastClearedLines = 0;
      comboCount = 0;
    }
  }

  void showScorePopup(String message) {
    final screenHeight = MediaQuery.of(context).size.height;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: screenHeight * 0.022,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: screenHeight * 0.12,
          left: screenHeight * 0.06,
          right: screenHeight * 0.06,
        ),
      ),
    );
  }

  bool canPlaceAnyPiece() {
    for (var piece in availablePieces) {
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          if (canPlacePieceAt(row, col, piece)) return true;
        }
      }
    }
    return false;
  }

  // REWARDED AD FUNCTION
  void watchAdForExtraPowerUps() {
    CompleteAdManager.instance.showRewardedAd(
      onRewarded: () {
        setState(() {
          undoCount += 1;
          bombCount += 1;
          shuffleCount += 1;
        });

        // Analytics: Log rewarded ad completion
        AnalyticsService.instance.logRewardedAdCompleted(
          rewardType: 'power_ups',
          rewardAmount: 3,
        );

        showScorePopup("🎁 REWARD EARNED!\n+1 to all power-ups!");
      },
      onAdClosed: () {
        print('Rewarded ad closed');
      },
    );
  }

  void useBomb() {
    if (bombCount <= 0) {
      showScorePopup("NO BLASTS LEFT!");
      return;
    }

    int centerRow = gridSize ~/ 2;
    int centerCol = gridSize ~/ 2;
    int clearedBlocks = 0;

    // Clear 3x3 area around center
    for (int i = centerRow - 1; i <= centerRow + 1; i++) {
      for (int j = centerCol - 1; j <= centerCol + 1; j++) {
        if (i >= 0 && i < gridSize && j >= 0 && j < gridSize) {
          if (grid[i][j] == 1) {
            grid[i][j] = 0;
            clearedBlocks++;
          }
        }
      }
    }

    setState(() {
      score += clearedBlocks * 5;
      bombCount--;
    });

    // Analytics: Log power-up usage
    AnalyticsService.instance.logPowerUpUsed(
      powerUpType: 'blast',
      remainingCount: bombCount,
    );

    if (clearedBlocks > 0) {
      showScorePopup(
        "⚡ BLAST! Cleared $clearedBlocks blocks\n+${clearedBlocks * 5} pts | Blasts left: $bombCount",
      );
    } else {
      showScorePopup(
        "⚡ BLAST! No blocks in center area\nBlasts left: $bombCount",
      );
    }
  }

  void useShuffle() {
    if (shuffleCount <= 0) {
      showScorePopup("NO SHUFFLES LEFT!");
      return;
    }

    setState(() {
      availablePieces = List.generate(3, (_) => getRandomPiece());
      score += 10;
      shuffleCount--;
    });

    // Analytics: Log power-up usage
    AnalyticsService.instance.logPowerUpUsed(
      powerUpType: 'shuffle',
      remainingCount: shuffleCount,
    );

    showScorePopup("SHUFFLED! +10 pts\nShuffles left: $shuffleCount");
  }

  void useUndo() {
    if (undoCount <= 0) {
      showScorePopup("NO UNDOS LEFT!");
      return;
    }

    int clearedCells = 0;
    for (int i = 0; i < gridSize && clearedCells < 5; i++) {
      for (int j = 0; j < gridSize && clearedCells < 5; j++) {
        if (grid[i][j] == 1) {
          grid[i][j] = 0;
          clearedCells++;
        }
      }
    }

    setState(() {
      score += clearedCells * 2;
      undoCount--;
    });

    // Analytics: Log power-up usage
    AnalyticsService.instance.logPowerUpUsed(
      powerUpType: 'undo',
      remainingCount: undoCount,
    );

    if (clearedCells > 0) {
      showScorePopup("UNDO! +${clearedCells * 2} pts\nUndos left: $undoCount");
    }
  }

  void pauseGame() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void resetGame() {
    setState(() {
      grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
      generateNewPieces();
      score = 0;
      isPaused = false;
      comboCount = 0;
      lastClearedLines = 0;
      // Reset power-up counts (All start with 2)
      undoCount = 2;
      bombCount = 2;
      shuffleCount = 2;
    });

    gameStartTime = DateTime.now();
    AnalyticsService.instance.logGameStart();
  }

  Future<void> endGame() async {
    if (gameStartTime != null) {
      final duration = DateTime.now().difference(gameStartTime!).inSeconds;
      final isHighScore = await GameStorage.instance.setHighScore(score);

      // Update high score display
      if (isHighScore) {
        setState(() {
          highScore = score;
        });
      }

      // Record game statistics
      await GameStorage.instance.recordGamePlayed(score);

      // Analytics: Log game end
      await AnalyticsService.instance.logGameEnd(
        score: score,
        duration: duration,
        isHighScore: isHighScore,
      );
    }
  }
}
