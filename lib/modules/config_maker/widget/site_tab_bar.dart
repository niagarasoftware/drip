import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Item model representing a site navigation tab.
class SiteTabItem {
  final String id;
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const SiteTabItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}

/// Google Sheets style bottom navigation tab bar for focusing canvas sections.
class SiteTabBar extends StatelessWidget {
  final String activeTabId;
  final List<SiteTabItem> tabs;
  final ScrollController scrollController;

  const SiteTabBar({
    super.key,
    required this.activeTabId,
    required this.tabs,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.0),
          bottom: BorderSide(color: Color(0xFF0F172A), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Left Scroll Action Buttons
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    scrollController.animateTo(
                      math.max(0.0, scrollController.offset - 150),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left, size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    scrollController.animateTo(
                      math.min(scrollController.position.maxScrollExtent, scrollController.offset + 150),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_right, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Tabs
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 6, right: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: tabs.map((tab) {
                  final bool isActive = tab.id == activeTabId;

                  return GestureDetector(
                    onTap: tab.onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF334155),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: isActive
                              ? tab.accentColor
                              : const Color(0xFF475569),
                          width: isActive ? 1.8 : 1.0,
                        ),
                        boxShadow: isActive
                            ? [
                          BoxShadow(
                            color: tab.accentColor.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, -1),
                          ),
                        ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tab.accentColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            tab.icon,
                            size: 14,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
