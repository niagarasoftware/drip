import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
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

  /// While true (user is dragging) expensive effects (blur shadows, hose ribs)
  /// are skipped; full detail returns when the drag stops.
  final ValueListenable<bool>? simplify;

  /// Pipes whose bounds do not touch this rect (scene coordinates) are not
  /// drawn at all. null = draw everything.
  final Rect? cullRect;
  bool get _lite => simplify?.value ?? false;

  PipePainter({
    required this.nodes,
    required this.pipes,
    this.selectedPipeId,
    this.pendingConnectFromId,
    this.pendingFromPortId,
    this.pendingDragPos,
    this.pendingIsInput = false,
    this.simplify,
    this.cullRect,
    super.repaint,
  });

  // ---------------------------------------------------------------------------
  // Pipe settings (Sleek, realistic industrial PVC)
  // ---------------------------------------------------------------------------
  /// Outer diameter of standard water pipes (reduced for a sleek, crisp visual balance).
  static const double _pipeDiameter = 5.0;

  // PVC grey palette for water pipes.
  static const Color _pipeEdge = Color(0xFF424A50); // dark charcoal outline / far edge
  static const Color _pipeBody = Color(0xFF8A97A0); // main PVC colour
  static const Color _pipeShade = Color(0xFF5E6970); // shaded underside
  static const Color _pipeLight = Color(0xFFE2E8EC); // lit top side

  // ---------------------------------------------------------------------------
  // Air hose settings (glossy ribbed hose with chrome clamps)
  // ---------------------------------------------------------------------------
  static const double _airDiameter = 6.5;

  static const Color _airEdge = Color(0xFF0A3550); // dark navy outline
  static const Color _airBody = Color(0xFF1E9BE0); // vivid blue (running)
  static const Color _airBodyIdle = Color(0xFF3D8DBA); // slightly muted (idle)
  static const Color _airShade = Color(0xFF0D5C8F); // shaded underside
  static const Color _airLight = Color(0xFF8BDCFF); // lit top side

  // ---------------------------------------------------------------------------
  // Fertilizer / Chemical dosing pipe settings (sleek, thin micro-tubing)
  // ---------------------------------------------------------------------------
  static const double _fertDiameter = 3.2;

  static const Color _fertEdge = Color(0xFF092915); // Dark forest green outline
  static const Color _fertBody = Color(0xFF1B5E20); // Rich green tube body
  static const Color _fertFlow = Color(0xFF388E3C); // Vibrant green active chemical solution
  static const Color _fertFlowIdle = Color(0xFF66BB6A); // Translucent green solution
  static const Color _fertLight = Color(0xFFC8E6C9); // Specular highlight streak

  static const Color _fertMetalEdge = Color(0xFF1B2E21); // Dark fitting edge
  static const Color _fertMetalBody = Color(0xFF2E7D32); // Emerald metallic body for fittings
  static const Color _fertMetalLight = Color(0xFFA5D6A7); // Lit side of fitting

  static const Color _metalEdge = Color(0xFF3B474F);
  static const Color _metalSteel = Color(0xFF78909C);
  static const Color _metalBody = Color(0xFFCFD8DC);
  static const Color _metalLight = Color(0xFFF5F8FA);

  /// Max distance (px) at which pipe ends / bends / sides count as touching.
  static const double _junctionTol = 3.0;

  Map<String, NodeObject> _byId = const {};

  NodeObject? _findNode(String id) => _byId[id];

  // Pipe classification (air / fertilizer) only depends on topology, never on
  // positions, so it is cached and reused for every frame of a drag.
  static int? _cacheSig;
  static Set<String> _cacheAir = const {};
  static Set<String> _cacheFert = const {};
  static Map<String, NodeObject> _cacheById = const {};

  static int? _cachedJunctionsSig;
  static Map<Offset, List<Offset>> _cachedWaterJunctions = const {};
  static Map<Offset, List<Offset>> _cachedAirJunctions = const {};
  static Map<Offset, List<Offset>> _cachedFertilizerJunctions = const {};

  static final Map<String, Path> _cachedPipePaths = {};
  static final Map<String, List<Offset>> _cachedPipePoints = {};
  static final Map<String, int> _cachedPipeStateHash = {};

  int _pipeStateHash(PipeConnection pipe, NodeObject from, NodeObject to, bool lite) {
    int h = Object.hash(
      pipe.id,
      pipe.fromPortId,
      pipe.toPortId,
      from.position.dx,
      from.position.dy,
      from.size.width,
      from.size.height,
      to.position.dx,
      to.position.dy,
      to.size.width,
      to.size.height,
      lite,
    );
    for (final wp in pipe.waypoints) {
      h = Object.hash(h, wp.dx, wp.dy);
    }
    return h;
  }

  int _topologySignature() {
    int h = nodes.length;
    for (final p in pipes) {
      h = Object.hash(h, p.id, p.fromNodeId, p.toNodeId, p.fromPortId, p.toPortId);
    }
    return h;
  }

  void _ensureAnalysis() {
    final sig = _topologySignature();
    if (_cacheSig == sig) {
      _byId = _cacheById;
      return;
    }
    _byId = {for (final n in nodes) n.id: n};
    _cacheById = _byId;
    _cacheAir = computeAirNodeIds(nodes, pipes);
    _cacheFert = _getFertilizerPipeIds(_cacheAir);
    _cacheSig = sig;
  }

  int _calcJunctionsSig(
    List<List<Offset>> water,
    List<List<Offset>> air,
    List<List<Offset>> fert,
  ) {
    int h = Object.hash(water.length, air.length, fert.length);
    for (final pts in water) {
      if (pts.isNotEmpty) {
        h = Object.hash(h, pts.first.dx, pts.first.dy, pts.last.dx, pts.last.dy);
      }
    }
    for (final pts in air) {
      if (pts.isNotEmpty) {
        h = Object.hash(h, pts.first.dx, pts.first.dy, pts.last.dx, pts.last.dy);
      }
    }
    for (final pts in fert) {
      if (pts.isNotEmpty) {
        h = Object.hash(h, pts.first.dx, pts.first.dy, pts.last.dx, pts.last.dy);
      }
    }
    return h;
  }

  Set<String> _getAirNodeIds() => _cacheAir;

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

    // Pipes attached to each junction or tank valve.
    final Map<String, List<PipeConnection>> attached = {};
    for (final pipe in pipes) {
      for (final id in [pipe.fromNodeId, pipe.toNodeId]) {
        final n = _findNode(id);
        if (n != null &&
            (n.type == NodeType.junction ||
                n.type == NodeType.singleTankValve ||
                n.type == NodeType.multiOutletTankValve)) {
          attached.putIfAbsent(id, () => []).add(pipe);
        }
      }
    }

    bool added = true;
    while (added) {
      added = false;
      attached.forEach((junctionId, list) {
        if (list.length < 2) return;
        final bool hasFertilizer = list.any((p) => result.contains(p.id));
        if (!hasFertilizer) return;
        for (final p in list) {
          if (!result.contains(p.id)) {
            final from = _findNode(p.fromNodeId);
            final to = _findNode(p.toNodeId);
            if (from == null || to == null) continue;
            if (_isAirPipe(p, from, to, airNodeIds)) continue;

            // Do not propagate fertilizer onto water sources
            final bool isFromWaterSource = from.type == NodeType.sump ||
                from.type == NodeType.well ||
                from.type == NodeType.overheadTank ||
                from.type == NodeType.naturalSource;
            final bool isToWaterSource = to.type == NodeType.sump ||
                to.type == NodeType.well ||
                to.type == NodeType.overheadTank ||
                to.type == NodeType.naturalSource;
            if (isFromWaterSource || isToWaterSource) continue;

            result.add(p.id);
            added = true;
          }
        }
      });
    }
    return result;
  }

  /// A pipe is an AIR pipe only when:
  ///  * it touches a blower, or
  ///  * it touches the TOP port of a fertilizer tank (that port is air-only), or
  ///  * both its ends are junctions of a pure-air network (see [computeAirNodeIds]).
  /// Everything else is liquid. A junction shared with liquid pipes is never
  /// treated as air, so fertilizer pipes can no longer be recoloured by air.
  bool _isAirPipe(PipeConnection pipe, NodeObject from, NodeObject to, Set<String> airNodeIds) {
    if (from.type == NodeType.blower || to.type == NodeType.blower) return true;
    if (from.type == NodeType.fertilizerTank && pipe.fromPortId == 'top_inlet') return true;
    if (to.type == NodeType.fertilizerTank && pipe.toPortId == 'top_inlet') return true;
    if (from.type == NodeType.junction &&
        to.type == NodeType.junction &&
        airNodeIds.contains(from.id) &&
        airNodeIds.contains(to.id)) {
      return true;
    }
    return false;
  }

  bool _isFertilizerPipe(PipeConnection pipe, NodeObject from, NodeObject to, Set<String> airNodeIds) {
    if (_isAirPipe(pipe, from, to, airNodeIds)) {
      return false;
    }

    // Tank valves used to fill or drain water sources carry water (ordinary pipe)
    final bool isFromWaterSource = from.type == NodeType.sump ||
        from.type == NodeType.well ||
        from.type == NodeType.overheadTank ||
        from.type == NodeType.naturalSource;
    final bool isToWaterSource = to.type == NodeType.sump ||
        to.type == NodeType.well ||
        to.type == NodeType.overheadTank ||
        to.type == NodeType.naturalSource;
    if (isFromWaterSource || isToWaterSource) {
      return false;
    }

    if (from.type == NodeType.mainFertilizerSource ||
        to.type == NodeType.mainFertilizerSource) {
      return true;
    }

    final bool fromFertTank =
        from.type == NodeType.fertilizerTank && pipe.fromPortId != 'top_inlet';
    final bool toFertTank =
        to.type == NodeType.fertilizerTank && pipe.toPortId != 'top_inlet';
    final bool fromInj = from.type == NodeType.multiInjector &&
        (pipe.fromPortId?.startsWith('channel_') ?? false);
    final bool toInj = to.type == NodeType.multiInjector &&
        (pipe.toPortId?.startsWith('channel_') ?? false);

    return fromFertTank || toFertTank || fromInj || toInj;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Points of ordinary water pipes, air pipes & fertilizer pipes.
    final List<List<Offset>> waterPipePoints = [];
    final List<List<Offset>> airPipePoints = [];
    final List<List<Offset>> fertilizerPipePoints = [];
    _ensureAnalysis();
    final Set<String> airNodeIds = _cacheAir;
    final Set<String> fertilizerPipeIds = _cacheFert;
    final List<List<Offset>> allPipePoints = [];

    final List<Map<String, dynamic>> pipesToDraw = [];

    for (final pipe in pipes) {
      final from = _findNode(pipe.fromNodeId);
      final to = _findNode(pipe.toNodeId);
      if (from == null || to == null) continue;

      final bool isAir = _isAirPipe(pipe, from, to, airNodeIds);
      final bool isFertilizer = fertilizerPipeIds.contains(pipe.id);
      final isSelected = pipe.id == selectedPipeId;

      final int hash = _pipeStateHash(pipe, from, to, _lite);
      Path? curvedPath = _cachedPipePaths[pipe.id];
      List<Offset>? points = _cachedPipePoints[pipe.id];

      if (curvedPath == null || points == null || _cachedPipeStateHash[pipe.id] != hash) {
        final start = portPosition(from, pipe.fromPortId, isInput: false);
        final end = portPosition(to, pipe.toPortId, isInput: true);
        points = <Offset>[start, ...pipe.waypoints, end];

        if (isAir) {
          curvedPath = _buildCurvedPath(points, cornerRadius: 8.0);
        } else if (isFertilizer) {
          curvedPath = _buildFertilizerPath(points, fertilizerPipePoints);
        } else {
          curvedPath = _buildCurvedPath(points, cornerRadius: 10.0);
        }

        _cachedPipePaths[pipe.id] = curvedPath;
        _cachedPipePoints[pipe.id] = points;
        _cachedPipeStateHash[pipe.id] = hash;
      }

      if (cullRect != null) {
        double minX = points.first.dx, maxX = minX;
        double minY = points.first.dy, maxY = minY;
        for (final q in points) {
          if (q.dx < minX) minX = q.dx;
          if (q.dx > maxX) maxX = q.dx;
          if (q.dy < minY) minY = q.dy;
          if (q.dy > maxY) maxY = q.dy;
        }
        if (!cullRect!.overlaps(Rect.fromLTRB(minX, minY, maxX, maxY).inflate(12))) {
          continue; // completely off-screen
        }
      }

      allPipePoints.add(points);

      if (isAir) {
        airPipePoints.add(points);
      } else if (isFertilizer) {
        fertilizerPipePoints.add(points);
      } else {
        waterPipePoints.add(points);
      }

      pipesToDraw.add({
        'pipe': pipe,
        'points': points,
        'path': curvedPath,
        'isSelected': isSelected,
        'isAir': isAir,
        'isFertilizer': isFertilizer,
      });
    }

    for (final pInfo in pipesToDraw) {
      final PipeConnection pipe = pInfo['pipe'];
      final List<Offset> points = pInfo['points'];
      final Path curvedPath = pInfo['path'];
      final bool isSelected = pInfo['isSelected'];
      final bool isAir = pInfo['isAir'];
      final bool isFertilizer = pInfo['isFertilizer'];

      try {
        if (isAir) {
          _drawAirPipe(canvas, points, curvedPath, isSelected, pipe.flowActive);
        } else if (isFertilizer) {
          _drawFertilizerPipe(canvas, points, curvedPath, isSelected, pipe.flowActive);
        } else {
          _drawWaterPipe(canvas, points, curvedPath, isSelected);
        }
      } catch (e, st) {
        debugPrint('PipePainter: failed to draw pipe ${pipe.id}: $e\n$st');
      }
    }

    // Elbows, tees and crosses for water, air and fertilizer pipes.
    if (!_lite) {
      final sig = _calcJunctionsSig(waterPipePoints, airPipePoints, fertilizerPipePoints);
      if (_cachedJunctionsSig != sig) {
        _cachedWaterJunctions = _buildJunctions(waterPipePoints);
        _cachedAirJunctions = _buildJunctions(airPipePoints);
        _cachedFertilizerJunctions = _buildJunctions(fertilizerPipePoints);
        _cachedJunctionsSig = sig;
      }
      _drawJunctionsWithMap(canvas, _cachedWaterJunctions, _pipeDiameter);
      _drawAirJunctionsWithMap(canvas, _cachedAirJunctions, _airDiameter);
      _drawFertilizerJunctionsWithMap(canvas, _cachedFertilizerJunctions, _fertDiameter);
    }

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
        } else if (from.type == NodeType.singleTankValve || from.type == NodeType.multiOutletTankValve) {
          isFertilizerDrag = pipes.any((p) =>
          fertilizerPipeIds.contains(p.id) &&
              (p.fromNodeId == from.id || p.toNodeId == from.id));
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
            } else if (n.type == NodeType.singleTankValve || n.type == NodeType.multiOutletTankValve) {
              if (pipes.any((p) =>
              fertilizerPipeIds.contains(p.id) &&
                  (p.fromNodeId == n.id || p.toNodeId == n.id))) {
                isFertilizerDrag = true;
                break;
              }
            }
          }
        }

        if (isAirDrag) {
          // --- Dragging preview for Air Hose ---
          final casingPaint = _tube(_airEdge, _airDiameter, cap: StrokeCap.round);
          final bodyPaint = _tube(_airBody, _airDiameter - 1.4, cap: StrokeCap.round);
          final lightPaint = _tube(_airLight, _airDiameter * 0.3, cap: StrokeCap.round);

          // Metal ferrule dot at the start port
          canvas.drawCircle(startPos, 5.0, Paint()..color = _metalEdge);
          canvas.drawCircle(startPos, 3.8, Paint()..color = _metalBody);
          canvas.drawCircle(startPos, 2.0, Paint()..color = _airBody);

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
          // --- Dragging preview for Fertilizer Tank ---
          final casingPaint = Paint()
            ..color = const Color(0xFF1B5E20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round;

          final innerPaint = Paint()
            ..color = const Color(0xFF4CAF50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round;

          canvas.drawCircle(startPos, 4.5, Paint()..color = const Color(0xFF1B5E20));
          canvas.drawCircle(startPos, 2.5, Paint()..color = const Color(0xFF4CAF50));

          if (pendingDragPos != null) {
            canvas.drawLine(startPos, pendingDragPos!, casingPaint);
            canvas.drawLine(startPos, pendingDragPos!, innerPaint);
          }
        } else {
          // --- Standard Pipe Dragging Preview ---
          final dashPaint = Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8;
          canvas.drawCircle(startPos, 5.5, dashPaint);
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
    canvas.drawCircle(best, 8, Paint()..color = const Color(0x33FF9800));
    canvas.drawCircle(
      best,
      8,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(best, 2.2, Paint()..color = const Color(0xFFFF9800));
  }

  // ---------------------------------------------------------------------------
  // Path Helper: Smooth Curved Corner Arc Construction
  // ---------------------------------------------------------------------------

  /// Constructs a smooth path from [points], rounding orthogonal corners with [cornerRadius].
  Path _buildCurvedPath(List<Offset> points, {double cornerRadius = 10.0}) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length < 3) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final pPrev = points[i - 1];
      final pCurr = points[i];
      final pNext = points[i + 1];

      final vIn = pCurr - pPrev;
      final lenIn = vIn.distance;
      final vOut = pNext - pCurr;
      final lenOut = vOut.distance;

      if (lenIn < 0.1 || lenOut < 0.1) {
        path.lineTo(pCurr.dx, pCurr.dy);
        continue;
      }

      final uIn = vIn / lenIn;
      final uOut = vOut / lenOut;

      // Check if nearly colinear (straight run)
      final dot = uIn.dx * uOut.dx + uIn.dy * uOut.dy;
      if (dot.abs() > 0.98) {
        path.lineTo(pCurr.dx, pCurr.dy);
        continue;
      }

      // Determine radius based on available segment lengths
      // Never use num.clamp here: it throws when the range is inverted
      // (segment shorter than 4px), which aborted the whole paint() and made
      // every later pipe disappear.
      final double r = math.min(cornerRadius, math.min(lenIn / 2, lenOut / 2));
      if (r < 1.0) {
        path.lineTo(pCurr.dx, pCurr.dy);
        continue;
      }

      final pStart = pCurr - uIn * r;
      final pEnd = pCurr + uOut * r;

      path.lineTo(pStart.dx, pStart.dy);
      path.quadraticBezierTo(pCurr.dx, pCurr.dy, pEnd.dx, pEnd.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  // ---------------------------------------------------------------------------
  // Air hose: glossy blue ribbed hose with chrome clamps (static)
  // ---------------------------------------------------------------------------

  void _drawAirPipe(Canvas canvas, List<Offset> points, Path curvedPath, bool isSelected, bool flowActive) {
    const double d = _airDiameter;

    if (_lite) {
      if (isSelected) {
        canvas.drawPath(
          curvedPath,
          Paint()
            ..color = const Color(0xFFFF9800)
            ..style = PaintingStyle.stroke
            ..strokeWidth = d + 3.0
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawPath(
        curvedPath,
        Paint()
          ..color = flowActive ? _airBody : _airBodyIdle
          ..style = PaintingStyle.stroke
          ..strokeWidth = d
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Selection halo
    if (isSelected) {
      canvas.drawPath(
        curvedPath,
        _tube(const Color(0xFFFF9800).withValues(alpha: 0.75), d + 5.0, cap: StrokeCap.round),
      );
    }

    // Soft contact shadow
    canvas.drawPath(
      curvedPath.shift(const Offset(0, 1.5)),
      _tube(const Color(0x35000000), d + 0.8,
          cap: StrokeCap.round, blur: const MaskFilter.blur(BlurStyle.normal, 1.5)),
    );

    // 1. Dark navy outline
    canvas.drawPath(curvedPath, _tube(_airEdge, d, cap: StrokeCap.round));
    // 2. Main hose body
    canvas.drawPath(
      curvedPath,
      _tube(flowActive ? _airBody : _airBodyIdle, d - 1.4, cap: StrokeCap.round),
    );
    // 3. Shaded underside (gives a round, 3D look)
    canvas.drawPath(
      curvedPath.shift(const Offset(0.6, 0.9)),
      _tube(_airShade.withValues(alpha: 0.70), d * 0.40, cap: StrokeCap.round),
    );
    // 4. Lit top side
    canvas.drawPath(
      curvedPath.shift(const Offset(-0.6, -0.9)),
      _tube(_airLight.withValues(alpha: 0.85), d * 0.32, cap: StrokeCap.round),
    );

    // 5. Hose ribs (corrugation) across the tube
    if (!_lite) _drawRibs(canvas, curvedPath, d);

    // 6. Glossy glint on top of the ribs
    canvas.drawPath(
      curvedPath.shift(const Offset(-0.8, -1.0)),
      _tube(Colors.white.withValues(alpha: 0.70), 0.8, cap: StrokeCap.round),
    );

    // 7. Chrome end clamps
    _airClamp(canvas, points.first, points[1]);
    _airClamp(canvas, points.last, points[points.length - 2]);
  }

  /// Evenly spaced raised rings along the hose.
  void _drawRibs(Canvas canvas, Path path, double d) {
    const double spacing = 6.0;
    const double margin = 14.0;
    final double half = (d - 1.0) / 2;

    final Paint dark = Paint()
      ..isAntiAlias = true
      ..color = _airEdge.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.butt;
    final Paint light = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 0.7
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
        canvas.drawLine(a + u * 1.1, b + u * 1.1, light);
      }
    }
  }

  /// Chrome ferrule + hose clamp with a screw lug at a pipe end.
  void _airClamp(Canvas canvas, Offset from, Offset toward) {
    final Offset v = toward - from;
    final double len = v.distance;
    if (len < 24) return;
    final Offset u = v / len;
    final Offset n = Offset(-u.dy, u.dx);

    // Steel ferrule (the port nipple)
    final Offset f0 = from + u * 1.2;
    final Offset f1 = from + u * 5.0;
    const double fw = _airDiameter + 1.4;
    canvas.drawLine(f0, f1, _tube(_metalEdge, fw));
    canvas.drawLine(f0, f1, _tube(_metalSteel, fw - 1.0));
    canvas.drawLine(
      f0 + const Offset(-0.4, -0.6),
      f1 + const Offset(-0.4, -0.6),
      _tube(_metalLight.withValues(alpha: 0.8), fw * 0.25),
    );

    // Clamp band
    final Offset a = from + u * 6.0;
    final Offset b = from + u * 13.0;
    const double w = _airDiameter + 2.8;
    canvas.drawLine(a, b, _tube(_metalEdge, w));
    canvas.drawLine(a, b, _tube(_metalBody, w - 1.1));
    canvas.drawLine(
      a + const Offset(-0.5, -0.7),
      b + const Offset(-0.5, -0.7),
      _tube(_metalLight, w * 0.3),
    );

    // Grooves at both edges of the band
    final Paint groove = _tube(_metalEdge.withValues(alpha: 0.55), 0.6);
    for (final Offset g in [a + u * 1.2, b - u * 1.2]) {
      canvas.drawLine(g - n * (w / 2 - 0.5), g + n * (w / 2 - 0.5), groove);
    }

    // Screw lug on the upper side of the band
    final double sign = n.dy <= 0 ? 1.0 : -1.0;
    final Offset lug = from + u * 9.5 + n * sign * (w / 2 - 0.2);
    canvas.drawCircle(lug, 1.8, Paint()..color = _metalEdge);
    canvas.drawCircle(lug, 1.2, Paint()..color = _metalBody);
    canvas.drawLine(
      lug - u * 0.8,
      lug + u * 0.8,
      _tube(_metalEdge, 0.5),
    );
  }

  void _drawAirJunctionsWithMap(Canvas canvas, Map<Offset, List<Offset>> junctions, double d) {
    if (junctions.isEmpty) return;
    junctions.forEach((pos, dirs) {
      if (dirs.length < 2) return;

      // Straight pass-through: no fitting needed.
      if (dirs.length == 2) {
        final dot = dirs[0].dx * dirs[1].dx + dirs[0].dy * dirs[1].dy;
        if (dot < -0.97) return;

        _drawAirElbowFitting(canvas, pos, dirs[0], dirs[1], d);
        return;
      }

      if (dirs.length == 3) {
        _drawAirTeeFitting(canvas, pos, dirs, d);
      } else if (dirs.length >= 4) {
        _drawAirCrossFitting(canvas, pos, dirs, d);
      }
    });
  }

  void _drawAirJunctions(Canvas canvas, List<List<Offset>> pipePoints) {
    if (pipePoints.isEmpty) return;
    _drawAirJunctionsWithMap(canvas, _buildJunctions(pipePoints), _airDiameter);
  }

  void _drawAirElbowFitting(Canvas canvas, Offset pos, Offset u1, Offset u2, double d) {
    final double sLen = d * 1.5;
    final Offset p1 = pos + u1 * sLen;
    final Offset p2 = pos + u2 * sLen;

    final Path elbowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(pos.dx, pos.dy, p2.dx, p2.dy);

    canvas.drawPath(elbowPath, _tube(_metalEdge, d + 2.0, cap: StrokeCap.round));
    canvas.drawPath(elbowPath, _tube(_metalBody, d + 0.6, cap: StrokeCap.round));
    canvas.drawPath(
      elbowPath.shift(const Offset(-0.6, -0.8)),
      _tube(_metalLight, d * 0.35, cap: StrokeCap.round),
    );

    _metalSocketBand(canvas, p1, u1, d);
    _metalSocketBand(canvas, p2, u2, d);
  }

  void _drawAirTeeFitting(Canvas canvas, Offset pos, List<Offset> dirs, double d) {
    if (dirs.length < 3) return;

    int m1 = 0, m2 = 1;
    double minDot = 1.0;
    for (int i = 0; i < dirs.length; i++) {
      for (int j = i + 1; j < dirs.length; j++) {
        final dot = dirs[i].dx * dirs[j].dx + dirs[i].dy * dirs[j].dy;
        if (dot < minDot) {
          minDot = dot;
          m1 = i;
          m2 = j;
        }
      }
    }

    final Offset uMain1 = dirs[m1];
    final Offset uMain2 = dirs[m2];
    final Offset uBranch = dirs.firstWhere((e) => e != uMain1 && e != uMain2, orElse: () => dirs[2]);

    final double sDist = d * 1.8;
    final Offset p1 = pos + uMain1 * sDist;
    final Offset p2 = pos + uMain2 * sDist;
    final Offset pB = pos + uBranch * sDist;

    // Main run
    canvas.drawLine(p1, p2, _tube(_metalEdge, d + 2.0, cap: StrokeCap.butt));
    canvas.drawLine(p1, p2, _tube(_metalBody, d + 0.6, cap: StrokeCap.butt));
    canvas.drawLine(
      p1 + const Offset(-0.6, -0.8),
      p2 + const Offset(-0.6, -0.8),
      _tube(_metalLight, d * 0.35, cap: StrokeCap.butt),
    );

    // Branch run
    canvas.drawLine(pos, pB, _tube(_metalEdge, d + 2.0, cap: StrokeCap.butt));
    canvas.drawLine(pos, pB, _tube(_metalBody, d + 0.6, cap: StrokeCap.butt));
    canvas.drawLine(
      pos + const Offset(-0.6, -0.8),
      pB + const Offset(-0.6, -0.8),
      _tube(_metalLight, d * 0.35, cap: StrokeCap.butt),
    );

    // Accent blue ring on hub
    canvas.drawCircle(pos, d * 0.5, _tube(_airBody, 1.2));

    _metalSocketBand(canvas, p1, uMain1, d);
    _metalSocketBand(canvas, p2, uMain2, d);
    _metalSocketBand(canvas, pB, uBranch, d);
  }

  void _drawAirCrossFitting(Canvas canvas, Offset pos, List<Offset> dirs, double d) {
    final double sDist = d * 1.8;
    for (final u in dirs) {
      final Offset p = pos + u * sDist;
      canvas.drawLine(pos, p, _tube(_metalEdge, d + 2.0, cap: StrokeCap.butt));
      canvas.drawLine(pos, p, _tube(_metalBody, d + 0.6, cap: StrokeCap.butt));
      canvas.drawLine(
        pos + const Offset(-0.6, -0.8),
        p + const Offset(-0.6, -0.8),
        _tube(_metalLight, d * 0.35, cap: StrokeCap.butt),
      );
      _metalSocketBand(canvas, p, u, d);
    }
    canvas.drawCircle(pos, d * 0.5, _tube(_airBody, 1.2));
  }

  void _metalSocketBand(Canvas canvas, Offset pos, Offset dir, double d) {
    final double w = d + 2.4;
    final Offset n = Offset(-dir.dy, dir.dx);
    final Offset a = pos - n * (w / 2);
    final Offset b = pos + n * (w / 2);

    canvas.drawLine(a, b, _tube(_metalEdge, 2.0));
    canvas.drawLine(a, b, _tube(_metalBody, 1.2));
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
      ..maskFilter = _lite ? null : blur;
  }

  void _drawWaterPipe(Canvas canvas, List<Offset> points, Path curvedPath, bool isSelected) {
    const double d = _pipeDiameter;

    if (_lite) {
      if (isSelected) {
        canvas.drawPath(
          curvedPath,
          Paint()
            ..color = const Color(0xFFFF9800)
            ..style = PaintingStyle.stroke
            ..strokeWidth = d + 3.0
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawPath(
        curvedPath,
        Paint()
          ..color = _pipeBody
          ..style = PaintingStyle.stroke
          ..strokeWidth = d
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Selection halo (the pipe itself keeps its normal colours).
    if (isSelected) {
      canvas.drawPath(
        curvedPath,
        _tube(const Color(0xFFFF9800).withValues(alpha: 0.65), d + 5.0, cap: StrokeCap.round),
      );
    }

    // Soft contact shadow.
    canvas.drawPath(
      curvedPath.shift(const Offset(0, 1.4)),
      _tube(const Color(0x38000000), d + 0.8,
          cap: StrokeCap.round, blur: const MaskFilter.blur(BlurStyle.normal, 1.4)),
    );

    // Tube layers, lit from the top-left: edge -> body -> shade -> light -> glint.
    canvas.drawPath(curvedPath, _tube(_pipeEdge, d, cap: StrokeCap.round));
    canvas.drawPath(curvedPath, _tube(_pipeBody, d - 1.2, cap: StrokeCap.round));
    canvas.drawPath(
      curvedPath.shift(const Offset(0.6, 0.8)),
      _tube(_pipeShade.withValues(alpha: 0.60), d * 0.38, cap: StrokeCap.round),
    );
    canvas.drawPath(
      curvedPath.shift(const Offset(-0.6, -0.8)),
      _tube(_pipeLight, d * 0.35, cap: StrokeCap.round),
    );
    canvas.drawPath(
      curvedPath.shift(const Offset(-0.8, -1.0)),
      _tube(Colors.white.withValues(alpha: 0.65), 0.8, cap: StrokeCap.round),
    );

    // Coupling collars near both ends of the pipe (where attached to nodes).
    _collar(canvas, points.first, points[1]);
    _collar(canvas, points.last, points[points.length - 2]);

    // Socket collar bands framing intermediate 90-degree bend elbows.
    _drawElbowBendCollars(canvas, points);
  }

  void _collar(Canvas canvas, Offset from, Offset toward) {
    final Offset v = toward - from;
    final double len = v.distance;
    if (len < 18) return;
    final Offset u = v / len;
    final Offset a = from + u * 3.5;
    final Offset b = from + u * 8.5;
    const double w = _pipeDiameter + 2.0;

    canvas.drawLine(a, b, _tube(_pipeEdge, w));
    canvas.drawLine(a, b, _tube(_pipeBody, w - 1.0));
    canvas.drawLine(
      a + const Offset(-0.5, -0.7),
      b + const Offset(-0.5, -0.7),
      _tube(_pipeLight, w * 0.3),
    );
  }

  /// Socket collar bands at intermediate bends (waypoint elbows).
  void _drawElbowBendCollars(Canvas canvas, List<Offset> points) {
    if (points.length < 3) return;
    const double d = _pipeDiameter;

    for (int i = 1; i < points.length - 1; i++) {
      final pPrev = points[i - 1];
      final pCurr = points[i];
      final pNext = points[i + 1];

      final vIn = pCurr - pPrev;
      final lenIn = vIn.distance;
      final vOut = pNext - pCurr;
      final lenOut = vOut.distance;

      if (lenIn < 0.1 || lenOut < 0.1) continue;

      final uIn = vIn / lenIn;
      final uOut = vOut / lenOut;

      final dot = uIn.dx * uOut.dx + uIn.dy * uOut.dy;
      if (dot.abs() > 0.98) continue; // skip straight runs

      final double r = math.min(10.0, math.min(lenIn / 2, lenOut / 2));
      if (r < 1.0) continue; // segment too short for a collar

      final Offset pStart = pCurr - uIn * r;
      final Offset pEnd = pCurr + uOut * r;

      _socketBand(canvas, pStart, uIn, d);
      _socketBand(canvas, pEnd, uOut, d);
    }
  }

  void _socketBand(Canvas canvas, Offset pos, Offset dir, double d) {
    final double w = d + 2.0;
    final Offset n = Offset(-dir.dy, dir.dx);
    final Offset a = pos - n * (w / 2);
    final Offset b = pos + n * (w / 2);

    final Offset bandOffset = dir * 2.0;
    final Offset a2 = a + bandOffset;
    final Offset b2 = b + bandOffset;

    final Path bandPath = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(a2.dx, a2.dy)
      ..close();

    canvas.drawPath(bandPath, Paint()..color = _pipeEdge..style = PaintingStyle.fill);

    final Path innerPath = Path()
      ..moveTo(a.dx + dir.dx * 0.3, a.dy + dir.dy * 0.3)
      ..lineTo(b.dx + dir.dx * 0.3, b.dy + dir.dy * 0.3)
      ..lineTo(b2.dx - dir.dx * 0.3, b2.dy - dir.dy * 0.3)
      ..lineTo(a2.dx - dir.dx * 0.3, a2.dy - dir.dy * 0.3)
      ..close();
    canvas.drawPath(innerPath, Paint()..color = _pipeBody..style = PaintingStyle.fill);

    canvas.drawLine(
      a + const Offset(-0.4, -0.6),
      b + const Offset(-0.4, -0.6),
      Paint()..color = _pipeLight..strokeWidth = 0.8..style = PaintingStyle.stroke,
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

  void _drawJunctionsWithMap(Canvas canvas, Map<Offset, List<Offset>> junctions, double d) {
    if (junctions.isEmpty) return;
    junctions.forEach((pos, dirs) {
      if (dirs.length < 2) return;

      // Straight pass-through: no fitting needed.
      if (dirs.length == 2) {
        final dot = dirs[0].dx * dirs[1].dx + dirs[0].dy * dirs[1].dy;
        if (dot < -0.97) return;

        // Draw sleek elbow fitting for 2-way meeting point
        _drawElbowFitting(canvas, pos, dirs[0], dirs[1], d);
        return;
      }

      // Tee (3-way) or Cross (4-way) fittings
      if (dirs.length == 3) {
        _drawTeeFitting(canvas, pos, dirs, d);
      } else if (dirs.length >= 4) {
        _drawCrossFitting(canvas, pos, dirs, d);
      }
    });
  }

  void _drawJunctions(Canvas canvas, List<List<Offset>> pipePoints) {
    if (pipePoints.isEmpty) return;
    _drawJunctionsWithMap(canvas, _buildJunctions(pipePoints), _pipeDiameter);
  }

  void _drawElbowFitting(Canvas canvas, Offset pos, Offset u1, Offset u2, double d) {
    final double sLen = d * 1.5;
    final Offset p1 = pos + u1 * sLen;
    final Offset p2 = pos + u2 * sLen;

    final Path elbowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(pos.dx, pos.dy, p2.dx, p2.dy);

    canvas.drawPath(
      elbowPath.shift(const Offset(0, 1.2)),
      _tube(const Color(0x35000000), d + 1.2, cap: StrokeCap.round, blur: const MaskFilter.blur(BlurStyle.normal, 1.4)),
    );

    canvas.drawPath(elbowPath, _tube(_pipeEdge, d + 1.2, cap: StrokeCap.round));
    canvas.drawPath(elbowPath, _tube(_pipeBody, d - 0.2, cap: StrokeCap.round));
    canvas.drawPath(
      elbowPath.shift(const Offset(0.6, 0.8)),
      _tube(_pipeShade.withValues(alpha: 0.60), d * 0.38, cap: StrokeCap.round),
    );
    canvas.drawPath(
      elbowPath.shift(const Offset(-0.6, -0.8)),
      _tube(_pipeLight, d * 0.35, cap: StrokeCap.round),
    );
    canvas.drawPath(
      elbowPath.shift(const Offset(-0.8, -1.0)),
      _tube(Colors.white.withValues(alpha: 0.65), 0.8, cap: StrokeCap.round),
    );

    _socketBand(canvas, p1, u1, d);
    _socketBand(canvas, p2, u2, d);
  }

  void _drawTeeFitting(Canvas canvas, Offset pos, List<Offset> dirs, double d) {
    if (dirs.length < 3) return;

    int m1 = 0, m2 = 1;
    double minDot = 1.0;
    for (int i = 0; i < dirs.length; i++) {
      for (int j = i + 1; j < dirs.length; j++) {
        final dot = dirs[i].dx * dirs[j].dx + dirs[i].dy * dirs[j].dy;
        if (dot < minDot) {
          minDot = dot;
          m1 = i;
          m2 = j;
        }
      }
    }

    final Offset uMain1 = dirs[m1];
    final Offset uMain2 = dirs[m2];
    final Offset uBranch = dirs.firstWhere((e) => e != uMain1 && e != uMain2, orElse: () => dirs[2]);

    final double sDist = d * 1.8;
    final Offset p1 = pos + uMain1 * sDist;
    final Offset p2 = pos + uMain2 * sDist;
    final Offset pB = pos + uBranch * sDist;

    // Drop shadow
    canvas.drawLine(
      p1 + const Offset(0, 1.2),
      p2 + const Offset(0, 1.2),
      _tube(const Color(0x35000000), d + 1.2, blur: const MaskFilter.blur(BlurStyle.normal, 1.4)),
    );
    canvas.drawLine(
      pos + const Offset(0, 1.2),
      pB + const Offset(0, 1.2),
      _tube(const Color(0x35000000), d + 1.2, blur: const MaskFilter.blur(BlurStyle.normal, 1.4)),
    );

    // Main run
    canvas.drawLine(p1, p2, _tube(_pipeEdge, d + 1.2, cap: StrokeCap.butt));
    canvas.drawLine(p1, p2, _tube(_pipeBody, d - 0.2, cap: StrokeCap.butt));
    canvas.drawLine(
      p1 + const Offset(0.6, 0.8),
      p2 + const Offset(0.6, 0.8),
      _tube(_pipeShade.withValues(alpha: 0.60), d * 0.38, cap: StrokeCap.butt),
    );
    canvas.drawLine(
      p1 + const Offset(-0.6, -0.8),
      p2 + const Offset(-0.6, -0.8),
      _tube(_pipeLight, d * 0.35, cap: StrokeCap.butt),
    );

    // Branch run
    canvas.drawLine(pos, pB, _tube(_pipeEdge, d + 1.2, cap: StrokeCap.butt));
    canvas.drawLine(pos, pB, _tube(_pipeBody, d - 0.2, cap: StrokeCap.butt));
    canvas.drawLine(
      pos + const Offset(0.6, 0.8),
      pB + const Offset(0.6, 0.8),
      _tube(_pipeShade.withValues(alpha: 0.60), d * 0.38, cap: StrokeCap.butt),
    );
    canvas.drawLine(
      pos + const Offset(-0.6, -0.8),
      pB + const Offset(-0.6, -0.8),
      _tube(_pipeLight, d * 0.35, cap: StrokeCap.butt),
    );

    // Compact T-center reinforcement cap
    final double hubR = d * 0.65;
    final Rect hubRect = Rect.fromCircle(center: pos, radius: hubR);
    canvas.drawCircle(pos + const Offset(0, 0.8), hubR, Paint()..color = const Color(0x30000000));
    canvas.drawCircle(
      pos,
      hubR,
      Paint()
        ..isAntiAlias = true
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [_pipeLight, _pipeBody, _pipeEdge],
          stops: [0.0, 0.6, 1.0],
        ).createShader(hubRect),
    );
    canvas.drawCircle(pos, hubR, _tube(_pipeEdge, 0.7));

    _socketBand(canvas, p1, uMain1, d);
    _socketBand(canvas, p2, uMain2, d);
    _socketBand(canvas, pB, uBranch, d);
  }

  void _drawCrossFitting(Canvas canvas, Offset pos, List<Offset> dirs, double d) {
    final double sDist = d * 1.8;

    for (final u in dirs) {
      final Offset pArm = pos + u * sDist;
      canvas.drawLine(
        pos + const Offset(0, 1.2),
        pArm + const Offset(0, 1.2),
        _tube(const Color(0x35000000), d + 1.2, blur: const MaskFilter.blur(BlurStyle.normal, 1.4)),
      );
      canvas.drawLine(pos, pArm, _tube(_pipeEdge, d + 1.2, cap: StrokeCap.butt));
      canvas.drawLine(pos, pArm, _tube(_pipeBody, d - 0.2, cap: StrokeCap.butt));
      canvas.drawLine(
        pos + const Offset(0.6, 0.8),
        pArm + const Offset(0.6, 0.8),
        _tube(_pipeShade.withValues(alpha: 0.60), d * 0.38, cap: StrokeCap.butt),
      );
      canvas.drawLine(
        pos + const Offset(-0.6, -0.8),
        pArm + const Offset(-0.6, -0.8),
        _tube(_pipeLight, d * 0.35, cap: StrokeCap.butt),
      );
    }

    final double hubR = d * 0.75;
    final Rect hubRect = Rect.fromCircle(center: pos, radius: hubR);
    canvas.drawCircle(pos + const Offset(0, 0.8), hubR, Paint()..color = const Color(0x30000000));
    canvas.drawCircle(
      pos,
      hubR,
      Paint()
        ..isAntiAlias = true
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [_pipeLight, _pipeBody, _pipeEdge],
          stops: [0.0, 0.6, 1.0],
        ).createShader(hubRect),
    );
    canvas.drawCircle(pos, hubR, _tube(_pipeEdge, 0.7));

    for (final u in dirs) {
      _socketBand(canvas, pos + u * sDist, u, d);
    }
  }

  // ---------------------------------------------------------------------------
  // Fertilizer Pipe Path & Chemical Dosing Fittings
  // ---------------------------------------------------------------------------

  Offset? _lineIntersection(Offset a1, Offset a2, Offset b1, Offset b2) {
    final double denom = (a2.dx - a1.dx) * (b2.dy - b1.dy) - (a2.dy - a1.dy) * (b2.dx - b1.dx);
    if (denom.abs() < 1e-5) return null;

    final double t = ((b1.dx - a1.dx) * (b2.dy - b1.dy) - (b1.dy - a1.dy) * (b2.dx - b1.dx)) / denom;
    final double u = ((b1.dx - a1.dx) * (a2.dy - a1.dy) - (b1.dy - a1.dy) * (a2.dx - a1.dx)) / denom;

    if (t > 0.08 && t < 0.92 && u > 0.08 && u < 0.92) {
      return Offset(a1.dx + t * (a2.dx - a1.dx), a1.dy + t * (a2.dy - a1.dy));
    }
    return null;
  }

  Path _buildFertilizerPath(List<Offset> points, List<List<Offset>> otherPipePoints) {
    if (_lite) {
      return _buildCurvedPath(points, cornerRadius: 6.0);
    }
    final Path path = Path();
    if (points.isEmpty) return path;
    if (points.length < 2) {
      path.moveTo(points.first.dx, points.first.dy);
      return path;
    }

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final pCurr = points[i];
      final pNext = points[i + 1];
      final v = pNext - pCurr;
      final len = v.distance;

      if (len < 0.1) continue;
      final u = v / len;
      final n = Offset(-u.dy, u.dx); // perpendicular normal vector

      final bool isVertical = (v.dx.abs() < 1.0);

      // Find interior crossings on this segment
      final List<Offset> crossings = [];
      for (final otherPts in otherPipePoints) {
        if (identical(otherPts, points)) continue;
        for (int j = 0; j < otherPts.length - 1; j++) {
          final qCurr = otherPts[j];
          final qNext = otherPts[j + 1];
          final bool otherIsVertical = ((qNext.dx - qCurr.dx).abs() < 1.0);

          // Vertical pipes get a clean bridge jump over horizontal pipes
          if (isVertical && !otherIsVertical) {
            final pt = _lineIntersection(pCurr, pNext, qCurr, qNext);
            if (pt != null) {
              if ((pt - pCurr).distance > 10.0 &&
                  (pt - pNext).distance > 10.0 &&
                  (pt - qCurr).distance > 10.0 &&
                  (pt - qNext).distance > 10.0) {
                crossings.add(pt);
              }
            }
          }
        }
      }

      if (crossings.isEmpty) {
        path.lineTo(pNext.dx, pNext.dy);
      } else {
        crossings.sort((a, b) => (a - pCurr).distance.compareTo((b - pCurr).distance));

        for (final c in crossings) {
          final Offset cStart = c - u * 6.0;
          final Offset cEnd = c + u * 6.0;
          final Offset cMid = c + n * 5.0;

          path.lineTo(cStart.dx, cStart.dy);
          path.quadraticBezierTo(cMid.dx, cMid.dy, cEnd.dx, cEnd.dy);
        }
        path.lineTo(pNext.dx, pNext.dy);
      }
    }

    return path;
  }

  void _drawFertilizerPipe(
      Canvas canvas,
      List<Offset> points,
      Path path,
      bool isSelected,
      bool flowActive,
      ) {
    const double d = _fertDiameter;

    if (_lite) {
      if (isSelected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFF9800)
            ..style = PaintingStyle.stroke
            ..strokeWidth = d + 3.0
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = flowActive ? _fertFlow : _fertBody
          ..style = PaintingStyle.stroke
          ..strokeWidth = d
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // 1. Selection halo
    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFF9800)
          ..style = PaintingStyle.stroke
          ..strokeWidth = d + 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 2. Drop shadow for depth & jump bridge separation
    canvas.drawPath(
      path.shift(const Offset(0, 1.0)),
      Paint()
        ..color = const Color(0x3B000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = d + 0.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = _lite ? null : const MaskFilter.blur(BlurStyle.normal, 1.0),
    );

    // 3. Outer casing
    canvas.drawPath(
      path,
      Paint()
        ..color = _fertEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = d
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 4. Tube body
    canvas.drawPath(
      path,
      Paint()
        ..color = _fertBody
        ..style = PaintingStyle.stroke
        ..strokeWidth = d - 1.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 5. Chemical flow stream
    canvas.drawPath(
      path,
      Paint()
        ..color = flowActive ? _fertFlow : _fertFlowIdle
        ..style = PaintingStyle.stroke
        ..strokeWidth = d - 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 6. Glossy sheen highlight
    canvas.drawPath(
      path.shift(const Offset(-0.4, -0.4)),
      Paint()
        ..color = _fertLight.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 7. Mini socket collars at start/end ports & bend elbows
    _fertilizerCollar(canvas, points.first, points[1]);
    _fertilizerCollar(canvas, points.last, points[points.length - 2]);
    _drawFertilizerElbowBendCollars(canvas, points);
  }

  void _drawFertilizerJunctionsWithMap(Canvas canvas, Map<Offset, List<Offset>> junctions, double d) {
    if (junctions.isEmpty) return;
    junctions.forEach((pos, dirs) {
      if (dirs.length < 2) return;

      if (dirs.length == 2) {
        final dot = dirs[0].dx * dirs[1].dx + dirs[0].dy * dirs[1].dy;
        if (dot < -0.97) return;

        _drawFertilizerElbowFitting(canvas, pos, dirs[0], dirs[1], d);
        return;
      }

      if (dirs.length == 3) {
        _drawFertilizerTeeFitting(canvas, pos, dirs, d);
      } else if (dirs.length >= 4) {
        _drawFertilizerCrossFitting(canvas, pos, dirs, d);
      }
    });
  }

  void _drawFertilizerJunctions(Canvas canvas, List<List<Offset>> pipePoints) {
    if (pipePoints.isEmpty) return;
    _drawFertilizerJunctionsWithMap(canvas, _buildJunctions(pipePoints), _fertDiameter);
  }

  void _drawFertilizerElbowFitting(Canvas canvas, Offset pos, Offset u1, Offset u2, double d) {
    final double sLen = d * 1.2;
    final Offset p1 = pos + u1 * sLen;
    final Offset p2 = pos + u2 * sLen;

    final Path elbowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(pos.dx, pos.dy, p2.dx, p2.dy);

    canvas.drawPath(elbowPath, _tube(_fertEdge, d + 0.8, cap: StrokeCap.round));
    canvas.drawPath(elbowPath, _tube(_fertBody, d - 0.2, cap: StrokeCap.round));

    _fertilizerSocketBand(canvas, p1, u1, d);
    _fertilizerSocketBand(canvas, p2, u2, d);
  }

  void _drawFertilizerTeeFitting(Canvas canvas, Offset pos, List<Offset> dirs, double d) {
    if (dirs.length < 3) return;

    int m1 = 0, m2 = 1;
    double minDot = 1.0;
    for (int i = 0; i < dirs.length; i++) {
      for (int j = i + 1; j < dirs.length; j++) {
        final dot = dirs[i].dx * dirs[j].dx + dirs[i].dy * dirs[j].dy;
        if (dot < minDot) {
          minDot = dot;
          m1 = i;
          m2 = j;
        }
      }
    }

    final Offset uMain1 = dirs[m1];
    final Offset uMain2 = dirs[m2];
    final Offset uBranch = dirs.firstWhere((e) => e != uMain1 && e != uMain2, orElse: () => dirs[2]);

    final double sDist = d * 1.4;
    final Offset p1 = pos + uMain1 * sDist;
    final Offset p2 = pos + uMain2 * sDist;
    final Offset pB = pos + uBranch * sDist;

    // Main run
    canvas.drawLine(p1, p2, _tube(_fertEdge, d + 0.8, cap: StrokeCap.butt));
    canvas.drawLine(p1, p2, _tube(_fertBody, d - 0.2, cap: StrokeCap.butt));

    // Branch run
    canvas.drawLine(pos, pB, _tube(_fertEdge, d + 0.8, cap: StrokeCap.butt));
    canvas.drawLine(pos, pB, _tube(_fertBody, d - 0.2, cap: StrokeCap.butt));

    // Compact junction center dot
    canvas.drawCircle(pos, d * 0.5, Paint()..color = _fertEdge);
    canvas.drawCircle(pos, d * 0.35, Paint()..color = _fertMetalBody);

    _fertilizerSocketBand(canvas, p1, uMain1, d);
    _fertilizerSocketBand(canvas, p2, uMain2, d);
    _fertilizerSocketBand(canvas, pB, uBranch, d);
  }

  void _drawFertilizerCrossFitting(Canvas canvas, Offset pos, List<Offset> dirs, double d) {
    final double sDist = d * 1.4;

    for (final u in dirs) {
      final Offset pArm = pos + u * sDist;
      canvas.drawLine(pos, pArm, _tube(_fertEdge, d + 0.8, cap: StrokeCap.butt));
      canvas.drawLine(pos, pArm, _tube(_fertBody, d - 0.2, cap: StrokeCap.butt));
    }

    // Compact junction center dot
    canvas.drawCircle(pos, d * 0.55, Paint()..color = _fertEdge);
    canvas.drawCircle(pos, d * 0.4, Paint()..color = _fertMetalBody);

    for (final u in dirs) {
      _fertilizerSocketBand(canvas, pos + u * sDist, u, d);
    }
  }

  void _fertilizerSocketBand(Canvas canvas, Offset pos, Offset dir, double d) {
    final double w = d + 1.2;
    final Offset n = Offset(-dir.dy, dir.dx);
    final Offset a = pos - n * (w / 2);
    final Offset b = pos + n * (w / 2);

    final Offset bandOffset = dir * 1.5;
    final Offset a2 = a + bandOffset;
    final Offset b2 = b + bandOffset;

    final Path bandPath = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(a2.dx, a2.dy)
      ..close();

    canvas.drawPath(bandPath, Paint()..color = _fertMetalEdge..style = PaintingStyle.fill);

    final Path innerPath = Path()
      ..moveTo(a.dx + dir.dx * 0.2, a.dy + dir.dy * 0.2)
      ..lineTo(b.dx + dir.dx * 0.2, b.dy + dir.dy * 0.2)
      ..lineTo(b2.dx - dir.dx * 0.2, b2.dy - dir.dy * 0.2)
      ..lineTo(a2.dx - dir.dx * 0.2, a2.dy - dir.dy * 0.2)
      ..close();
    canvas.drawPath(innerPath, Paint()..color = _fertMetalBody..style = PaintingStyle.fill);

    canvas.drawLine(
      a + const Offset(-0.3, -0.3),
      b + const Offset(-0.3, -0.3),
      Paint()..color = _fertMetalLight..strokeWidth = 0.5..style = PaintingStyle.stroke,
    );
  }

  void _fertilizerCollar(Canvas canvas, Offset from, Offset toward) {
    final Offset v = toward - from;
    final double len = v.distance;
    if (len < 12) return;
    final Offset u = v / len;
    final Offset a = from + u * 2.0;
    final Offset b = from + u * 5.0;
    const double w = _fertDiameter + 1.2;

    canvas.drawLine(a, b, _tube(_fertEdge, w));
    canvas.drawLine(a, b, _tube(_fertBody, w - 0.8));
  }

  void _drawFertilizerElbowBendCollars(Canvas canvas, List<Offset> points) {
    if (points.length < 3) return;
    const double d = _fertDiameter;

    for (int i = 1; i < points.length - 1; i++) {
      final pPrev = points[i - 1];
      final pCurr = points[i];
      final pNext = points[i + 1];

      final vIn = pCurr - pPrev;
      final lenIn = vIn.distance;
      final vOut = pNext - pCurr;
      final lenOut = vOut.distance;

      if (lenIn < 0.1 || lenOut < 0.1) continue;

      final uIn = vIn / lenIn;
      final uOut = vOut / lenOut;

      final dot = uIn.dx * uOut.dx + uIn.dy * uOut.dy;
      if (dot.abs() > 0.98) continue;

      final double r = math.min(6.0, math.min(lenIn / 2, lenOut / 2));
      if (r < 1.0) continue;

      final Offset pStart = pCurr - uIn * r;
      final Offset pEnd = pCurr + uOut * r;

      _fertilizerSocketBand(canvas, pStart, uIn, d);
      _fertilizerSocketBand(canvas, pEnd, uOut, d);
    }
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

/// Ids of nodes that belong to a PURE air network: every blower, plus every
/// junction whose connected group of junctions reaches only air terminals
/// (a blower outlet or a fertilizer tank's top port) and no liquid terminal.
///
/// A junction group that also touches a liquid port (pump, valve, tank side
/// inlet/outlet, injector...) is mixed and is NOT air, so connecting a blower
/// can never turn the fertilizer pipes blue.
Set<String> computeAirNodeIds(List<NodeObject> nodes, List<PipeConnection> pipes) {
  final byId = {for (final n in nodes) n.id: n};
  final result = <String>{
    for (final n in nodes)
      if (n.type == NodeType.blower) n.id,
  };

  // union-find over junctions
  final parent = <String, String>{};
  String find(String x) {
    var r = x;
    while (parent[r] != r) {
      r = parent[r]!;
    }
    while (parent[x] != r) {
      final nx = parent[x]!;
      parent[x] = r;
      x = nx;
    }
    return r;
  }

  bool isJ(String id) => byId[id]?.type == NodeType.junction;
  for (final n in nodes) {
    if (n.type == NodeType.junction) parent[n.id] = n.id;
  }
  for (final p in pipes) {
    if (isJ(p.fromNodeId) && isJ(p.toNodeId)) {
      parent[find(p.fromNodeId)] = find(p.toNodeId);
    }
  }

  final airTerminals = <String, int>{};
  final liquidTerminals = <String, int>{};
  void terminal(String junctionId, NodeObject? other, String? port) {
    if (other == null) return;
    final root = find(junctionId);
    final bool air = other.type == NodeType.blower ||
        (other.type == NodeType.fertilizerTank && port == 'top_inlet');
    final map = air ? airTerminals : liquidTerminals;
    map[root] = (map[root] ?? 0) + 1;
  }

  for (final p in pipes) {
    final fj = isJ(p.fromNodeId), tj = isJ(p.toNodeId);
    if (fj && !tj) terminal(p.fromNodeId, byId[p.toNodeId], p.toPortId);
    if (tj && !fj) terminal(p.toNodeId, byId[p.fromNodeId], p.fromPortId);
  }

  for (final id in parent.keys) {
    final root = find(id);
    if ((airTerminals[root] ?? 0) > 0 && (liquidTerminals[root] ?? 0) == 0) {
      result.add(id);
    }
  }
  return result;
}