import 'package:flutter/material.dart';
import '../model/service_request_model.dart';
import '../repository/service_request_repository.dart';
import 'service_request_constants.dart';
import 'service_request_shared.dart';

class AddHandlerSheet extends StatefulWidget {
  final ValueChanged<TicketHandler> onSubmit;
  final ServiceRequestRepository repository;
  const AddHandlerSheet({super.key, required this.onSubmit, required this.repository});

  @override
  State<AddHandlerSheet> createState() => _AddHandlerSheetState();
}

class _AddHandlerSheetState extends State<AddHandlerSheet> {
  List<TicketHandler>? _dealers;
  TicketHandler? _selectedDealer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDealers();
  }

  Future<void> _fetchDealers() async {
    // final dealers = await widget.repository.getDealers();
    if (mounted) {
      setState(() {
        // _dealers = dealers;
        _isLoading = false;
      });
    }
  }

  void _submit() {
    if (_selectedDealer == null) return;
    // We only want the handler info, maybe not all their salesPersons yet?
    // The user said "dealer is the service handler".
    // Let's pass the selected dealer but with empty salesPerson list if they want to add them one by one,
    // OR pass the dealer with their salesPersons.
    // Given the previous code, it seems they want to add service persons later or optionally.
    // Let's include the dealer's info.
    widget.onSubmit(TicketHandler(
      sNo: _selectedDealer!.sNo,
      name: _selectedDealer!.name,
      mobileNumber: _selectedDealer!.mobileNumber,
      statusMessage: _selectedDealer!.statusMessage,
      targetDates: const [],
      salesPerson: const [], // Start with empty, add specifically later?
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Select Dealer',
      subtitle: 'Choose an authorized dealer to handle this service request.',
      onSubmit: _submit,
      submitLabel: 'Assign Dealer',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Dealers',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ServiceRequestPalette.inkSoft)),
                const SizedBox(height: 12),
                if (_dealers == null || _dealers!.isEmpty)
                  const Text('No dealers found.')
                else
                  ..._dealers!.map((dealer) {
                    final isSelected = _selectedDealer?.sNo == dealer.sNo;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDealer = dealer),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? ServiceRequestPalette.primarySoft : ServiceRequestPalette.field,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.mutedLight,
                              radius: 20,
                              child: Text(dealer.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dealer.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.inkSoft)),
                                  Text(dealer.statusMessage,
                                      style: const TextStyle(fontSize: 12, color: ServiceRequestPalette.muted)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: ServiceRequestPalette.primary)
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
    );
  }
}

class AddServicePersonSheet extends StatefulWidget {
  final ValueChanged<SalesPerson> onSubmit;
  final List<SalesPerson> availablePersons;
  const AddServicePersonSheet({super.key, required this.onSubmit, required this.availablePersons});

  @override
  State<AddServicePersonSheet> createState() => _AddServicePersonSheetState();
}

class _AddServicePersonSheetState extends State<AddServicePersonSheet> {
  SalesPerson? _selectedPerson;

  void _submit() {
    if (_selectedPerson == null) return;
    widget.onSubmit(_selectedPerson!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Select Service Person',
      subtitle: 'Choose a service technician from the dealer\'s team.',
      onSubmit: _submit,
      submitLabel: 'Assign Person',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dealer\'s Team',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ServiceRequestPalette.inkSoft)),
          const SizedBox(height: 12),
          if (widget.availablePersons.isEmpty)
            const Text('No service persons available for this dealer.')
          else
            ...widget.availablePersons.map((person) {
              final isSelected = _selectedPerson?.sNo == person.sNo;
              return GestureDetector(
                onTap: () => setState(() => _selectedPerson = person),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? ServiceRequestPalette.primarySoft : ServiceRequestPalette.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.mutedLight,
                        radius: 18,
                        child: Text(person.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(person.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.inkSoft)),
                            Text(person.statusMessage,
                                style: const TextStyle(fontSize: 12, color: ServiceRequestPalette.muted)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: ServiceRequestPalette.primary)
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

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
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: ServiceRequestPalette.ink, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text("Tell us what's wrong and we'll route it to the right person.",
                  style: TextStyle(color: ServiceRequestPalette.muted, fontSize: 15)),
              const SizedBox(height: 32),
              const Text('New ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ServiceRequestPalette.ink)),
              const Text('Fill in the details below — our team responds within 24 hours',
                  style: TextStyle(color: ServiceRequestPalette.muted, fontSize: 13.5)),
              const SizedBox(height: 26),
              ResponsiveRow(children: [
                _labeledField('Your name*', 'Siva'),
                _labeledField('Phone number', '+91 00000 00000'),
                _labeledField('Product*', 'X200 Controller / MAC address'),
              ]),
              const SizedBox(height: 28),
              const Text('Issue type*',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ServiceRequestPalette.inkSoft)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 22,
                runSpacing: 14,
                children: _issueTypes.map(_buildIssueChip).toList(),
              ),
              const SizedBox(height: 28),
              ResponsiveRow(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What went wrong? (optional)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ServiceRequestPalette.inkSoft)),
                    const SizedBox(height: 10),
                    TextFormField(
                      maxLines: 4,
                      decoration: fieldDecoration(hint: 'Describe the issue and when it started'),
                    ),
                  ],
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload image (optional)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ServiceRequestPalette.inkSoft)),
                    SizedBox(height: 10),
                    UploadDropZone(),
                  ],
                ),
              ]),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Fields marked * are required.',
                        style: TextStyle(color: ServiceRequestPalette.mutedLight, fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ServiceRequestPalette.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
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
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ServiceRequestPalette.inkSoft)),
        const SizedBox(height: 8),
        TextFormField(decoration: fieldDecoration(hint: hint)),
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
          color: isSelected ? ServiceRequestPalette.primarySoft : ServiceRequestPalette.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? ServiceRequestPalette.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16, color: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.mutedLight),
            const SizedBox(width: 8),
            Text(type,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? ServiceRequestPalette.primary : ServiceRequestPalette.inkSoft)),
          ],
        ),
      ),
    );
  }
}
