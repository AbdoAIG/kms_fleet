import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DeveloperCredit extends StatefulWidget {
  final bool compact;
  final bool darkBackground;
  final double? fontSize;
  final double? iconSize;

  const DeveloperCredit({
    super.key,
    this.compact = true,
    this.darkBackground = false,
    this.fontSize,
    this.iconSize,
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
      duration: const Duration(milliseconds: 1500),
    );
    _fadeController.forward(from: 0);
    _switchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
    final useFontSize = widget.fontSize ?? (widget.compact ? 10.0 : 14.0);
    final useIconSize = widget.iconSize ?? (widget.compact ? 12.0 : 16.0);
    final verticalPadding = widget.compact ? 4.0 : 12.0;

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: useIconSize, color: AppColors.textHint),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: useFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
