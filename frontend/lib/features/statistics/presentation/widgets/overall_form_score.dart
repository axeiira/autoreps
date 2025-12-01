import 'package:flutter/material.dart';

/// A widget that displays the overall form score as a percentage
/// with a circular progress indicator.
///
/// Example:
/// OverallFormScore(percent: 87, percentColor: Color(0xFF94B900))
class OverallFormScore extends StatelessWidget {
  final int percent;
  final Color percentColor;

  const OverallFormScore({
    super.key,
    required this.percent,
    this.percentColor = const Color(0xFFC7F705),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Overall Form Score',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(percentColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      color: percentColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Form Score',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildScoreBreakdown(),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildScoreStat(
          'Excellent',
          _getExcellentCount(),
          const Color(0xFF94B900),
        ),
        _buildScoreStat('Good', _getGoodCount(), const Color(0xFFC7F705)),
        _buildScoreStat('Needs Work', _getNeedsWorkCount(), Colors.orange),
      ],
    );
  }

  Widget _buildScoreStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
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

  int _getExcellentCount() {
    if (percent >= 90) return 25;
    if (percent >= 80) return 18;
    return 12;
  }

  int _getGoodCount() {
    if (percent >= 90) return 8;
    if (percent >= 80) return 12;
    return 15;
  }

  int _getNeedsWorkCount() {
    if (percent >= 90) return 2;
    if (percent >= 80) return 5;
    return 8;
  }
}
