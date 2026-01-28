import 'package:flutter/material.dart';

/// Physique de défilement personnalisée lisse et réactive
class SmoothScrollPhysics extends ScrollPhysics {
  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  double frictionFactor(double overscrollFriction) => 0.02 * overscrollFriction;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    return BouncingScrollSimulation(
      spring: spring,
      position: position.pixels,
      velocity: velocity * 0.91,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      tolerance: tolerance,
    );
  }
}

/// Physique de défilement avec amortissement élastique
class ElasticScrollPhysics extends ScrollPhysics {
  const ElasticScrollPhysics({super.parent});

  @override
  ElasticScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ElasticScrollPhysics(parent: buildParent(ancestor));
  }

  double frictionFactor(double overscrollFriction) =>
      0.015 * overscrollFriction;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      0.0,
      velocity,
      tolerance: tolerance,
    );
  }
}

/// Physique de défilement contrôlée sans débordement
class ConstrainedScrollPhysics extends ScrollPhysics {
  const ConstrainedScrollPhysics({super.parent});

  @override
  ConstrainedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ConstrainedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return null;
    }

    final tolerance = toleranceFor(position);
    return BouncingScrollSimulation(
      spring: spring,
      position: position.pixels,
      velocity: velocity * 0.95,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      tolerance: tolerance,
    );
  }
}
