import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterBudgetManagerScreen extends StatelessWidget {
  const WaterBudgetManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Water Budget Manager',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildWeeklyVsRequiredCard(),
            const SizedBox(height: 20),
            _buildModesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildSummaryCard('Available Water:', '91,400 Liters'),
        const SizedBox(width: 12),
        _buildSummaryCard('Season Need', '2,46,800 Liters'),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8F0F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyVsRequiredCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop, color: Color(0xFF42A5F5), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly vs Required',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildWeeklyChart(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _chartLabel('15h'),
                const SizedBox(height: 30),
                _chartLabel('10h'),
                const SizedBox(height: 30),
                _chartLabel('5h'),
                const SizedBox(height: 30),
                _chartLabel('0'),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _bar(20),
                  _bar(80),
                  _bar(40),
                  _bar(110),
                  _bar(100, isGradient: true),
                  _bar(90),
                  _bar(60),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Days',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const SizedBox(width: 24),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                    7,
                    (index) => SizedBox(
                          width: 32,
                          child: Center(
                            child: Text('${index + 1}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[400])),
                          ),
                        )),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _chartLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]));
  }

  Widget _bar(double height, {bool isGradient = false}) {
    return Container(
      width: 32,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isGradient ? null : const Color(0xFFF0F0F0),
        gradient: isGradient
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFA6D0D4), Color(0xFF1B7F8A)],
              )
            : null,
      ),
    );
  }

  Widget _buildModesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop,
                    color: Color(0xFF42A5F5), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Modes',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('Normal',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black87)),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildModesChart(),
        ],
      ),
    );
  }

  Widget _buildModesChart() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _chartLabel('3,000 L'),
                  _chartLabel('2,500 L'),
                  _chartLabel('2,000 L'),
                  _chartLabel('1,500 L'),
                  _chartLabel('1,000 L'),
                  _chartLabel('500 L'),
                  _chartLabel('0 L'),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7,
                          (index) => Container(height: 1, color: Colors.grey[200])),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7,
                          (index) => Container(width: 1, color: Colors.grey[200])),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _modeBar(100),
                          _modeBar(120),
                          _modeBar(120),
                          _modeBar(100),
                          _modeBar(100),
                          _modeBar(90),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'TH', 'F', 'S']
                .map((day) => Text(day,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black54)))
                .toList(),
          ),
        )
      ],
    );
  }

  Widget _modeBar(double height) {
    return Container(
      width: 28,
      height: height,
      color: const Color(0xFF40C4FF),
    );
  }
}
