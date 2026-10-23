import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'node_type_model.dart';

/// Simple ChangeNotifier helper for notifying canvas structure and drag events.
class CanvasNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Result of a nearest-pipe-segment lookup: which pipe, which segment
/// (0-based, between points[i] and points[i+1] of that pipe's full path),
/// and how far the query point was from it.
class PipeHit {
  final PipeConnection pipe;
  final int segmentIndex;
  final double distance;

  /// Closest point on that segment to the query point (where a joint goes).
  final Offset point;

  PipeHit({
    required this.pipe,
    required this.segmentIndex,
    required this.distance,
    required this.point,
  });
}
