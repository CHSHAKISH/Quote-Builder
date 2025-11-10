// lib/screens/quote_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client_info.dart';
import '../models/line_item.dart';
import '../models/quote_status.dart';

class QuotePreviewScreen extends StatelessWidget {
  final ClientInfo client;
  final List<LineItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final bool isTaxInclusive;
  final QuoteStatus status; // <-- NEW

  const QuotePreviewScreen({
    Key? key,
    required this.client,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.isTaxInclusive,
    required this.status, // <-- NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
    NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text("Quote Preview"),
        actions: [
          // --- NEW: Add status chip to AppBar ---
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: _buildStatusChip(status)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("QUOTE", style: Theme.of(context).textTheme.displaySmall),
            SizedBox(height: 24),

            Text("To:", style: Theme.of(context).textTheme.titleSmall),
            Text(client.name, style: Theme.of(context).textTheme.titleLarge),
            Text(client.address),
            if (client.reference.isNotEmpty) Text("Ref: ${client.reference}"),
            SizedBox(height: 16),

            Chip(
              label: Text(
                isTaxInclusive ? "Tax Inclusive" : "Tax Exclusive",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor:
              isTaxInclusive ? Colors.green : Colors.blueGrey,
            ),
            SizedBox(height: 32),

            _buildItemsTable(context, currencyFormat),
            SizedBox(height: 24),
            _buildTotals(context, currencyFormat),
          ],
        ),
      ),
    );
  }

  // --- NEW: Status Chip Widget (copied from form screen) ---
  Widget _buildStatusChip(QuoteStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case QuoteStatus.Draft:
        color = Colors.blueGrey;
        icon = Icons.edit;
        break;
      case QuoteStatus.Sent:
        color = Colors.blue;
        icon = Icons.send;
        break;
      case QuoteStatus.Accepted:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(status.name, style: TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildItemsTable(BuildContext context, NumberFormat currencyFormat) {
    // ... (no change in this function) ...
    final headerStyle = TextStyle(fontWeight: FontWeight.bold);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 3, child: Text("Item", style: headerStyle)),
            Expanded(
                flex: 1,
                child: Text("Qty", style: headerStyle, textAlign: TextAlign.right)),
            Expanded(
                flex: 2,
                child: Text("Rate", style: headerStyle, textAlign: TextAlign.right)),
            Expanded(
                flex: 2,
                child: Text("Total", style: headerStyle, textAlign: TextAlign.right)),
          ],
        ),
        Divider(thickness: 2),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 3, child: Text(item.name)),
                Expanded(
                    flex: 1,
                    child: Text(item.quantity.toString(),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 2,
                    child: Text(
                        currencyFormat.format(
                            item.getPreTaxRate(isTaxInclusive)),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 2,
                    child: Text(
                        currencyFormat.format(
                            item.total(isTaxInclusive: isTaxInclusive)),
                        textAlign: TextAlign.right)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotals(BuildContext context, NumberFormat currencyFormat) {
    // ... (no change in this function) ...
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _totalRow("Subtotal", currencyFormat.format(subtotal)),
            _totalRow("Tax", currencyFormat.format(tax)),
            Divider(thickness: 2),
            _totalRow("Grand Total", currencyFormat.format(total),
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String title, String amount, {bool isTotal = false}) {
    // ... (no change in this function) ...
    final style = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: style),
          Text(amount, style: style),
        ],
      ),
    );
  }
}