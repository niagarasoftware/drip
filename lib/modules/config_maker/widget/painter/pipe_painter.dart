import 'dart:ui';
import 'package:flutter/material.dart';

import '../../model/node_type_model.dart';

class PipePainter extends CustomPainter {
  final List<NodeObject> nodes;
  final List<PipeConnection> pipes;
  final String? selectedPipeId;
  final String? pendingConnectFromId;
  final String? pendingFromPortId;
  final Offset? pendingDragPos;
  final bool pendingIsInput;

  PipePainter({
    required this.nodes,
    required this.pipes,
    this.selectedPipeId,
    this.pendingConnectFromId,
    this.pendingFromPortId,
    this.pendingDragPos,
    this.pendingIsInput = false,
    super.repaint,
  });

  // ---------------------------------------------------------------------------
  // Pipe settings
  // ---------------------------------------------------------------------------
  /// Outer diameter of standard water pipes.
  static const double _pipeDiameter = 6.0;

  // PVC grey palette for water pipes.
  static const Color _pipeEdge = Color(0xFF59636A); // dark outline / far edge
  static const Color _pipeBody = Color(0xFF98A4AC); // main PVC colour
  static const Color _pipeLight = Color(0xFFD3DBE0); // lit side of the tube

  // ---------------------------------------------------------------------------
  // Air hose settings (glossy ribbed hose with chrome clamps)
  // ---------------------------------------------------------------------------
  static const double _airDiameter = 7.5;

  static const Color _airEdge = Color(0xFF0A3550); // dark navy outline
  static const Color _airBody = Color(0xFF1E9BE0); // vivid blue (running)
  static const Color _airBodyIdle = Color(0xFF3D8DBA); // slightly muted (idle)
  static const Color _airShade = Color(0xFF0D5C8F); // shaded underside
  static const Color _airLight = Color(0xFF8BDCFF); // lit top side

  static const Color _metalEdge = Color(0xFF3B474F);
  static const Color _metalSteel = Color(0xFF78909C);
  static const Color _metalBody = Color(0xFFCFD8DC);
  static const Color _metalLight = Color(0xFFF5F8FA);

  /// Max distance (px) at which pipe ends / bends / sides count as touching.
  static const double _junctionTol = 3.0;

