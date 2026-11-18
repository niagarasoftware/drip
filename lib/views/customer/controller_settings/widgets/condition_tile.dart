import 'package:flutter/material.dart';

class ConditionTile extends StatelessWidget {
  final String name;
  final String rule;
  final bool status;
  final VoidCallback onRemove;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<String> onNameChanged;

  const ConditionTile({
    super.key,
    required this.name,
    required this.rule,
    required this.status,
    required this.onRemove,
    required this.onStatusChanged,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(rule, style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.7,
          child: Tooltip(
            message: status ? 'deactivate' : 'activate',
            child: Switch(
              hoverColor: Theme.of(context).primaryColor,
              activeColor: Theme.of(context).primaryColorLight,
              value: status,
              onChanged: onStatusChanged,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Remove condition',
          icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove Condition'),
                content: Text('Are you sure you want to remove this $name ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onRemove();
                    },
                    child: const Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Edit condition name',
          icon: const Icon(Icons.mode_edit, size: 20),
          onPressed: () => _editName(context),
        )
      ],
    );
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Condition Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onNameChanged(controller.text.trim());
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}