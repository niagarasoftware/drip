import 'package:flutter/material.dart';
import '../view/utils/config_maker_colors.dart';

/// Floating right-side vertical overlay buttons (Undo, Redo, AI Auto Arrange, Hide Joints, Zoom +/- with scale %, Export, Clear).
class DrawSiteControlsOverlay extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onAiAutoArrange;
  final VoidCallback onToggleHideJoints;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onExportJson;
  final VoidCallback onClearCanvas;
  final bool canUndo;
  final bool canRedo;
  final bool globalHideJoints;
  final TransformationController transformationController;
  final bool fullAccess;

  const DrawSiteControlsOverlay({
    super.key,
    required this.onUndo,
    required this.onRedo,
    this.onAiAutoArrange,
    required this.onToggleHideJoints,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onExportJson,
    required this.onClearCanvas,
    required this.canUndo,
    required this.canRedo,
    required this.globalHideJoints,
    required this.transformationController,
    this.fullAccess = true,
  });

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? iconColor,
    required ConfigMakerColors colors,
  }) {
    final bool enabled = onPressed != null;
    final color = enabled
        ? (iconColor ?? (colors.isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8)))
        : colors.textMuted;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }

  Widget _buildDivider(ConfigMakerColors colors) {
    return Container(
      width: 22,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: colors.controlsDivider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ConfigMakerColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: colors.controlsBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.controlsBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isLight ? 0.10 : 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fullAccess) ...[
              _buildIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
                iconColor: colors.controlsIconColor,
                colors: colors,
              ),
              _buildIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                onPressed: canRedo ? onRedo : null,
                iconColor: colors.controlsIconColor,
                colors: colors,
              ),
              _buildDivider(colors),
            ],
            if (onAiAutoArrange != null) ...[
              _buildIconButton(
                icon: Icons.auto_awesome_rounded,
                tooltip: 'Generate Site Diagram',
                onPressed: onAiAutoArrange,
                iconColor: const Color(0xFFA855F7),
                colors: colors,
              ),
              _buildDivider(colors),
            ],
            if (fullAccess) ...[
              _buildIconButton(
                icon: globalHideJoints ? Icons.layers_clear_rounded : Icons.layers_rounded,
                tooltip: globalHideJoints ? 'Show Joints' : 'Hide Joints',
                onPressed: onToggleHideJoints,
                iconColor: globalHideJoints ? const Color(0xFFF59E0B) : (colors.isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8)),
                colors: colors,
              ),
              _buildDivider(colors),
            ],
            _buildIconButton(
              icon: Icons.add_circle_outline_rounded,
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
              colors: colors,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: transformationController,
                builder: (context, matrix, _) {
                  final scale = matrix.getMaxScaleOnAxis();
                  return Text(
                    '${(scale * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                    ),
                  );
                },
              ),
            ),
            _buildIconButton(
              icon: Icons.remove_circle_outline_rounded,
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
              colors: colors,
            ),
            if (fullAccess) ...[
              _buildDivider(colors),
              _buildIconButton(
                icon: Icons.file_download_rounded,
                tooltip: 'Export configuration (JSON)',
                onPressed: onExportJson,
                iconColor: const Color(0xFF10B981),
                colors: colors,
              ),
              _buildIconButton(
                icon: Icons.delete_sweep_rounded,
                tooltip: 'Clear canvas',
                onPressed: onClearCanvas,
                iconColor: const Color(0xFFEF4444),
                colors: colors,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
