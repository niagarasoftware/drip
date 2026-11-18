import 'package:flutter/material.dart';
import '../model/service_request_model.dart';
import 'service_request_constants.dart';
import 'service_request_shared.dart';

class DetailsPanel extends StatelessWidget {
  final ServiceRequest ticket;
  final String category;
  final VoidCallback onAddHandler;
  final void Function(int handlerIndex) onAddServicePerson;
  const DetailsPanel({
    super.key,
    required this.ticket,
    required this.category,
    required this.onAddHandler,
    required this.onAddServicePerson,
  });

  @override
  Widget build(BuildContext context) {
    final handlers = ticket.ticketHandler;
    final totalPersonnel = handlers.fold<int>(0, (sum, h) => sum + h.salesPerson.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ticket details',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800, color: ServiceRequestPalette.ink, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text('#TCK-${ticket.ticketId}',
                        style: const TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 14)),
                  ],
                ),
              ),
              if (handlers.isNotEmpty) SummaryPill(handlerCount: handlers.length, personnelCount: totalPersonnel),
            ],
          ),
          const SizedBox(height: 32),
          IssueDetailsSection(ticket: ticket, category: category),
          const SizedBox(height: 40),
          Text(
            handlers.length > 1 ? 'Ticket handlers' : 'Ticket handler details',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: ServiceRequestPalette.ink, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          if (handlers.isEmpty)
            AddHandlerPlaceholder(onTap: onAddHandler)
          else ...[
            for (int i = 0; i < handlers.length; i++)
              HandlerGroup(
                handler: handlers[i],
                index: i,
                total: handlers.length,
                onAddServicePerson: () => onAddServicePerson(i),
              ),
            const SizedBox(height: 4),
            DashedAddButton(
              label: 'Add another handler',
              icon: Icons.person_add_alt_1_outlined,
              onTap: onAddHandler,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class IssueDetailsSection extends StatelessWidget {
  final ServiceRequest ticket;
  final String category;
  const IssueDetailsSection({super.key, required this.ticket, required this.category});

  @override
  Widget build(BuildContext context) {
    final activeTypes = ticket.issueType.where((t) => t.value).map((t) => t.type).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InfoChip(label: category, icon: Icons.category_outlined),
            const SizedBox(width: 12),
            InfoChip(label: ticket.mobileNumber, icon: Icons.phone_android_rounded),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Issue description',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ServiceRequestPalette.inkSoft)),
        const SizedBox(height: 8),
        Text(
          ticket.issueDescription,
          style: const TextStyle(color: ServiceRequestPalette.muted, fontSize: 14, height: 1.6),
        ),
        if (activeTypes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Reported issues',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ServiceRequestPalette.inkSoft)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeTypes
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ServiceRequestPalette.field,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ServiceRequestPalette.border),
                      ),
                      child: Text(t,
                          style: const TextStyle(
                              color: ServiceRequestPalette.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
        if (ticket.images.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Uploaded images',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ServiceRequestPalette.inkSoft)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ticket.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => Container(
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ServiceRequestPalette.border),
                  image: DecorationImage(image: NetworkImage(ticket.images[i]), fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class HandlerGroup extends StatelessWidget {
  final TicketHandler handler;
  final int index;
  final int total;
  final VoidCallback onAddServicePerson;
  const HandlerGroup({
    super.key,
    required this.handler,
    required this.index,
    required this.total,
    required this.onAddServicePerson,
  });

  @override
  Widget build(BuildContext context) {
    final personnel = handler.salesPerson;
    return Padding(
      padding: EdgeInsets.only(bottom: index == total - 1 ? 8 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HandlerCard(handler: handler, index: index, total: total),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 2),
            child: Column(
              children: [
                for (int i = 0; i < personnel.length; i++)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TreeConnector(continuesBelow: true),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 6),
                            child: PersonnelCard(person: personnel[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TreeConnector(continuesBelow: false),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: DashedAddButton(
                            label: 'Add service person',
                            icon: Icons.person_add_alt_1_outlined,
                            onTap: onAddServicePerson,
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HandlerCard extends StatelessWidget {
  final TicketHandler handler;
  final int index;
  final int total;
  const HandlerCard({super.key, required this.handler, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final accent = ServiceRequestHandlerAccents.of(index);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Text(
                handler.name.isNotEmpty ? handler.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      handler.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15.5, color: ServiceRequestPalette.inkSoft),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      total > 1 ? 'Handler ${index + 1}' : 'Handler',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(
                  handler.statusMessage.isNotEmpty ? handler.statusMessage : handler.mobileNumber,
                  style: const TextStyle(color: ServiceRequestPalette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (handler.mobileNumber.isNotEmpty)
            RoundIconButton(
                icon: Icons.phone_outlined,
                onTap: () {},
                bg: Colors.white,
                fg: ServiceRequestPalette.inkSoft),
        ],
      ),
    );
  }
}

class PersonnelCard extends StatelessWidget {
  final SalesPerson person;
  const PersonnelCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: ServiceRequestPalette.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ServiceRequestPalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: ServiceRequestPalette.primarySoft,
            child: Text(
              person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: ServiceRequestPalette.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5, color: ServiceRequestPalette.inkSoft)),
                if (person.statusMessage.isNotEmpty)
                  Text(person.statusMessage,
                      style: const TextStyle(color: ServiceRequestPalette.muted, fontSize: 12.5)),
              ],
            ),
          ),
          RoundIconButton(
              icon: Icons.phone_outlined,
              onTap: () {},
              bg: Colors.white,
              fg: ServiceRequestPalette.inkSoft),
          const SizedBox(width: 8),
          RoundIconButton(
              icon: Icons.mail_outline,
              onTap: () {},
              bg: Colors.white,
              fg: ServiceRequestPalette.inkSoft),
        ],
      ),
    );
  }
}

class AddHandlerPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const AddHandlerPlaceholder({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ServiceRequestPalette.field,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ServiceRequestPalette.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1_outlined, size: 34, color: ServiceRequestPalette.primary),
              const SizedBox(height: 10),
              const Text('Add ticket handler',
                  style: TextStyle(
                      color: ServiceRequestPalette.inkSoft, fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Assign who owns this ticket',
                  style: TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
