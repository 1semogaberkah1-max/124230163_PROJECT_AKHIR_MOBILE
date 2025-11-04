// File: lib/screens/profile_screen.dart

import 'dart:io'; // Untuk File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _fullNameController;
  String? _selectedTimezone;

  final List<String> _timezones = ['WIB', 'WITA', 'WIT', 'London', 'UTC'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final profile = await _userService.getOrCreateUserProfile(user);

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _selectedTimezone = profile?.defaultTz ?? 'WIB';

    setState(() {
      _userProfile = profile;
      _isLoading = false;
    });
  }

  // --- Fungsi Upload Foto ---
  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null || _userProfile == null) return;

    setState(() => _isSaving = true);
    final imageFile = File(pickedFile.path);

    // --- PERBAIKAN TYPO DI SINI ---
    // Pastikan nama method sudah benar (misal: uploadProfilePicture)
    final newPhotoUrl = await _userService.uploadProfilePicture(
      imageFile,
      _userProfile!.id,
    );
    // ----------------------------

    if (newPhotoUrl != null) {
      final updatedProfile = _userProfile!.copyWith(photoUrl: newPhotoUrl);
      await _userService.updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah foto.')),
      );
    }
    setState(() => _isSaving = false);
  }

  // --- Fungsi Simpan Perubahan (Nama & TZ) ---
  Future<void> _saveProfileChanges() async {
    if (_userProfile == null || _selectedTimezone == null) return;

    setState(() => _isSaving = true);

    final updatedProfile = _userProfile!.copyWith(
      fullName: _fullNameController.text.trim(),
      defaultTz: _selectedTimezone,
    );

    final success = await _userService.updateUserProfile(updatedProfile);

    if (mounted) {
      if (success) {
        setState(() {
          _userProfile = updatedProfile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil.')),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Gagal memuat profil.'))
              : _buildProfileForm(themeNotifier),
    );
  }

  Widget _buildProfileForm(ThemeNotifier themeNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Bagian Foto Profil ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.5),
                      backgroundImage: (_userProfile?.photoUrl != null)
                          ? CachedNetworkImageProvider(
                              _userProfile!.photoUrl!,
                            )
                          : null,
                      child: (_userProfile?.photoUrl == null)
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                          onPressed: _pickAndUploadImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- SAKLAR MODE TEMA ---
              Text(
                'Mode Tampilan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistem'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Terang'),
                    icon: Icon(Icons.brightness_5),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Gelap'),
                    icon: Icon(Icons.brightness_2),
                  ),
                ],
                selected: {themeNotifier.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  themeNotifier.setThemeMode(newSelection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.standard,
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 8.0)),
                ),
              ),
              const SizedBox(height: 24),
              // ------------------------------------

              // --- Email (Read-only) ---
              TextFormField(
                initialValue: _userProfile!.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // --- Nama Lengkap (Edit) ---
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // --- Zona Waktu (Edit) ---
              DropdownButtonFormField<String>(
                value: _selectedTimezone,
                decoration: const InputDecoration(
                  labelText: 'Zona Waktu Default',
                  prefixIcon: Icon(Icons.public),
                ),
                items: _timezones.map((String tz) {
                  return DropdownMenuItem<String>(
                    value: tz,
                    child: Text(tz),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTimezone = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // --- Tombol Simpan ---
              ElevatedButton.icon(
                onPressed: _saveProfileChanges,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Perubahan'),
              ),
              const SizedBox(height: 16),

              // --- Tombol Logout ---
              TextButton.icon(
                onPressed: () {
                  AuthService().signOutUser(context);
                },
                icon: Icon(Icons.logout,
                    color: Theme.of(context).colorScheme.error),
                label: Text(
                  'Logout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
          // --- Overlay Loading ---
          if (_isSaving)
            Container(
              // Latar belakang semi-transparan
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Text('Menyimpan...',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
