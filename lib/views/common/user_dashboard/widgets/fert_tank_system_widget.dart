import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oro_drip_irrigation/models/customer/site_model.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';

/// Fertilizer tank concept (shown only when fertilizerChannel exists).
///
/// WEB (horizontal, wraps instead of scrolling). Tanks flow left -> right and
/// WRAP to the next row when [maxWidth] is reached. Every row is joined to the
/// same main-source collector line, and every row has its own injector lines:
///
///  [Main]─[Pump]─┬──[in]─[Tank 1]─[out1][out2]──┬──[in]─[Tank 2]─[out3]
///                │                              └ rail ...      │   │
///                │                                    ─────────●───●── I1
///                │                                    ──────────────●── I2
///                │
///                └──[in]─[Tank 3]─[out4]
///                                 │
///                                 ───────●──  I3
///
/// MOBILE (vertical): one row per outlet valve, mirrored right -> left.
///
/// Lines are BROKEN at every icon so they never run behind a widget.
class FertTankSystemWidget extends StatelessWidget {
  final FertTankSystem system;
  final int customerId, controllerId, modelId;
  final String deviceId;
  final bool isWide;

  /// Web only: total width (incl. padding) the widget may use before the
  /// tanks wrap to the next row. null = never wrap.
  final double? maxWidth;

  const FertTankSystemWidget({
    super.key,
    required this.system,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
    required this.deviceId,
    required this.isWide,
    this.maxWidth,
  });

  static const double colW = 76;
  static const double connW = 22;
  static const double rowH = 74;
  static const double iconCy = 20;
  static const double injGap = 30;

  // mobile-only constants
  static const double injGapMobile = 18;
  static const double valveColW = 56; // mobile valve column width (was colW = 76)
  static const double mainColW = 56; // mobile main source/pump column width (was colW = 76)
  static const double tankColW = 56; // mobile tank column width (was colW = 76)

  // horizontal (web) layout constants
  static const double hGap = 16;
  static const double injRowGap = 20;
  static const double injTop = 78; // injector lines start below tank labels
  static const double valveDropFrom = 46;
  static const double rowGap = 34; // space between wrapped tank rows

  // icon half sizes + gap used to break the lines
  static const double valveR = 11; // valve circle 22
  static const double pumpR = 20; // pump circle 40
  static const double boxHalf = 23; // source / tank box 46
  static const double lineGap = 3; // space between line end and icon

  // top spacing: captions sit above the top rail, rail sits above the icons
  static const double capTop = -28;
  static const double railY = -12;

  static final Color lineColor = Colors.blueGrey.shade100;
  static final Color injColor = Colors.blueGrey.shade100;

  double _cy(int row) => row * rowH + iconCy;

  @override
  Widget build(BuildContext context) =>
      isWide ? _buildHorizontal(context) : _buildVertical(context);

  // ============================================================
  // WEB: horizontal layout (wrapping)
  // ============================================================
  static double _rightOf(List<_HUnit> us) {
    double lastEnd = 0, maxCx = 0;
    final inj = <double>{};
    for (final u in us) {
      lastEnd = math.max(lastEnd, u.end);
      final vs = u.tank.outletValves;
      if (vs.isNotEmpty) {
        maxCx = math.max(maxCx, u.valveX + (vs.length - 0.5) * colW);
      }
      for (final v in vs) {
        inj.addAll(v.channelSNos);
      }
    }
    return math.max(lastEnd, inj.isEmpty ? 0.0 : maxCx + 24 + 28) + 6;
  }

  static _HRow _makeRow(List<_HUnit> units, double y) {
    final injNames = <double, String>{};
    double lastEnd = 0, maxCx = 0;
    for (final u in units) {
      lastEnd = math.max(lastEnd, u.end);
      final vs = u.tank.outletValves;
      if (vs.isNotEmpty) {
        maxCx = math.max(maxCx, u.valveX + (vs.length - 0.5) * colW);
      }
      for (final v in vs) {
        for (int i = 0; i < v.channelSNos.length; i++) {
          injNames[v.channelSNos[i]] = v.channelNames[i];
        }
      }
    }
    final injSNos = injNames.keys.toList()..sort();
    final injEnd = injSNos.isEmpty ? lastEnd : maxCx + 24;
    final right =
        math.max(lastEnd, injSNos.isEmpty ? 0.0 : injEnd + 28) + 6;
    final h = injSNos.isEmpty
        ? rowH
        : math.max(rowH, injTop + (injSNos.length - 1) * injRowGap + 14);
    return _HRow(units, y, h, injSNos, injNames, injEnd, right);
  }

