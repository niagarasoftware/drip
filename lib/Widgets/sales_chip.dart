import 'package:flutter/material.dart';
import '../../models/sales_data_model.dart';


class SalesChip extends StatelessWidget {
  final int index;
  final Category item;
  const SalesChip({super.key, required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: item.color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black12, width: 0.1),
      ),
      color: WidgetStateProperty.resolveWith<Color>((states) => Colors.blueGrey.shade50),
      label: Text('${index + 1} - ${item.categoryName}', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}