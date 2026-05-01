import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Order Status ──────────────────────────────────────────────
enum OrderStatus { packed, shipped, delivered }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.packed:
        return 'Dikemas';
      case OrderStatus.shipped:
        return 'Dikirim';
      case OrderStatus.delivered:
        return 'Diterima';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.packed:
        return Icons.inventory_2_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.packed:
        return const Color(0xFFF9A825);
      case OrderStatus.shipped:
        return const Color(0xFF2196F3);
      case OrderStatus.delivered:
        return const Color(0xFF4CAF50);
    }
  }

  Color get bgColor {
    switch (this) {
      case OrderStatus.packed:
        return const Color(0xFFFFF8E1);
      case OrderStatus.shipped:
        return const Color(0xFFE3F2FD);
      case OrderStatus.delivered:
        return const Color(0xFFE8F5E9);
    }
  }
}

// ── Order Model ───────────────────────────────────────────────
class OrderHistoryItem {
  final String orderId;
  final List<String> productNames;
  final int totalItems;
  final double totalPrice;
  final DateTime orderDate;
  final OrderStatus status;
  final List<String> productImageUrls;
  final String paymentMethod;
  final String recipientName;
  final String deliveryAddress;

  const OrderHistoryItem({
    required this.orderId,
    required this.productNames,
    required this.totalItems,
    required this.totalPrice,
    required this.orderDate,
    required this.status,
    this.productImageUrls = const [],
    this.paymentMethod = '-',
    this.recipientName = '',
    this.deliveryAddress = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'productNames': productNames,
      'productImageUrls': productImageUrls,
      'totalItems': totalItems,
      'totalPrice': totalPrice,
      'orderDate': orderDate.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'recipientName': recipientName,
      'deliveryAddress': deliveryAddress,
    };
  }

  factory OrderHistoryItem.fromMap(Map<String, dynamic> map) {
    return OrderHistoryItem(
      orderId: map['orderId'] as String,
      productNames: (map['productNames'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      productImageUrls: (map['productImageUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      totalItems: map['totalItems'] as int,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      orderDate:
          DateTime.tryParse(map['orderDate'] as String? ?? '') ??
          DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => OrderStatus.packed,
      ),
      paymentMethod: map['paymentMethod'] as String? ?? '-',
      recipientName: map['recipientName'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
    );
  }
}

// ── Global Store ──────────────────────────────────────────────
class OrderHistoryStore {
  static final OrderHistoryStore instance = OrderHistoryStore._();
  OrderHistoryStore._();

  static const _storageKey = 'order_history_items';

  final List<OrderHistoryItem> _orders = [];

  List<OrderHistoryItem> get orders => List.unmodifiable(_orders);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _orders
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
            (item) => OrderHistoryItem.fromMap(Map<String, dynamic>.from(item)),
          ),
        );
    } catch (_) {
      _orders.clear();
    }
  }

  Future<void> addOrder(OrderHistoryItem order) async {
    _orders.insert(0, order);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_orders.map((order) => order.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static String generateId() {
    final now = DateTime.now();
    return 'FT${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }
}
