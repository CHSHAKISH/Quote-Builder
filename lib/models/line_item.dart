// lib/models/line_item.dart
class LineItem {
  String id;
  String name;
  double quantity;
  double rate;
  double discount; // Optional [cite: 15]
  double taxPercent;

  LineItem({
    required this.id,
    this.name = '',
    this.quantity = 1.0,
    this.rate = 0.0,
    this.discount = 0.0,
    this.taxPercent = 0.0,
  });

  // --- Per-item calculations ---

  /// (rate - discount) * quantity
  double get _baseTotal {
    return (rate - discount) * quantity;
  }

  /// tax amount
  double get _taxAmount {
    return _baseTotal * (taxPercent / 100);
  }

  /// Per-item total: ((rate - discount) * quantity) + tax
  double get total {
    return _baseTotal + _taxAmount;
  }
}