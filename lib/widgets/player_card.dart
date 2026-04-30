import 'dart:math';
import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final Set<int> targetShapeSquares;
  final Set<int>? completedSquares;

  const PlayerCard({
    super.key,
    required this.name,
    required this.targetShapeSquares,
    this.completedSquares,
  });

  @override
  Widget build(BuildContext context) {
    final Set<int> displayCompletedSquares;

    if (completedSquares != null) {
      displayCompletedSquares = completedSquares!;
    } else {
      final random = Random(name.hashCode);

      final targetList = targetShapeSquares.toList();
      targetList.shuffle(random);

      final completedCount = random.nextInt(targetShapeSquares.length + 1);
      displayCompletedSquares = targetList.take(completedCount).toSet();
    }

    final completedTargetCount = displayCompletedSquares
        .where((index) => targetShapeSquares.contains(index))
        .length;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(Icons.person, size: 18),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 55,
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 25,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final isTarget = targetShapeSquares.contains(index);
                    final isCompleted = displayCompletedSquares.contains(index);

                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isTarget
                            ? Colors.white
                            : Colors.grey.shade300,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '$completedTargetCount/${targetShapeSquares.length} tiles',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
