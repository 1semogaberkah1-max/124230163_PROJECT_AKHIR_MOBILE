import 'package:flutter/material.dart';
import '../main.dart';
import '../models/reminder_model.dart';
import '../models/user_profile_model.dart';
import '../services/reminder_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderService _reminderService = ReminderService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  UserProfile? _currentUserProfile;
  Future<List<Reminder>>? _remindersFuture;
  bool _isLoadingProfile = true;

  final List<String> _daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
    'Setiap Hari',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _notificationService.requestPermissions();

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    final profile = await _userService.getOrCreateUserProfile(user);
    setState(() {
      _currentUserProfile = profile;
      _isLoadingProfile = false;
      if (profile != null) {
        _refreshReminders();
      }
    });
  }

  void _refreshReminders() {
    setState(() {
      _remindersFuture = _reminderService.getReminders();
    });
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    final updatedReminder = Reminder(
      id: reminder.id,
      userId: reminder.userId,
      title: reminder.title,
      scheduleDay: reminder.scheduleDay,
      scheduleTime: reminder.scheduleTime,
      timezone: reminder.timezone,
      isActive: !reminder.isActive,
      createdAt: reminder.createdAt,
    );

    final success = await _reminderService.updateReminder(updatedReminder);
    if (success) {
      _refreshReminders();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui reminder.')),
        );
      }
    }
  }

  Future<void> _deleteReminder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Reminder?'),
        content: const Text('Anda yakin ingin menghapus reminder ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reminderService.deleteReminder(id);
      if (success) {
        _refreshReminders();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus reminder.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Belajar'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: (_currentUserProfile == null)
            ? null
            : () => _showAddReminderSheet(context, _currentUserProfile!),
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentUserProfile == null) {
      return const Center(
        child: Text('Gagal memuat profil pengguna. Silakan login ulang.'),
      );
    }

    return FutureBuilder<List<Reminder>>(
      future: _remindersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final reminders = snapshot.data;
        if (reminders == null || reminders.isEmpty) {
          return const Center(
            child: Text(
              'Anda belum mengatur reminder.\nTekan tombol + untuk menambah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(
                  Icons.alarm,
                  color: reminder.isActive ? Colors.indigo : Colors.grey,
                ),
                title: Text(
                  reminder.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration:
                        !reminder.isActive ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  '${reminder.scheduleDay} - ${reminder.scheduleTime.format(context)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: reminder.isActive,
                      onChanged: (value) => _toggleReminder(reminder),
                      activeColor: Colors.indigo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteReminder(reminder.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddReminderSheet(BuildContext context, UserProfile profile) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String selectedDay = 'Setiap Hari';
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tambah Reminder Baru',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Judul Pengingat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      title = value;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Jadwal Hari',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: _daysOfWeek.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedDay = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Pilih Jam'),
                    trailing: TextButton(
                      child: Text(
                        selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null && picked != selectedTime) {
                          setModalState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newReminder = Reminder(
                          id: '',
                          userId: profile.id,
                          title: title,
                          scheduleDay: selectedDay,
                          scheduleTime: selectedTime,
                          timezone: profile.defaultTz,
                          isActive: true,
                          createdAt: DateTime.now(),
                        );

                        final success = await _reminderService.addReminder(
                          reminder: newReminder,
                          currentUserId: profile.id,
                        );

                        if (mounted) {
                          if (success) {
                            Navigator.pop(context);
                            _refreshReminders();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reminder berhasil disimpan!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menyimpan reminder.'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
