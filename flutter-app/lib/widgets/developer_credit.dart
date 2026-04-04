import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Animated developer credit widget.
/// Each name appears separately with fade in/out effect.
class DeveloperCredit extends StatefulWidget {
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
      text: '\u062A\u0637\u0648\u064A\u0631: \u0639\u0628\u062F\u0627\u0644\u0631\u062D\u0645\u0646 \u0625\u0628\u0631\u0627\u0647\u064A\u0645',
      icon: Icons.code_rounded,
    ),
    _CreditItem(
      text: '\u062A\u0635\u0645\u064A\u0645: \u0634\u0647\u062F \u0646\u0627\u062C\u062D',
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
    _fadeController.forward(from: 0);
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
