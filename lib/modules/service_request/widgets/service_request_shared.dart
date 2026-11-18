import 'package:flutter/material.dart';
import 'service_request_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final ServiceRequestStatusStyle style;
  const StatusBadge({super.key, required this.status, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: style.fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: style.fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.bg = ServiceRequestPalette.primary,
    this.fg = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: fg, size: 20)),
      ),
    );
  }
}

class DashedAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  const DashedAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 11 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: compact ? ServiceRequestPalette.primary.withOpacity(0.02) : null,
            border: Border.all(color: ServiceRequestPalette.primary.withOpacity(compact ? 0.25 : 0.35), width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 18, color: ServiceRequestPalette.primary),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: ServiceRequestPalette.primary, fontWeight: FontWeight.w700, fontSize: compact ? 13 : 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: ServiceRequestPalette.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.confirmation_number_outlined, size: 36, color: ServiceRequestPalette.primary),
          ),
          const SizedBox(height: 18),
          const Text('Select a ticket',
              style: TextStyle(color: ServiceRequestPalette.ink, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Its timeline and details will show up here',
              style: TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 13)),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const InfoChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: ServiceRequestPalette.field, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ServiceRequestPalette.muted),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: ServiceRequestPalette.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class SummaryPill extends StatelessWidget {
  final int handlerCount;
  final int personnelCount;
  const SummaryPill({super.key, required this.handlerCount, required this.personnelCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: ServiceRequestPalette.primarySoft, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_rounded, size: 15, color: ServiceRequestPalette.primary),
          const SizedBox(width: 6),
          Text(
            '$handlerCount ${handlerCount == 1 ? 'handler' : 'handlers'} · $personnelCount ${personnelCount == 1 ? 'person' : 'people'}',
            style: const TextStyle(color: ServiceRequestPalette.primary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class TreeConnector extends StatelessWidget {
  final bool continuesBelow;
  const TreeConnector({super.key, this.continuesBelow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 0,
            bottom: continuesBelow ? 0 : null,
            height: continuesBelow ? null : 26,
            child: Container(width: 1.5, color: const Color(0xFFDCE2E6)),
          ),
          Positioned(
            left: 12,
            top: 25,
            child: Container(width: 13, height: 1.5, color: const Color(0xFFDCE2E6)),
          ),
        ],
      ),
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;
  const ResponsiveRow({super.key, required this.children, this.spacing = 24, this.breakpoint = 600});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < breakpoint;
      return Flex(
        direction: narrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            narrow ? children[i] : Expanded(child: children[i]),
            if (i != children.length - 1) SizedBox(width: narrow ? 0 : spacing, height: narrow ? spacing : 0),
          ],
        ],
      );
    });
  }
}

class SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final String submitLabel;
  final VoidCallback onSubmit;
  const SheetShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onSubmit,
    this.submitLabel = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 16, 36, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(title,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: ServiceRequestPalette.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: ServiceRequestPalette.muted, fontSize: 14.5)),
              const SizedBox(height: 28),
              child,
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: ServiceRequestPalette.muted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ServiceRequestPalette.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
                    ),
                    child: Text(submitLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadDropZone extends StatelessWidget {
  const UploadDropZone({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ServiceRequestPalette.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ServiceRequestPalette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: ServiceRequestPalette.mutedLight, size: 28),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: ServiceRequestPalette.muted, fontSize: 12),
              children: [
                TextSpan(
                    text: 'Click to upload',
                    style: TextStyle(color: ServiceRequestPalette.primary, fontWeight: FontWeight.w700)),
                TextSpan(text: ' or drag and drop'),
              ],
            ),
          ),
          const Text('PNG, JPG, TIF up to 5MB',
              style: TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 10.5)),
        ],
      ),
    );
  }
}

InputDecoration fieldDecoration({String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: ServiceRequestPalette.border),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 13.5),
    filled: true,
    fillColor: ServiceRequestPalette.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ServiceRequestPalette.primary, width: 1.5),
    ),
  );
}
