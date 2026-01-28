import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget d'animation shimmer pour les éléments chargement
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: 0.6 + (_controller.value * 0.4), child: child);
      },
      child: widget.child,
    );
  }
}

/// Animation pulse pour les éléments actifs
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Softer pulse: smaller scale and slower rhythm
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Animation bounce pour les boutons
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Gentle bounce with reduced amplitude and smoother curve
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -10 * _animation.value),
      child: widget.child,
    );
  }
}

/// Widget de chargement animé avec points
class DotLoader extends StatefulWidget {
  final Color color;
  final double size;

  const DotLoader({super.key, required this.color, this.size = 12.0});

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // slightly slower dot loader for softer movement
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 7,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index * 0.2,
                  (index + 1) * 0.2,
                  curve: Curves.easeInOut,
                ),
              ),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.5),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Animation fadeSlide pour les éléments de liste
extension CustomAnimations on Widget {
  Widget fadeSlideIn({
    Duration duration = const Duration(milliseconds: 600),
    int delayMs = 0,
  }) {
    return (this)
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: duration)
        .slideX(begin: -12, end: 0, curve: Curves.easeInOut);
  }

  Widget slideUpIn({
    Duration duration = const Duration(milliseconds: 600),
    int delayMs = 0,
  }) {
    return (this)
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: duration)
        .slideY(begin: 12, end: 0, curve: Curves.easeInOut);
  }

  Widget scaleIn({
    Duration duration = const Duration(milliseconds: 600),
    int delayMs = 0,
  }) {
    return (this)
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: duration)
        .scale(duration: duration, curve: Curves.easeInOut);
  }

  Widget rotateIn({
    Duration duration = const Duration(milliseconds: 600),
    int delayMs = 0,
  }) {
    return (this)
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: duration)
        .rotate(begin: -0.04, end: 0, curve: Curves.easeInOut);
  }
}
