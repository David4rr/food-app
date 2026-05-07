// lib/core/services/print_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transaction.dart';

class PrintService {
  static Future<void> printReceipt(Transaction txn) async {
    final pdf = await _buildReceiptPdf(txn);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static Future<void> printReceiptBluetooth(Transaction txn) async {
    final pdf = await _buildReceiptPdf(txn);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt_${txn.id.substring(0, 8)}.pdf',
    );
  }

  static Future<void> shareReceipt(
    BuildContext context,
    Transaction txn,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final pdf = await _buildReceiptPdf(txn);
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/receipt_${txn.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Receipt #${txn.id.substring(0, 8)}',
      sharePositionOrigin: origin,
    );
  }

  static Future<pw.Document> _buildReceiptPdf(Transaction txn) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy  HH:mm');
    final currencyFmt = NumberFormat('#,##0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 8),
              pw.Text(
                'DAPURKU',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Homemade Food', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              pw.Text(
                'Order #${txn.id.substring(0, 8)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                dateFmt.format(txn.timestamp),
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (txn.customerName.isNotEmpty)
                pw.Text(
                  txn.customerName,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.Text(
                'Payment: ${txn.paymentMethod.toUpperCase()}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
              ...txn.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.productName}\n${item.quantity}x @ ${currencyFmt.format(item.price)}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Text(
                        'Rp ${currencyFmt.format(item.price * item.quantity)}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rp ${currencyFmt.format(txn.totalAmount)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Thank you!', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
