import 'package:flutter/material.dart';
import '../model/service_request_model.dart';
import '../repository/service_request_repository.dart';

/// ---------------------------------------------------------------------
/// Design tokens — single source of truth for color, radius & spacing.
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = Color(0xFF036666);
  static const primarySoft = Color(0xFFE4F1F1);
  static const ink = Color(0xFF111827);
  static const inkSoft = Color(0xFF374151);
  static const muted = Color(0xFF6B7280);
  static const mutedLight = Color(0xFF9CA3AF);
  static const border = Color(0xFFEEF0F2);
  static const canvas = Color(0xFFFCFCFB);
  static const panel = Color(0xFFF7FAFA);
  static const field = Color(0xFFF7F8FA);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFC2410C);
  static const warningBg = Color(0xFFFFEEDD);
  static const pending = Color(0xFF475569);
  static const pendingBg = Color(0xFFEEF1F4);
}

const _radiusSm = 10.0;
const _radiusMd = 14.0;
const _radiusLg = 20.0;

/// Status → (fg, bg) lookup shared by badges and timeline nodes.
class _StatusStyle {
  final Color fg;
  final Color bg;
  const _StatusStyle(this.fg, this.bg);

  static const pending = _StatusStyle(_Palette.pending, _Palette.pendingBg);
  static const inProgress = _StatusStyle(_Palette.warning, _Palette.warningBg);
  static const closed = _StatusStyle(_Palette.success, _Palette.successBg);

  static _StatusStyle of(String status) {
    switch (status) {
      case 'Closed':
        return closed;
      case 'In progress':
        return inProgress;
      default:
        return pending;
    }
  }
}

/// A small rotating accent palette used to visually distinguish multiple
/// ticket handlers on the same ticket (avatar gradient, badge text, border).
class _HandlerAccents {
  static const List<Color> _colors = [
    _Palette.primary,
    Color(0xFF7C3AED), // violet
    Color(0xFF2563EB), // blue
    Color(0xFFC2410C), // amber/orange
    Color(0xFF0891B2), // cyan
  ];
  static Color of(int index) => _colors[index % _colors.length];
}

/// ---------------------------------------------------------------------
/// copyWith-style helpers for the (intentionally immutable) model classes,
/// kept here so service_request_model.dart doesn't need to change.
/// ---------------------------------------------------------------------
extension _ServiceRequestX on ServiceRequest {
  ServiceRequest withHandlers(List<TicketHandler> handlers) => ServiceRequest(
    ticketId: ticketId,
    name: name,
    mobileNumber: mobileNumber,
    issueDescription: issueDescription,
    issueType: issueType,
    issueStatus: issueStatus,
    ticketHandler: handlers,
    images: images,
  );
}

extension _TicketHandlerX on TicketHandler {
  TicketHandler withPersons(List<SalesPerson> persons) => TicketHandler(
    sNo: sNo,
    name: name,
    mobileNumber: mobileNumber,
    statusMessage: statusMessage,
    targetDates: targetDates,
    salesPerson: persons,
  );
}

class ServiceRequestScreen extends StatefulWidget {
  final int userId;
  final int controllerId;
  const ServiceRequestScreen({super.key, required this.userId, required this.controllerId});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _repository = ServiceRequestRepository();
  static const _filters = ['All', 'In progress', 'Closed'];

