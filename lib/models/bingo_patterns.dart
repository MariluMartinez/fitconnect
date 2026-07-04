const List<String> bingoPatternNames = [
  'X',
  'Plus',
  'Diamond',
  'T',
  'U',
  'Arrow',
  'Heart',
  'Lightning Bolt',
  'Crown',
  'Shield',
  'Hourglass',
  'Spiral',
];
const List<Set<int>> bingoPatterns = [
  // X - 9 tiles
  {0, 4, 6, 8, 12, 16, 18, 20, 24},

  // Plus - 9 tiles
  {2, 7, 10, 11, 12, 13, 14, 17, 22},

  // Diamond - 9 tiles
  {2, 6, 8, 10, 12, 14, 16, 18, 22},

  // T - 8 tiles
  {0, 1, 2, 3, 4, 7, 12, 17, 22},

  // U - 13 tiles
  {0, 5, 10, 15, 20, 4, 9, 14, 19, 24, 21, 22, 23},

  // Arrow - 9 tiles
  {2, 6, 8, 10, 11, 12, 13, 14, 17, 22},

  // Heart - 10 tiles
  {1, 3, 5, 7, 9, 10, 14, 16, 18, 22},

  // Lightning Bolt - 8 tiles
  {3, 7, 11, 12, 13, 17, 21, 20},

  // Crown - 11 tiles
  {0, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14},

  // Shield - 12 tiles
  {1, 2, 3, 5, 9, 10, 14, 16, 18, 21, 22, 23},

  // Hourglass - 13 tiles
  {0, 1, 2, 3, 4, 6, 8, 12, 16, 18, 20, 21, 22},

  // Spiral - 13 tiles
  {0, 1, 2, 3, 4, 9, 14, 19, 24, 23, 22, 21, 20},
];
