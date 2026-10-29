import 'package:flutter/material.dart';
import '../../../Widgets/sized_image.dart';
import '../view/utils/config_maker_colors.dart';

/// Page heading for configuration screens.
/// Displays an icon badge, title, total item count badge, subtitle, and an optional action button.
class ConfigPageHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final int totalCount;
  final String countUnitSingular;
  final String countUnitPlural;
  final Color primaryColor;
  final IconData icon;
  final VoidCallback? onAddPressed;
  final String addButtonLabel;

  const ConfigPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalCount,
    this.countUnitSingular = 'item',
    this.countUnitPlural = 'items',
    required this.primaryColor,
    this.icon = Icons.tune_rounded,
    this.onAddPressed,
    this.addButtonLabel = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final unitText = totalCount == 1 ? countUnitSingular : countUnitPlural;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount $unitText',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (onAddPressed != null) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              addButtonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state container for configuration screens when no items are added.
class ConfigEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback? onAddPressed;
  final String buttonLabel;

  const ConfigEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.waves_rounded,
    required this.primaryColor,
    this.onAddPressed,
    this.buttonLabel = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: primaryColor.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (onAddPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section container used inside configuration cards (e.g. Inlet, Outlet, Aeration, Mixing).
class ConfigFlowSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  const ConfigFlowSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 8,
          endIndent: 8,
          color: accent.withValues(alpha: 0.18),
        ));
      }
      rows.add(children[i]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 13, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

/// Component tile for displaying object/sensor assignment inside configuration cards.
/// Supports both full row style (with chips and edit/add icon) and compact style (for sensor grids).
class ConfigComponentTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final List<String> names;
  final bool isAssigned;
  final VoidCallback onTap;
  final Color accent;
  final bool compact;

  const ConfigComponentTile({
    super.key,
    required this.title,
    required this.imagePath,
    required this.names,
    required this.isAssigned,
    required this.onTap,
    required this.accent,
    this.compact = false,
  });

  Widget _buildImage(Color color) {
    if (imagePath.endsWith('.svg')) {
      return SizedImage(
        imagePath: imagePath,
        color: color,
      );
    } else {
      return Image.asset(
        imagePath,
        color: color,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    if (compact) {
      return Material(
        color: isAssigned
            ? accent.withValues(alpha: colors.isLight ? 0.12 : 0.15)
            : colors.unassignedBadgeBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isAssigned
              ? BorderSide(color: accent.withValues(alpha: 0.5))
              : BorderSide(color: colors.unassignedBadgeBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: _buildImage(isAssigned ? accent : colors.textMuted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAssigned ? names.join(', ') : 'Tap to add',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isAssigned ? FontWeight.bold : FontWeight.w500,
                          fontStyle: isAssigned ? FontStyle.normal : FontStyle.italic,
                          color: isAssigned ? accent : colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isAssigned
                      ? accent.withValues(alpha: 0.18)
                      : colors.unassignedBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: isAssigned ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
                ),
                child: _buildImage(isAssigned ? accent : colors.textMuted),
              ),
              const SizedBox(width: 10),

              // Label + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isAssigned)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 90),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final name in names)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: colors.unassignedBadgeBg,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'Not assigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action icon
              isAssigned
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit_rounded, size: 17, color: accent),
                    )
                  : Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, size: 17, color: accent),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type selector dropdown popup button with icon and styled options.
class ConfigTypeSelector extends StatelessWidget {
  final String currentType;
  final List<String> typeList;
  final Map<String, IconData> typeIcons;
  final ValueChanged<String> onSelected;
  final String tooltip;

  const ConfigTypeSelector({
    super.key,
    required this.currentType,
    required this.typeList,
    required this.typeIcons,
    required this.onSelected,
    this.tooltip = 'Change type',
  });

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    const activeAccent = Color(0xFF38BDF8); // Bright sky blue accent

    return PopupMenuButton<String>(
      tooltip: tooltip,
      initialValue: currentType,
      color: colors.isLight ? Colors.white : const Color(0xFF181C38),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.innerBorder),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => typeList.map((type) {
        final selected = type == currentType;
        return PopupMenuItem<String>(
          value: type,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? activeAccent.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  typeIcons[type] ?? Icons.circle,
                  size: 18,
                  color: selected ? activeAccent : colors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? activeAccent : colors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, size: 18, color: activeAccent),
              ],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
        decoration: BoxDecoration(
          color: colors.isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E2648),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcons[currentType] ?? Icons.circle, size: 14, color: activeAccent),
            const SizedBox(width: 6),
            Text(
              currentType,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: activeAccent),
          ],
        ),
      ),
    );
  }
}

