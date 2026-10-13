import 'package:flutter/material.dart';

class ChannelLogPage extends StatelessWidget {
  final List<ChannelLogRecord> logs;

  const ChannelLogPage({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No channel logs available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 2
            : 1;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Channel Log',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 280,
              ),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return _ChannelCard(
                  record: logs[index],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class ChannelLogRecord {
  final String channelName;
  final String tankName;
  final List<ChannelSequenceRecord> sequences;

  const ChannelLogRecord({
    required this.channelName,
    required this.tankName,
    required this.sequences,
  });
}

class ChannelSequenceRecord {
  final String sequenceName;
  final String valveName;
  final String setValue;
  final String actualValue;
  final String ec;
  final String ph;

  const ChannelSequenceRecord({
    required this.sequenceName,
    required this.valveName,
    required this.setValue,
    required this.actualValue,
    required this.ec,
    required this.ph,
  });
}

class _ChannelCard extends StatelessWidget {
  final ChannelLogRecord record;

  const _ChannelCard({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.channelName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006775),
                  ),
                ),
                Chip(
                  label: Text(record.tankName),
                  backgroundColor:
                  const Color(0xFFE6F2F4),
                ),
              ],
            ),
            Text(
              '${record.sequences.length} SEQUENCES',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: record.sequences.length,
                separatorBuilder: (_, __) =>
                const Divider(),
                itemBuilder: (context, index) {
                  final sequence =
                  record.sequences[index];

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              sequence.sequenceName,
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            Text(sequence.valveName),
                          ],
                        ),
                      ),
                      _value('Set',
                          sequence.setValue),
                      _value('Actual',
                          sequence.actualValue),
                      _value('EC', sequence.ec),
                      _value('pH', sequence.ph),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _value(String label, String value) {
    return Padding(
      padding:
      const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.blueGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}