  static _HLayout _hLayout(FertTankSystem system, double? maxWidth) {
    final mains = system.mainSources;
    final mainW =
    mains.map((m) => colW + m.pumps.length * (connW + colW)).toList();
    final collectorX = (mainW.isEmpty ? 0.0 : mainW.reduce(math.max)) + 16;
    final x0 = collectorX + 24;

    _HUnit geom(FertTank t, double start) {
      final tankX = start + connW + t.inletValves.length * colW;
      final tankRight = tankX + colW;
      final valveX = tankRight + 8;
      final end = t.outletValves.isEmpty
          ? tankRight
          : valveX + t.outletValves.length * colW;
      return _HUnit(t, start, tankX, tankRight, valveX, end);
    }

    final rows = <_HRow>[];
    var cur = <_HUnit>[];
    double x = x0;
    double y = 0;

    for (final t in system.tanks) {
      var u = geom(t, x);
      if (cur.isNotEmpty &&
          maxWidth != null &&
          _rightOf([...cur, u]) > maxWidth) {
        // wrap: close this row, start a new one under it
        final r = _makeRow(cur, y);
        rows.add(r);
        y += r.h + rowGap;
        cur = <_HUnit>[];
        x = x0;
        u = geom(t, x0);
      }
      cur.add(u);
      x = u.end + hGap;
    }
    if (cur.isNotEmpty) rows.add(_makeRow(cur, y));

    final width = rows.isEmpty
        ? collectorX + 6
        : rows.map((r) => r.right).reduce(math.max);
    final bottom = rows.isEmpty ? 0.0 : rows.last.y + rows.last.h;
    final height = math.max(mains.length * rowH, bottom);

    return _HLayout(rows, collectorX, width, height);
  }

  /// Size used by the parent. Pass the same [maxWidth] given to the widget.
  static Size measure(FertTankSystem system, {double? maxWidth}) {
    if (!kIsWeb) return _measureVertical(system);
    final l = _hLayout(system, maxWidth == null ? null : maxWidth - 8);
    return Size(l.width + 8, l.height + 42 + 8);
  }

  Widget _buildHorizontal(BuildContext context) {
    final L = _hLayout(system, maxWidth == null ? null : maxWidth! - 8);
    final mains = system.mainSources;
    final c = <Widget>[];

    c.add(Positioned(left: 0, top: capTop, child: _caption('FERT MAIN SOURCE')));
    if (L.rows.isNotEmpty) {
      c.add(Positioned(
          left: L.rows.first.units.first.start + connW,
          top: capTop,
          child: _caption('FERTILIZER TANKS')));
    }

    // ---------- main sources ----------
    for (int i = 0; i < mains.length; i++) {
      c.add(Positioned(left: 0, top: i * rowH, child: _mainRow(mains[i])));
      final sx = _mainEndX(mains[i]);
      c.add(_h(sx, _cy(i), L.collectorX - sx));
    }

    // ---------- collector: one vertical line that every row joins ----------
    double colTop = _cy(0);
    double colBottom = _cy(math.max(0, mains.length - 1));
    for (final r in L.rows) {
      colTop = math.min(colTop, r.units.length > 1 ? r.rail : r.y0);
      colBottom = math.max(colBottom, r.y0);
    }
    if (colBottom > colTop) c.add(_v(L.collectorX, colTop, colBottom));

    // ---------- tank rows ----------
    for (final r in L.rows) {
      final y0 = r.y0;
      double yInj(int j) => r.y + injTop + j * injRowGap;

      // rail above the row (only when the row has more than one tank)
      if (r.units.length > 1) {
        c.add(_h(L.collectorX, r.rail, r.units.last.start - L.collectorX));
      }

      final injMinX = <int, double>{};
      final valveDrops = <List<double>>[]; // [cx, lastFeedY]
      final dots = <Offset>[];

      for (int ui = 0; ui < r.units.length; ui++) {
        final u = r.units[ui];
        final t = u.tank;

        // feed into this tank unit
        if (ui > 0) c.add(_v(u.start, r.rail, y0));
        final feedX = ui == 0 ? L.collectorX : u.start;

        // one broken line through: inlet valves -> tank -> outlet valves
        final obs = <List<double>>[];
        for (int i = 0; i < t.inletValves.length; i++) {
          obs.add([u.start + connW + i * colW + colW / 2, valveR]);
          c.add(Positioned(
            left: u.start + connW + i * colW,
            top: r.y,
            width: colW,
            child: _valveChip(context, t.inletValves[i], isInlet: true),
          ));
        }
        obs.add([u.tankX + colW / 2, boxHalf]);
        c.add(Positioned(
            left: u.tankX, top: r.y, width: colW, child: _tankBox(t)));

        double endX = u.tankX + colW / 2;
        if (t.outletValves.isNotEmpty) {
          endX = u.valveX + (t.outletValves.length - 0.5) * colW;
        }

        for (int s = 0; s < t.outletValves.length; s++) {
          final v = t.outletValves[s];
          final cx = u.valveX + s * colW + colW / 2;
          obs.add([cx, valveR]);
          c.add(Positioned(
            left: u.valveX + s * colW,
            top: r.y,
            width: colW,
            child: _valveChip(context, v, isInlet: false),
          ));

          int lastFeed = -1;
          for (int j = 0; j < r.injSNos.length; j++) {
            if (v.channelSNos.contains(r.injSNos[j])) {
              lastFeed = j;
              injMinX[j] = math.min(injMinX[j] ?? double.infinity, cx);
              dots.add(Offset(cx, yInj(j)));
            }
          }
          if (lastFeed >= 0) valveDrops.add([cx, yInj(lastFeed)]);
        }

        c.addAll(_hBroken(feedX, endX, y0, obs));
      }

      // injector lines + chips for THIS row
      for (int j = 0; j < r.injSNos.length; j++) {
        final sx = injMinX[j] ?? r.injEnd;
        c.add(_h(sx, yInj(j), r.injEnd - sx));
        c.add(Positioned(
          left: r.injEnd,
          top: yInj(j) - 10,
          width: 28,
          height: 20,
          child: _injChip(r.injNames[r.injSNos[j]] ?? ''),
        ));
      }
      if (r.injSNos.isNotEmpty) {
        c.add(Positioned(
            left: r.injEnd,
            top: r.y + injTop - 28,
            child: _caption('INJECTORS')));
      }
      for (final d in valveDrops) {
        c.add(_v(d[0], r.y + valveDropFrom, d[1]));
      }
      for (final p in dots) {
        c.add(_dot(p.dx, p.dy));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 42, left: 4, right: 4, bottom: 8),
      child: SizedBox(
        width: L.width,
        height: L.height,
        child: Stack(clipBehavior: Clip.none, children: c),
      ),
    );
  }

