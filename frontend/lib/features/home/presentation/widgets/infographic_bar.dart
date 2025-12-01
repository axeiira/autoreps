import 'package:flutter/material.dart';
import 'package:flutter_autoreps/features/user_plan/presentation/user_plan.dart';
import 'package:flutter_autoreps/features/user_plan/data/repositories/user_profile_repository.dart';
import 'package:flutter_autoreps/features/user_plan/data/models/user_profile.dart';

/// InfographicBar
///
/// A small summary bar used on the home screen. It's based on the provided
/// prototype but implemented as a reusable widget.
class InfographicBar extends StatefulWidget {
  final String title;
  final VoidCallback? onModify;
  final double width;
  final double height;

  const InfographicBar({
    super.key,
    this.title = 'User Training',
    this.onModify,
    this.width = 342,
    this.height = 60,
  });

  @override
  State<InfographicBar> createState() => _InfographicBarState();
}

class _InfographicBarState extends State<InfographicBar> {
  final _profileRepository = UserProfileRepository();
  bool _isLoading = true;
  int _reps = 0;
  int _sets = 0;
  String _formCondition = '-';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _profileRepository.getProfile();

      if (profile != null) {
        final calculated = _calculateRecommendation(profile);
        setState(() {
          _reps = calculated['reps'] as int;
          _sets = calculated['sets'] as int;
          _formCondition = 'Good';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No profile found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load';
        _isLoading = false;
      });
    }
  }

  /// Calculate recommended reps and sets based on user profile
  Map<String, int> _calculateRecommendation(UserProfile profile) {
    int reps = 12; // default
    int sets = 2; // default

    // Calculate based on experience level
    switch (profile.experienceLevel) {
      case 'Beginner':
        reps = 8;
        sets = 2;
        break;
      case 'Intermediate':
        reps = 12;
        sets = 3;
        break;
      case 'Advanced':
        reps = 15;
        sets = 4;
        break;
    }

    // Adjust based on goal
    switch (profile.primaryGoal) {
      case 'Lose weight':
        reps += 3;
        sets += 1;
        break;
      case 'Build strength':
        reps += 2;
        break;
      case 'Improve endurance':
        reps += 5;
        sets += 1;
        break;
    }

    // Adjust based on age
    if (profile.age > 50) {
      reps = (reps * 0.8).round();
    } else if (profile.age < 25) {
      reps = (reps * 1.1).round();
    }

    return {'reps': reps, 'sets': sets};
  }

  @override
  void dispose() {
    _profileRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );
    final titleStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );
    final valueStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF9A9A9A),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: Color(0xFF9A9A9A),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: Colors.white, // explicit white background per design
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            children: [
              // Left icon placeholder (you can replace with an Avatar or SVG)
              Positioned(
                left: 4,
                top: (widget.height - 25) / 2,
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: CircleAvatar(
                    radius: 12.5,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              // Title
              Positioned(
                left: 48,
                top: 12,
                child: Text(widget.title, style: titleStyle),
              ),

              // Modify button
              Positioned(
                left: 48,
                top: 30,
                child: GestureDetector(
                  onTap:
                      widget.onModify ??
                      () async {
                        await Navigator.pushNamed(
                          context,
                          UserPlanPage.routeName,
                        );
                        // Reload profile after returning from user plan page
                        _loadProfile();
                      },
                  child: Container(
                    width: 80,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Modify',
                      textAlign: TextAlign.center,
                      style:
                          theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),

              // Column labels (Reps / Set / Form Condition)
              Positioned(
                left: 156,
                top: 12,
                child: Text('Reps', style: labelStyle),
              ),
              Positioned(
                left: 200,
                top: 12,
                child: Text('Set', style: labelStyle),
              ),
              Positioned(
                left: 248,
                top: 12,
                child: Text('Form', style: labelStyle),
              ),

              // Values - Show loading or error states
              if (_isLoading)
                Positioned(
                  left: 156,
                  top: 28,
                  child: SizedBox(
                    width: 120,
                    child: Text('Loading...', style: valueStyle),
                  ),
                )
              else if (_error != null)
                Positioned(
                  left: 156,
                  top: 28,
                  child: SizedBox(
                    width: 120,
                    child: Text(
                      _error!,
                      style: valueStyle.copyWith(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
              else ...[
                Positioned(
                  left: 156,
                  top: 28,
                  child: Text('$_reps', style: valueStyle),
                ),
                Positioned(
                  left: 200,
                  top: 28,
                  child: Text('$_sets', style: valueStyle),
                ),
                Positioned(
                  left: 248,
                  top: 28,
                  child: Text(
                    _formCondition,
                    style: valueStyle.copyWith(color: const Color(0xFF94B900)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
