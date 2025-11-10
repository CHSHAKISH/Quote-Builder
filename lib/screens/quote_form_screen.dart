// lib/screens/quote_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../models/line_item.dart';
import '../models/quote_status.dart'; // <-- NEW: Import status
import 'quote_preview_screen.dart';

class QuoteFormScreen extends StatefulWidget {
  const QuoteFormScreen({super.key});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _referenceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _referenceCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().loadQuote();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showClearDialog(QuoteProvider quote) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Clear Quote?"),
          content: Text("This will clear all client info and line items. This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text("Clear", style: TextStyle(color: Colors.red)),
              onPressed: () {
                quote.clearQuote();
                Navigator.of(dialogContext).pop();
                _showSnackBar("Quote cleared");
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Confirmation for Sending Quote ---
  Future<void> _showSendDialog(QuoteProvider quote) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Send Quote?"),
          content: Text("This will mark the quote as 'Sent' and save it. You will no longer be able to save it as a draft."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text("Send"),
              onPressed: () {
                quote.sendQuote();
                Navigator.of(dialogContext).pop();
                _showSnackBar("Quote marked as Sent!");
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuoteProvider>(
      builder: (context, quote, child) {
        if (_nameCtrl.text != quote.clientInfo.name) {
          _nameCtrl.text = quote.clientInfo.name;
        }
        if (_addressCtrl.text != quote.clientInfo.address) {
          _addressCtrl.text = quote.clientInfo.address;
        }
        if (_referenceCtrl.text != quote.clientInfo.reference) {
          _referenceCtrl.text = quote.clientInfo.reference;
        }

        // --- NEW: Check if saving/sending is allowed ---
        bool canSaveDraft = quote.status == QuoteStatus.Draft;
        bool canSend = quote.status == QuoteStatus.Draft;

        return Scaffold(
          appBar: AppBar(
            title: Text("Product Quote Builder"),
            actions: [
              // --- MODIFIED: Save Draft Button ---
              IconButton(
                icon: Icon(Icons.save_as),
                tooltip: "Save Draft",
                // Disable button if not a draft
                onPressed: canSaveDraft ? () {
                  quote.saveQuote();
                  _showSnackBar("Draft Saved!");
                } : null,
              ),
              // --- NEW: Send Quote Button ---
              IconButton(
                icon: Icon(Icons.send),
                tooltip: "Send Quote",
                // Disable button if not a draft
                onPressed: canSend ? () {
                  _showSendDialog(quote);
                } : null,
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep),
                tooltip: "Clear Quote",
                onPressed: () {
                  _showClearDialog(quote);
                },
              ),
              IconButton(
                icon: Icon(Icons.remove_red_eye),
                tooltip: "Preview",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuotePreviewScreen(
                        client: quote.clientInfo,
                        items: quote.lineItems,
                        subtotal: quote.subtotal,
                        tax: quote.totalTax,
                        total: quote.grandTotal,
                        isTaxInclusive: quote.isTaxInclusive,
                        status: quote.status, // <-- NEW: Pass status
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientInfo(context, quote),

                // --- NEW: Status Indicator ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: _buildStatusChip(quote.status),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0), // Reduced margin
                  child: SwitchListTile(
                    title: Text("Tax Inclusive Mode"),
                    subtitle: Text(
                        "If ON, the 'Rate' field already includes tax."),
                    value: quote.isTaxInclusive,
                    onChanged: (bool val) {
                      quote.setTaxMode(val);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),

                Text("Line Items",
                    style: Theme.of(context).textTheme.headlineSmall),
                _buildLineItems(context, quote, canSaveDraft), // <-- Pass edit flag
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("Add Item"),
                    // --- NEW: Disable adding items if not a draft
                    onPressed: canSaveDraft ? () {
                      quote.addItem();
                    } : null,
                  ),
                ),
                Divider(height: 48),
                _buildTotals(context, quote),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NEW: Status Chip Widget ---
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

  Widget _buildClientInfo(BuildContext context, QuoteProvider quote) {
    // --- NEW: Disable editing if not a draft ---
    bool isEditable = quote.status == QuoteStatus.Draft;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Client Information",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              enabled: isEditable, // <-- NEW
              decoration: InputDecoration(
                  labelText: "Client Name", border: OutlineInputBorder()),
              onChanged: (value) => quote.updateClientInfo(name: value),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              enabled: isEditable, // <-- NEW
              decoration: InputDecoration(
                  labelText: "Address", border: OutlineInputBorder()),
              onChanged: (value) => quote.updateClientInfo(address: value),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _referenceCtrl,
              enabled: isEditable, // <-- NEW
              decoration: InputDecoration(
                  labelText: "Reference #", border: OutlineInputBorder()),
              onChanged: (value) => quote.updateClientInfo(reference: value),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED: Pass 'isEditable' flag ---
  Widget _buildLineItems(BuildContext context, QuoteProvider quote, bool isEditable) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: quote.lineItems.length,
      itemBuilder: (context, index) {
        final item = quote.lineItems[index];
        return LineItemRow(
          key: ValueKey(item.id),
          item: item,
          provider: quote,
          isEditable: isEditable, // <-- NEW
        );
      },
    );
  }

  Widget _buildTotals(BuildContext context, QuoteProvider quote) {
    // ... (no change) ...
    final currencyFormat =
    NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _totalRow("Subtotal", currencyFormat.format(quote.subtotal)),
            _totalRow("Tax", currencyFormat.format(quote.totalTax)),
            Divider(thickness: 2),
            _totalRow("Grand Total", currencyFormat.format(quote.grandTotal),
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String title, String amount, {bool isTotal = false}) {
    // ... (no change) ...
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

// --- MODIFIED: LineItemRow ---
class LineItemRow extends StatefulWidget {
  final LineItem item;
  final QuoteProvider provider;
  final bool isEditable; // <-- NEW

  const LineItemRow({
    Key? key,
    required this.item,
    required this.provider,
    required this.isEditable, // <-- NEW
  }) : super(key: key);

  @override
  _LineItemRowState createState() => _LineItemRowState();
}

class _LineItemRowState extends State<LineItemRow> {
  // ... (no changes to controllers or initState/dispose) ...
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _discCtrl;
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _rateCtrl = TextEditingController(text: widget.item.rate.toString());
    _discCtrl = TextEditingController(text: widget.item.discount.toString());
    _taxCtrl = TextEditingController(text: widget.item.taxPercent.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _updateProvider() {
    // ... (no change) ...
    widget.provider.updateItem(
      widget.item.id,
      name: _nameCtrl.text,
      qty: double.tryParse(_qtyCtrl.text) ?? 0.0,
      rate: double.tryParse(_rateCtrl.text) ?? 0.0,
      disc: double.tryParse(_discCtrl.text) ?? 0.0,
      tax: double.tryParse(_taxCtrl.text) ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    enabled: widget.isEditable, // <-- NEW
                    decoration: InputDecoration(labelText: "Product/Service"),
                    onChanged: (val) => _updateProvider(),
                  ),
                ),
                // --- MODIFIED: Hide delete button if not editable ---
                if (widget.isEditable)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.provider.removeItem(widget.item.id),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              runSpacing: 12.0,
              spacing: 12.0,
              children: [
                _buildTextField(
                  controller: _qtyCtrl,
                  label: "Qty",
                  width: 80,
                  isEditable: widget.isEditable, // <-- NEW
                ),
                _buildTextField(
                  controller: _rateCtrl,
                  label: "Rate",
                  width: 120,
                  isEditable: widget.isEditable, // <-- NEW
                ),
                _buildTextField(
                  controller: _discCtrl,
                  label: "Discount",
                  width: 120,
                  isEditable: widget.isEditable, // <-- NEW
                ),
                _buildTextField(
                  controller: _taxCtrl,
                  label: "Tax %",
                  width: 80,
                  isEditable: widget.isEditable, // <-- NEW
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED: Add isEditable flag ---
  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        double width = 100,
        required bool isEditable, // <-- NEW
      }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        enabled: isEditable, // <-- NEW
        decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10)),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) => _updateProvider(),
      ),
    );
  }
}