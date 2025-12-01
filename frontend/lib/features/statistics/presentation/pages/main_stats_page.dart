import 'package:flutter/material.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';
import 'package:flutter_autoreps/features/statistics/presentation/widgets/weekly_score.dart';
import 'package:flutter_autoreps/features/statistics/presentation/widgets/stats_overview.dart';
import 'package:flutter_autoreps/core/network/api_client.dart';
import 'package:flutter_autoreps/core/config/api_config.dart';
import 'dart:convert';

class MainStatsPage extends StatefulWidget {
  const MainStatsPage({super.key});
  static const routeName = '/stats';

  @override
  State<MainStatsPage> createState() => _MainStatsPageState();
}

class _MainStatsPageState extends State<MainStatsPage> {
  bool _isLoading = true;
  int _totalWorkouts = 0;
  int _totalReps = 0;
  List<int> _weeklyReps = [0, 0, 0, 0, 0, 0, 0];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final apiClient = ApiClient();

      // Fetch summary data
      final summaryResponse = await apiClient.get(
        '${ApiConfig.analytics}/summary',
      );

      if (summaryResponse.statusCode == 200) {
        final summaryData = json.decode(summaryResponse.body);
        _totalWorkouts = summaryData['total_sessions'] ?? 0;
        _totalReps = summaryData['total_reps'] ?? 0;
      }

      // Fetch weekly data
      final weeklyResponse = await apiClient.get(
        '${ApiConfig.analytics}/weekly',
      );

      if (weeklyResponse.statusCode == 200) {
        final weeklyData = json.decode(weeklyResponse.body) as List;
        _processWeeklyData(weeklyData);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  void _processWeeklyData(List<dynamic> data) {
    // Initialize with zeros for all 7 days
    final weekReps = List<int>.filled(7, 0);

    for (var entry in data) {
      final dayStr = entry['day'] as String;
      final reps = entry['reps'] as int? ?? 0;
      final date = DateTime.parse(dayStr);

      // Calculate which day of week (0=Sunday, 6=Saturday)
      final dayOfWeek = date.weekday % 7;
      weekReps[dayOfWeek] = reps;
    }

    _weeklyReps = weekReps;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Statistics',
      currentNavIndex: 2,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadAnalytics();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quick stats overview
                          StatsOverview(
                            totalWorkouts: _totalWorkouts,
                            totalReps: _totalReps,
                          ),
                          const SizedBox(height: 16),

                          // Weekly activity chart (Sun - Sat)
                          WeeklyScore(values: _weeklyReps),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
