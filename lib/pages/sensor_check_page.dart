import 'package:flutter/material.dart';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import '../services/beacon_service.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:async';

class SensorCheckPage extends StatefulWidget {
  const SensorCheckPage({super.key});

  @override
  State<SensorCheckPage> createState() => _SensorCheckPageState();
}

class _SensorCheckPageState extends State<SensorCheckPage> {
  final _beaconService = BeaconService();
  Map<String, bool> _permissions = {
    'authorization': false,
    'bluetooth': false,
    'location': false,
  };
  bool _isScanning = false;
  StreamSubscription<List<Beacon>>? _beaconStreamSubscription;
  final Map<String, List<BeaconReading>> _beaconReadings = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _beaconStreamSubscription?.cancel();
    _beaconService.stopScanning();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final permissions = await _beaconService.checkPermissions();
    setState(() {
      _permissions = permissions;
    });
  }

  Future<void> _requestPermission(String title) async {
    if (title == 'Bluetooth') {
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    } else if (title == 'Location') {
      await flutterBeacon.requestAuthorization;
    } else if (title == 'Authorization') {
      await flutterBeacon.requestAuthorization;
    }
    await Future.delayed(
        const Duration(seconds: 1)); // Wait for settings to update
    await _checkPermissions();
  }

  Widget _buildPermissionTile(String title, bool isGranted) {
    return ListTile(
      leading: Icon(
        isGranted ? Icons.check_circle : Icons.error,
        color: isGranted ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(isGranted ? 'Granted' : 'Not Granted'),
      trailing: !isGranted
          ? TextButton(
              onPressed: () => _requestPermission(title),
              child: const Text('Request'),
            )
          : null,
    );
  }

  void _startScanning() async {
    if (_isScanning) return;

    try {
      await _beaconService.startScanning();
      _beaconStreamSubscription = _beaconService.beaconStream.listen(
        (beacons) {
          setState(() {
            for (var beacon in beacons) {
              final key =
                  '${beacon.proximityUUID}-${beacon.major}-${beacon.minor}';
              if (!_beaconReadings.containsKey(key)) {
                _beaconReadings[key] = [];
              }
              _beaconReadings[key]!.add(
                BeaconReading(
                  rssi: beacon.rssi,
                  major: beacon.major,
                  minor: beacon.minor,
                  timestamp: DateTime.now(),
                ),
              );

              // Remove readings older than 3 seconds
              _beaconReadings[key] = _beaconReadings[key]!
                  .where((reading) => reading.timestamp.isAfter(
                      DateTime.now().subtract(const Duration(seconds: 3))))
                  .toList();
            }
          });
        },
      );

      setState(() {
        _isScanning = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopScanning() async {
    await _beaconService.stopScanning();
    _beaconStreamSubscription?.cancel();
    setState(() {
      _isScanning = false;
      _beaconReadings.clear();
    });
  }

  double _calculateMeanRSSI(List<BeaconReading> readings) {
    if (readings.isEmpty) return 0;
    final sum = readings.fold(0, (sum, reading) => sum + reading.rssi);
    return sum / readings.length;
  }

  @override
  Widget build(BuildContext context) {
    // Sort beacons by major and minor
    final sortedBeacons = _beaconReadings.entries.toList()
      ..sort((a, b) {
        final aMajor = a.value.first.major;
        final bMajor = b.value.first.major;
        if (aMajor != bMajor) {
          return aMajor.compareTo(bMajor);
        }
        return a.value.first.minor.compareTo(b.value.first.minor);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor & Beacon Check'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Required Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildPermissionTile(
                    'Authorization', _permissions['authorization'] ?? false),
                _buildPermissionTile(
                    'Bluetooth', _permissions['bluetooth'] ?? false),
                _buildPermissionTile(
                    'Location', _permissions['location'] ?? false),
                const Divider(),
                if (_permissions.values.every((granted) => granted))
                  Center(
                    child: ElevatedButton(
                      onPressed: _isScanning ? _stopScanning : _startScanning,
                      child: Text(
                          _isScanning ? 'Stop Scanning' : 'Start Scanning'),
                    ),
                  ),
              ],
            ),
          ),
          if (_isScanning &&
              _permissions.values.every((granted) => granted)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Detected Beacons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: sortedBeacons.length,
                itemBuilder: (context, index) {
                  final entry = sortedBeacons[index];
                  final meanRSSI = _calculateMeanRSSI(entry.value);
                  final beacon = entry.value.first;

                  return Card(
                    child: ListTile(
                      title: Text(
                        'Major: ${beacon.major.toString().padLeft(5, '0')} - Minor: ${beacon.minor.toString().padLeft(5, '0')}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: Text(
                        'Mean RSSI (3s): ${meanRSSI.toStringAsFixed(2)} dBm (${entry.value.length} readings)',
                        style: TextStyle(
                          color: entry.value.isEmpty
                              ? Colors.red
                              : meanRSSI < -85
                                  ? Colors.red
                                  : meanRSSI < -70
                                      ? Colors.orange
                                      : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BeaconReading {
  final int rssi;
  final int major;
  final int minor;
  final DateTime timestamp;

  BeaconReading({
    required this.rssi,
    required this.major,
    required this.minor,
    required this.timestamp,
  });
}
