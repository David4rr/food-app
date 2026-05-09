import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/product.dart';

Future<AddOn?> showAddOnDialog(BuildContext context) async {
  final aoNameCtrl = TextEditingController();
  final aoPriceCtrl = TextEditingController(text: '0');
  final uuid = const Uuid();

  return await showDialog<AddOn>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('New Add-on'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aoNameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. No corn, Extra cheese',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aoPriceCtrl,
              decoration: const InputDecoration(
                labelText: 'Extra Price',
                prefixText: 'Rp ',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final n = aoNameCtrl.text.trim();
            if (n.isEmpty) return;
            Navigator.pop(
              dctx,
              AddOn(
                id: uuid.v4(),
                name: n,
                price: double.tryParse(aoPriceCtrl.text.trim()) ?? 0,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
