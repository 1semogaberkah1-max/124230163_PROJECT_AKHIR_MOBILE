import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/learning_log_model.dart';
import '../models/user_profile_model.dart';
import '../services/log_service.dart';
import '../services/user_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ManualLogScreen extends StatefulWidget {
  const ManualLogScreen({super.key});

  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final LogService _logService = LogService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _costController =
      TextEditingController(text: '0');
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  UserProfile? _currentUserProfile;
  bool _isLoadingProfile = true;
  bool _isUploading = false;
  File? _selectedImage;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _materialController.dispose();
    _durationController.dispose();
    _costController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    final profile = await _userService.getOrCreateUserProfile(user);
    setState(() {
      _currentUserProfile = profile;
      _isLoadingProfile = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Layanan lokasi nonaktif. Mohon aktifkan GPS.')));
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Izin lokasi ditolak permanen, aktifkan di setelan HP.')));
      }
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() => _isFetchingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10));

      if (kIsWeb) {
        _locationController.text =
            "Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      } else {
        await setLocaleIdentifier('id_ID');

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          final addressParts = [
            place.street,
            place.subLocality,
            place.locality
          ];
          final address = addressParts
              .where((part) => part != null && part.isNotEmpty)
              .join(', ');
          _locationController.text = address;
        } else {
          _locationController.text = "Gagal mendapatkan nama alamat";
        }
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi: $e');
      _locationController.text = 'Error: ${e.toString()}';
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate() || _currentUserProfile == null) {
      return;
    }

    setState(() => _isUploading = true);

    String? photoUrl;

    if (_selectedImage != null) {
      photoUrl = await _logService.uploadImageToStorage(
        _selectedImage!,
        _currentUserProfile!.id,
      );
      if (photoUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah foto.')),
          );
        }
        setState(() => _isUploading = false);
        return;
      }
    }

    final newLog = LearningLog(
      id: '',
      userId: _currentUserProfile!.id,
      material: _materialController.text.trim(),
      durationMin: int.parse(_durationController.text),
      costIdr: int.tryParse(_costController.text) ?? 0,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      timezone: _currentUserProfile!.defaultTz,
      txnTimestamp: DateTime.now(),
      photoUrl: photoUrl,
    );

    final success = await _logService.addLog(newLog);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil disimpan!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan laporan.')),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Laporan Manual'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentUserProfile == null) {
      return const Center(
          child: Text('Gagal memuat profil. Silakan login ulang.'));
    }
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menyimpan laporan...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(
                labelText: 'Materi Belajar *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Materi tidak boleh kosong.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durasi (Menit) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Durasi tidak boleh kosong.';
                }
                if (int.tryParse(value) == null) {
                  return 'Harus berupa angka.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Biaya (IDR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokasi (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin_drop),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isFetchingLocation ? null : _getCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _isFetchingLocation
                    ? 'Mencari lokasi...'
                    : 'Gunakan Lokasi Saat Ini',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Foto Bukti (Opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Text('Belum ada foto dipilih'),
                    ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Pilih Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
              ),
            ),
            if (_selectedImage != null)
              TextButton.icon(
                onPressed: () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Hapus Foto',
                    style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitLog,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Laporan'),
            ),
          ],
        ),
      ),
    );
  }
}
