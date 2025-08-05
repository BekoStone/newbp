import 'package:flutter/material.dart';
import '../widgets/block_piece_widget.dart';
import '../widgets/simple_banner_ad.dart';
import '../widgets/tutorial_dialog.dart';
import '../services/complete_ad_manager.dart';
import '../services/game_storage.dart';
import '../services/analytics_service.dart';
import '../game/game_logic.dart';
import '../game/game_dialogs.dart';

const int gridSize = 8;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with GameLogic, GameDialogs {
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  // Helper function for smart grid-based dropping
  List<int>? _findClosestValidPositionFromGrid(int targetRow, int targetCol, List<List<int>> piece) {
    // Find ALL valid positions and sort by distance
    List<MapEntry<double, List<int>>> validPositions = [];
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (canPlacePieceAt(row, col, piece)) {
          // Calculate distance from target
          double distance = ((row - targetRow) * (row - targetRow) + 
                           (col - targetCol) * (col - targetCol)).toDouble();
          validPositions.add(MapEntry(distance, [row, col]));
        }
      }
    }

    // Sort by distance (closest first)
    validPositions.sort((a, b) => a.key.compareTo(b.key));
    
    // Return closest valid position
    return validPositions.isNotEmpty ? validPositions.first.value : null;
  }

  Future<void> _initializeGame() async {
    // Load high score
    highScore = await GameStorage.instance.getHighScore();

    // Log screen view
    await AnalyticsService.instance.logScreenView('game_screen');

    // Show tutorial if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTutorialIfNeeded(context);
    });

    generateNewPieces();
    _startNewGame();
  }

  void _startNewGame() {
    gameStartTime = DateTime.now();
    AnalyticsService.instance.logGameStart();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate responsive sizes - RESTORED BIG GRID
    final isTablet = screenWidth > 600;

    // BIGGER GRID: Even more screen space 
    final gridPadding = screenWidth * 0.03; // Less padding = bigger grid
    final availableGridWidth = screenWidth - (gridPadding * 2);
    final maxCellSize = (availableGridWidth - (gridSize - 1) * 2) / gridSize;
    final cellSize = maxCellSize.clamp(35.0, isTablet ? 70.0 : 50.0); // Even bigger cells

    // Calculate exact grid size
    final actualGridSize = (cellSize * gridSize) + ((gridSize - 1) * 2) + 16;

    // NORMAL component heights (restored)
    final powerUpHeight = screenHeight * 0.08; // Back to normal size
    final bannerAdHeight = screenHeight * 0.08; // Back to normal
    // NO SPACING between grid and power-ups
    final spaceBetweenSections = 0.0; // REMOVED spacing

    // Minimal padding
    final topGridPadding = screenHeight * 0.01;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(isTablet),
      body: Container(
        // BACKGROUND: Works with or without image
        decoration: const BoxDecoration(
          // Beautiful gradient background (always works)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0a0a), // Dark black
              Color(0xFF1a1a2e), // Dark blue
              Color(0xFF16213e), // Medium blue  
              Color(0xFF0f3460), // Lighter blue
              Color(0xFF533483), // Purple accent
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
          // OPTIONAL: Uncomment below and add image to assets/images/game_bg.jpg
           image: DecorationImage(
             image: AssetImage('assets/images/game_bg.jpg'),
             fit: BoxFit.cover,
            opacity: 0.3,
           ),
        ),
        child: Column(
          children: [
            // PAUSE OVERLAY (if paused)
            if (isPaused)
              Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Text(
                    'PAUSED',
                    style: TextStyle(
                      fontSize: screenHeight * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            if (!isPaused) ...[
              // MAIN CONTENT - Takes available space
              Expanded(
                child: Column(
                  children: [
                    // SMALL PADDING between app bar and grid
                    SizedBox(height: topGridPadding),

                    // GAME GRID - Big size restored
                    Flexible(
                      flex: 3, // Takes most space
                      child: _buildGameGrid(actualGridSize, gridPadding, cellSize),
                    ),

                    // NO SPACE between grid and power-ups - directly connected
                    
                    // POWER-UP BUTTONS - Normal size restored
                    Container(
                      height: powerUpHeight, // Back to normal size
                      child: _buildPowerUpButtons(
                        powerUpHeight,
                        screenWidth,
                        screenHeight,
                        isTablet,
                      ),
                    ),

                    // DRAGGABLE PIECES - Only this section is compact
                    Flexible(
                      flex: 1, // Takes remaining space
                      child: _buildDraggablePieces(
                        screenWidth,
                        screenHeight,
                        cellSize,
                        topGridPadding,
                        gridPadding,
                      ),
                    ),
                  ],
                ),
              ),

              // BANNER AD - Always at bottom, fixed height
              Container(
                height: bannerAdHeight,
                child: _buildBannerAd(bannerAdHeight, screenWidth),
              ),
            ],
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isTablet) {
    return AppBar(
      title: Column(
        children: [
          Text(
            'Block Puzzle | Score: $score',
            style: TextStyle(color: Colors.black, fontSize: isTablet ? 18 : 16),
          ),
          if (highScore > 0)
            Text(
              'High Score: $highScore',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (comboCount > 1)
            Text(
              'COMBO x$comboCount',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFFFEFD5),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: pauseGame,
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          color: Colors.black,
          iconSize: isTablet ? 28 : 24,
        ),
        IconButton(
          onPressed: showSettingsDialog,
          icon: const Icon(Icons.settings),
          color: Colors.black,
          iconSize: isTablet ? 28 : 24,
        ),
      ],
    );
  }

  Widget _buildGameGrid(
    double actualGridSize,
    double gridPadding,
    double cellSize,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: gridPadding),
      child: Center(
        child: Container(
          width: actualGridSize,
          height: actualGridSize,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6), // Darker for better contrast
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEFD5), width: 3), // Thicker border
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFEFD5).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridSize * gridSize,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              mainAxisSpacing: 2.0, // Reduced spacing for bigger cells
              crossAxisSpacing: 2.0,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              int row = index ~/ gridSize;
              int col = index % gridSize;
              return DragTarget<List<List<int>>>(
                onWillAccept: (piece) => 
                    piece != null && canPlacePieceAt(row, col, piece),
                onAccept: (piece) {
                  // Try exact position first, then find closest if needed
                  int dropRow = row;
                  int dropCol = col;
                  
                  if (!canPlacePieceAt(dropRow, dropCol, piece)) {
                    // Find closest valid position using smart priority
                    var closestPosition = _findClosestValidPositionFromGrid(dropRow, dropCol, piece);
                    if (closestPosition != null) {
                      dropRow = closestPosition[0];
                      dropCol = closestPosition[1];
                    } else {
                      return; // No valid position found
                    }
                  }
                  
                  setState(() {
                    placePieceAt(dropRow, dropCol, piece);
                    availablePieces.remove(piece);
                    if (availablePieces.isEmpty) {
                      generateNewPieces();
                    }
                    if (!canPlaceAnyPiece()) {
                      showGameOverDialog();
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  bool canDrop =
                      candidateData.isNotEmpty &&
                      candidateData.first != null &&
                      canPlacePieceAt(row, col, candidateData.first!);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: canDrop
                          ? Colors.green.withOpacity(0.8) // Brighter green when can drop
                          : grid[row][col] == 1
                          ? Colors.blue.withOpacity(0.9)
                          : Colors.white.withOpacity(0.15), // More visible empty cells
                      border: Border.all(
                        color: canDrop 
                            ? Colors.greenAccent // Bright border when can drop
                            : grid[row][col] == 1 
                            ? Colors.blueAccent
                            : Colors.grey[600]!,
                        width: canDrop ? 3 : 1.5, // Thicker border when can drop
                      ),
                      borderRadius: BorderRadius.circular(4),
                      // GLOW EFFECT when can drop - makes it much easier to see
                      boxShadow: canDrop ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpButtons(
    double powerUpHeight,
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    return Container(
      height: powerUpHeight,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFD5).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12), // Normal radius restored
        border: Border.all(color: Colors.grey[400]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8, // Normal shadow restored
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02, // Normal padding restored
        vertical: screenHeight * 0.005,
      ),
      child: Row(
        children: [
          // Clear power-up - NORMAL SIZE RESTORED
          Expanded(
            child: ElevatedButton.icon(
              onPressed: undoCount > 0 ? useUndo : null,
              icon: Icon(Icons.cleaning_services, size: isTablet ? 20 : 16), // Normal icons
              label: Text(
                'Clear ($undoCount)',
                style: TextStyle(fontSize: isTablet ? 14 : 10), // Normal text
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: undoCount > 0 ? Colors.orange : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.01, // Normal padding
                  vertical: screenHeight * 0.008,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.01), // Normal spacing

          // Blast power-up - NORMAL SIZE RESTORED
          Expanded(
            child: ElevatedButton.icon(
              onPressed: bombCount > 0 ? useBomb : null,
              icon: Icon(Icons.flash_on, size: isTablet ? 20 : 16),
              label: Text(
                'Blast ($bombCount)',
                style: TextStyle(fontSize: isTablet ? 14 : 10),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: bombCount > 0 ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.01,
                  vertical: screenHeight * 0.008,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.01),

          // Shuffle power-up - NORMAL SIZE RESTORED
          Expanded(
            child: ElevatedButton.icon(
              onPressed: shuffleCount > 0 ? useShuffle : null,
              icon: Icon(Icons.shuffle, size: isTablet ? 20 : 16),
              label: Text(
                'Shuffle ($shuffleCount)',
                style: TextStyle(fontSize: isTablet ? 14 : 10),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: shuffleCount > 0 ? Colors.purple : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.01,
                  vertical: screenHeight * 0.008,
                ),
              ),
            ),
          ),

          // Watch Ad button - NORMAL SIZE RESTORED
          if ((undoCount == 0 || bombCount == 0 || shuffleCount == 0) &&
              CompleteAdManager.instance.isRewardedAdReady) ...[
            SizedBox(width: screenWidth * 0.01),
            ElevatedButton.icon(
              onPressed: watchAdForExtraPowerUps,
              icon: Icon(Icons.play_circle_filled, size: isTablet ? 18 : 14), // Normal size
              label: Text(
                'Ad\n+1',
                style: TextStyle(fontSize: isTablet ? 12 : 8), // Normal text
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.01,
                  vertical: screenHeight * 0.008,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraggablePieces(
    double screenWidth,
    double screenHeight,
    double cellSize,
    double topGridPadding,
    double gridPadding,
  ) {
    // FIXED SMALL SIZES - not based on grid cellSize
    final smallCellSize = 24.0; // Fixed small size for resting pieces
    final draggingCellSize = 28.0; // Fixed size when dragging
    final placeholderCellSize = 12.0; // Fixed tiny size for placeholder
    
    return Container(
      width: double.infinity,
      height: screenHeight * 0.12, // Fixed small container height
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.008, // Small padding
        horizontal: screenWidth * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          availablePieces.length,
          (index) => Expanded(
            child: Center(
              child: Draggable<List<List<int>>>(
                data: availablePieces[index],
                // FEEDBACK: Fixed dragging size
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: BlockPieceWidget(
                      piece: availablePieces[index],
                      cellSize: draggingCellSize, // Fixed 28px when dragging
                      opacity: 0.9,
                      scale: 1.0, // No scaling needed
                    ),
                  ),
                ),
                // PLACEHOLDER: Fixed tiny size
                childWhenDragging: BlockPieceWidget(
                  piece: availablePieces[index],
                  cellSize: placeholderCellSize, // Fixed 12px placeholder
                  opacity: 0.2,
                  scale: 1.0, // No scaling needed
                ),
                onDragEnd: (details) {
                  // SMART DROP: Always try to find closest position (no velocity requirement)
                  if (!details.wasAccepted && availablePieces.length > index) {
                    var closestPosition = findClosestValidPosition(
                      details.offset.dx,
                      details.offset.dy,
                      availablePieces[index],
                      cellSize,
                      topGridPadding + kToolbarHeight,
                      gridPadding,
                    );

                    if (closestPosition != null) {
                      setState(() {
                        placePieceAt(
                          closestPosition[0],
                          closestPosition[1],
                          availablePieces[index],
                        );
                        availablePieces.removeAt(index);
                        if (availablePieces.isEmpty) {
                          generateNewPieces();
                        }
                        if (!canPlaceAnyPiece()) {
                          showGameOverDialog();
                        }
                      });
                    }
                  }
                },
                // RESTING STATE: Fixed small size
                child: BlockPieceWidget(
                  piece: availablePieces[index],
                  cellSize: smallCellSize, // Fixed 18px when resting
                  scale: 1.0, // No scaling needed
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerAd(double bannerAdHeight, double screenWidth) {
    return Container(
      height: bannerAdHeight,
      width: double.infinity,
      color: Colors.black.withOpacity(0.8), // Semi-transparent
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: const SimpleBannerAd(),
    );
  }
}