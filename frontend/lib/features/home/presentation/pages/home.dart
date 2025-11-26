import 'package:flutter/material.dart';
import 'package:flutter_autoreps/features/home/presentation/widgets/streak.dart';
import 'package:flutter_autoreps/features/home/presentation/widgets/infographic_bar.dart';
import 'package:flutter_autoreps/features/home/presentation/widgets/start_training.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';

class HomePage extends StatefulWidget {
	const HomePage({super.key});
	static const routeName = '/home';

	@override
	State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
	@override
	Widget build(BuildContext context) {
			return AppScaffold(
				title: 'Home',
				currentNavIndex: 0,
				body: SafeArea(
					child: SingleChildScrollView(
						child: Padding(
							padding: const EdgeInsets.only(top: 32.0),
							child: Align(
								alignment: Alignment.topCenter,
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: const [
										StreakCard(),
										SizedBox(height: 16),
										InfographicBar(),
										SizedBox(height: 32),
										StartTrainingCard(),
									],
								),
							),
						),
					),
				),
			);
	}
}

