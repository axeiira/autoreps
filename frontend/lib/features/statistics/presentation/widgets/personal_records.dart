import 'package:flutter/material.dart';

/// A widget that displays personal squat records and achievements.
class PersonalRecords extends StatelessWidget {
  final int bestSingleSet;
  final int bestDailyTotal;
  final int longestStreak;

  const PersonalRecords({
    super.key,
    required this.bestSingleSet,
    required this.bestDailyTotal,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: const Color(0xFFC7F705),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Squat Records',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecordItem('Best Single Set', bestSingleSet, 'reps'),
          const SizedBox(height: 8),
          _buildRecordItem('Best Daily Total', bestDailyTotal, 'reps'),
          const SizedBox(height: 8),
          _buildRecordItem('Longest Streak', longestStreak, 'days'),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String label, int value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFC7F705).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value $unit',
            style: const TextStyle(
              color: Color(0xFFC7F705),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
