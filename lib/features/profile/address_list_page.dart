import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/address_model.dart';
import '../auth/controllers/auth_controller.dart';

class AddressController extends GetxController {
  AddressController({required this.email});

  final String email;
  final addresses = <AddressModel>[].obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final list = await AddressStore.instance.loadAddresses(email);
    addresses.assignAll(list);
    loading.value = false;
  }

  Future<void> refreshAfterFormSave() async {
    AddressStore.instance.clearCache();
    await load();
  }

  Future<void> deleteAddress(String id) async {
    await AddressStore.instance.deleteAddress(email, id);
    await load();
  }

  Future<void> setDefault(String id) async {
    await AddressStore.instance.setDefault(email, id);
    await load();
  }
}

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  late final AddressController _addressController;
  late final String _controllerTag;

  String get _email =>
      context.read<AuthController>().userEmail ?? 'guest';

  @override
  void initState() {
    super.initState();
    _controllerTag = 'addresses_${_email.trim().toLowerCase()}';
    _addressController = Get.put(
      AddressController(email: _email),
      tag: _controllerTag,
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Alamat?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text('Alamat ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    await _addressController.deleteAddress(id);
  }

  Future<void> _setDefault(String id) async {
    await _addressController.setDefault(id);
  }

  void _openForm({AddressModel? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddressFormPage(
          email: _email,
          existing: existing,
        ),
      ),
    );
    if (result == true) {
      await _addressController.refreshAfterFormSave();
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AddressController>(tag: _controllerTag)) {
      Get.delete<AddressController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Alamat'),
        centerTitle: false,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded, size: 20),
        label: const Text('Tambah Alamat',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Obx(() {
        if (_addressController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final addresses = _addressController.addresses;
        if (addresses.isEmpty) return _emptyState();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _addressCard(addresses[i]),
        );
      }),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.softAccent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.location_off_rounded,
                  size: 40, color: AppColors.sage),
            ),
            const SizedBox(height: 20),
            const Text('Belum ada alamat tersimpan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Tambahkan alamat agar checkout lebih cepat',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _addressCard(AddressModel addr) {
    final isDefault = addr.isDefault;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: isDefault ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDefault
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.softCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _labelIcon(addr.label),
                    color:
                        isDefault ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(addr.label,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Utama',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(addr.recipientName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  iconSize: 20,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') _openForm(existing: addr);
                    if (val == 'default') _setDefault(addr.id);
                    if (val == 'delete') _delete(addr.id);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 13)),
                        ])),
                    if (!isDefault)
                      const PopupMenuItem(
                          value: 'default',
                          child: Row(children: [
                            Icon(Icons.star_outline_rounded,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Jadikan Utama',
                                style: TextStyle(fontSize: 13)),
                          ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Hapus',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.error)),
                        ])),
                  ],
                ),
              ],
            ),
          ),
          // Address body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(addr.phone,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(addr.fullAddress,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4)),
                    ),
                  ],
                ),
                if (addr.note != null && addr.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.note_outlined,
                            size: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(addr.note!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _labelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'rumah':
        return Icons.home_rounded;
      case 'kantor':
        return Icons.business_rounded;
      case 'kos':
        return Icons.apartment_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}

// ============================================================
// ADDRESS FORM PAGE
// ============================================================
class _AddressFormPage extends StatefulWidget {
  final String email;
  final AddressModel? existing;

  const _AddressFormPage({required this.email, this.existing});

  @override
  State<_AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<_AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _noteCtrl;
  final MapController _mapCtrl = MapController();

  String _label = 'Rumah';
  bool _isDefault = false;
  bool _saving = false;
  bool _gpsLoading = false;
  bool _geocoding = false;
  ll.LatLng _pinLatLng = const ll.LatLng(-7.7956, 110.3695);

  bool get _isEdit => widget.existing != null;

  static const _labels = ['Rumah', 'Kantor', 'Kos', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.recipientName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressCtrl = TextEditingController(text: e?.fullAddress ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _label = e.label;
      _isDefault = e.isDefault;
      if (e.latitude != null && e.longitude != null) {
        _pinLatLng = ll.LatLng(e.latitude!, e.longitude!);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final addr = AddressModel(
      id: _isEdit
          ? widget.existing!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      label: _label,
      recipientName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      fullAddress: _addressCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      latitude: _pinLatLng.latitude,
      longitude: _pinLatLng.longitude,
      isDefault: _isDefault,
    );

    if (_isEdit) {
      await AddressStore.instance.updateAddress(widget.email, addr);
    } else {
      await AddressStore.instance.addAddress(widget.email, addr);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
    if (v.trim().length < 10) return 'Minimal 10 digit';
    return null;
  }

  Future<void> _goToMyLocation() async {
    setState(() => _gpsLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS belum aktif.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi diblokir permanen.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final picked = ll.LatLng(position.latitude, position.longitude);
      _mapCtrl.move(picked, 17);
      setState(() => _pinLatLng = picked);
      await _reverseGeocode(picked);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _reverseGeocode(ll.LatLng latLng) async {
    setState(() => _geocoding = true);
    try {
      final address = await _nominatimReverse(latLng.latitude, latLng.longitude);
      if (mounted) setState(() => _addressCtrl.text = address);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressCtrl.text =
            'Lat: ${latLng.latitude.toStringAsFixed(6)}, Lng: ${latLng.longitude.toStringAsFixed(6)}';
      });
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<String> _nominatimReverse(double lat, double lng) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=id',
    );
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'FitLifeApp/1.0'},
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Gagal membaca alamat dari peta.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawAddress = data['address'] as Map<String, dynamic>?;
    if (rawAddress == null) {
      return data['display_name']?.toString() ?? '';
    }

    final seen = <String>{};
    final parts = <String>[];
    void add(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return;
      if (seen.add(text.toLowerCase())) parts.add(text);
    }

    add(rawAddress['road']);
    add(rawAddress['neighbourhood']);
    add(rawAddress['suburb']);
    add(rawAddress['village']);
    add(rawAddress['town'] ?? rawAddress['city']);
    add(rawAddress['county']);
    add(rawAddress['state']);
    add(rawAddress['postcode']);

    return parts.isEmpty ? data['display_name']?.toString() ?? '' : parts.join(', ');
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Alamat' : 'Tambah Alamat'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label selector
              const Text('Label Alamat',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _labels.map((l) {
                  final active = _label == l;
                  return GestureDetector(
                    onTap: () => setState(() => _label = l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.softCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border,
                            width: active ? 1.5 : 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            l == 'Rumah'
                                ? Icons.home_rounded
                                : l == 'Kantor'
                                    ? Icons.business_rounded
                                    : l == 'Kos'
                                        ? Icons.apartment_rounded
                                        : Icons.location_on_rounded,
                            size: 16,
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(l,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              _field('Nama Penerima', _nameCtrl, Icons.person_outline,
                  validator: _required),
              const SizedBox(height: 12),
              _field('Nomor HP', _phoneCtrl, Icons.phone_outlined,
                  type: TextInputType.phone, validator: _phoneValidator),
              const SizedBox(height: 12),
              _mapPicker(),
              const SizedBox(height: 12),
              _field('Alamat Lengkap', _addressCtrl, Icons.location_on_outlined,
                  maxLines: 3, validator: _required),
              const SizedBox(height: 12),
              _field('Catatan untuk kurir (opsional)', _noteCtrl,
                  Icons.note_outlined),

              const SizedBox(height: 16),

              // Default toggle
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jadikan Alamat Utama',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Alamat ini akan dipilih otomatis saat checkout',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Alamat',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: AppColors.softCard,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.border, width: .8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.2)),
        ),
      );

  Widget _mapPicker() => Container(
        height: 230,
        decoration: BoxDecoration(
          color: AppColors.softCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _pinLatLng,
                  initialZoom: 15,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() => _pinLatLng = position.center);
                    }
                  },
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) {
                      _reverseGeocode(_pinLatLng);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fitlife.app',
                  ),
                ],
              ),
              const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 42,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Geser peta atau gunakan lokasi saat ini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (_geocoding)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black45,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mencari alamat...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'profile_address_gps',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _gpsLoading ? null : _goToMyLocation,
                  child: _gpsLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
}
