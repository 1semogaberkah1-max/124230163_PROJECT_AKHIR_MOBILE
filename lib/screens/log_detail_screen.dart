// File: lib/screens/log_detail_screen.dart
// (VERSI DENGAN YOUTUBE)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- IMPORT BARU
import '../models/learning_log_model.dart';
import '../models/video_model.dart'; // <-- IMPORT BARU
import '../services/log_service.dart';
import '../services/currency_service.dart';
import '../services/youtube_service.dart'; // <-- IMPORT BARU
import 'log_list_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LogDetailScreen extends StatefulWidget {
  final LearningLog log;

  const LogDetailScreen({super.key, required this.log});

  @override
  State<LogDetailScreen> createState() => _LogDetailScreenState();
}

class _LogDetailScreenState extends State<LogDetailScreen> {
  final LogService _logService = LogService();
  final CurrencyService _currencyService = CurrencyService();
  final YoutubeService _youtubeService = YoutubeService(); // <-- TAMBAHAN BARU
  bool _isDeleting = false;

  late TextEditingController _materialController;
  late TextEditingController _durationController;
  late TextEditingController _costController;
  late TextEditingController _notesController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late Future<Map<String, dynamic>?> _ratesFuture;
  late Future<List<VideoModel>> _videoFuture; // <-- TAMBAHAN BARU

  @override
  void initState() {
    super.initState();
    _materialController = TextEditingController(text: widget.log.material);
    _durationController = TextEditingController(
      text: widget.log.durationMin.toString(),
    );
    _costController = TextEditingController(
      text: widget.log.costIdr.toString(),
    );
    _notesController = TextEditingController(text: widget.log.notes);

    _ratesFuture = _currencyService.getExchangeRates();
    _videoFuture = _youtubeService.searchVideos(widget.log.material);
  }

  @override
  void dispose() {
    _materialController.dispose();
    _durationController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}j';
    }
    return '${hours}j ${minutes}m';
  }

  Future<void> _deleteLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Log?'),
        content: Text(
          'Anda yakin ingin menghapus log "${widget.log.material}"?',
        ),
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
      setState(() => _isDeleting = true);
      final success = await _logService.deleteLog(widget.log.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log berhasil dihapus!')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LogListScreen(refresh: true),
            ),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal menghapus log.',
              ),
            ),
          );
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  Future<void> _updateLog() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedLog = LearningLog(
      id: widget.log.id,
      userId: widget.log.userId,
      material: _materialController.text.trim(),
      durationMin:
          int.tryParse(_durationController.text) ?? widget.log.durationMin,
      costIdr: int.tryParse(_costController.text) ?? widget.log.costIdr,
      notes: _notesController.text.trim(),
      location: widget.log.location,
      timezone: widget.log.timezone,
      txnTimestamp: widget.log.txnTimestamp,
      photoUrl: widget.log.photoUrl,
    );

    final success = await _logService.updateLog(updatedLog);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log berhasil diperbarui!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LogListScreen(refresh: true),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memperbarui log.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _launchVideo(String videoId) async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka video.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy HH:mm',
      'id_ID',
    ).format(log.txnTimestamp.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail & Edit Log'),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _isDeleting ? null : _deleteLog,
            tooltip: 'Hapus Log',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (log.photoUrl != null && log.photoUrl!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti Foto:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: log.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  TextFormField(
                    controller: _materialController,
                    decoration: const InputDecoration(
                      labelText: 'Materi Belajar',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Durasi (Menit)',
                      suffixText: _formatDuration(
                        int.tryParse(_durationController.text) ?? 0,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Durasi tidak boleh kosong.';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Harus angka.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Biaya (IDR)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Biaya tidak boleh kosong.';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Harus angka.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildCurrencySection(log.costIdr),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.pin_drop,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text('Lokasi: ${log.location ?? 'Tidak Dicatat'}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text('Waktu Dicatat: $formattedDate'),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _updateLog,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),
            Text(
              'Rekomendasi Video Terkait',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildVideoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySection(int costIdr) {
    if (costIdr == 0) {
      return Container();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _ratesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Memuat kurs mata uang...'),
              ],
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text('Gagal memuat kurs.'),
              ],
            ),
          );
        }

        final rates = snapshot.data!;
        final double rateUSD = rates['USD'] ?? 0.0;
        final double rateEUR = rates['EUR'] ?? 0.0;
        final double rateJPY = rates['JPY'] ?? 0.0;

        final double costUSD = costIdr * rateUSD;
        final double costEUR = costIdr * rateEUR;
        final double costJPY = costIdr * rateJPY;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimasi Biaya (Konversi):',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'USD: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(costUSD)}',
              ),
              Text(
                'EUR: ${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(costEUR)}',
              ),
              Text(
                'JPY: ${NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(costJPY)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoSection() {
    return FutureBuilder<List<VideoModel>>(
      future: _videoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat video.'));
        }

        final videos = snapshot.data;
        if (videos == null || videos.isEmpty) {
          return const Center(child: Text('Tidak ada video rekomendasi.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    width: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 100,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.image)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(video.channelTitle),
                onTap: () {
                  _launchVideo(video.id);
                },
              ),
            );
          },
        );
      },
    );
  }
}
