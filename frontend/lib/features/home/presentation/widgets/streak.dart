import 'package:flutter/material.dart';
import 'package:flutter_autoreps/features/home/data/repositories/workout_repository.dart';

/// A small card that displays how many days the current training streak is.
///
/// - Fixed size: width 232, height 116
/// - Content centered
///
/// Example:
/// StreakCard()
class StreakCard extends StatefulWidget {
  final Color? backgroundColor;

  const StreakCard({super.key, this.backgroundColor});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  final _workoutRepository = WorkoutRepository();
  int _days = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _workoutRepository.getWorkoutHistory();
      final streak = _workoutRepository.calculateStreak(sessions);

      setState(() {
        _days = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _days = 0;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _workoutRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to no background so the card doesn't show a solid purple box.
    final bg = widget.backgroundColor ?? Colors.transparent;

    // Figma-inspired design: large number on left, 'days' and 'Streak' on right
    return SizedBox(
      width: 232,
      height: 116,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Big number on the left
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: 129,
                  height: 116,
                  child: Align(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              '$_days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 128,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              // 'days' label
              Positioned(
                left: 100,
                top: 32,
                child: Text(
                  'days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'Anek Tamil',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // 'Streak' label with accent color
              Positioned(
                left: 100,
                top: 63,
                child: Text(
                  'Streak',
                  style: const TextStyle(
                    color: Color(0xFFC7F705),
                    fontSize: 32,
                    fontFamily: 'Anek Tamil',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
