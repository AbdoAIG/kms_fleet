import 'package:flutter/material.dart';

/// A widget that displays a vehicle image with 360° rotation capability.
/// User can drag horizontally to rotate the image, creating a 3D spin effect.
class VehicleRotatingImage extends StatefulWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final Color accentColor;
  final double height;
  final double borderRadius;

  const VehicleRotatingImage({
    super.key,
    required this.imagePath,
    required this.fallbackIcon,
    required this.accentColor,
    this.height = 200,
    this.borderRadius = 16,
  });

  @override
  State<VehicleRotatingImage> createState() => _VehicleRotatingImageState();
}

class _VehicleRotatingImageState extends State<VehicleRotatingImage> {
  double _rotationAngle = 0.0;
  double _currentDragX = 0.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentDragX += details.delta.dx;
      // Map horizontal drag to rotation angle
      _rotationAngle = (_currentDragX * 0.5) % 360;
      if (_rotationAngle < 0) _rotationAngle += 360;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Keep the current rotation angle
  }

  /// Returns a value from -1 to 1 representing the facing direction
  double get _facingFactor {
    // cos of the angle gives us the "facing" factor
    final radians = _rotationAngle * 3.14159265 / 180;
    return radians == 0 ? 1.0 : (1.0 / (1.0 + (radians * 0.3).abs()));
  }

  Matrix4 get _transformMatrix {
    final radians = _rotationAngle * 3.14159265 / 180;
    // Simulate 3D Y-axis rotation using a combination of:
    // - Horizontal scaling (perspective narrowing)
    // - Slight vertical offset (wheel-like effect)
    final scaleX = (0.3 + 0.7 * (1.0 - (radians.abs() % 6.283) / 6.283 * 0.5)).clamp(0.4, 1.0);
    final skewX = (radians % 6.283) * 0.02;

    return Matrix4.identity()
      ..setEntry(0, 0, scaleX)
      ..setEntry(0, 1, skewX);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor.withOpacity(0.08),
            widget.accentColor.withOpacity(0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              // Vehicle image with rotation transform
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeOut,
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: _transformMatrix,
                    child: widget.imagePath != null
                        ? Image.asset(
                            widget.imagePath!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _buildFallback(),
                          )
                        : _buildFallback(),
                  ),
                ),
              ),
              // Rotation hint overlay (fades out after first interaction)
              if (_rotationAngle == 0.0)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'اسحب للدوران 360°',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Reset button (appears after rotation)
              if (_rotationAngle != 0.0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _rotationAngle = 0.0;
                        _currentDragX = 0.0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.refresh, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        widget.fallbackIcon,
        size: 64,
        color: widget.accentColor.withOpacity(0.25),
      ),
    );
  }
}
