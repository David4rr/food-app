// lib/core/services/export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/transaction.dart';

class ExportService {
  static Future<void> exportTransactionsCsv(
    BuildContext context,
    List<Transaction> txns,
  ) async {
    final buf = StringBuffer();
    buf.writeln('Date,Customer,Payment,Items,Total');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    for (final txn in txns) {
      final items = txn.items
          .map((i) => '${i.quantity}x ${i.productName}')
          .join('; ');
      buf.writeln(
        '${dateFmt.format(txn.timestamp)},${txn.customerName.isEmpty ? 'Walk-in' : txn.customerName},${txn.paymentMethod},"$items",${txn.totalAmount}',
      );
    }

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/transactions_export.csv');
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await file.writeAsString(buf.toString());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Transaction Export',
      sharePositionOrigin: origin,
    );
  }

  static Future<void> exportReportPdf(
    BuildContext context,
    List<Transaction> txns,
  ) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy');
    final currencyFmt = NumberFormat('#,##0');
    final now = DateTime.now();

    final totalRevenue = txns.fold<double>(0, (s, t) => s + t.totalAmount);
    final totalOrders = txns.length;

    final topItems = <String, int>{};
    for (final txn in txns) {
      for (final item in txn.items) {
        topItems[item.productName] =
            (topItems[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = topItems.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Sales Report')),
          pw.Text('Generated: ${dateFmt.format(now)}'),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Total Orders: $totalOrders',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Total Revenue: Rp ${currencyFmt.format(totalRevenue)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Top Products',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...sorted
              .take(10)
              .map(
                (e) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '${e.value} sold',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...txns.map(
            (t) => pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${dateFmt.format(t.timestamp)} - ${t.customerName.isEmpty ? "Walk-in" : t.customerName}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Rp ${currencyFmt.format(t.totalAmount)}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/sales_report.pdf');
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Sales Report',
      sharePositionOrigin: origin,
    );
  }
}
