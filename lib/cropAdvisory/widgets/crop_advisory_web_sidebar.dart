import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CropAdvisoryWebSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final bool isSetup;

  const CropAdvisoryWebSidebar({
    super.key,
    this.selectedIndex = -1,
    this.onItemSelected,
    this.isSetup = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (Navigator.canPop(context))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          const SizedBox(height: 20),
          _buildSideNavItem(context, 0, 'Home', 'assets/Images/CropAdvisory/home_icon_active.png'),
          _buildSideNavItem(context, 1, 'Weather', 'assets/Images/CropAdvisory/weather.png'),
          _buildSideNavItem(context, 2, 'Irrigation', 'assets/Images/CropAdvisory/irrigation.png'),
          _buildSideNavItem(context, 3, 'Disease', 'assets/Images/CropAdvisory/disease.png'),
          _buildSideNavItem(context, 4, 'Report', 'assets/Images/CropAdvisory/report.png'),
          const Spacer(),
          if (isSetup)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Crop Setup',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSideNavItem(BuildContext context, int index, String label, String iconPath) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: isSetup ? null : () => onItemSelected?.call(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 5,
            ),
          ),
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
