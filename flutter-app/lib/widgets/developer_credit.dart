import 'dart:async';
import 'package:flutter/material.dart';

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

  static const Color _gold = Color(0xFFD4A017);
  static const Color _goldLight = Color(0xFFF5D060);

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
    // 5 seconds between each switch
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
    final useFontSize = widget.fontSize ?? (widget.compact ? 11.0 : 14.0);
    final useIconSize = widget.iconSize ?? (widget.compact ? 14.0 : 18.0);
    final verticalPadding = widget.compact ? 8.0 : 16.0;

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [_gold, _goldLight, _gold],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: useIconSize),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: useFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
