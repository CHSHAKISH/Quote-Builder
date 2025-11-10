// lib/providers/quote_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/client_info.dart';
import '../models/line_item.dart';
import '../models/quote_status.dart'; // <-- NEW: Import our status model

class QuoteProvider with ChangeNotifier {
  ClientInfo clientInfo = ClientInfo();
  List<LineItem> lineItems = [];
  bool isTaxInclusive = false;
  QuoteStatus status = QuoteStatus.Draft; // <-- NEW: The status field

  final _uuid = Uuid();
  static const _saveKey = 'currentQuote';

  // --- Client Info Methods (No change) ---
  void updateClientInfo({String? name, String? address, String? reference}) {

    clientInfo.name = name ?? clientInfo.name;
    clientInfo.address = address ?? clientInfo.address;
    clientInfo.reference = reference ?? clientInfo.reference;
    notifyListeners();
  }

  // --- Line Item Methods (No change) ---
  void addItem() {

    lineItems.add(LineItem(id: _uuid.v4()));
    notifyListeners();
  }

  void removeItem(String id) {

    lineItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateItem(String id,
      {String? name,
        double? qty,
        double? rate,
        double? disc,
        double? tax}) {

    final index = lineItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = lineItems[index];
      item.name = name ?? item.name;
      item.quantity = qty ?? item.quantity;
      item.rate = rate ?? item.rate;
      item.discount = disc ?? item.discount;
      item.taxPercent = tax ?? item.taxPercent;
      notifyListeners();
    }
  }

  // --- Tax Mode Method (No change) ---
  void setTaxMode(bool isInclusive) {
    // ... (no change) ...
    isTaxInclusive = isInclusive;
    notifyListeners();
  }


  /// Sets the quote status
  void setStatus(QuoteStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }

  /// Simulates sending the quote
  void sendQuote() {
    // This is the "Simulate Send Action"
    // In a real app, this would also email or API call
    if (status == QuoteStatus.Draft) {
      status = QuoteStatus.Sent;
      saveQuote(); // Auto-save when sent
      notifyListeners();
    }
  }

  // --- Auto-Calculation Getters (No change) ---
  double get subtotal {
    // ... (no change) ...
    return lineItems.fold(
        0.0,
            (prev, item) =>
        prev + item.baseTotal(isTaxInclusive: isTaxInclusive));
  }

  double get totalTax {
    // ... (no change) ...
    return lineItems.fold(
        0.0,
            (prev, item) =>
        prev + item.taxAmount(isTaxInclusive: isTaxInclusive));
  }

  double get grandTotal {
    // ... (no change) ...
    return lineItems.fold(
        0.0,
            (prev, item) => prev + item.total(isTaxInclusive: isTaxInclusive));
  }

  // --- Save, Load, and Clear Methods (MODIFIED) ---

  Future<void> saveQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final quoteData = {
      'clientInfo': clientInfo.toJson(),
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'isTaxInclusive': isTaxInclusive,
      'status': status.name, // <-- NEW: Save the status as a string
    };
    final quoteString = jsonEncode(quoteData);
    await prefs.setString(_saveKey, quoteString);
    notifyListeners();
  }

  Future<void> loadQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final quoteString = prefs.getString(_saveKey);
    if (quoteString == null) {
      return;
    }

    final quoteData = jsonDecode(quoteString) as Map<String, dynamic>;

    clientInfo = ClientInfo.fromJson(quoteData['clientInfo']);
    final itemsList = quoteData['itemsList'] as List?; // Make nullable
    lineItems = itemsList?.map((item) => LineItem.fromJson(item)).toList() ?? []; // Handle null
    isTaxInclusive = quoteData['isTaxInclusive'] ?? false;
    status = statusFromName(quoteData['status'] ?? 'Draft'); // <-- NEW: Load status

    notifyListeners();
  }

  Future<void> clearQuote() async {
    final prefs = await SharedPreferences.getInstance();
    clientInfo = ClientInfo();
    lineItems = [];
    isTaxInclusive = false;
    status = QuoteStatus.Draft; // <-- NEW: Reset the status
    await prefs.remove(_saveKey);
    notifyListeners();
  }
}