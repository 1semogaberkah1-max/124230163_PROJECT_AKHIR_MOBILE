import 'package:flutter/material.dart';
import '../main.dart';
import '../models/feedback_model.dart';
import '../models/user_profile_model.dart';
import '../services/feedback_service.dart';
import '../services/user_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final UserService _userService = UserService();

  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  UserProfile? _currentUserProfile;
  FeedbackModel? _existingFeedback;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _userService.getOrCreateUserProfile(user);
    if (profile == null) {
      setState(() => _isLoading = false);
      return;
    }
    _currentUserProfile = profile;

    final feedback = await _feedbackService.getFeedback(profile.id);
    if (feedback != null) {
      _existingFeedback = feedback;
      _kesanController.text = feedback.kesan ?? '';
      _saranController.text = feedback.saran ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveFeedback() async {
    if (_currentUserProfile == null) return;

    setState(() => _isSaving = true);

    final FeedbackModel feedbackToSave = FeedbackModel(
      id: _existingFeedback?.id ?? UniqueKey().toString(),
      userId: _currentUserProfile!.id,
      kesan: _kesanController.text.trim(),
      saran: _saranController.text.trim(),
      createdAt: _existingFeedback?.createdAt ?? DateTime.now(),
    );

    final success = await _feedbackService.saveFeedback(feedbackToSave);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saran & Kesan berhasil disimpan!')),
        );
        setState(() {
          _existingFeedback = feedbackToSave;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data.')),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saran & Kesan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    if (_currentUserProfile == null) {
      return const Center(child: Text('Gagal memuat data pengguna.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kesan Anda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _kesanController,
            decoration: const InputDecoration(
              hintText: 'Tulis kesan Anda tentang mata kuliah ini...',
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          Text(
            'Saran Anda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _saranController,
            decoration: const InputDecoration(
              hintText: 'Tulis saran Anda untuk perbaikan ke depannya...',
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveFeedback,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}
