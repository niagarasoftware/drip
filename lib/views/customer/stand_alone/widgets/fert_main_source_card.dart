import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oro_drip_irrigation/models/customer/site_model.dart';

/// Stand-alone cards for the NEW fertilizer tank concept.
///  - FertMainSourceCard : fertilizer main source (type 6) -> its pumps
///  - FertTankValveCard  : fertilizer tanks (type 7) -> inlet / outlet valves

Widget _cardShell(String title, List<Widget> children) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.blueGrey.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 0),
        ...children,
      ],
    ),
  );
}

Widget _subHeader(String text) => Padding(
  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey.shade400,
    ),
  ),
);

// ------------------------------------------------------------
// Fertilizer main source -> pumps
// ------------------------------------------------------------
class FertMainSourceCard extends StatelessWidget {
  final List<FertMainSource> sources;
  final void Function(PumpModel pump, bool value) onChanged;

  const FertMainSourceCard({
    super.key,
    required this.sources,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final withPumps = sources.where((s) => s.pumps.isNotEmpty).toList();
    if (withPumps.isEmpty) return const SizedBox.shrink();

    return _cardShell('Fertilizer main source pump', [
      for (final s in withPumps) ...[
        _subHeader(s.source.name),
        for (final pump in s.pumps)
          ListTile(
            dense: true,
            leading: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg_images/pump.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    pump.status == 1 ? Colors.green : Colors.black54,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (_) =>
                  const Icon(Icons.error, size: 20, color: Colors.red),
                ),
              ),
            ),
            title: Text(pump.name, style: const TextStyle(fontSize: 14)),
            trailing: Switch(
              value: pump.selected,
              onChanged: (v) => onChanged(pump, v),
            ),
          ),
      ],
      const SizedBox(height: 4),
    ]);
  }
}

// ------------------------------------------------------------
// Fertilizer tank -> inlet valves / outlet valves
// ------------------------------------------------------------
class FertTankValveCard extends StatelessWidget {
  final List<FertTank> tanks;
  final void Function(TankValveModel valve, bool value) onChanged;

  const FertTankValveCard({
    super.key,
    required this.tanks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visible = tanks
        .where((t) => t.inletValves.isNotEmpty || t.outletValves.isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return _cardShell('Fertilizer tank valves', [
      for (final t in visible) ...[
        _subHeader(t.name),
        for (final v in t.inletValves) _valveTile(v, 'Inlet'),
        for (final v in t.outletValves) _valveTile(v, 'Outlet'),
      ],
      const SizedBox(height: 4),
    ]);
  }

  Widget _valveTile(TankValveModel v, String kind) {
    final injectors =
    v.channelNames.isEmpty ? '' : ' • ${v.channelNames.join(', ')}';
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.faucetDrip,
            size: 20,
            color: v.status == 1 ? Colors.green : Colors.black54,
          ),
        ),
      ),
      title: Text(v.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text('$kind$injectors', style: const TextStyle(fontSize: 11)),
      trailing : Transform.scale(
        scale: 0.7,
        child: Switch(
          activeThumbColor: Colors.teal,
          hoverColor: Colors.pink.shade100,
          value: v.selected,
          onChanged: (val) => onChanged(v, val),
        ),
      ),
    );
  }
}