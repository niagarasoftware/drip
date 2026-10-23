import 'package:flutter/material.dart';

/// Floating right-side vertical overlay buttons (Undo, Redo, Hide Joints, Zoom +/- with scale %, Export, Clear).
class DrawSiteControlsOverlay extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onToggleHideJoints;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onExportJson;
  final VoidCallback onClearCanvas;
  final bool canUndo;
  final bool canRedo;
  final bool globalHideJoints;
  final TransformationController transformationController;

  const DrawSiteControlsOverlay({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleHideJoints,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onExportJson,
    required this.onClearCanvas,
    required this.canUndo,
    required this.canRedo,
    required this.globalHideJoints,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              tooltip: 'Redo',
              icon: const Icon(Icons.redo),
              onPressed: canRedo ? onRedo : null,
            ),
            const SizedBox(height: 4),
            Container(width: 24, height: 1, color: Colors.black12),
            const SizedBox(height: 4),
            IconButton(
              tooltip: globalHideJoints ? 'Disable Hide Joints' : 'Enable Hide Joints',
              icon: Icon(globalHideJoints ? Icons.layers_clear : Icons.layers),
              onPressed: onToggleHideJoints,
            ),
            const SizedBox(height: 4),
            Container(width: 24, height: 1, color: Colors.black12),
            const SizedBox(height: 4),
            IconButton(
              tooltip: 'Zoom in',
              icon: const Icon(Icons.zoom_in),
              onPressed: onZoomIn,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: ListenableBuilder(
                listenable: transformationController,
                builder: (_, __) {
                  final scale = transformationController.value.getMaxScaleOnAxis();
                  return Text(
                    '${(scale * 100).round()}%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            IconButton(
              tooltip: 'Zoom out',
              icon: const Icon(Icons.zoom_out),
              onPressed: onZoomOut,
            ),
            const SizedBox(height: 4),
            Container(width: 24, height: 1, color: Colors.black12),
            const SizedBox(height: 4),
            IconButton(
              tooltip: 'Export configuration (JSON)',
              icon: const Icon(Icons.file_download),
              onPressed: onExportJson,
            ),
            IconButton(
              tooltip: 'Clear canvas',
              icon: const Icon(Icons.delete_sweep),
              onPressed: onClearCanvas,
            ),
          ],
        ),
      ),
    );
  }
}
