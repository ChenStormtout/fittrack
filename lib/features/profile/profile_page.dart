import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import 'edit_profile_page.dart';
import 'saran_kesan_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  bool _isPickingImage = false;
  bool _isImageInitialized = false;

  String _profileImageKey(String? email) {
    final safeEmail = (email ?? 'guest').trim().toLowerCase();
    return 'fitlife_profile_image_$safeEmail';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isImageInitialized) return;
    _isImageInitialized = true;

    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final email = context.read<AuthController>().userEmail;
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_profileImageKey(email));

    if (!mounted) return;

    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        setState(() => _profileImage = file);
      }
    }
  }

  Future<void> _pickAndSaveProfileImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final email = context.read<AuthController>().userEmail;
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 900,
      );

      if (pickedFile == null) {
        if (mounted) setState(() => _isPickingImage = false);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();

      final safeEmail = (email ?? 'guest')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_');

      final savedImagePath =
          '${appDir.path}/fitlife_profile_$safeEmail.jpg';

      final savedImage = await File(pickedFile.path).copy(savedImagePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey(email), savedImage.path);

      if (!mounted) return;

      setState(() {
        _profileImage = savedImage;
        _isPickingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil disimpan'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _isPickingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih foto profil'),
        ),
      );
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AuthController authCtrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Keluar?',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: const Text(
          'Kamu yakin ingin logout dari FitLife? Foto profil dan data lokal tetap tersimpan di perangkat ini.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Ya, Logout',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      authCtrl.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    final name = (user?.fullName?.isNotEmpty ?? false)
        ? user!.fullName!
        : 'FitLife User';

    final email = authController.userEmail ?? '-';
    final goal = user?.goal ?? 'Belum diatur';
    final gender = user?.gender ?? '-';
    final activityLevel = user?.activityLevel ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.28),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: _isPickingImage ? null : _pickAndSaveProfileImage,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _isPickingImage
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(
                      icon: Icons.flag_rounded,
                      label: goal,
                    ),
                    _HeroChip(
                      icon: Icons.fitness_center_rounded,
                      label: activityLevel,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Berat',
                  value: user?.weightKg != null ? '${user!.weightKg} kg' : '-',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Tinggi',
                  value: user?.heightCm != null ? '${user!.heightCm} cm' : '-',
                  icon: Icons.height_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Umur',
                  value: user?.age?.toString() ?? '-',
                  icon: Icons.cake_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _SectionCard(
            title: 'Training Profile',
            icon: Icons.insights_rounded,
            child: Column(
              children: [
                _profileItem('Gender', gender),
                _profileItem('Goal', goal),
                _profileItem('Activity Level', activityLevel),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _SectionCard(
            title: 'Pengaturan Akun',
            icon: Icons.settings_rounded,
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profil',
                  subtitle: 'Perbarui data tubuh dan target latihan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Saran & Kesan TPM',
                  subtitle: 'Isi kesan dan pesan mata kuliah TPM',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SaranKesanPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.fingerprint_rounded,
                  title: authController.biometricEnabled
                      ? 'Biometric Aktif'
                      : 'Aktifkan Biometric',
                  subtitle: authController.biometricEnabled
                      ? 'Login biometric sudah siap digunakan'
                      : 'Login lebih cepat dengan autentikasi perangkat',
                  onTap: () async {
                    if (authController.biometricEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Biometric sudah aktif'),
                        ),
                      );
                      return;
                    }

                    final success = await authController.enableBiometric();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Biometric berhasil diaktifkan'
                              : 'Biometric gagal atau tidak tersedia',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Keluar dari akun saat ini',
                  onTap: () => _confirmLogout(context, authController),
                  danger: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lengkapi profil dengan benar agar rekomendasi nutrisi, target kalori, dan ringkasan harian menjadi lebih akurat.',
                    style: TextStyle(
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
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
                  width: 42,
                  height: 42,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bgColor = danger ? const Color(0xFFFFF3F2) : AppColors.softCard;
    final iconColor = danger ? AppColors.error : AppColors.primary;
    final titleColor = danger ? AppColors.error : AppColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: danger
                ? AppColors.error.withOpacity(0.12)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: danger
                  ? AppColors.error.withOpacity(0.65)
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}