  List<ServiceRequest> _tickets = [];
  ServiceRequest? _selected;
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final tickets = await _repository.getTickets();
    setState(() {
      _tickets = tickets;
      _selected = tickets.isNotEmpty ? tickets.first : null;
    });
  }

  String _statusOf(ServiceRequest t) {
    final done = t.issueStatus.where((s) => s.value);
    if (done.isEmpty) return 'Pending';
    return done.any((s) => s.name == 'Ticket Closed') ? 'Closed' : 'In progress';
  }

  String _categoryOf(ServiceRequest t) {
    final type = t.issueType.where((x) => x.value).map((x) => x.type);
    return type.isNotEmpty ? type.first : 'General';
  }

  List<ServiceRequest> get _filtered => _activeFilter == 'All'
      ? _tickets
      : _tickets.where((t) => _statusOf(t) == _activeFilter).toList();

  void _replaceSelected(ServiceRequest updated) {
    setState(() {
      final idx = _tickets.indexWhere((t) => t.ticketId == updated.ticketId);
      if (idx != -1) _tickets[idx] = updated;
      _selected = updated;
    });
  }

  void _addHandler(TicketHandler handler) {
    if (_selected == null) return;
    final handlers = [..._selected!.ticketHandler, handler];
    _replaceSelected(_selected!.withHandlers(handlers));
    // TODO: persist via _repository once an "add handler" endpoint exists.
  }

  void _addServicePerson(int handlerIndex, SalesPerson person) {
    if (_selected == null) return;
    final handlers = [..._selected!.ticketHandler];
    if (handlerIndex < 0 || handlerIndex >= handlers.length) return;
    final handler = handlers[handlerIndex];
    handlers[handlerIndex] = handler.withPersons([...handler.salesPerson, person]);
    _replaceSelected(_selected!.withHandlers(handlers));
    // TODO: persist via _repository once an "add service person" endpoint exists.
  }

  void _openCreateTicketDialog() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateTicketDialog(),
  );

  void _openAddHandlerSheet() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddHandlerSheet(onSubmit: _addHandler),
  );

  void _openAddServicePersonSheet(int handlerIndex) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddServicePersonSheet(onSubmit: (p) => _addServicePerson(handlerIndex, p)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.canvas,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            flex: 2,
            child: _selected == null ? const _EmptyState() : _TimelineCard(ticket: _selected!),
          ),
          Expanded(
            flex: 4,
            child: _selected == null
                ? const SizedBox.shrink()
                : _DetailsPanel(
              ticket: _selected!,
              category: _categoryOf(_selected!),
              onAddHandler: _openAddHandlerSheet,
              onAddServicePerson: _openAddServicePersonSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _Palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tickets',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _Palette.ink, letterSpacing: -0.5)),
                _RoundIconButton(icon: Icons.add_rounded, onTap: _openCreateTicketDialog),
              ],
            ),
          ),
          _FilterBar(
            filters: _filters,
            active: _activeFilter,
            countFor: (f) => f == 'All' ? _tickets.length : _tickets.where((t) => _statusOf(t) == f).length,
            onSelect: (f) => setState(() => _activeFilter = f),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
              child: Text('No tickets here', style: TextStyle(color: _Palette.mutedLight, fontSize: 13)),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final ticket = _filtered[i];
                return _TicketCard(
                  ticket: ticket,
                  status: _statusOf(ticket),
                  selected: _selected?.ticketId == ticket.ticketId,
                  onTap: () => setState(() => _selected = ticket),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------- Sidebar bits -------------------------------

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String active;
  final int Function(String) countFor;
  final ValueChanged<String> onSelect;
  const _FilterBar({required this.filters, required this.active, required this.countFor, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: _Palette.field, borderRadius: BorderRadius.circular(_radiusSm)),
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
                      color: isActive ? _Palette.ink : _Palette.mutedLight,
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

class _TicketCard extends StatelessWidget {
  final ServiceRequest ticket;
  final String status;
  final bool selected;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _StatusStyle.of(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radiusMd),
              border: Border.all(color: selected ? _Palette.primary : _Palette.border, width: selected ? 1.4 : 1),
              boxShadow: [
                BoxShadow(
                  color: selected ? _Palette.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
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
                        style: const TextStyle(color: _Palette.mutedLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    _StatusBadge(status: status, style: style),
                  ],
                ),
                const SizedBox(height: 10),
                Text(ticket.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: _Palette.ink)),
                const SizedBox(height: 5),
                Text(
                  ticket.issueDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _Palette.muted, fontSize: 12.5, height: 1.5),
                ),
                if (ticket.ticketHandler.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 13, color: _Palette.mutedLight),
                      const SizedBox(width: 4),
                      Text('${ticket.ticketHandler.length} handlers',
                          style: TextStyle(color: _Palette.mutedLight, fontSize: 11, fontWeight: FontWeight.w600)),
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

/// -------------------------------- Shared atoms --------------------------------

class _StatusBadge extends StatelessWidget {
  final String status;
  final _StatusStyle style;
  const _StatusBadge({required this.status, required this.style});

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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  const _RoundIconButton({required this.icon, required this.onTap, this.bg = _Palette.primary, this.fg = Colors.white});

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

/// A small pill button used for secondary "add" actions (add handler / add
/// service person) so both share one visual language. `compact` shrinks it
/// for use nested under a handler card.
class _DashedAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  const _DashedAddButton({
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
            color: compact ? _Palette.primary.withOpacity(0.02) : null,
            border: Border.all(color: _Palette.primary.withOpacity(compact ? 0.25 : 0.35), width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 18, color: _Palette.primary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: _Palette.primary, fontWeight: FontWeight.w700, fontSize: compact ? 13 : 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: _Palette.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.confirmation_number_outlined, size: 36, color: _Palette.primary),
          ),
          const SizedBox(height: 18),
          const Text('Select a ticket', style: TextStyle(color: _Palette.ink, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Its timeline and details will show up here', style: TextStyle(color: _Palette.mutedLight, fontSize: 13)),
        ],
      ),
    );
  }
}

/// ------------------------------- Timeline panel -------------------------------

class _TimelineCard extends StatelessWidget {
  final ServiceRequest ticket;
  const _TimelineCard({required this.ticket});

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
      margin: const EdgeInsets.all(28),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _Palette.panel,
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ticket status', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _Palette.ink)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (_, i) => _TimelineNode(
                status: visible[i],
                ticket: ticket,
                isLast: i == visible.length - 1,
                icon: _iconFor(visible[i].name),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final IssueStatus status;
  final ServiceRequest ticket;
  final bool isLast;
  final IconData icon;
  const _TimelineNode({required this.status, required this.ticket, required this.isLast, required this.icon});

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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _Palette.success.withOpacity(0.12) : Colors.white,
                  border: Border.all(color: done ? _Palette.success : const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Icon(done ? Icons.check_rounded : icon, size: 17, color: done ? _Palette.success : _Palette.pending),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: done ? _Palette.success.withOpacity(0.35) : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5, color: done ? _Palette.inkSoft : _Palette.mutedLight)),
                  const SizedBox(height: 3),
                  Text(d.subtitle, style: TextStyle(color: _Palette.muted, fontSize: 12.5)),
                  if (d.date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(d.date, style: TextStyle(color: _Palette.mutedLight, fontSize: 11.5)),
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

/// -------------------------------- Details panel --------------------------------

class _DetailsPanel extends StatelessWidget {
  final ServiceRequest ticket;
  final String category;
  final VoidCallback onAddHandler;
  final void Function(int handlerIndex) onAddServicePerson;
  const _DetailsPanel({
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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _Palette.ink, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text('#TCK-${ticket.ticketId}', style: const TextStyle(color: _Palette.mutedLight, fontSize: 14)),
                  ],
                ),
              ),
              if (handlers.isNotEmpty) _SummaryPill(handlerCount: handlers.length, personnelCount: totalPersonnel),
            ],
          ),
          const SizedBox(height: 32),
          _IssueDetailsSection(ticket: ticket, category: category),
          const SizedBox(height: 40),
          Text(
            handlers.length > 1 ? 'Ticket handlers' : 'Ticket handler details',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _Palette.ink, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          if (handlers.isEmpty)
            _AddHandlerPlaceholder(onTap: onAddHandler)
          else ...[
            for (int i = 0; i < handlers.length; i++)
              _HandlerGroup(
                handler: handlers[i],
                index: i,
                total: handlers.length,
                onAddServicePerson: () => onAddServicePerson(i),
              ),
            const SizedBox(height: 4),
            _DashedAddButton(
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

class _IssueDetailsSection extends StatelessWidget {
  final ServiceRequest ticket;
  final String category;
  const _IssueDetailsSection({required this.ticket, required this.category});

  @override
  Widget build(BuildContext context) {
    final activeTypes = ticket.issueType.where((t) => t.value).map((t) => t.type).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _InfoChip(label: category, icon: Icons.category_outlined),
            const SizedBox(width: 12),
            _InfoChip(label: ticket.mobileNumber, icon: Icons.phone_android_rounded),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Issue description',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Palette.inkSoft)),
        const SizedBox(height: 8),
        Text(
          ticket.issueDescription,
          style: const TextStyle(color: _Palette.muted, fontSize: 14, height: 1.6),
        ),
        if (activeTypes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Reported issues',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Palette.inkSoft)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeTypes
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _Palette.field,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _Palette.border),
                      ),
                      child: Text(t, style: const TextStyle(color: _Palette.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
        if (ticket.images.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Uploaded images',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _Palette.inkSoft)),
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
                  border: Border.all(color: _Palette.border),
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

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: _Palette.field, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _Palette.muted),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: _Palette.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Small badge summarizing how many handlers / service persons are on a
/// ticket at a glance.
class _SummaryPill extends StatelessWidget {
  final int handlerCount;
  final int personnelCount;
  const _SummaryPill({required this.handlerCount, required this.personnelCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: _Palette.primarySoft, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_rounded, size: 15, color: _Palette.primary),
          const SizedBox(width: 6),
          Text(
            '$handlerCount ${handlerCount == 1 ? 'handler' : 'handlers'} · $personnelCount ${personnelCount == 1 ? 'person' : 'people'}',
            style: const TextStyle(color: _Palette.primary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A short tree-style connector (vertical rail + branch) drawn to the left
/// of anything nested under a ticket handler, so the hierarchy reads at a
/// glance. `continuesBelow` keeps the rail running to the next sibling;
/// the last item in a group cuts the rail short at the branch point.
class _TreeConnector extends StatelessWidget {
  final bool continuesBelow;
  const _TreeConnector({this.continuesBelow = true});

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

/// One ticket handler plus its own nested service persons, visually
/// grouped so it's obvious which service persons belong to which handler.
class _HandlerGroup extends StatelessWidget {
  final TicketHandler handler;
  final int index;
  final int total;
  final VoidCallback onAddServicePerson;
  const _HandlerGroup({
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
          _HandlerCard(handler: handler, index: index, total: total),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 2),
            child: Column(
              children: [
                for (int i = 0; i < personnel.length; i++)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _TreeConnector(continuesBelow: true),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 6),
                            child: _PersonnelCard(person: personnel[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TreeConnector(continuesBelow: false),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _DashedAddButton(
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

class _HandlerCard extends StatelessWidget {
  final TicketHandler handler;
  final int index;
  final int total;
  const _HandlerCard({required this.handler, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    final accent = _HandlerAccents.of(index);
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: _Palette.inkSoft),
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
                  style: TextStyle(color: _Palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (handler.mobileNumber.isNotEmpty)
            const _RoundIconButton(icon: Icons.phone_outlined, onTap: _noop, bg: Colors.white, fg: _Palette.inkSoft),
        ],
      ),
    );
  }
}

class _PersonnelCard extends StatelessWidget {
  final SalesPerson person;
  const _PersonnelCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _Palette.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: _Palette.primarySoft,
            child: Text(
              person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
              style: const TextStyle(color: _Palette.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _Palette.inkSoft)),
                if (person.statusMessage.isNotEmpty)
                  Text(person.statusMessage, style: TextStyle(color: _Palette.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const _RoundIconButton(icon: Icons.phone_outlined, onTap: _noop, bg: Colors.white, fg: _Palette.inkSoft),
          const SizedBox(width: 8),
          const _RoundIconButton(icon: Icons.mail_outline, onTap: _noop, bg: Colors.white, fg: _Palette.inkSoft),
        ],
      ),
    );
  }
}

void _noop() {}

class _AddHandlerPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _AddHandlerPlaceholder({required this.onTap});

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
            color: _Palette.field,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Palette.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1_outlined, size: 34, color: _Palette.primary),
              const SizedBox(height: 10),
              Text('Add ticket handler', style: TextStyle(color: _Palette.inkSoft, fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Assign who owns this ticket', style: TextStyle(color: _Palette.mutedLight, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _Palette.border),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(color: _Palette.mutedLight, fontSize: 13.5),
    filled: true,
    fillColor: _Palette.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _Palette.primary, width: 1.5),
    ),
  );
}

/// A row that lays its children out side by side above [breakpoint] and
/// stacks them vertically below it.
class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;
  const _ResponsiveRow({required this.children, this.spacing = 24, this.breakpoint = 600});

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

/// A generic bottom sheet shell shared by every "add ___" flow, so the
/// grab handle / title / subtitle / actions row aren't rebuilt each time.
class _SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final String submitLabel;
  final VoidCallback onSubmit;
  const _SheetShell({
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
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _Palette.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: _Palette.muted, fontSize: 14.5)),
              const SizedBox(height: 28),
              child,
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: _Palette.muted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
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

/// ---------------------------- Add ticket handler sheet ----------------------------

class _AddHandlerSheet extends StatefulWidget {
  final ValueChanged<TicketHandler> onSubmit;
  const _AddHandlerSheet({required this.onSubmit});

  @override
  State<_AddHandlerSheet> createState() => _AddHandlerSheetState();
}

class _AddHandlerSheetState extends State<_AddHandlerSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController();

  /// Optional service persons added at the same time as the handler.
  final List<_PersonDraft> _persons = [_PersonDraft()];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _role.dispose();
    for (final p in _persons) {
      p.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final salesPersons = _persons
        .where((p) => p.name.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => SalesPerson(
      sNo: e.key + 1,
      name: e.value.name.text.trim(),
      mobileNumber: e.value.phone.text.trim(),
      statusMessage: e.value.role.text.trim(),
    ))
        .toList();

    widget.onSubmit(TicketHandler(
      sNo: 1,
      name: _name.text.trim(),
      mobileNumber: _phone.text.trim(),
      statusMessage: _role.text.trim(),
      targetDates: const [],
      salesPerson: salesPersons,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Add ticket handler',
      subtitle: 'Assign who owns this ticket — you can add service persons under them too.',
      onSubmit: _submit,
      submitLabel: 'Add handler',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResponsiveRow(children: [
            _labeledInput('Handler name*', _name, hint: 'e.g. Arun Kumar'),
            _labeledInput('Phone number', _phone, hint: '+91 00000 00000'),
          ]),
          const SizedBox(height: 20),
          _labeledInput('Role / status', _role, hint: 'e.g. Regional Support Lead'),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service persons (optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _Palette.ink)),
              TextButton.icon(
                onPressed: () => setState(() => _persons.add(_PersonDraft())),
                icon: const Icon(Icons.add_rounded, size: 18, color: _Palette.primary),
                label: const Text('Add another', style: TextStyle(color: _Palette.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _persons.length; i++) _personRow(i),
        ],
      ),
    );
  }

  Widget _personRow(int index) {
    final draft = _persons[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _Palette.field, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service person ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
              if (_persons.length > 1)
                InkWell(
                  onTap: () => setState(() {
                    _persons[index].dispose();
                    _persons.removeAt(index);
                  }),
                  child: const Icon(Icons.close_rounded, size: 18, color: _Palette.mutedLight),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ResponsiveRow(spacing: 16, children: [
            _labeledInput('Name', draft.name, hint: 'Full name'),
            _labeledInput('Phone', draft.phone, hint: 'Mobile number'),
            _labeledInput('Role', draft.role, hint: 'e.g. Field Technician'),
          ]),
        ],
      ),
    );
  }

  Widget _labeledInput(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, decoration: _fieldDecoration(hint: hint)),
      ],
    );
  }
}

/// Lightweight mutable holder of controllers for one service-person row.
class _PersonDraft {
  final name = TextEditingController();
  final phone = TextEditingController();
  final role = TextEditingController();
  void dispose() {
    name.dispose();
    phone.dispose();
    role.dispose();
  }
}

/// ------------------------- Add service person (to a specific handler) -------------------------

class _AddServicePersonSheet extends StatefulWidget {
  final ValueChanged<SalesPerson> onSubmit;
  const _AddServicePersonSheet({required this.onSubmit});

  @override
  State<_AddServicePersonSheet> createState() => _AddServicePersonSheetState();
}

class _AddServicePersonSheetState extends State<_AddServicePersonSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _role.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    widget.onSubmit(SalesPerson(
      sNo: 0,
      name: _name.text.trim(),
      mobileNumber: _phone.text.trim(),
      statusMessage: _role.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Add service person',
      subtitle: 'Assign an additional person to help resolve this ticket.',
      onSubmit: _submit,
      submitLabel: 'Add person',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Full name*', _name, hint: 'e.g. Priya Raman'),
          const SizedBox(height: 20),
          _field('Phone number', _phone, hint: '+91 00000 00000'),
          const SizedBox(height: 20),
          _field('Role / status', _role, hint: 'e.g. Field Technician'),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, decoration: _fieldDecoration(hint: hint)),
      ],
    );
  }
}

/// ------------------------------- Create ticket sheet -------------------------------

class CreateTicketDialog extends StatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  static const _issueTypes = ['Application', 'Hardware', 'Valve', 'Filter', 'Fertilizer', 'Sensors', 'Others'];
  final Set<String> _selected = {'Application'};

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
              const Text('Raise a complaint',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _Palette.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text("Tell us what's wrong and we'll route it to the right person.",
                  style: TextStyle(color: _Palette.muted, fontSize: 15)),
              const SizedBox(height: 32),
              const Text('New ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Palette.ink)),
              const Text('Fill in the details below — our team responds within 24 hours',
                  style: TextStyle(color: _Palette.muted, fontSize: 13.5)),
              const SizedBox(height: 26),
              _ResponsiveRow(children: [
                _labeledField('Your name*', 'Siva'),
                _labeledField('Phone number', '+91 00000 00000'),
                _labeledField('Product*', 'X200 Controller / MAC address'),
              ]),
              const SizedBox(height: 28),
              const Text('Issue type*', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 22,
                runSpacing: 14,
                children: _issueTypes.map(_buildIssueChip).toList(),
              ),
              const SizedBox(height: 28),
              _ResponsiveRow(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What went wrong? (optional)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
                    const SizedBox(height: 10),
                    TextFormField(
                      maxLines: 4,
                      decoration: _fieldDecoration(hint: 'Describe the issue and when it started'),
                    ),
                  ],
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload image (optional)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
                    SizedBox(height: 10),
                    _UploadDropZone(),
                  ],
                ),
              ]),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Fields marked * are required.', style: TextStyle(color: _Palette.mutedLight, fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Submit ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _Palette.inkSoft)),
        const SizedBox(height: 8),
        TextFormField(decoration: _fieldDecoration(hint: hint)),
      ],
    );
  }

  Widget _buildIssueChip(String type) {
    final isSelected = _selected.contains(type);
    return GestureDetector(
      onTap: () => setState(() => isSelected ? _selected.remove(type) : _selected.add(type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _Palette.primarySoft : _Palette.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _Palette.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16, color: isSelected ? _Palette.primary : _Palette.mutedLight),
            const SizedBox(width: 8),
            Text(type,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _Palette.primary : _Palette.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _Palette.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: _Palette.mutedLight, size: 28),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: _Palette.muted, fontSize: 12),
              children: [
                TextSpan(text: 'Click to upload', style: TextStyle(color: _Palette.primary, fontWeight: FontWeight.w700)),
                TextSpan(text: ' or drag and drop'),
              ],
            ),
          ),
          const Text('PNG, JPG, TIF up to 5MB', style: TextStyle(color: _Palette.mutedLight, fontSize: 10.5)),
        ],
      ),
    );
  }
}