import 'package:flutter/material.dart';
import '../model/service_request_model.dart';
import 'service_request_constants.dart';
import 'service_request_shared.dart';

class FilterBar extends StatelessWidget {
  final List<String> filters;
  final String active;
  final int Function(String) countFor;
  final ValueChanged<String> onSelect;
  const FilterBar(
      {super.key, required this.filters, required this.active, required this.countFor, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration:
            BoxDecoration(color: ServiceRequestPalette.field, borderRadius: BorderRadius.circular(radiusSm)),
        child: Row(
          children: filters.map((f) {
            final isActive = f == active;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive
                        ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    '$f (${countFor(f)})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? ServiceRequestPalette.ink : ServiceRequestPalette.mutedLight,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final ServiceRequest ticket;
  final String status;
  final bool selected;
  final VoidCallback onTap;
  const TicketCard({super.key, required this.ticket, required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = ServiceRequestStatusStyle.of(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusMd),
              border: Border.all(
                  color: selected ? ServiceRequestPalette.primary : ServiceRequestPalette.border,
                  width: selected ? 1.4 : 1),
              boxShadow: [
                BoxShadow(
                  color: selected ? ServiceRequestPalette.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#TCK-${ticket.ticketId}',
                        style: const TextStyle(
                            color: ServiceRequestPalette.mutedLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    StatusBadge(status: status, style: style),
                  ],
                ),
                const SizedBox(height: 10),
                Text(ticket.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15.5, color: ServiceRequestPalette.ink)),
                const SizedBox(height: 5),
                Text(
                  ticket.issueDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ServiceRequestPalette.muted, fontSize: 12.5, height: 1.5),
                ),
                if (ticket.ticketHandler.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 13, color: ServiceRequestPalette.mutedLight),
                      const SizedBox(width: 4),
                      Text('${ticket.ticketHandler.length} handlers',
                          style: const TextStyle(
                              color: ServiceRequestPalette.mutedLight, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
