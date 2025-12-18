import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  final bool isPlaying;

  const LiquidBackground({super.key, required this.isPlaying});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation; // 1. Add an Animation object

  @override
  void initState() {
    super.initState();
    // 2. Make it faster (7 seconds instead of 10)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    // 3. Add a Curve for "Fluent" motion (Eases in and out)
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine, // Smooth sine wave motion
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LiquidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation, // Listen to the curved animation
      builder: (context, child) {
        return RepaintBoundary(
          child: Stack(
            children: [
              Container(
                color: const Color(0xFF1E1E2C),
                width: double.infinity,
                height: double.infinity,
              ),

              // Blob 1: Top Left -> Moves diagonally down-right
              Positioned(
                // MOVES FURTHER: Increased from 200 to 400
                top: -100 + (_animation.value * 400),
                // Moves right significantly now
                left: -100 + (_animation.value * 200),
                child: _buildBlob(color: const Color(0xcf8839ef), size: 400),
              ),

              // Blob 2: Bottom Right -> Moves diagonally up-left
              Positioned(
                // MOVES FURTHER: Increased from 150 to 300
                bottom: -100 + (_animation.value * 300),
                right: -50 + (_animation.value * 200),
                child: _buildBlob(color: Colors.blueAccent.shade700, size: 350),
              ),

              // Blob 3: Bottom Left -> Pulses and moves slightly up
              Positioned(
                bottom: -50 + (_animation.value * 150),
                left: -50 + (_animation.value * 100), // Adds sideways drift
                child: _buildBlob(
                  color: Colors.deepPurple.shade900,
                  // Grows bigger: 300 -> 500
                  size: 300 + (_animation.value * 200),
                ),
              ),

              Positioned.fill(
                child: BackdropFilter(
                  // Kept high blur for maximum liquid effect
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.black.withOpacity(0.1)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlob({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

