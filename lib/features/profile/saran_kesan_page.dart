import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';

class SaranKesanPage extends StatefulWidget {
  const SaranKesanPage({super.key});

  @override
  State<SaranKesanPage> createState() => _SaranKesanPageState();
}

class _SaranKesanPageState extends State<SaranKesanPage> {
  final _formKey = GlobalKey<FormState>();
  final _kesanController = TextEditingController();
  final _saranController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  String _storageKey(String? email) {
    final safeEmail = (email ?? 'guest').trim().toLowerCase();
    return 'fitlife_tpm_feedback_$safeEmail';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;
    _isInitialized = true;

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final email = context.read<AuthController>().userEmail;
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(email);

    if (!mounted) return;

    _kesanController.text = prefs.getString('${key}_kesan') ?? '';
    _saranController.text = prefs.getString('${key}_saran') ?? '';

    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final email = context.read<AuthController>().userEmail;
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(email);

    await prefs.setString('${key}_kesan', _kesanController.text.trim());
    await prefs.setString('${key}_saran', _saranController.text.trim());

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saran dan kesan berhasil disimpan'),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bagian ini wajib diisi';
    }
    return null;
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthController>().userEmail ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saran & Kesan TPM'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.20),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Kesan & Pesan Mata Kuliah TPM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tuliskan pengalaman, kesan, dan saran kamu selama mengikuti mata kuliah Teknologi dan Pemrograman Mobile.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _PremiumInputCard(
                    icon: Icons.favorite_rounded,
                    title: 'Kesan',
                    subtitle: 'Ceritakan pengalaman kamu selama mengikuti TPM.',
                    child: TextFormField(
                      controller: _kesanController,
                      maxLines: 6,
                      validator: _required,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Mata kuliah TPM memberikan pengalaman baru dalam membuat aplikasi mobile secara langsung...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _PremiumInputCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'Pesan / Saran',
                    subtitle:
                        'Tuliskan masukan agar pembelajaran TPM semakin baik.',
                    child: TextFormField(
                      controller: _saranController,
                      maxLines: 6,
                      validator: _required,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Semoga pembelajaran ke depan lebih banyak praktik, studi kasus, dan pembahasan error secara langsung...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveData,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Saran & Kesan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data saran dan kesan disimpan di perangkat berdasarkan akun yang sedang login.',
                            style: TextStyle(
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PremiumInputCard extends StatelessWidget {
  const _PremiumInputCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.softCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}