import 'package:flutter/material.dart';
import '../model/service_request_model.dart';
import 'service_request_constants.dart';

class TimelineCard extends StatelessWidget {
  final ServiceRequest ticket;
  const TimelineCard({super.key, required this.ticket});

  IconData _iconFor(String name) {
    if (name.contains('Complaint')) return Icons.report_problem_outlined;
    if (name.contains('Responsible')) return Icons.person_outline;
    if (name.contains('Escalated')) return Icons.business_outlined;
    if (name.contains('Closed')) return Icons.lock_clock_outlined;
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final visible = ticket.issueStatus.where((s) => s.display).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: CustomPaint(
        painter: VoucherPainter(
          color: const Color(0xFFF8FAFC),
          accentColor: ServiceRequestPalette.primary.withOpacity(0.05),
          borderColor: ServiceRequestPalette.primary.withOpacity(0.2),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ticket status',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ServiceRequestPalette.ink)),
                            SizedBox(height: 2),
                            Text('Real-time tracking',
                                style: TextStyle(fontSize: 11, color: ServiceRequestPalette.muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ServiceRequestPalette.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: ServiceRequestPalette.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            '#TCK-${ticket.ticketId}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, i) => TimelineNode(
                          status: visible[i],
                          ticket: ticket,
                          isLast: i == visible.length - 1,
                          icon: _iconFor(visible[i].name),
                        ),
                      ),
                    ),
                    const _VoucherFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineNode extends StatelessWidget {
  final IssueStatus status;
  final ServiceRequest ticket;
  final bool isLast;
  final IconData icon;
  const TimelineNode({super.key, required this.status, required this.ticket, required this.isLast, required this.icon});

  ({String subtitle, String date}) get _detail {
    if (ticket.ticketHandler.isEmpty) return (subtitle: 'Pending', date: '');
    final handler = ticket.ticketHandler.first;
    if (status.name == 'Customer Raised Complaint' && handler.targetDates.isNotEmpty) {
      final t = handler.targetDates.first;
      return (subtitle: t.reason, date: t.date);
    }
    if (status.name == 'Ticket Responsible Person') {
      return (subtitle: 'Assigned to ${handler.name}', date: '');
    }
    return (subtitle: 'Pending', date: '');
  }

  @override
  Widget build(BuildContext context) {
    final done = status.value;
    final d = _detail;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? ServiceRequestPalette.success : Colors.white,
                  border: Border.all(
                      color: done ? ServiceRequestPalette.success : const Color(0xFFCBD5E1), width: 1.5),
                  boxShadow: done
                      ? [BoxShadow(color: ServiceRequestPalette.success.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Icon(done ? Icons.check_rounded : icon,
                    size: 16, color: done ? Colors.white : ServiceRequestPalette.pending),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: done ? ServiceRequestPalette.success : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: done ? ServiceRequestPalette.inkSoft : ServiceRequestPalette.mutedLight)),
                  if (d.subtitle.isNotEmpty && d.subtitle != 'Pending') ...[
                    const SizedBox(height: 4),
                    Text(d.subtitle, style: const TextStyle(color: ServiceRequestPalette.muted, fontSize: 12)),
                  ],
                  if (d.date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: ServiceRequestPalette.mutedLight),
                          const SizedBox(width: 4),
                          Text(d.date,
                              style: const TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherFooter extends StatelessWidget {
  const _VoucherFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            20,
            (index) => Container(
              width: 4,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: ServiceRequestPalette.border,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 16, color: ServiceRequestPalette.mutedLight),
            SizedBox(width: 8),
            Text(
              'Official Service Record',
              style: TextStyle(
                color: ServiceRequestPalette.mutedLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class VoucherPainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final Color borderColor;

  VoucherPainter({required this.color, required this.accentColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path();
    const radius = 24.0;
    const biteRadius = 16.0;
    final biteY = size.height * 0.78;

    // Drawing the main shape with bites on the sides
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius));
    
    path.lineTo(size.width, biteY - biteRadius);
    path.arcToPoint(Offset(size.width, biteY + biteRadius), 
        radius: const Radius.circular(biteRadius), clockwise: false);
    
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius));
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: const Radius.circular(radius));
    
    path.lineTo(0, biteY + biteRadius);
    path.arcToPoint(Offset(0, biteY - biteRadius), 
        radius: const Radius.circular(biteRadius), clockwise: false);
        
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: const Radius.circular(radius));

    // Shadow
    canvas.drawShadow(path.shift(const Offset(0, 6)), Colors.black.withOpacity(0.2), 16.0, false);

    canvas.drawPath(path, paint);

    // Header Highlight (Clip to main path)
    final headerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, 100)); // Fixed height header highlight
    
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(headerPath, accentPaint);
    canvas.restore();

    canvas.drawPath(path, borderPaint);

    // Draw circular "punches" at the bite level instead of a simple dashed line
    final punchPaint = Paint()
      ..color = borderColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    const punchRadius = 2.0;
    const punchSpace = 8.0;
    double startX = biteRadius + 12;
    
    while (startX < size.width - biteRadius - 12) {
      canvas.drawCircle(Offset(startX, biteY), punchRadius, punchPaint);
      startX += punchSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
