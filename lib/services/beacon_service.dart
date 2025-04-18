import 'dart:async';
import 'dart:io' show Platform;
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';

class BeaconService {
  static final BeaconService _instance = BeaconService._internal();
  factory BeaconService() => _instance;
  BeaconService._internal();

  StreamSubscription<RangingResult>? _streamRanging;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beaconDataController = StreamController<List<Beacon>>.broadcast();
  final Map<String, int> _beaconCounts = {};
  final Map<String, List<BeaconRecord>> _beaconRecords = {};
  DateTime? _startTime;

  Stream<List<Beacon>> get beaconStream => _beaconDataController.stream;
  bool _isScanning = false;

  Future<Map<String, bool>> checkPermissions() async {
    final authorizationStatus = await flutterBeacon.authorizationStatus;
    final bluetoothState = await flutterBeacon.bluetoothState;
    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;

    return {
      'authorization': authorizationStatus == AuthorizationStatus.allowed ||
          authorizationStatus == AuthorizationStatus.always,
      'bluetooth': bluetoothState == BluetoothState.stateOn,
      'location': locationServiceEnabled,
    };
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      // Check and request permissions first
      final authorizationStatus = await flutterBeacon.authorizationStatus;
      final bluetoothState = await flutterBeacon.bluetoothState;
      final locationServiceEnabled =
          await flutterBeacon.checkLocationServicesIfEnabled;

      print('Authorization Status: $authorizationStatus');
      print('Bluetooth State: $bluetoothState');
      print('Location Service Enabled: $locationServiceEnabled');

      _startTime = DateTime.now();
      _beaconCounts.clear();

      // Initialize scanning settings
      if (Platform.isIOS) {
        await flutterBeacon.setScanPeriod(3000);
        await flutterBeacon.setBetweenScanPeriod(0);
      } else {
        // Android settings for faster scanning
        await flutterBeacon.setScanPeriod(300);
        await flutterBeacon.setBetweenScanPeriod(0);
        await flutterBeacon.setUseTrackingCache(true);
        await flutterBeacon.setMaxTrackingAge(10000);

        await flutterBeacon.setBackgroundScanPeriod(1000);
        await flutterBeacon.setBackgroundBetweenScanPeriod(500);
      }

      // Initialize scanning
      await flutterBeacon.initializeScanning;

      final regions = <Region>[
        Region(
          identifier: 'museum',
          proximityUUID: "e2c566db-5dff-b48d-2b06-0d0f5a71096e",
        )
      ];

      // Resume if paused, otherwise start new
      if (_streamRanging != null) {
        if (_streamRanging!.isPaused) {
          _streamRanging?.resume();
          return;
        }
      }

      _streamRanging = flutterBeacon.ranging(regions).listen(
        (RangingResult result) {
          print('Raw ranging result: $result'); // Log raw result
          _regionBeacons[result.region] = result.beacons;
          final allBeacons = <Beacon>[];

          for (var list in _regionBeacons.values) {
            allBeacons.addAll(list);
          }

          // Update beacon counts and log
          for (var beacon in allBeacons) {
            _processBeacon(beacon);
          }

          // Sort beacons
          allBeacons.sort((a, b) {
            int compare = a.proximityUUID.compareTo(b.proximityUUID);
            if (compare == 0) {
              compare = a.major.compareTo(b.major);
            }
            if (compare == 0) {
              compare = a.minor.compareTo(b.minor);
            }
            return compare;
          });

          _beaconDataController.add(allBeacons);
        },
        onError: (error) {
          print('Beacon scanning error: $error');
        },
      );

      _isScanning = true;
    } catch (e) {
      print('Error initializing beacon scanning: $e');
      rethrow;
    }
  }

  Future<void> pauseScanning() async {
    _streamRanging?.pause();
    _regionBeacons.clear();
  }

  Future<void> stopScanning() async {
    if (_startTime != null) {
      final totalTime = DateTime.now().difference(_startTime!).inSeconds;
      print('\n=== Final Beacon Summary ===');
      print('Total scanning time: $totalTime seconds');
      _beaconCounts.forEach((beaconId, count) {
        print(
            '$beaconId: $count total (${(count / totalTime).toStringAsFixed(2)} adv/s)');
      });
      print('========================\n');
    }

    await _streamRanging?.cancel();
    _regionBeacons.clear();
    _beaconRecords.clear();
    _isScanning = false;
  }

  Future<void> dispose() async {
    await stopScanning();
    await _beaconDataController.close();
  }

  void _processBeacon(Beacon beacon) {
    final beaconId = Platform.isIOS
        ? '${beacon.proximityUUID}-${beacon.major}-${beacon.minor}'
        : 'beacon-${beacon.major}-${beacon.minor}';

    _beaconCounts[beaconId] = (_beaconCounts[beaconId] ?? 0) + 1;

    // Store the individual advertisement
    final record = BeaconRecord(
      uuid: beacon.proximityUUID,
      major: beacon.major,
      minor: beacon.minor,
      rssi: beacon.rssi,
      accuracy: beacon.accuracy,
      timestamp: DateTime.now(),
    );

    if (!_beaconRecords.containsKey(beaconId)) {
      _beaconRecords[beaconId] = [];
    }
    _beaconRecords[beaconId]!.add(record);

    final elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    print('Beacon [$elapsedSeconds s] - ID: $beaconId\n'
        '  RSSI: ${beacon.rssi} dBm\n'
        '  Accuracy: ${beacon.accuracy.toStringAsFixed(2)}m\n'
        '  Total Count: ${_beaconCounts[beaconId]}\n'
        '  Rate: ${(_beaconCounts[beaconId]! / elapsedSeconds).toStringAsFixed(2)} adv/s');
  }

  // Original report format for frontend display
  Map<String, Map<String, dynamic>> getFrontendReport() {
    final beaconData = <String, Map<String, dynamic>>{};

    // Process all beacons from all regions
    for (var beacons in _regionBeacons.values) {
      for (var beacon in beacons) {
        final beaconId = Platform.isIOS
            ? '${beacon.proximityUUID}-${beacon.major}-${beacon.minor}'
            : 'beacon-${beacon.major}-${beacon.minor}';

        final key = '${beacon.major}-${beacon.minor}';

        if (!beaconData.containsKey(key)) {
          beaconData[key] = {
            'count': _beaconCounts[beaconId] ?? 1,
            'rssi': beacon.rssi,
            'accuracy': beacon.accuracy,
            'uuid': beacon.proximityUUID
          };
        } else {
          // Update RSSI if the new value is stronger
          if (beacon.rssi > beaconData[key]!['rssi']) {
            beaconData[key]!['rssi'] = beacon.rssi;
            beaconData[key]!['accuracy'] = beacon.accuracy;
          }
          beaconData[key]!['count'] = _beaconCounts[beaconId] ?? 1;
        }
      }
    }

    return beaconData;
  }

  // Detailed report with individual advertisements for storage
  Map<String, dynamic> getReport() {
    final bleReadings = <String, Map<String, dynamic>>{};
    final bleData = <String, List<Map<String, dynamic>>>{};

    // Process all beacons from all regions
    for (var entry in _beaconRecords.entries) {
      final records = entry.value;

      // Get the last record for summary info
      final lastRecord = records.last;
      final key = '${lastRecord.major}-${lastRecord.minor}';

      // Create summary for bleReadings
      bleReadings[key] = {
        'count': records.length,
        'last_rssi': lastRecord.rssi,
        'last_accuracy': lastRecord.accuracy,
        'uuid': lastRecord.uuid,
      };

      // Create detailed data for bleData
      bleData[key] = records.map((r) => r.toJson()).toList();
    }

    return {
      'bleReadings': bleReadings,
      'bleData': bleData,
    };
  }

  BeaconRecord createBeaconRecord(Beacon beacon) {
    return BeaconRecord(
      uuid: beacon.proximityUUID,
      major: beacon.major,
      minor: beacon.minor,
      rssi: beacon.rssi,
      accuracy: beacon.accuracy,
      timestamp: DateTime.now(),
    );
  }

  Future<void> prepare() async {
    // On iOS, we need to ensure ranging is ready before we start scanning
    // This helps prevent the delay in data collection
    try {
      await flutterBeacon.initializeScanning;
    } catch (e) {
      print('Error preparing beacon service: $e');
      // We don't throw here as the service might still work
    }
  }
}

class BeaconRecord {
  final String uuid;
  final int major;
  final int minor;
  final int rssi;
  final double accuracy;
  final DateTime timestamp;

  BeaconRecord({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.rssi,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'major': major,
        'minor': minor,
        'rssi': rssi,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };
}
