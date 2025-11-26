import 'package:flutter/material.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';
import 'package:flutter_autoreps/features/statistics/presentation/widgets/overall_form_score.dart';
import 'package:flutter_autoreps/features/statistics/presentation/widgets/weekly_score.dart';
import 'package:flutter_autoreps/features/statistics/presentation/widgets/stats_overview.dart';
import 'package:flutter_autoreps/features/statistics/presentation/widgets/personal_records.dart';

class MainStatsPage extends StatelessWidget {
	const MainStatsPage({super.key});
	static const routeName = '/stats';

	@override
	Widget build(BuildContext context) {
		return AppScaffold(
			title: 'Statistics',
			currentNavIndex: 2,
			body: SafeArea(
				child: SingleChildScrollView(
					child: Padding(
						padding: const EdgeInsets.only(top: 20.0),
						child: Align(
							alignment: Alignment.topCenter,
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									// Quick stats overview
									const StatsOverview(
										totalWorkouts: 42,
										totalReps: 1250,
										currentStreak: 7,
									),
									const SizedBox(height: 16),
									
									// Overall form score with circular progress
									const OverallFormScore(
										percent: 87,
										percentColor: Color(0xFF94B900),
									),
									const SizedBox(height: 16),
									
									// Weekly activity chart (Sun - Sat)
									const WeeklyScore(
										values: [10, 12, 8, 0, 5, 18, 9],
									),
									const SizedBox(height: 16),
									
									// Squat personal records
									const PersonalRecords(
										bestSingleSet: 45,
										bestDailyTotal: 120,
										longestStreak: 14,
									),
									const SizedBox(height: 32),
								],
							),
						),
					),
				),
			),
		);
	}
}