  // ============================================================
  // MOBILE: vertical layout (mirrored right -> left)
  // ============================================================
  Widget _buildVertical(BuildContext context) {
    final tanks = system.tanks;
    final mains = system.mainSources;

    // keeps text/icons readable inside the mirrored canvas
    Widget unflip(Widget w) => Transform.flip(flipX: true, child: w);

    // ---------- main section ----------
    final mainWidths = mains
        .map((m) => mainColW + m.pumps.length * (connW + mainColW))
        .toList();
    final maxMainW = mainWidths.isEmpty ? 0.0 : mainWidths.reduce(math.max);
    final collectorX = maxMainW + 16;

    // ---------- tank groups ----------
    final groups = <_Group>[];
    int row = 0;
    for (final t in tanks) {
      final k = math.max(1, t.outletValves.length);
      final inletW = t.inletValves.isEmpty
          ? 0.0
          : t.inletValves.length * valveColW + connW;
      final tankX = collectorX + connW + inletW;
      final tankRight = tankX + tankColW;
      final forkX = tankRight + 12;
      final valveX = forkX + 12;
      groups.add(_Group(t, row, k, tankX, tankRight, forkX, valveX));
      row += k;
    }
    final totalRows = math.max(row, mains.length);

    // ---------- injector columns ----------
    final injNames = <double, String>{};
    for (final t in tanks) {
      for (final v in t.outletValves) {
        for (int i = 0; i < v.channelSNos.length; i++) {
          injNames[v.channelSNos[i]] = v.channelNames[i];
        }
      }
    }
    final injSNos = injNames.keys.toList()..sort();

    double crossStart = 0;
    for (final g in groups) {
      if (g.tank.outletValves.isNotEmpty) {
        crossStart = math.max(crossStart, g.valveX + valveColW);
      }
    }
    double injX(int j) => crossStart + 16 + j * injGapMobile;
    final crossEnd =
    injSNos.isEmpty ? crossStart : injX(injSNos.length - 1) + 6;

    final tanksEnd = groups.isEmpty
        ? collectorX
        : groups.map((g) => g.tankRight).reduce(math.max);
    final width = math.max(crossEnd, tanksEnd) + 6;

    // ---------- vertical layout ----------
    final chipTop = _cy(totalRows - 1) + 26;
    const joinTopY = railY;
    final height = injSNos.isEmpty ? totalRows * rowH : chipTop + 24;

    // ---------- build drawing (in normal coords, mirrored at the end) ----------
    final c = <Widget>[];

    if (mains.isNotEmpty) {
      c.add(Positioned(
          left: 0, top: capTop, child: unflip(_caption('FERT MAIN SOURCE'))));
    }

    c.add(Positioned(
        left: collectorX,
        top: capTop,
        child: unflip(_caption('FERTILIZER TANKS'))));
    if (injSNos.isNotEmpty) {
      c.add(Positioned(
          left: crossStart + 4,
          top: capTop,
          child: unflip(_caption('INJECTORS'))));
    }

    // main source rows
    for (int i = 0; i < mains.length; i++) {
      c.add(Positioned(
          left: 0,
          top: i * rowH,
          child: _mainRow(mains[i], unflipContent: true, cw: mainColW)));
      final sx = _mainEndX(mains[i], cw: mainColW);
      c.add(_h(sx, _cy(i), collectorX - sx));
    }

    // collector
    final lastGroupRow = groups.isEmpty ? 0 : groups.last.row;
    final collectorBottom = _cy(math.max(lastGroupRow, mains.length - 1));
    if (collectorBottom > _cy(0)) {
      c.add(_v(collectorX, _cy(0), collectorBottom));
    }

    // tank groups
    for (final g in groups) {
      final t = g.tank;
      final y = _cy(g.row);
      final tankCx = g.tankX + tankColW / 2;

      final obs = <List<double>>[];
      for (int i = 0; i < t.inletValves.length; i++) {
        final cx = collectorX + connW + i * valveColW + valveColW / 2;
        obs.add([cx, valveR]);
        c.add(Positioned(
          left: collectorX + connW + i * valveColW,
          top: g.row * rowH,
          width: valveColW,
          child: unflip(_valveChip(context, t.inletValves[i],
              isInlet: true, reverseIcon: true, labelW: valveColW - 6)),
        ));
      }
      obs.add([tankCx, boxHalf]);
      c.addAll(_hBroken(collectorX, tankCx, y, obs));

      c.add(Positioned(
        left: g.tankX,
        top: g.row * rowH,
        width: tankColW,
        child: unflip(_tankBox(t, cw: tankColW)),
      ));


      if (t.outletValves.isEmpty) continue;

      final tx = tankCx + boxHalf + lineGap;
      c.add(_h(tx, y, g.forkX - tx));
      if (g.rows > 1) c.add(_v(g.forkX, y, _cy(g.row + g.rows - 1)));

      for (int s = 0; s < t.outletValves.length; s++) {
        final v = t.outletValves[s];
        final r = g.row + s;
        final vy = _cy(r);
        final valveCx = g.valveX + valveColW / 2;

        final fx2 = valveCx - valveR - lineGap;
        c.add(_h(g.forkX, vy, fx2 - g.forkX));

        c.add(Positioned(
          left: g.valveX,
          top: r * rowH,
          width: valveColW,
          child: unflip(_valveChip(context, v,
              isInlet: false, reverseIcon: true, labelW: valveColW - 6)),
        ));

        final feeds = <int>[];
        for (int j = 0; j < injSNos.length; j++) {
          if (v.channelSNos.contains(injSNos[j])) feeds.add(j);
        }
        final sx = valveCx + valveR + lineGap;
        final ex = feeds.isEmpty ? crossStart : injX(feeds.last);
        c.add(_h(sx, vy, ex - sx));
        for (final j in feeds) {
          c.add(_dot(injX(j), vy));
        }
      }
    }

    // injector columns + chips
    if (injSNos.isNotEmpty) {
      final firstX = injX(0);
      final lastX = injX(injSNos.length - 1);

      c.add(_h(firstX, joinTopY, (lastX + 10) - (firstX - 8)));

      for (int j = 0; j < injSNos.length; j++) {
        c.add(_v(injX(j), joinTopY, chipTop));
        c.add(Positioned(
          left: injX(j) - 14,
          top: chipTop,
          width: 28,
          height: 20,
          child: unflip(_injChip(injNames[injSNos[j]] ?? '')),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 42, left: 4, right: 4, bottom: 8),
      child: Transform.flip(
        flipX: true, // <-- the mirror (right -> left)
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(clipBehavior: Clip.none, children: c),
        ),
      ),
    );
  }

  static Size _measureVertical(FertTankSystem system) {
    final tanks = system.tanks;
    final mains = system.mainSources;

    final mainWidths = mains
        .map((m) => mainColW + m.pumps.length * (connW + mainColW))
        .toList();
    final maxMainW = mainWidths.isEmpty ? 0.0 : mainWidths.reduce(math.max);
    final collectorX = maxMainW + 16;

    int row = 0;
    double crossStart = 0;
    double tanksEnd = collectorX;
    final injNos = <double>{};

    for (final t in tanks) {
      final k = math.max(1, t.outletValves.length);
      final inletW = t.inletValves.isEmpty
          ? 0.0
          : t.inletValves.length * valveColW + connW;
      final tankX = collectorX + connW + inletW;
      final tankRight = tankX + tankColW;
      final valveX = tankRight + 24;
      if (t.outletValves.isNotEmpty) {
        crossStart = math.max(crossStart, valveX + valveColW);
      }
      tanksEnd = math.max(tanksEnd, tankRight);
      for (final v in t.outletValves) {
        injNos.addAll(v.channelSNos);
      }
      row += k;
    }

    final totalRows = math.max(row, mains.length);
    final crossEnd = injNos.isEmpty
        ? crossStart
        : crossStart + 16 + (injNos.length - 1) * injGapMobile + 14;
    final width = math.max(crossEnd, tanksEnd) + 6 + 8;

    final chipTop = (totalRows - 1) * rowH + iconCy + 26;
    final h = injNos.isEmpty ? totalRows * rowH : chipTop + 24;
    return Size(width, h + 42 + 8);
  }

  // ============================================================
  // drawing helpers
  // ============================================================
  Widget _h(double left, double y, double w) => Positioned(
    left: left,
    top: y - 1,
    width: math.max(0, w),
    height: 2,
    child: ColoredBox(color: lineColor),
  );

  Widget _v(double x, double y1, double y2) => Positioned(
    left: x - 1,
    top: y1 - 1,
    width: 2,
    height: math.max(0, (y2 - y1) + 2),
    child: ColoredBox(color: lineColor),
  );

  /// Horizontal line from x1 to x2 that STOPS before every obstacle
  /// ([centerX, halfWidth]) and continues after it.
  List<Widget> _hBroken(
      double x1, double x2, double y, List<List<double>> obstacles) {
    final sorted = [...obstacles]..sort((a, b) => a[0].compareTo(b[0]));
    final out = <Widget>[];
    double cur = x1;
    for (final o in sorted) {
      final l = o[0] - o[1] - lineGap;
      final r = o[0] + o[1] + lineGap;
      if (l > cur) out.add(_h(cur, y, math.min(l, x2) - cur));
      cur = math.max(cur, r);
      if (cur >= x2) return out;
    }
    if (x2 > cur) out.add(_h(cur, y, x2 - cur));
    return out;
  }

  Widget _dot(double cx, double cy) => Positioned(
    left: cx - 5,
    top: cy - 5,
    width: 10,
    height: 10,
    child: DecoratedBox(
      decoration: BoxDecoration(color: injColor, shape: BoxShape.circle),
    ),
  );

  Widget _injChip(String name) => Tooltip(
    message: name,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: injColor, width: 1),
      ),
      child: Center(
        child: Text(
          _shortNo(name),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ),
    ),
  );

  Widget _caption(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 8,
      letterSpacing: 0.6,
      color: Colors.blueGrey.shade400,
      fontWeight: FontWeight.w600,
    ),
  );

  String _shortNo(String name) {
    final m = RegExp(r'(\d+)\s*$').firstMatch(name);
    return m == null ? name : m.group(1)!;
  }

  // ------------------------------------------------------------
  // Main source (sourceType 6) ── pump ── pump
  // ------------------------------------------------------------

  /// x where the line leaving this main-source row should start
  /// (just after its last icon).
  double _mainEndX(FertMainSource m, {double cw = colW}) {
    final w = cw + m.pumps.length * (connW + cw);
    final lastCx = w - cw / 2;
    final half = m.pumps.isEmpty ? boxHalf : pumpR;
    return lastCx + half + lineGap;
  }

  Widget _mainRow(FertMainSource m,
      {bool unflipContent = false, double cw = colW}) {
    Widget uf(Widget w) =>
        unflipContent ? Transform.flip(flipX: true, child: w) : w;

    final src = m.source;
    final level = src.level.isNotEmpty ? src.level.first.value : '-';
    final w = cw + m.pumps.length * (connW + cw);

    final children = <Widget>[
      Positioned(
        left: 0,
        top: 0,
        width: cw,
        child: uf(_box(
          icon: Icons.water,
          color: Colors.black54,
          border: Colors.black12,
          iconColor: Colors.white,
          name: src.name,
          sub: level == '-' ? null : 'L: $level',
          labelW: cw - 6,
        )),
      ),
    ];

    double prevCx = cw / 2;
    double prevHalf = boxHalf;
    for (int i = 0; i < m.pumps.length; i++) {
      final left = cw + i * (connW + cw) + connW;
      final cx = left + cw / 2;
      children.add(Positioned(
        left: left,
        top: 0,
        width: cw,
        child: uf(_pumpChip(m.pumps[i], labelW: cw - 6)),
      ));
      // connector stops before each icon
      final sx = prevCx + prevHalf + lineGap;
      final ex = cx - pumpR - lineGap;
      children.add(_h(sx, iconCy, ex - sx));
      prevCx = cx;
      prevHalf = pumpR;
    }

    return SizedBox(
      width: w,
      height: rowH,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _pumpChip(PumpModel pump, {double labelW = colW - 6}) {
    final on = pump.status == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Colors.green.shade400 : Colors.grey.shade300,
            border: Border.all(color: Colors.black38, width: 1),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/svg_images/pump.svg',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              colorFilter:
              const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
              placeholderBuilder: (_) =>
              const Icon(Icons.error, size: 20, color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: labelW,
          child: Text(
            pump.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _tankBox(FertTank t, {double cw = colW}) {
    final level = t.source.level.isNotEmpty ? t.source.level.first.value : '-';
    return _box(
      icon: FontAwesomeIcons.water,
      color: Colors.teal.shade100,
      border: Colors.teal.shade50,
      iconColor: Colors.teal,
      name: t.name,
      sub: level == '-' ? null : 'L: $level',
      labelW: cw - 6,
    );
  }

  Widget _valveChip(BuildContext context, TankValveModel v,
      {bool isInlet = false,
        bool reverseIcon = false,
        double labelW = colW - 6}) {
    final rawKey = v.sNo.toString();
    final paddedKey = v.sNo.toStringAsFixed(3);

    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) =>
      provider.getTankValveOnOffStatus(rawKey) ??
          provider.getTankValveOnOffStatus(paddedKey),
      builder: (_, status, __) {
        final parts = status?.split(',') ?? [];
        final int onOffStatus =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? v.status) : v.status;
        final int percent = parts.length > 2
            ? (int.tryParse(parts[2]) ?? v.completePercent)
            : v.completePercent;

        // ---- Color mapping by status ----
        Color statusColor;
        switch (onOffStatus) {
          case 1:
            statusColor = Colors.green;
            break;
          case 2:
            statusColor = Colors.blue;
            break;
          case 3:
            statusColor = Colors.yellow;
            break;
          case 4:
            statusColor = Colors.orange;
            break;
          case 5:
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.black54;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Tooltip(
              message: '${v.name}\n'
                  '${isInlet ? 'Inlet' : 'Outlet'}\n'
                  'status: $onOffStatus'
                  '${percent > 0 ? ' • $percent%' : ''}',
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      border: Border.all(color: Colors.black26, width: 0.6),
                    ),
                    child: Center(
                      child: Transform.flip(
                        flipX: reverseIcon,
                        child: const FaIcon(
                          FontAwesomeIcons.faucetDrip,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (percent > 0 && percent < 100)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: labelW,
              child: Text(
                v.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: statusColor == Colors.yellow
                      ? Colors.black87
                      : statusColor,
                  fontWeight: isInlet ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _box({
    required dynamic icon,
    required Color color,
    required Color border,
    required Color iconColor,
    required String name,
    String? sub,
    double labelW = colW - 6,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1),
          ),
          child: Center(
            child: icon is IconData
                ? Icon(icon, size: 22, color: iconColor)
                : FaIcon(icon, size: 22, color: iconColor),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: labelW,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        if (sub != null)
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.black54)),
      ],
    );
  }
}

// ---------- vertical (mobile) helper ----------
class _Group {
  final FertTank tank;
  final int row;
  final int rows;
  final double tankX, tankRight, forkX, valveX;
  _Group(this.tank, this.row, this.rows, this.tankX, this.tankRight, this.forkX,
      this.valveX);
}

// ---------- horizontal (web) helpers ----------
class _HUnit {
  final FertTank tank;
  final double start, tankX, tankRight, valveX, end;
  _HUnit(this.tank, this.start, this.tankX, this.tankRight, this.valveX,
      this.end);
}

/// One wrapped row of tanks (with its own injector lines).
class _HRow {
  final List<_HUnit> units;
  final double y, h;
  final List<double> injSNos;
  final Map<double, String> injNames;
  final double injEnd, right;
  _HRow(this.units, this.y, this.h, this.injSNos, this.injNames, this.injEnd,
      this.right);

  /// y of the icon centre line of this row
  double get y0 => y + FertTankSystemWidget.iconCy;

  /// y of the rail above this row
  double get rail => y + FertTankSystemWidget.railY;
}

class _HLayout {
  final List<_HRow> rows;
  final double collectorX, width, height;
  _HLayout(this.rows, this.collectorX, this.width, this.height);
}


/*
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oro_drip_irrigation/models/customer/site_model.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';

/// NEW fertilizer tank concept (shown only when fertilizerChannel exists).
/// Everything flows left -> right:
///
///  [Main source]─[Pump]─┬─[inlet valve]─[Tank 5]─┬─[outlet valve 1]──●──●──●──●
///                       │                        └─[outlet valve 2]──●──●
///                       └─[inlet valve]─[Tank 6]───[outlet valve 3]──●──●──●
///                                                                    I1 I2 I3 I4   (injectors)
///
/// A dot on an injector column means "this valve feeds that injector".
/// Injector columns are joined at the top only.
class FertTankSystemWidget extends StatelessWidget {
  final FertTankSystem system;
  final int customerId, controllerId, modelId;
  final String deviceId;

  const FertTankSystemWidget({
    super.key,
    required this.system,
    required this.customerId,
    required this.controllerId,
    required this.modelId,
    required this.deviceId,
  });

  static const double colW = 76;
  static const double connW = 22;
  static const double rowH = 74;
  static const double iconCy = 20;
  static const double injGap = 30;
  static final Color lineColor = Colors.blueGrey.shade100;
  static final Color injColor = Colors.blueGrey.shade100;

  double _cy(int row) => row * rowH + iconCy;

  @override
  Widget build(BuildContext context) {
    final tanks = system.tanks;
    final mains = system.mainSources;

    // ---------- main section ----------
    final mainWidths =
        mains.map((m) => colW + m.pumps.length * (connW + colW)).toList();
    final maxMainW = mainWidths.isEmpty ? 0.0 : mainWidths.reduce(math.max);
    final collectorX = maxMainW + 16;

    // ---------- tank groups ----------
    final groups = <_Group>[];
    int row = 0;
    for (final t in tanks) {
      final k = math.max(1, t.outletValves.length);
      final inletW =
          t.inletValves.isEmpty ? 0.0 : t.inletValves.length * colW + connW;
      final tankX = collectorX + connW + inletW;
      final tankRight = tankX + colW;
      final forkX = tankRight + 12;
      final valveX = forkX + 12;
      groups.add(_Group(t, row, k, tankX, tankRight, forkX, valveX));
      row += k;
    }
    final totalRows = math.max(row, mains.length);

    // ---------- injector columns ----------
    final injNames = <double, String>{};
    for (final t in tanks) {
      for (final v in t.outletValves) {
        for (int i = 0; i < v.channelSNos.length; i++) {
          injNames[v.channelSNos[i]] = v.channelNames[i];
        }
      }
    }
    final injSNos = injNames.keys.toList()..sort();

    double crossStart = 0;
    for (final g in groups) {
      if (g.tank.outletValves.isNotEmpty) {
        crossStart = math.max(crossStart, g.valveX + colW);
      }
    }
    double injX(int j) => crossStart + 16 + j * injGap;
    final crossEnd =
        injSNos.isEmpty ? crossStart : injX(injSNos.length - 1) + 18;

    final tanksEnd = groups.isEmpty
        ? collectorX
        : groups.map((g) => g.tankRight).reduce(math.max);
    final width = math.max(crossEnd, tanksEnd) + 6;

    // ---------- vertical layout ----------
    final chipTop = _cy(totalRows - 1) + 26;
    final joinTopY = _cy(0) - 20;
    final height = injSNos.isEmpty ? totalRows * rowH : chipTop + 24;

    // ---------- build drawing ----------
    final c = <Widget>[];

    c.add(Positioned(left: 0, top: -14, child: _caption('FERT MAIN SOURCE')));
    c.add(Positioned(
        left: collectorX, top: -14, child: _caption('FERTILIZER TANKS')));
    if (injSNos.isNotEmpty) {
      c.add(Positioned(
          left: crossStart + 4, top: -14, child: _caption('INJECTORS')));
    }

    // ---------- main source rows ----------
    for (int i = 0; i < mains.length; i++) {
      c.add(Positioned(left: 0, top: i * rowH, child: _mainRow(mains[i])));
      c.add(_h(mainWidths[i], _cy(i), collectorX - mainWidths[i]));
    }

    // ---------- collector ----------
    final lastGroupRow = groups.isEmpty ? 0 : groups.last.row;
    final collectorBottom = _cy(math.max(lastGroupRow, mains.length - 1));
    if (collectorBottom > _cy(0)) {
      c.add(_v(collectorX, _cy(0), collectorBottom));
    }

    // ---------- tank groups ----------
    for (final g in groups) {
      final t = g.tank;
      final y = _cy(g.row);

      c.add(_h(collectorX, y, g.tankX - collectorX));
      for (int i = 0; i < t.inletValves.length; i++) {
        c.add(Positioned(
          left: collectorX + connW + i * colW,
          top: g.row * rowH,
          width: colW,
          child: _valveChip(context, t.inletValves[i], isInlet: true),
        ));
      }
      c.add(Positioned(
        left: g.tankX,
        top: g.row * rowH,
        width: colW,
        child: _tankBox(t),
      ));

      if (t.outletValves.isEmpty) continue;

      c.add(_h(g.tankRight, y, g.forkX - g.tankRight));
      if (g.rows > 1) c.add(_v(g.forkX, y, _cy(g.row + g.rows - 1)));

      for (int s = 0; s < t.outletValves.length; s++) {
        final v = t.outletValves[s];
        final r = g.row + s;
        final vy = _cy(r);
        c.add(_h(g.forkX, vy, g.valveX - g.forkX));
        c.add(Positioned(
          left: g.valveX,
          top: r * rowH,
          width: colW,
          child: _valveChip(context, v, isInlet: false),
        ));

        // valve -> injectors (crossbar)
        final feeds = <int>[];
        for (int j = 0; j < injSNos.length; j++) {
          if (v.channelSNos.contains(injSNos[j])) feeds.add(j);
        }
        c.add(_h(
            g.valveX + colW,
            vy,
            (feeds.isEmpty ? crossStart : injX(feeds.last)) -
                (g.valveX + colW)));
        for (final j in feeds) {
          c.add(Positioned(
            left: injX(j) - 5,
            top: vy - 5,
            width: 10,
            height: 10,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: injColor, shape: BoxShape.circle),
            ),
          ));
        }
      }
    }

    // ---------- injector columns + chips (top join only) ----------
    if (injSNos.isNotEmpty) {
      final firstX = injX(0);
      final lastX = injX(injSNos.length - 1);

      // top rail only
      c.add(_h(firstX - 0, joinTopY, (lastX + 20) - (firstX - 8)));

      for (int j = 0; j < injSNos.length; j++) {
        // vertical column from top rail down to chip
        c.add(_v(injX(j), joinTopY, chipTop));

        // injector chip
        c.add(Positioned(
          left: injX(j) - 14,
          top: chipTop,
          width: 28,
          height: 20,
          child: Tooltip(
            message: injNames[injSNos[j]] ?? '',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: injColor, width: 1),
              ),
              child: Center(
                child: Text(
                  _shortNo(injNames[injSNos[j]] ?? ''),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 42, left: 4, right: 4, bottom: 8),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(clipBehavior: Clip.none, children: c),
      ),
    );
  }

  // ---------- drawing helpers ----------
  Widget _h(double left, double y, double w) => Positioned(
        left: left,
        top: y - 1,
        width: math.max(0, w),
        height: 2,
        child: ColoredBox(color: lineColor),
      );

  Widget _v(double x, double y1, double y2) => Positioned(
        left: x - 1,
        top: y1 - 1,
        width: 2,
        height: (y2 - y1) + 2,
        child: ColoredBox(color: lineColor),
      );

  Widget _caption(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 8,
          letterSpacing: 0.6,
          color: Colors.blueGrey.shade400,
          fontWeight: FontWeight.w600,
        ),
      );

  String _shortNo(String name) {
    final m = RegExp(r'(\d+)\s*$').firstMatch(name);
    return m == null ? name : m.group(1)!;
  }

  // ------------------------------------------------------------
  // Main source (sourceType 6) ── pump ── pump
  // ------------------------------------------------------------
  Widget _mainRow(FertMainSource m) {
    final src = m.source;
    final level = src.level.isNotEmpty ? src.level.first.value : '-';
    return SizedBox(
      height: rowH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: colW,
            child: _box(
              icon: Icons.water,
              color: Colors.black54,
              border: Colors.black12,
              iconColor: Colors.white,
              name: src.name,
              sub: level == '-' ? null : 'L: $level',
            ),
          ),
          for (final pump in m.pumps) ...[
            Padding(
              padding: const EdgeInsets.only(top: iconCy - 1),
              child: Container(width: connW, height: 2, color: lineColor),
            ),
            SizedBox(width: colW, child: _pumpChip(pump)),
          ],
        ],
      ),
    );
  }

  Widget _pumpChip(PumpModel pump) {
    final on = pump.status == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Colors.green.shade400 : Colors.grey.shade300,
            border: Border.all(
              color: Colors.black38,
              width: 1,
            ),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/svg_images/pump.svg',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              colorFilter:
                  const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
              placeholderBuilder: (_) =>
                  const Icon(Icons.error, size: 20, color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: colW - 6,
          child: Text(
            pump.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _tankBox(FertTank t) {
    final level = t.source.level.isNotEmpty ? t.source.level.first.value : '-';
    return _box(
      icon: FontAwesomeIcons.faucetDrip,
      color: Colors.black54,
      border: Colors.black12,
      iconColor: Colors.white,
      name: t.name,
      sub: level == '-' ? null : 'L: $level',
    );
  }

  Widget _valveChip(BuildContext context, TankValveModel v,
      {bool isInlet = false}) {
    final rawKey = v.sNo.toString();
    final paddedKey = v.sNo.toStringAsFixed(3);

    return Selector<MqttPayloadProvider, String?>(
      selector: (_, provider) =>
          provider.getTankValveOnOffStatus(rawKey) ??
          provider.getTankValveOnOffStatus(paddedKey),
      builder: (_, status, __) {
        final parts = status?.split(',') ?? [];
        final int onOffStatus =
            parts.length > 1 ? (int.tryParse(parts[1]) ?? v.status) : v.status;
        final int percent = parts.length > 2
            ? (int.tryParse(parts[2]) ?? v.completePercent)
            : v.completePercent;

        // ---- Color mapping by status ----
        Color statusColor;
        switch (onOffStatus) {
          case 1:
            statusColor = Colors.green;
            break;
          case 2:
            statusColor = Colors.blue;
            break;
          case 3:
            statusColor = Colors.yellow;
            break;
          case 4:
            statusColor = Colors.orange;
            break;
          case 5:
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.black54;
        }

        final Color iconColor =
            (onOffStatus == 3) ? Colors.black87 : Colors.white;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Tooltip(
              message: '${v.name}\n'
                  '${isInlet ? 'Inlet' : 'Outlet'}\n'
                  'status: $onOffStatus'
                  '${percent > 0 ? ' • $percent%' : ''}',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      border: Border.all(
                        color: Colors.black26,
                        width: 0.6,
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.faucetDrip,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (percent > 0 && percent < 100)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: colW - 6,
              child: Text(
                v.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: statusColor == Colors.yellow
                      ? Colors.black87
                      : statusColor,
                  fontWeight: isInlet ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _box({
    required dynamic icon,
    required Color color,
    required Color border,
    required Color iconColor,
    required String name,
    String? sub,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1),
          ),
          child: Center(
            child: icon is IconData
                ? Icon(icon, size: 22, color: iconColor)
                : FaIcon(icon, size: 22, color: iconColor),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: colW - 6,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        if (sub != null)
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.black54)),
      ],
    );
  }
}

class _Group {
  final FertTank tank;
  final int row;
  final int rows;
  final double tankX, tankRight, forkX, valveX;
  _Group(this.tank, this.row, this.rows, this.tankX, this.tankRight, this.forkX,
      this.valveX);
}
*/
