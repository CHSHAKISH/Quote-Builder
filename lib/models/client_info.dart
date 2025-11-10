// lib/models/client_info.dart
class ClientInfo {
  String name;
  String address;
  String reference;

  ClientInfo({
    this.name = '',
    this.address = '',
    this.reference = '',
  });


  /// Converts this ClientInfo object into a JSON-compatible Map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'reference': reference,
    };
  }

  /// Creates a new ClientInfo instance from a JSON Map.
  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      name: json['name'] as String,
      address: json['address'] as String,
      reference: json['reference'] as String,
    );
  }
}