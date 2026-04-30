enum BingoGoalType { 
  steps, 
  distance, 
  activeMinutes 
}

class BingoGoal {
  final BingoGoalType type;
  final String label;
  final double requiredValue;

  BingoGoal({
    required this.type,
    required this.label,
    required this.requiredValue,
  });
}