/// Responsive configuration card shell container.
/// Automatically handles single-column vs multi-column layout on wide screens.
class ConfigCardShell extends StatelessWidget {
  final Widget headerBlock;
  final bool isComplete;
  final Color completeColor;
  final List<Widget> body;
  final Widget? footer;
  final bool expandHeader;
  final double? rightPanelWidth;

  const ConfigCardShell({
    super.key,
    required this.headerBlock,
    required this.isComplete,
    this.completeColor = const Color(0xFF059669),
    required this.body,
    this.footer,
    this.expandHeader = false,
    this.rightPanelWidth,
  });

  Widget _buildBodyGrid(List<Widget> bodyItems, {required bool wide}) {
    if (bodyItems.isEmpty) return const SizedBox();

    if (wide) {
      final rows = <Widget>[];
      for (var i = 0; i < bodyItems.length; i += 2) {
        final hasPair = i + 1 < bodyItems.length;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: bodyItems[i]),
                if (hasPair) ...[
                  const SizedBox(width: 10),
                  Expanded(child: bodyItems[i + 1]),
                ],
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withGaps(rows, 10),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withGaps(bodyItems, 10),
      );
    }
  }

  List<Widget> _withGaps(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? completeColor.withValues(alpha: 0.48)
              : colors.cardBorder,
          width: isComplete ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isComplete
                ? completeColor.withValues(alpha: colors.isLight ? 0.05 : 0.08)
                : Colors.black.withValues(alpha: colors.isLight ? 0.05 : 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxW = constraints.maxWidth;
          final bool isUltraWide = maxW >= 880 && body.isNotEmpty;
          final bool isMediumWide = maxW >= 620;

          if (isUltraWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (expandHeader) ...[
                        Expanded(
                          child: headerBlock,
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: rightPanelWidth ?? 360.0,
                          child: _buildBodyGrid(body, wide: false),
                        ),
                      ] else ...[
                        SizedBox(
                          width: 280,
                          child: headerBlock,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBodyGrid(body, wide: true),
                        ),
                      ],
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer!,
                ],
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerBlock,
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildBodyGrid(body, wide: isMediumWide),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer!,
                ],
              ],
            );
          }
        },
      ),
    );
  }
}

/// Collapsible section container for level and sensors.
class ConfigSensorsSection extends StatelessWidget {
  final Key? storageKey;
  final String title;
  final int activeSensorCount;
  final int totalSensors;
  final Color primaryColor;
  final List<Widget> children;

  const ConfigSensorsSection({
    super.key,
    this.storageKey,
    this.title = 'Level and sensors',
    required this.activeSensorCount,
    this.totalSensors = 6,
    required this.primaryColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    final active = activeSensorCount > 0;
    final subTextColor = colors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: colors.innerSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          iconTheme: IconThemeData(color: subTextColor),
        ),
        child: ExpansionTile(
          key: storageKey,
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: active ? primaryColor.withValues(alpha: 0.18) : colors.unassignedBadgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_rounded,
              size: 14,
              color: active ? primaryColor : subTextColor,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: active ? primaryColor.withValues(alpha: 0.18) : colors.unassignedBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeSensorCount/$totalSensors active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: active ? primaryColor : subTextColor,
                  ),
                ),
              ),
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}
