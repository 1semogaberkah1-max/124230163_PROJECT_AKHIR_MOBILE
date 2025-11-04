// File: lib/screens/recap_screen.dart
// (TELAH DIPERBARUI UNTUK MENAMPILKAN LOKASI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/log_service.dart';
import '../services/currency_service.dart';

class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  final LogService _logService = LogService();
  final CurrencyService _currencyService = CurrencyService();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = true;

  Future<Map<String, dynamic>?>? _recapFuture;
  Future<List<Map<String, dynamic>>?>? _topMaterialsFuture;
  Future<Map<String, dynamic>?>? _ratesFuture;
  // --- TAMBAHAN BARU 1: State Future untuk Lokasi ---
  Future<List<Map<String, dynamic>>?>? _topLocationsFuture;
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 6));
    _ratesFuture = _currencyService.getExchangeRates();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      final endOfDay =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      _recapFuture = _logService.getRecap(
        startDate: _startDate,
        endDate: endOfDay,
      );
      _topMaterialsFuture = _logService.getTopMaterials(
        startDate: _startDate,
        endDate: endOfDay,
      );
      // --- TAMBAHAN BARU 2: Panggil service lokasi ---
      _topLocationsFuture = _logService.getTopLocations(
        startDate: _startDate,
        endDate: endOfDay,
      );
      // ----------------------------------------------

      // --- TAMBAHAN BARU 3: Tambahkan ke Future.wait ---
      Future.wait([
        _recapFuture!,
        _topMaterialsFuture!,
        _topLocationsFuture! // <-- Tambahkan di sini
      ]).then((_) {
        // ----------------------------------------------
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes == 0) return '0 Menit';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    String result = '';
    if (hours > 0) result += '${hours} Jam ';
    if (minutes > 0) result += '${minutes} Menit';
    return result.trim();
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap & Statistik'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // UI Pemilih Tanggal
            Text(
              'Rentang Tanggal Laporan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
            ),
            const Divider(height: 32, thickness: 1),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_isLoading) ...[
              // Bagian 1: Rekap Total
              _buildRecapTotalSection(),
              const SizedBox(height: 24),
              // Bagian 2: Top Materi
              _buildTopMaterialsSection(),
              const SizedBox(height: 24), // Beri jarak
              // --- TAMBAHAN BARU 4: Panggil widget lokasi ---
              _buildTopLocationsSection(),
              // --------------------------------------------
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecapTotalSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _recapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat data rekap.'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Tidak ada data pada rentang ini.'));
        }

        final data = snapshot.data!;
        final int totalDuration = data['total_duration_min'] as int;
        final int totalCost = data['total_cost_idr'] as int;

        return Column(
          children: [
            // Card Total Durasi
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.timer, size: 40, color: Colors.indigo),
                    const SizedBox(height: 8),
                    const Text(
                      'TOTAL DURASI BELAJAR',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      _formatDuration(totalDuration),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card Total Biaya (Sekarang dengan Konversi)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.monetization_on,
                        size: 40, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      'TOTAL BIAYA BELAJAR',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      _formatCurrency(totalCost),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (totalCost > 0) ...[
                      const Divider(height: 20, thickness: 1),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _ratesFuture,
                        builder: (context, rateSnapshot) {
                          if (rateSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Memuat kurs...',
                                style: TextStyle(color: Colors.grey));
                          }
                          if (!rateSnapshot.hasData ||
                              rateSnapshot.data == null) {
                            return const Text('Gagal memuat kurs.',
                                style: TextStyle(color: Colors.red));
                          }

                          final rates = rateSnapshot.data!;
                          final double rateUSD = rates['USD'] ?? 0.0;
                          final double rateEUR = rates['EUR'] ?? 0.0;
                          final double rateJPY = rates['JPY'] ?? 0.0;

                          final double costUSD = totalCost * rateUSD;
                          final double costEUR = totalCost * rateEUR;
                          final double costJPY = totalCost * rateJPY;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USD: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(costUSD)}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              Text(
                                'EUR: ${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(costEUR)}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              Text(
                                'JPY: ${NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(costJPY)}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materi Terbanyak Dipelajari',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>?>(
          future: _topMaterialsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Gagal memuat data materi.');
            }
            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('Belum ada data materi'),
                  subtitle: Text(
                      'Anda belum mencatat materi apapun pada rentang ini.'),
                ),
              );
            }

            final materials = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final item = materials[index];
                final String name = item['material_name'] ?? 'Tanpa Nama';
                final int minutes = (item['total_minutes'] as num).toInt();

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      _formatDuration(minutes),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- TAMBAHAN BARU 5: Widget untuk Top Lokasi ---
  // (Ini adalah salinan dari _buildTopMaterialsSection yang dimodifikasi)
  Widget _buildTopLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tempat Belajar Terfavorit', // <-- Judul diubah
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>?>(
          future: _topLocationsFuture, // <-- Gunakan Future lokasi
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Gagal memuat data lokasi.');
            }
            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('Belum ada data lokasi'), // <-- Teks diubah
                  subtitle: Text(
                      'Anda belum mencatat lokasi belajar pada rentang ini.'),
                ),
              );
            }

            final locations = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final item = locations[index];
                // <-- Ambil 'location_name' dari RPC
                final String name = item['location_name'] ?? 'Tanpa Nama';
                final int minutes = (item['total_minutes'] as num).toInt();

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      // <-- Warna diubah
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.teal, // <-- Warna diubah
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      _formatDuration(minutes),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
