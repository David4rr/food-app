import 'package:flutter/material.dart';

import '../../../../models/product.dart';

class AddonList extends StatelessWidget {
  final List<AddOn> addOns;
  final void Function(AddOn) onDelete;

  const AddonList({super.key, required this.addOns, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: addOns.map((a) {
        final colors = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: colors.primaryContainer,
              child: Text(
                a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(a.name, style: const TextStyle(fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (a.price > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '+Rp ${a.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colors.error),
                  onPressed: () => onDelete(a),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
