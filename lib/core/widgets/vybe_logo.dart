import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Vybe Cabs mark: a rounded violet tile with a car glyph, optionally
/// followed by the wordmark.
class VybeLogo extends StatelessWidget {
  const VybeLogo({super.key, this.size = 88, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.violet, AppTheme.violetDim],
            ),
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.violet.withValues(alpha: 0.35),
                blurRadius: size * 0.35,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: Icon(
            Icons.local_taxi_rounded,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.24),
          Text(
            'Vybe Cabs',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: size * 0.06),
          Text(
            'Your ride, your vybe',
            style: TextStyle(
              fontSize: size * 0.15,
              color: AppTheme.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
