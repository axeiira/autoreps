import 'package:flutter/material.dart';

/// A widget that displays a weekly activity chart showing workout counts
/// for each day of the week (Sun - Sat).
///
/// Example:
/// WeeklyScore(values: [10, 12, 8, 0, 5, 18, 9])
class WeeklyScore extends StatelessWidget {
  final List<int> values;
  final Color barColor;

  const WeeklyScore({
    super.key,
    required this.values,
    this.barColor = const Color(0xFFC7F705),
  });

  @override
  Widget build(BuildContext context) {
    assert(
      values.length == 7,
      'WeeklyScore requires exactly 7 values (Sun-Sat)',
    );

    final maxValue = values.reduce((a, b) => a > b ? a : b);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${values.reduce((a, b) => a + b)} reps',
                style: TextStyle(
                  color: barColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildBars(maxValue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildDayLabels(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBars(int maxValue) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return List.generate(7, (index) {
      final value = values[index];
      final heightPercent = maxValue > 0 ? value / maxValue : 0.0;
      final barHeight = 150 * heightPercent;

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$value',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(height: 16),
          Container(
            width: 32,
            height: barHeight.clamp(4.0, 150.0),
            decoration: BoxDecoration(
              color: value > 0 ? barColor : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _buildDayLabels() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return List.generate(7, (index) {
      final isToday = DateTime.now().weekday % 7 == index;
      return SizedBox(
        width: 32,
        child: Text(
          days[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isToday ? barColor : Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      );
    });
  }
}
