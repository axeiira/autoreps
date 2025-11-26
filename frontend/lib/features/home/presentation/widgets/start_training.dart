import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_autoreps/features/record/presentation/cam.dart';

/// StartTrainingCard
///
/// A card that shows a large training panel with a dumbell SVG and a start
/// button. Uses the provided prototype layout and the included SVG assets.
class StartTrainingCard extends StatelessWidget {
    final double width;
    final double height;
    final VoidCallback? onStart;
    final Color? backgroundColor;

    const StartTrainingCard({
        super.key,
        this.width = 342,
        this.height = 328,
        this.onStart,
        this.backgroundColor,
    });

    @override
    Widget build(BuildContext context) {

        return SizedBox(
            width: width,
            height: height,
            child: Stack(
                children: [
                    // Rounded card with white border (prototype)
                    Positioned.fill(
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white, width: 7),
                            ),
                        ),
                    ),

                    // Dumbbell SVG centered within the card (no absolute positioning)
                    Positioned.fill(
                        child: Center(
                            child: Transform.rotate(
                                angle: 0,
                                child: SizedBox(
                                    width: 261,
                                    height: 261,
                                    child: SvgPicture.asset(
                                        'assets/images/dumbell.svg',
                                        fit: BoxFit.contain,
                                    ),
                                ),
                            ),
                        ),
                    ),

                    // Start button (SVG) with touch handler
                    Positioned(
                        left: 152,
                        top: 250,
                        child: GestureDetector(
                            onTap: onStart ?? () => Navigator.pushNamed(context, CameraPage.routeName),
                            child: SizedBox(
                                width: 38,
                                height: 38,
                                child: SvgPicture.asset('assets/images/start.svg'),
                            ),
                        ),
                    ),

                    // 'Start' label below button
                    Positioned(
                        left: 142,
                        top: 269 + 20,
                        child: SizedBox(
                            width: 58,
                            child: Text(
                                'Start',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}