  NodeObject? _findNode(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Set<String> _getAirNodeIds() {
    final Set<String> airNodeIds = {};
    for (final node in nodes) {
      if (node.type == NodeType.blower) {
        airNodeIds.add(node.id);
      }
    }
    for (final pipe in pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;
      if (from.type == NodeType.fertilizerTank && pipe.fromPortId == 'top_inlet') {
        airNodeIds.add(from.id);
      }
      if (to.type == NodeType.fertilizerTank && pipe.toPortId == 'top_inlet') {
        airNodeIds.add(to.id);
      }
    }

    // Air propagates through junction (T / cross) fittings.
    bool added = true;
    while (added) {
      added = false;
      for (final pipe in pipes) {
        final from = _findNode(pipe.fromNodeId);
        final to = _findNode(pipe.toNodeId);
        if (from == null || to == null) continue;

        if (airNodeIds.contains(pipe.fromNodeId)) {
          if (to.type == NodeType.junction && !airNodeIds.contains(to.id)) {
            airNodeIds.add(to.id);
            added = true;
          }
        }
        if (airNodeIds.contains(pipe.toNodeId)) {
          if (from.type == NodeType.junction && !airNodeIds.contains(from.id)) {
            airNodeIds.add(from.id);
            added = true;
          }
        }
      }
    }
    return airNodeIds;
  }

  /// Ids of pipes that carry fertilizer. A pipe is fertilizer if its own
  /// endpoints say so, or if it is the other half of a fertilizer run that
  /// was split by a plain pass-through junction (exactly two pipes attached).
  /// Tees / crosses do NOT propagate, so a fertilizer tube joined onto a water
  /// main never turns the main green.
  Set<String> _getFertilizerPipeIds(Set<String> airNodeIds) {
    final Set<String> result = {};
    for (final pipe in pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;
      if (_isFertilizerPipe(pipe, from, to, airNodeIds)) result.add(pipe.id);
    }

    // Pipes attached to each junction.
    final Map<String, List<PipeConnection>> attached = {};
    for (final pipe in pipes) {
      for (final id in [pipe.fromNodeId, pipe.toNodeId]) {
        final n = _findNode(id);
        if (n != null && n.type == NodeType.junction) {
          attached.putIfAbsent(id, () => []).add(pipe);
        }
      }
    }

    bool added = true;
    while (added) {
      added = false;
      attached.forEach((junctionId, list) {
        if (list.length != 2) return;
        final a = list[0], b = list[1];
        final aFert = result.contains(a.id);
        final bFert = result.contains(b.id);
        if (aFert == bFert) return;
        final other = aFert ? b : a;
        final from = _findNode(other.fromNodeId);
        final to = _findNode(other.toNodeId);
        if (from == null || to == null) return;
        if (_isAirPipe(other, from, to, airNodeIds)) return;
        result.add(other.id);
        added = true;
      });
    }
    return result;
  }

  bool _isAirPipe(PipeConnection pipe, NodeObject from, NodeObject to, Set<String> airNodeIds) {
    if (from.type == NodeType.blower || to.type == NodeType.blower) {
      return true;
    }
    if ((from.type == NodeType.fertilizerTank && pipe.fromPortId == 'top_inlet') ||
        (to.type == NodeType.fertilizerTank && pipe.toPortId == 'top_inlet')) {
      return true;
    }
    if (airNodeIds.contains(pipe.fromNodeId) && airNodeIds.contains(pipe.toNodeId)) {
      return true;
    }
    return false;
  }

  bool _isFertilizerPipe(PipeConnection pipe, NodeObject from, NodeObject to, Set<String> airNodeIds) {
    if (_isAirPipe(pipe, from, to, airNodeIds)) {
      return false;
    }
    if (from.type == NodeType.mainFertilizerSource ||
        to.type == NodeType.mainFertilizerSource) {
      return true;
    }
    bool isCh(String? id) =>
        id != null &&
            (id.startsWith('channel_') || id.startsWith('outlet_') || id == 'outlet');

    final bool fromFertTank =
        from.type == NodeType.fertilizerTank && pipe.fromPortId != 'top_inlet';
    final bool toFertTank =
        to.type == NodeType.fertilizerTank && pipe.toPortId != 'top_inlet';
    final bool fromInj = from.type == NodeType.multiInjector &&
        (pipe.fromPortId?.startsWith('channel_') ?? false);
    final bool toInj = to.type == NodeType.multiInjector &&
        (pipe.toPortId?.startsWith('channel_') ?? false);
    final bool fromValve =
        from.type == NodeType.multiOutletTankValve && isCh(pipe.fromPortId);
    final bool toValve =
        to.type == NodeType.multiOutletTankValve && isCh(pipe.toPortId);

    return fromFertTank || toFertTank || fromInj || toInj || fromValve || toValve;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Points of ordinary water pipes & air pipes, used afterwards to draw junctions.
    final List<List<Offset>> waterPipePoints = [];
    final List<List<Offset>> airPipePoints = [];
    final Set<String> airNodeIds = _getAirNodeIds();
    final Set<String> fertilizerPipeIds = _getFertilizerPipeIds(airNodeIds);
    final List<List<Offset>> allPipePoints = [];

    for (final pipe in pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;

      final start = portPosition(from, pipe.fromPortId, isInput: false);
      final end = portPosition(to, pipe.toPortId, isInput: true);
      final points = <Offset>[start, ...pipe.waypoints, end];
      allPipePoints.add(points);
      final isSelected = pipe.id == selectedPipeId;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }

      final bool isAir = _isAirPipe(pipe, from, to, airNodeIds);
      final bool isFertilizer = fertilizerPipeIds.contains(pipe.id);

      if (isAir) {
        // --- Air Pipe (glossy ribbed hose, static) ---
        _drawAirPipe(canvas, points, path, isSelected, pipe.flowActive);
        airPipePoints.add(points);
      } else if (isFertilizer) {
        // --- Fertilizer / Chemical Dosing Pipe (Realistic thin flexible tubing) ---
        canvas.drawPath(
          path,
          Paint()
            ..color = isSelected ? const Color(0xFFFF9800) : const Color(0xFF1B5E20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 6.5 : 4.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

        // Inner chemical / natural fertilizer liquid solution
        canvas.drawPath(
          path,
          Paint()
            ..color = pipe.flowActive
                ? const Color(0xFF4CAF50) // Vibrant green fertilizer solution
                : const Color(0xFFA5D6A7) // Muted translucent green
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 3.2 : 2.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

        // Sheen / gloss highlight streak
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.40)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      } else {
        // --- Standard Main Water Pipe: static, realistic grey PVC ---
        _drawWaterPipe(canvas, points, path, isSelected);
        waterPipePoints.add(points);
      }
    }

    // Elbows, tees and crosses where water pipes & air pipes meet.
    _drawJunctions(canvas, waterPipePoints);
    _drawAirJunctions(canvas, airPipePoints);

    // Rubber-band preview line while user is dragging a port in connect mode.
    if (pendingConnectFromId != null) {
      final from = _findNode(pendingConnectFromId!);
      if (from != null) {
        final startPos = portPosition(from, pendingFromPortId, isInput: pendingIsInput);

        bool isAirDrag = false;
        bool isFertilizerDrag = false;

        if (from.type == NodeType.blower || pendingFromPortId == 'top_inlet' || airNodeIds.contains(from.id)) {
          isAirDrag = true;
        } else if (from.type == NodeType.mainFertilizerSource) {
          isFertilizerDrag = true;
        } else if (from.type == NodeType.junction) {
          isFertilizerDrag = pipes.any((p) =>
          fertilizerPipeIds.contains(p.id) &&
              (p.fromNodeId == from.id || p.toNodeId == from.id));
        } else if (from.type == NodeType.fertilizerTank) {
          isFertilizerDrag = (pendingFromPortId != 'top_inlet');
        } else if (from.type == NodeType.multiInjector) {
          isFertilizerDrag = (pendingFromPortId != null && pendingFromPortId!.startsWith('channel_'));
        } else if (from.type == NodeType.multiOutletTankValve) {
          isFertilizerDrag = (pendingFromPortId != null && (pendingFromPortId!.startsWith('channel_') || pendingFromPortId!.startsWith('outlet_') || pendingFromPortId == 'outlet'));
        }

        if (!isAirDrag && !isFertilizerDrag && pendingDragPos != null) {
          for (final n in nodes) {
            if (n.type == NodeType.blower) {
              if ((n.position & n.size).inflate(30).contains(pendingDragPos!) ||
                  (n.outputPort - pendingDragPos!).distance < 40) {
                isAirDrag = true;
                break;
              }
            } else if (n.type == NodeType.fertilizerTank) {
              final topInlet = n.getPort('top_inlet', isInput: true);
              if ((topInlet - pendingDragPos!).distance < 40) {
                isAirDrag = true;
                break;
              }
              final leftInlet = n.getPort('inlet', isInput: true);
              final outlet = n.getPort('outlet', isInput: false);
              if ((leftInlet - pendingDragPos!).distance < 40 ||
                  (outlet - pendingDragPos!).distance < 40) {
                isFertilizerDrag = true;
                break;
              }
            } else if (n.type == NodeType.mainFertilizerSource) {
              if ((n.position & n.size).inflate(30).contains(pendingDragPos!) ||
                  (n.inputPort - pendingDragPos!).distance < 40 ||
                  (n.outputPort - pendingDragPos!).distance < 40) {
                isFertilizerDrag = true;
                break;
              }
            } else if (n.type == NodeType.multiInjector) {
              for (int i = 0; i < 4; i++) {
                final p = n.getPort('channel_$i', isInput: true);
                if ((p - pendingDragPos!).distance < 40) {
                  isFertilizerDrag = true;
                  break;
                }
              }
            } else if (n.type == NodeType.multiOutletTankValve) {
              for (int i = 0; i < 4; i++) {
                final p = n.getPort('channel_$i', isInput: false);
                if ((p - pendingDragPos!).distance < 40) {
                  isFertilizerDrag = true;
                  break;
                }
              }
            }
          }
        }

        if (isAirDrag) {
          // --- Dragging preview for Air Hose (matches the final hose look) ---
          final casingPaint = _tube(_airEdge, _airDiameter, cap: StrokeCap.round);
          final bodyPaint = _tube(_airBody, _airDiameter - 1.6, cap: StrokeCap.round);
          final lightPaint = _tube(_airLight, _airDiameter * 0.3, cap: StrokeCap.round);

          // Metal ferrule dot at the start port
          canvas.drawCircle(startPos, 5.5, Paint()..color = _metalEdge);
          canvas.drawCircle(startPos, 4.2, Paint()..color = _metalBody);
          canvas.drawCircle(startPos, 2.2, Paint()..color = _airBody);

          if (pendingDragPos != null) {
            canvas.drawLine(startPos, pendingDragPos!, casingPaint);
            canvas.drawLine(startPos, pendingDragPos!, bodyPaint);
            canvas.drawLine(
              startPos + const Offset(-0.6, -0.9),
              pendingDragPos! + const Offset(-0.6, -0.9),
              lightPaint,
            );
          }
        } else if (isFertilizerDrag) {
          // --- Dragging preview for Fertilizer Tank (Thin chemical tube) ---
          final casingPaint = Paint()
            ..color = const Color(0xFF1B5E20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeCap = StrokeCap.round;

          final innerPaint = Paint()
            ..color = const Color(0xFF4CAF50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round;

          canvas.drawCircle(startPos, 5, Paint()..color = const Color(0xFF1B5E20));
          canvas.drawCircle(startPos, 3, Paint()..color = const Color(0xFF4CAF50));

          if (pendingDragPos != null) {
            canvas.drawLine(startPos, pendingDragPos!, casingPaint);
            canvas.drawLine(startPos, pendingDragPos!, innerPaint);
          }
        } else {
          // --- Standard Pipe Dragging Preview ---
          final dashPaint = Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          canvas.drawCircle(startPos, 6, dashPaint);
          if (pendingDragPos != null) {
            canvas.drawLine(startPos, pendingDragPos!, dashPaint);
          }
        }
      }

      // Snap indicator: when the dragged end is close to the side of an
      // existing pipe, show where the T-joint will be created.
      if (pendingDragPos != null) {
        _drawSnapIndicator(canvas, allPipePoints, pendingDragPos!);
      }
    }
  }

  void _drawSnapIndicator(Canvas canvas, List<List<Offset>> allPipePoints, Offset cursor) {
    Offset? best;
    double bestDist = kPipeSnapTolerance;
    for (final pts in allPipePoints) {
      for (int i = 0; i < pts.length - 1; i++) {
        final q = closestPointOnSegment(cursor, pts[i], pts[i + 1]);
        final d = (cursor - q).distance;
        // Near a pipe's own end it's a port target, not a side joint.
        if ((q - pts.first).distance < 12 || (q - pts.last).distance < 12) continue;
        if (d < bestDist) {
          bestDist = d;
          best = q;
        }
      }
    }
    if (best == null) return;
    canvas.drawCircle(best, 9, Paint()..color = const Color(0x33FF9800));
    canvas.drawCircle(
      best,
      9,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(best, 2.5, Paint()..color = const Color(0xFFFF9800));
  }

  // ---------------------------------------------------------------------------
  // Air hose: glossy blue ribbed hose with chrome clamps (static, no animation)
  // ---------------------------------------------------------------------------

  void _drawAirPipe(Canvas canvas, List<Offset> points, Path path, bool isSelected, bool flowActive) {
    const double d = _airDiameter;

    // Selection halo
    if (isSelected) {
      canvas.drawPath(
        path,
        _tube(const Color(0xFFFF9800).withValues(alpha: 0.75), d + 6, cap: StrokeCap.round),
      );
    }

    // Soft contact shadow
    canvas.drawPath(
      path.shift(const Offset(0, 1.8)),
      _tube(const Color(0x40000000), d + 1,
          cap: StrokeCap.round, blur: const MaskFilter.blur(BlurStyle.normal, 1.8)),
    );

    // 1. Dark navy outline
    canvas.drawPath(path, _tube(_airEdge, d, cap: StrokeCap.round));
    // 2. Main hose body
    canvas.drawPath(
      path,
      _tube(flowActive ? _airBody : _airBodyIdle, d - 1.6, cap: StrokeCap.round),
    );
    // 3. Shaded underside (gives a round, 3D look)
    canvas.drawPath(
      path.shift(const Offset(0.7, 1.1)),
      _tube(_airShade.withValues(alpha: 0.75), d * 0.42, cap: StrokeCap.round),
    );
    // 4. Lit top side
    canvas.drawPath(
      path.shift(const Offset(-0.8, -1.1)),
      _tube(_airLight.withValues(alpha: 0.9), d * 0.32, cap: StrokeCap.round),
    );

    // 5. Hose ribs (corrugation) across the tube
    _drawRibs(canvas, path, d);

    // 6. Glossy glint on top of the ribs
    canvas.drawPath(
      path.shift(const Offset(-1.0, -1.3)),
      _tube(Colors.white.withValues(alpha: 0.75), 1.0, cap: StrokeCap.round),
    );

    // 7. Chrome end clamps
    _airClamp(canvas, points.first, points[1]);
    _airClamp(canvas, points.last, points[points.length - 2]);
  }

  /// Evenly spaced raised rings along the hose (static).
  void _drawRibs(Canvas canvas, Path path, double d) {
    const double spacing = 6.5;
    const double margin = 16.0; // leave the clamp areas clean
    final double half = (d - 1.0) / 2;

    final Paint dark = Paint()
      ..isAntiAlias = true
      ..color = _airEdge.withValues(alpha: 0.38)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.butt;
    final Paint light = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.butt;

    for (final metric in path.computeMetrics()) {
      final double len = metric.length;
      for (double s = margin; s < len - margin; s += spacing) {
        final Tangent? t = metric.getTangentForOffset(s);
        if (t == null) continue;
        final Offset u = t.vector;
        final Offset n = Offset(-u.dy, u.dx);
        final Offset a = t.position - n * half;
        final Offset b = t.position + n * half;
        canvas.drawLine(a, b, dark);
        canvas.drawLine(a + u * 1.3, b + u * 1.3, light);
      }
    }
  }

  /// Chrome ferrule + hose clamp with a screw lug at a pipe end.
  void _airClamp(Canvas canvas, Offset from, Offset toward) {
    final Offset v = toward - from;
    final double len = v.distance;
    if (len < 28) return;
    final Offset u = v / len;
    final Offset n = Offset(-u.dy, u.dx);

    // Steel ferrule (the port nipple)
    final Offset f0 = from + u * 1.5;
    final Offset f1 = from + u * 6.0;
    const double fw = _airDiameter + 1.6;
    canvas.drawLine(f0, f1, _tube(_metalEdge, fw));
    canvas.drawLine(f0, f1, _tube(_metalSteel, fw - 1.2));
    canvas.drawLine(
      f0 + const Offset(-0.5, -0.7),
      f1 + const Offset(-0.5, -0.7),
      _tube(_metalLight.withValues(alpha: 0.8), fw * 0.25),
    );

    // Clamp band
    final Offset a = from + u * 7.0;
    final Offset b = from + u * 15.0;
    const double w = _airDiameter + 3.6;
    canvas.drawLine(a, b, _tube(_metalEdge, w));
    canvas.drawLine(a, b, _tube(_metalBody, w - 1.3));
    canvas.drawLine(
      a + const Offset(-0.6, -0.9),
      b + const Offset(-0.6, -0.9),
      _tube(_metalLight, w * 0.3),
    );

    // Grooves at both edges of the band
    final Paint groove = _tube(_metalEdge.withValues(alpha: 0.55), 0.7);
    for (final Offset g in [a + u * 1.4, b - u * 1.4]) {
      canvas.drawLine(g - n * (w / 2 - 0.6), g + n * (w / 2 - 0.6), groove);
    }

    // Screw lug on the upper side of the band
    final double sign = n.dy <= 0 ? 1.0 : -1.0;
    final Offset lug = from + u * 11.0 + n * sign * (w / 2 - 0.2);
    canvas.drawCircle(lug, 2.0, Paint()..color = _metalEdge);
    canvas.drawCircle(lug, 1.4, Paint()..color = _metalBody);
    canvas.drawLine(
      lug - u * 0.9,
      lug + u * 0.9,
      _tube(_metalEdge, 0.6),
    );
  }

  void _drawAirJunctions(Canvas canvas, List<List<Offset>> pipePoints) {
    if (pipePoints.isEmpty) return;
    final junctions = _buildJunctions(pipePoints);
    const double d = _airDiameter;

    junctions.forEach((pos, dirs) {
      if (dirs.length < 2) return;

      // Straight pass-through: no fitting needed.
      if (dirs.length == 2) {
        final dot = dirs[0].dx * dirs[1].dx + dirs[0].dy * dirs[1].dy;
        if (dot < -0.97) return;
      }

      // Tee / cross: chrome sleeve on every arm.
      if (dirs.length >= 3) {
        const double w = d + 3.2;
        for (final u in dirs) {
          final a = pos;
          final b = pos + u * (d * 1.9);
          canvas.drawLine(a, b, _tube(_metalEdge, w));
          canvas.drawLine(a, b, _tube(_metalBody, w - 1.3));
          canvas.drawLine(
            a + const Offset(-0.6, -0.9),
            b + const Offset(-0.6, -0.9),
            _tube(_metalLight, w * 0.3),
          );
        }
      }

      // Chrome ball elbow / tee body with a blue accent ring
      final double r = dirs.length >= 3 ? d * 1.0 : d * 0.85;
      final Rect rect = Rect.fromCircle(center: pos, radius: r);
      canvas.drawCircle(
          pos + const Offset(0, 1.3), r, Paint()..color = const Color(0x45000000));
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..isAntiAlias = true
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            colors: [_metalLight, _metalBody, _metalSteel, _metalEdge],
            stops: [0.0, 0.4, 0.8, 1.0],
          ).createShader(rect),
      );
      canvas.drawCircle(pos, r, _tube(_metalEdge, 0.8));
      canvas.drawCircle(pos, r * 0.52, _tube(_airBody, 1.3));
    });
  }

  // ---------------------------------------------------------------------------
  // Realistic grey PVC water pipe
  // ---------------------------------------------------------------------------

  Paint _tube(Color c, double w,
      {StrokeCap cap = StrokeCap.butt, MaskFilter? blur}) {
    return Paint()
      ..isAntiAlias = true
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = blur;
  }

  void _drawWaterPipe(Canvas canvas, List<Offset> points, Path path, bool isSelected) {
    const double d = _pipeDiameter;

    // Selection halo (the pipe itself keeps its normal colours).
    if (isSelected) {
      canvas.drawPath(
        path,
        _tube(const Color(0xFFFF9800).withValues(alpha: 0.65), d + 6, cap: StrokeCap.round),
      );
    }

    // Soft contact shadow.
    canvas.drawPath(
      path.shift(const Offset(0, 1.6)),
      _tube(const Color(0x47000000), d + 1,
          cap: StrokeCap.round, blur: const MaskFilter.blur(BlurStyle.normal, 1.6)),
    );

    // Tube layers, lit from the top-left: edge -> body -> shade -> light -> glint.
    canvas.drawPath(path, _tube(_pipeEdge, d, cap: StrokeCap.round));
    canvas.drawPath(path, _tube(_pipeBody, d - 1.4, cap: StrokeCap.round));
    canvas.drawPath(
      path.shift(const Offset(0.7, 1.0)),
      _tube(_pipeEdge.withValues(alpha: 0.55), d * 0.4, cap: StrokeCap.round),
    );
    canvas.drawPath(
      path.shift(const Offset(-0.7, -0.9)),
      _tube(_pipeLight, d * 0.34, cap: StrokeCap.round),
    );
    canvas.drawPath(
      path.shift(const Offset(-0.9, -1.1)),
      _tube(Colors.white.withValues(alpha: 0.6), 0.9, cap: StrokeCap.round),
    );

    // Elbow fittings are drawn by _drawJunctions after all pipes are painted.

    // Coupling collars near both ends of the pipe.
    _collar(canvas, points.first, points[1]);
    _collar(canvas, points.last, points[points.length - 2]);
  }

  void _collar(Canvas canvas, Offset from, Offset toward) {
    final Offset v = toward - from;
    final double len = v.distance;
    if (len < 20) return;
    final Offset u = v / len;
    final Offset a = from + u * 4;
    final Offset b = from + u * 10;
    const double w = _pipeDiameter + 2.4;

    canvas.drawLine(a, b, _tube(_pipeEdge, w));
    canvas.drawLine(a, b, _tube(_pipeBody, w - 1.2));
    canvas.drawLine(
      a + const Offset(-0.6, -0.8),
      b + const Offset(-0.6, -0.8),
      _tube(_pipeLight, w * 0.3),
    );
  }

  // ---------------------------------------------------------------------------
  // Junction fittings: elbow (2 dirs), tee (3 dirs), cross (4 dirs)
  // ---------------------------------------------------------------------------

  /// Adds the unit direction from [from] to [to] unless a direction within
  /// ~12° is already recorded.
  void _addDir(List<Offset> dirs, Offset from, Offset to) {
    final v = to - from;
    final len = v.distance;
    if (len < 0.001) return;
    final u = v / len;
    for (final e in dirs) {
      if (e.dx * u.dx + e.dy * u.dy > 0.978) return;
    }
    dirs.add(u);
  }

  Map<Offset, List<Offset>> _buildJunctions(List<List<Offset>> pipePoints) {
    final Map<Offset, List<Offset>> result = {};

    Offset keyFor(Offset p) {
      for (final k in result.keys) {
        if ((k - p).distance <= _junctionTol) return k;
      }
      result[p] = [];
      return p;
    }

    // 1) Ends and bends of every pipe, with the directions of adjacent segments.
    for (final pts in pipePoints) {
      for (int i = 0; i < pts.length; i++) {
        final k = keyFor(pts[i]);
        if (i > 0) _addDir(result[k]!, k, pts[i - 1]);
        if (i < pts.length - 1) _addDir(result[k]!, k, pts[i + 1]);
      }
    }

    // 2) A point lying on the side of another pipe splits that pipe into two arms.
    for (final entry in result.entries) {
      final pos = entry.key;
      for (final pts in pipePoints) {
        for (int i = 0; i < pts.length - 1; i++) {
          final a = pts[i], b = pts[i + 1];
          if ((pos - a).distance <= _junctionTol ||
              (pos - b).distance <= _junctionTol) {
            continue;
          }
          if (distanceToSegment(pos, a, b) <= _junctionTol) {
            _addDir(entry.value, pos, a);
            _addDir(entry.value, pos, b);
          }
        }
      }
    }
    return result;
  }

  void _drawJunctions(Canvas canvas, List<List<Offset>> pipePoints) {
    if (pipePoints.isEmpty) return;
    final junctions = _buildJunctions(pipePoints);
    const double d = _pipeDiameter;

    junctions.forEach((pos, dirs) {
      if (dirs.length < 2) return;

      // Straight pass-through: no fitting needed.
      if (dirs.length == 2) {
        final dot = dirs[0].dx * dirs[1].dx + dirs[0].dy * dirs[1].dy;
        if (dot < -0.97) return;
      }

      // Tee / cross: a short sleeve on every arm.
      if (dirs.length >= 3) {
        const double w = d + 2.4;
        for (final u in dirs) {
          final a = pos;
          final b = pos + u * (d * 1.9);
          canvas.drawLine(a, b, _tube(_pipeEdge, w));
          canvas.drawLine(a, b, _tube(_pipeBody, w - 1.2));
          canvas.drawLine(
            a + const Offset(-0.6, -0.8),
            b + const Offset(-0.6, -0.8),
            _tube(_pipeLight, w * 0.3),
          );
        }
      }

      // Hub (round elbow for 2 arms, larger body for tee / cross).
      final double r = dirs.length >= 3 ? d * 1.0 : d * 0.82;
      final Rect rect = Rect.fromCircle(center: pos, radius: r);
      canvas.drawCircle(
          pos + const Offset(0, 1.2), r, Paint()..color = const Color(0x40000000));
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..isAntiAlias = true
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            colors: [_pipeLight, _pipeBody, _pipeEdge],
            stops: [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
      canvas.drawCircle(pos, r, _tube(_pipeEdge, 0.8));
    });
  }

  @override
  bool shouldRepaint(covariant PipePainter oldDelegate) => true;
}

/// Shortest distance from [p] to the segment [a]-[b], used for pipe hit
/// testing (tap-to-select) and for locating where to insert a new bend point.
double distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
  if (abLenSq == 0) return (p - a).distance;
  double t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / abLenSq;
  t = t.clamp(0.0, 1.0);
  final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - proj).distance;
}

/// Distance (px) within which a dragged pipe end / a tap in connect mode
/// snaps onto the side of an existing pipe to form a T / cross joint.
const double kPipeSnapTolerance = 18.0;

/// Closest point to [p] on the segment [a]-[b]. Used to place a junction
/// exactly on the pipe line so the pipe stays straight after it is split.
Offset closestPointOnSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
  if (abLenSq == 0) return a;
  double t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / abLenSq;
  t = t.clamp(0.0, 1.0);
  return Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
}

/// Position of a pipe endpoint on [node]. A junction has no ports: it is a
/// single point at the centre of its (tiny) box.
Offset portPosition(NodeObject node, String? portId, {required bool isInput}) {
  if (node.type == NodeType.junction) {
    return node.position + Offset(node.size.width / 2, node.size.height / 2);
  }
  return node.getPort(portId, isInput: isInput);
}