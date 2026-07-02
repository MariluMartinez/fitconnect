import 'package:flutter/material.dart';

Color getDifficultyColor(String difficulty) {
  switch (difficulty) {
    case 'Beginner':
      return Colors.green;
    case 'Intermediate':
      return Colors.orange;
    case 'Advanced':
      return const Color.fromARGB(255, 236, 164, 159);
    default:
      return Colors.grey;
  }
}

Widget difficultyDot(String difficulty, {double size = 14}) {
  return Icon(
    Icons.circle,
    size: size,
    color: getDifficultyColor(difficulty),
  );
}