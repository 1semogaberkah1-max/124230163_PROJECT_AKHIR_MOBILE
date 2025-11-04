// File: lib/screens/ai_settings_screen.dart

import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

class AiSettingsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AiSettingsScreen({super.key, required this.userProfile});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final UserService _userService = UserService();

  // Semua kategori yang tersedia (DEFAULT)
  final List<String> _defaultCategories = [
    'Reminder Belajar',
    'Saran Materi',
    'Fakta Menarik',
    'Tips Belajar'
  ];

  // Kategori yang sedang aktif (diambil dari profil)
  late List<String> _activeCategories;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi dengan preferensi user saat ini
    _activeCategories = List.from(widget.userProfile.aiReminderPrefs);

    // Hapus duplikasi jika ada (untuk keamanan)
    _activeCategories = _activeCategories.toSet().toList();
  }

  // Handle perubahan checkbox
  void _toggleCategory(String category, bool isChecked) {
    setState(() {
      if (isChecked && !_activeCategories.contains(category)) {
        _activeCategories.add(category);
      } else if (!isChecked && _activeCategories.contains(category)) {
        _activeCategories.remove(category);
      }
    });
  }

  // Fungsi Tambah Kategori Kustom
  Future<void> _addCustomCategory() async {
    TextEditingController controller = TextEditingController();

    final String? newCategory = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori Kustom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Misal: Tips Produktivitas Coding',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                // Pastikan nama kategori tidak terlalu panjang
                final categoryName =
                    text.length > 50 ? '${text.substring(0, 50)}...' : text;
                Navigator.pop(context, categoryName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      // Cek duplikasi (case-insensitive)
      if (_activeCategories
          .map((e) => e.toLowerCase())
          .contains(newCategory.toLowerCase())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori ini sudah ada.')),
          );
        }
        return;
      }
      // Tambahkan kategori baru ke list aktif dan set default checked
      _toggleCategory(newCategory, true);
    }
  }

  // Fungsi Hapus Kategori Kustom
  void _removeCustomCategory(String category) {
    setState(() {
      _activeCategories.remove(category);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori "$category" dihapus dari daftar.')),
      );
    }
  }

  // Handle simpan
  Future<void> _saveSettings() async {
    if (_activeCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus memilih setidaknya satu kategori.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Simpan hanya kategori yang aktif
    final success = await _userService.updateAiReminderPrefs(
      userId: widget.userProfile.id,
      prefs: _activeCategories,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        // Pop dan kirim sinyal 'perubahan' (true) kembali ke home screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferensi AI berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kirim sinyal perubahan ke HomeScreen
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan preferensi. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget Kustom untuk Kategori
  Widget _buildCategoryList() {
    // Gabungkan default categories dan custom categories yang aktif
    final List<String> allUniqueCategories =
        _defaultCategories.toSet().toList();

    // Tambahkan custom categories yang saat ini aktif
    for (var cat in _activeCategories) {
      if (!_defaultCategories.contains(cat)) {
        allUniqueCategories.add(cat);
      }
    }

    return ListView(
      // Padding untuk menghindari tumpang tindih dengan tombol simpan
      padding: const EdgeInsets.only(bottom: 20),
      children: allUniqueCategories.map((category) {
        final isDefault = _defaultCategories.contains(category);
        final isActive = _activeCategories.contains(category);
        final colors = Theme.of(context).colorScheme;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: Checkbox(
            value: isActive,
            onChanged: (bool? isChecked) {
              if (isChecked != null) {
                _toggleCategory(category, isChecked);
              }
            },
            activeColor: colors.primary,
          ),
          title: Text(category),
          trailing: isDefault
              ? null // Tidak ada tombol hapus untuk default
              : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeCustomCategory(category),
                ),
          // Tambahkan indikator visual untuk kategori custom
          subtitle: !isDefault
              ? const Text('Kustom',
                  style: TextStyle(color: Colors.grey, fontSize: 12))
              : null,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Pengingat AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih kategori pesan AI harian (centang untuk aktif, kustom bisa ditambahkan):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Tombol Tambah Kustom
            OutlinedButton.icon(
              onPressed: _addCustomCategory,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah Kategori Kustom'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Daftar Kategori
            Expanded(
              child: _buildCategoryList(),
            ),

            // Tombol Simpan
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pengaturan'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
