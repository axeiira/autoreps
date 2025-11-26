import 'package:flutter/material.dart';

/// A widget that displays recent workout stats including total workouts,
/// total reps, and current streak.
class StatsOverview extends StatelessWidget {
  final int totalWorkouts;
  final int totalReps;
  final int currentStreak;

  const StatsOverview({
    super.key,
    required this.totalWorkouts,
    required this.totalReps,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Workouts',
            value: '$totalWorkouts',
            icon: Icons.fitness_center,
            color: const Color(0xFFC7F705),
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Total Reps',
            value: '$totalReps',
            icon: Icons.repeat,
            color: const Color(0xFF94B900),
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Streak',
            value: '$currentStreak',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.white.withOpacity(0.1),
    );
  }
}
