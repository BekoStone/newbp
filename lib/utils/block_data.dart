import 'dart:math';

final List<List<List<int>>> blockShapes = [
  // Original 7 pieces
  [
    [1]
  ],
  [
    [1, 1]
  ],
  [
    [1],
    [1]
  ],
  [
    [1, 1, 1]
  ],
  [
    [1],
    [1],
    [1]
  ],
  [
    [1, 1],
    [1, 1]
  ],
  [
    [0, 1, 0],
    [1, 1, 1]
  ],
  
  // NEW: 3 Additional pieces for more variety
  [
    [1, 0],
    [1, 0],
    [1, 1]
  ], // L-shape
  
  [
    [0, 1],
    [0, 1],
    [1, 1]
  ], // Reverse L-shape
  
  [
    [1, 1, 0],
    [0, 1, 1]
  ], // Z-shape
];

List<List<int>> getRandomPiece() {
  final random = Random();
  return blockShapes[random.nextInt(blockShapes.length)];
}