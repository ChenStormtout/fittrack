import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddressModel {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final String? note;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    this.note,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'recipientName': recipientName,
        'phone': phone,
        'fullAddress': fullAddress,
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        recipientName: json['recipientName']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        fullAddress: json['fullAddress']?.toString() ?? '',
        note: json['note']?.toString(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['isDefault'] == true,
      );

  AddressModel copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phone,
    String? fullAddress,
    String? note,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      AddressModel(
        id: id ?? this.id,
        label: label ?? this.label,
        recipientName: recipientName ?? this.recipientName,
        phone: phone ?? this.phone,
        fullAddress: fullAddress ?? this.fullAddress,
        note: note ?? this.note,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isDefault: isDefault ?? this.isDefault,
      );
}

class AddressStore {
  AddressStore._();
  static final AddressStore instance = AddressStore._();

  static String _key(String email) => 'fitlife_addresses_$email';

  final Map<String, List<AddressModel>> _cache = {};

  Future<List<AddressModel>> loadAddresses(String email) async {
    if (_cache.containsKey(email)) return List.from(_cache[email]!);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(email));
    if (raw == null || raw.isEmpty) {
      _cache[email] = [];
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List;
      final list = decoded
          .whereType<Map>()
          .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _cache[email] = list;
      return List.from(list);
    } catch (_) {
      _cache[email] = [];
      return [];
    }
  }

  Future<void> _save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache[email] ?? [];
    await prefs.setString(
        _key(email), jsonEncode(list.map((a) => a.toJson()).toList()));
  }

  Future<void> addAddress(String email, AddressModel address) async {
    final list = await loadAddresses(email);
    if (address.isDefault || list.isEmpty) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    final addr = list.isEmpty ? address.copyWith(isDefault: true) : address;
    list.add(addr);
    _cache[email] = list;
    await _save(email);
  }

  Future<void> updateAddress(String email, AddressModel address) async {
    final list = await loadAddresses(email);
    final idx = list.indexWhere((a) => a.id == address.id);
    if (idx < 0) return;
    if (address.isDefault) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list[idx] = address;
    _cache[email] = list;
    await _save(email);
  }

  Future<void> deleteAddress(String email, String addressId) async {
    final list = await loadAddresses(email);
    list.removeWhere((a) => a.id == addressId);
    if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    _cache[email] = list;
    await _save(email);
  }

  Future<void> setDefault(String email, String addressId) async {
    final list = await loadAddresses(email);
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == addressId);
    }
    _cache[email] = list;
    await _save(email);
  }

  void clearCache() => _cache.clear();
}
