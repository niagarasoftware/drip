import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Report',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Irrigation Section ---
            const Text(
              'Irrigation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.water_drop_outlined,
                              color: Color(0xFF3D9BA5),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Jan 7 – Jan 13',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'Export As Pdf',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down,
                                size: 16, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bar Chart
                  const _IrrigationBarChart(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Fertigation Section ---
            const Text(
              'Fertigation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // Fertilizer applied card
            _InfoCard(
              icon: Icons.science_outlined,
              title: 'Fertilizer applied',
              description: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                  children: [
                    TextSpan(text: 'A total of '),
                    TextSpan(
                      text: '50 kg',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                      ' of fertilizer was successfully applied during the fertigation process.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Mixing time card
            _InfoCard(
              icon: Icons.timer_outlined,
              title: 'Mixing time',
              description: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                  children: [
                    TextSpan(
                        text:
                        'The fertilizer mixing operation was completed in '),
                    TextSpan(
                      text: '30 minutes,',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                      ' ensuring proper nutrient preparation and distribution for the irrigation cycle.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Bar Chart Widget ─────────────────────────────────────────────────────────

class _IrrigationBarChart extends StatelessWidget {
  const _IrrigationBarChart();

  // Hours for days 1–7
  static const List<double> _data = [10, 15, 16, 16, 15, 15, 15];
  static const double _maxY = 20;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y-axis labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('15h',
                  style: TextStyle(fontSize: 11, color: Colors.black38)),
              Text('10h',
                  style: TextStyle(fontSize: 11, color: Colors.black38)),
              Text('5h',
                  style: TextStyle(fontSize: 11, color: Colors.black38)),
              Text('0', style: TextStyle(fontSize: 11, color: Colors.black38)),
            ],
          ),
          const SizedBox(width: 8),
          // Bars + x-labels
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_data.length, (i) {
                      final fraction = _data[i] / _maxY;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: FractionallySizedBox(
                            heightFactor: fraction,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF3D9BA5),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                // X-axis labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Days',
                        style:
                        TextStyle(fontSize: 11, color: Colors.black38)),
                    ...List.generate(
                      _data.length,
                          (i) => Expanded(
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black38),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card Widget ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          description,
        ],
      ),
    );
  }
}

