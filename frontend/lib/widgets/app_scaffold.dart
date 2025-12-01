import 'package:flutter/material.dart';
import 'package:flutter_autoreps/widgets/navbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBottomNav;
  final int currentNavIndex;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBottomNav = true,
    this.currentNavIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        elevation: 0,
        centerTitle: true,
        // increase leading slot width so the 'AUTOREPS' label can fit on one line
        leadingWidth: 120,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        leading: const Padding(
          padding: EdgeInsets.only(left: 30.0),
          child: SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'AUTO',
                      style: TextStyle(
                        color: Color(0xFFC7F705), // match logo green
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: 'REPS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: SvgPicture.asset(
              'lib/assets/shared/Logo.svg',
              width: 48,
              height: 17,
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: body,
      bottomNavigationBar: showBottomNav
          ? AppNavBar(currentIndex: currentNavIndex)
          : null,
    );
  }
}
