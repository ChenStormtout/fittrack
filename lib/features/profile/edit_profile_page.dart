import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/controllers/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'Male';
  String _goal = 'Maintain';
  String _activityLevel = 'Sedang';

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;
    _isInitialized = true;

    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _heightController.text = user.heightCm?.toString() ?? '';
      _weightController.text = user.weightKg?.toString() ?? '';
      _gender = user.gender ?? 'Male';
      _goal = user.goal ?? 'Maintain';
      _activityLevel = user.activityLevel ?? 'Sedang';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AuthController>().updateProfile(
          fullName: _fullNameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _gender,
          heightCm: double.parse(_heightController.text.trim()),
          weightKg: double.parse(_weightController.text.trim()),
          goal: _goal,
          activityLevel: _activityLevel,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profil berhasil disimpan' : 'Gagal menyimpan profil',
        ),
      ),
    );

    if (success) Navigator.pop(context);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Umur'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _gender = value!),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tinggi Badan (cm)'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Berat Badan (kg)'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _goal,
                items: const [
                  DropdownMenuItem(value: 'Cutting', child: Text('Cutting')),
                  DropdownMenuItem(value: 'Bulking', child: Text('Bulking')),
                  DropdownMenuItem(value: 'Maintain', child: Text('Maintain')),
                ],
                onChanged: (value) => setState(() => _goal = value!),
                decoration: const InputDecoration(labelText: 'Goal'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _activityLevel,
                items: const [
                  DropdownMenuItem(value: 'Rendah', child: Text('Rendah')),
                  DropdownMenuItem(value: 'Sedang', child: Text('Sedang')),
                  DropdownMenuItem(value: 'Tinggi', child: Text('Tinggi')),
                ],
                onChanged: (value) => setState(() => _activityLevel = value!),
                decoration: const InputDecoration(labelText: 'Activity Level'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}