import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A reusable animated developer credit widget.
/// Each credit line fades in/out separately in a loop.
class DeveloperCredit extends StatefulWidget {
  /// Whether to show a compact version (for bottom of screens).
  /// When true, shows only one line at a time in a smaller font.
  final bool compact;

  const DeveloperCredit({super.key, this.compact = true});

  @override
  State<DeveloperCredit> createState() => _DeveloperCreditState();
}

class _DeveloperCreditState extends State<DeveloperCredit>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  int _currentIndex = 0;
  Timer? _switchTimer;

  final List<_CreditItem> _credits = const [
    _CreditItem(
      text: 'تطوير: عبدالرحمن إبراهيم',
      icon: Icons.code_rounded,
    ),
    _CreditItem(
      text: 'تصميم: شهد ناجح',
      icon: Icons.palette_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Start first fade-in
    _fadeController.forward(from: 0);
    // Switch to next credit periodically
    _switchTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _switchCredit();
    });
  }

  void _switchCredit() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _credits.length;
        });
        _fadeController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _switchTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final credit = _credits[_currentIndex];
    final fontSize = widget.compact ? 10.0 : 13.0;
    final iconSize = widget.compact ? 12.0 : 16.0;
    final verticalPadding = widget.compact ? 8.0 : 16.0;

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              credit.icon,
              size: iconSize,
              color: AppColors.primary.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              credit.text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.primary.withOpacity(0.6),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditItem {
  final String text;
  final IconData icon;

  const _CreditItem({required this.text, required this.icon});
}
