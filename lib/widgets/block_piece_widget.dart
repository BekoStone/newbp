import 'package:flutter/material.dart';

class BlockPieceWidget extends StatelessWidget {
  final List<List<int>> piece;
  final double opacity;
  final double cellSize;
  final double scale; // NEW: Scale factor for resizing

  const BlockPieceWidget({
    super.key,
    required this.piece,
    this.opacity = 1.0,
    this.cellSize = 30.0,
    this.scale = 1.0, // Default: no scaling
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive spacing
    final spacing = (cellSize * 0.05).clamp(1.0, 3.0); // 5% of cell size, min 1px, max 3px
    final borderRadius = (cellSize * 0.08).clamp(2.0, 6.0); // 8% of cell size
    final borderWidth = (cellSize * 0.04).clamp(1.0, 2.0); // 4% of cell size
    
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: piece.map((row) => 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) => 
              Container(
                width: cellSize,
                height: cellSize,
                margin: EdgeInsets.all(spacing),
                decoration: cell == 1 ? BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.orange[300]!, 
                    width: borderWidth,
                  ),
                  // Add shadow for better visual depth
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: cellSize * 0.1,
                      offset: Offset(cellSize * 0.02, cellSize * 0.02),
                    ),
                  ],
                ) : null, // OPTIMIZED: Only create decoration when needed
              )
            ).toList(),
          )
        ).toList(),
      ),
    );
  }
}