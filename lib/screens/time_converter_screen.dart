import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class TimeConverterScreen extends StatefulWidget {
  const TimeConverterScreen({super.key});

  @override
  State<TimeConverterScreen> createState() => _TimeConverterScreenState();
}

class _TimeConverterScreenState extends State<TimeConverterScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedZoneName = 'WIB';

  final Map<String, tz.Location> _timezones = {
    'WIB': tz.getLocation('Asia/Jakarta'),
    'WITA': tz.getLocation('Asia/Makassar'),
    'WIT': tz.getLocation('Asia/Jayapura'),
    'London': tz.getLocation('Europe/London'),
  };

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Map<String, String> _convertTime() {
    final Map<String, String> results = {};
    final tz.Location fromLocation = _timezones[_selectedZoneName]!;
    final nowInFromZone = tz.TZDateTime.now(fromLocation);

    final tz.TZDateTime selectedDateTime = tz.TZDateTime(
      fromLocation,
      nowInFromZone.year,
      nowInFromZone.month,
      nowInFromZone.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    _timezones.forEach((zoneName, location) {
      if (zoneName != _selectedZoneName) {
        final convertedTime = tz.TZDateTime.from(selectedDateTime, location);
        results[zoneName] = DateFormat('HH:mm').format(convertedTime);
      }
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> convertedTimes = _convertTime();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Waktu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Waktu & Zona Asal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.access_time,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Waktu yang Dipilih'),
                trailing: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedZoneName,
              decoration: const InputDecoration(
                labelText: 'Dari Zona Waktu',
                prefixIcon: Icon(Icons.public),
              ),
              items: _timezones.keys.map((String zone) {
                return DropdownMenuItem<String>(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedZoneName = value;
                  });
                }
              },
            ),
            const Divider(height: 40, thickness: 1),
            Text(
              'Hasil Konversi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...convertedTimes.entries.map((entry) {
              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
