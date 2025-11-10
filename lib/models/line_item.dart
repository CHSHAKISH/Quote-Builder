// lib/models/line_item.dart
class LineItem {
  String id;
  String name;
  double quantity;
  double rate;
  double discount;
  double taxPercent;

  LineItem({
    required this.id,
    this.name = '',
    this.quantity = 1.0,
    this.rate = 0.0,
    this.discount = 0.0,
    this.taxPercent = 0.0,
  });


  /// Calculates the pre-tax, pre-discount, per-item rate.
  double getPreTaxRate(bool isTaxInclusive) {
    if (isTaxInclusive) {

      return rate / (1 + (taxPercent / 100));
    } else {
      // If exclusive, the rate is the pre-tax rate.
      return rate;
    }
  }

  /// (Pre-Tax Rate - Discount) * Quantity
  double baseTotal({required bool isTaxInclusive}) {
    final preTaxRate = getPreTaxRate(isTaxInclusive);
    return (preTaxRate - discount) * quantity;
  }

  /// Tax Amount
  double taxAmount({required bool isTaxInclusive}) {
    // Tax is always calculated from the base total
    return baseTotal(isTaxInclusive: isTaxInclusive) * (taxPercent / 100);
  }

  /// Final total for the line item
  double total({required bool isTaxInclusive}) {
    return baseTotal(isTaxInclusive: isTaxInclusive) +
        taxAmount(isTaxInclusive: isTaxInclusive);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'rate': rate,
      'discount': discount,
      'taxPercent': taxPercent,
    };
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      taxPercent: (json['taxPercent'] as num).toDouble(),
    );
  }
}