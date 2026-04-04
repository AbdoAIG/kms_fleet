import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DeveloperCredit extends StatefulWidget {
  final bool compact;
  final bool darkBackground;
  final double? fontSize;

  const DeveloperCredit({
    super.key,
    this.compact = true,
    this.darkBackground = false,
    this.fontSize,
  });

  @override
  State<DeveloperCredit> createState() => _DeveloperCreditState();
}

class _DeveloperCreditState extends State<DeveloperCredit>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  int _currentIndex = 0;
  Timer? _switchTimer;

  final List<Map<String, IconData>> _credits = const [
    {'تطوير: عبدالرحمن إبراهيم': Icons.code_rounded},
    {'تصميم: شهد ناجح': Icons.palette_rounded},
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
    final text = credit.keys.first;
    final icon = credit.values.first;
    final useFontSize = widget.fontSize ?? (widget.compact ? 10.0 : 13.0);
    final iconSize = widget.compact ? 12.0 : 16.0;
    final verticalPadding = widget.compact ? 8.0 : 16.0;
    final textColor = widget.darkBackground
        ? Colors.white.withOpacity(0.7)
        : AppColors.primary.withOpacity(0.6);

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: useFontSize,
                fontWeight: FontWeight.w500,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
