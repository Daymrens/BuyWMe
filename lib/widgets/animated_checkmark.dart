import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnimatedCheckmark extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onTap;
  final double size;

  const AnimatedCheckmark({
    super.key,
    required this.isChecked,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isChecked ? AppTheme.primaryGreen : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isChecked ? AppTheme.primaryGreen : Colors.grey,
            width: 2,
          ),
        ),
        child: isChecked
            ? Icon(
                Icons.check,
                size: size * 0.7,
                color: Colors.white,
              )
                .animate()
                .scale(
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 100.ms)
            : null,
      ),
    );
  }
}
