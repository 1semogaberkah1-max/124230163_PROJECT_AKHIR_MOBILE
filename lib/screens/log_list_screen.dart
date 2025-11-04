import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/learning_log_model.dart';
import '../services/log_service.dart';
import 'log_detail_screen.dart';

class LogListScreen extends StatefulWidget {
  final bool refresh;
  const LogListScreen({super.key, this.refresh = false});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final LogService _logService = LogService();

  final TextEditingController _searchController = TextEditingController();
  List<LearningLog> _allLogs = [];
  List<LearningLog> _filteredLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();

    _searchController.addListener(_filterLogs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLogs);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await _logService.getLogs();
    setState(() {
      _allLogs = logs;
      _filteredLogs = logs;
      _isLoading = false;
    });
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLogs = _allLogs;
      } else {
        _filteredLogs = _allLogs.where((log) {
          return log.material.toLowerCase().contains(query);
        }).toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Belajar Anda'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan materi...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredLogs.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Anda belum mencatat kegiatan belajar apa pun.'
                        : 'Tidak ada riwayat yang cocok dengan "${_searchController.text}".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: _filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = _filteredLogs[index];

                  final formattedDate = DateFormat(
                    'EEEE, dd MMMM yyyy HH:mm',
                    'id_ID',
                  ).format(log.txnTimestamp.toLocal());

                  final formattedCost = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp',
                    decimalDigits: 0,
                  ).format(log.costIdr);

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ListTile(
                      leading:
                          const Icon(Icons.menu_book, color: Colors.indigo),
                      title: Text(
                        log.material,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Waktu: ${_formatDuration(log.durationMin)}'),
                          Text('Biaya: $formattedCost'),
                          if (log.location != null && log.location!.isNotEmpty)
                            Text('Tempat: ${log.location!}'),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (log.notes != null && log.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Catatan: ${log.notes!}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (log.photoUrl != null)
                            const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.grey,
                            ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LogDetailScreen(log: log),
                          ),
                        ).then((_) => _fetchLogs());
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
