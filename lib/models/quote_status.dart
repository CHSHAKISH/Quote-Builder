// lib/models/quote_status.dart

enum QuoteStatus {
  Draft,
  Sent,
  Accepted,
}
extension QuoteStatusExtension on QuoteStatus {
  /// Converts enum to a string
  String get name {
    switch (this) {
      case QuoteStatus.Draft:
        return 'Draft';
      case QuoteStatus.Sent:
        return 'Sent';
      case QuoteStatus.Accepted:
        return 'Accepted';
    }
  }
}

/// Converts a string back to an enum
QuoteStatus statusFromName(String name) {
  return QuoteStatus.values.firstWhere(
        (status) => status.name == name,
    orElse: () => QuoteStatus.Draft,
  );
}