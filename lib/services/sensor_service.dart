import 'dart:async';
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:compassx/compassx.dart';

class SensorService {
  // Counters for sensor readings
  int _accelerometerReadings = 0;
  int _gyroscopeReadings = 0;
  int _magnetometerReadings = 0;
  int _compassReadings = 0;
  StreamSubscription? _sensorSubscription;
  StreamSubscription<CompassXEvent>? _compassSubscription;
  final List<SensorDataRecord> _sensorRecords = [];
  DateTime? _startTime;
  double _compassHeading = 0.0;
  bool _isCompassInitialized = false;
  double _compassAccuracy = -1.0;
  bool _shouldCalibrate = false;

  // Getter for compass heading
  double get compassHeading => _compassHeading;

  Stream<SensorRecord> get sensorStream {
    return Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) async {
      // Get individual sensor readings
      final accel = await Future.value(motionSensors.accelerometer.first);
      final gyro = await Future.value(motionSensors.gyroscope.first);
      final mag = await Future.value(motionSensors.magnetometer.first);

      // For the compass, we'll use the current heading value stored in _compassHeading
      // which is updated by the _compassSubscription

      return SensorRecord(
        accelerometer: Vector3(accel.x, accel.y, accel.z),
        gyroscope: Vector3(gyro.x, gyro.y, gyro.z),
        magnetometer: Vector3(mag.x, mag.y, mag.z),
        compass: _compassHeading,
        compassAccuracy: _compassAccuracy,
        shouldCalibrate: _shouldCalibrate,
        timestamp: DateTime.now(),
      );
    });
  }

  Future<void> startRecording() async {
    // Reset counters and data
    _accelerometerReadings = 0;
    _gyroscopeReadings = 0;
    _magnetometerReadings = 0;
    _compassReadings = 0;
    _sensorRecords.clear();
    _startTime = DateTime.now();

    // Initialize compass if not already initialized
    if (!_isCompassInitialized) {
      await prepare();
    }

    // Start compass listener using the correct API
    // CompassX.events provides a stream of CompassXEvent
    _compassSubscription = CompassX.events?.listen((event) {
      _compassHeading = event.heading;
      _compassAccuracy = event.accuracy;
      _shouldCalibrate = event.shouldCalibrate;
    });

    // Start counting readings and storing data
    _sensorSubscription = sensorStream.listen((record) {
      if (record.accelerometer != null) _accelerometerReadings++;
      if (record.gyroscope != null) _gyroscopeReadings++;
      if (record.magnetometer != null) _magnetometerReadings++;
      if (record.compass != null) _compassReadings++;

      // Store the raw sensor data
      _sensorRecords.add(SensorDataRecord(
        accelerometer: record.accelerometer,
        gyroscope: record.gyroscope,
        magnetometer: record.magnetometer,
        compass: record.compass,
        compassAccuracy: record.compassAccuracy,
        shouldCalibrate: record.shouldCalibrate,
        timestamp: record.timestamp,
      ));
    });
  }

  Future<void> stopRecording() async {
    await _sensorSubscription?.cancel();
    await _compassSubscription?.cancel();
    _sensorSubscription = null;
    _compassSubscription = null;
  }

  // Original report for frontend display
  Map<String, int> getReport() {
    return {
      'accelerometer': _accelerometerReadings,
      'gyroscope': _gyroscopeReadings,
      'magnetometer': _magnetometerReadings,
      'compass': _compassReadings,
    };
  }

  // Updated method to get detailed sensor data for storage
  Map<String, dynamic> getDetailedReport() {
    return {
      'summary': getReport(),
      'accelerometerData': _sensorRecords
          .where((record) => record.accelerometer != null)
          .map((record) => {
                'x': record.accelerometer!.x,
                'y': record.accelerometer!.y,
                'z': record.accelerometer!.z,
                'timestamp': record.timestamp.toIso8601String(),
              })
          .toList(),
      'gyroscopeData': _sensorRecords
          .where((record) => record.gyroscope != null)
          .map((record) => {
                'x': record.gyroscope!.x,
                'y': record.gyroscope!.y,
                'z': record.gyroscope!.z,
                'timestamp': record.timestamp.toIso8601String(),
              })
          .toList(),
      'magnetometerData': _sensorRecords
          .where((record) => record.magnetometer != null)
          .map((record) => {
                'x': record.magnetometer!.x,
                'y': record.magnetometer!.y,
                'z': record.magnetometer!.z,
                'timestamp': record.timestamp.toIso8601String(),
              })
          .toList(),
      'compassData': _sensorRecords
          .where((record) => record.compass != null)
          .map((record) => {
                'heading': record.compass,
                'accuracy': record.compassAccuracy,
                'needsCalibration': record.shouldCalibrate,
                'isTrueNorth':
                    true, // CompassX always provides true north heading
                'timestamp': record.timestamp.toIso8601String(),
              })
          .toList(),
    };
  }

  Future<void> prepare() async {
    // Check if CompassX is already initialized
    if (!_isCompassInitialized) {
      try {
        // CompassX doesn't need explicit initialization beyond ensuring
        // location permissions are granted on Android, which we've done in main.dart
        // Just make sure we can access the stream
        if (CompassX.events != null) {
          _isCompassInitialized = true;
        }
      } catch (e) {
        print('Failed to initialize compass: $e');
      }
    }
    return;
  }
}

class SensorRecord {
  final Vector3? accelerometer;
  final Vector3? gyroscope;
  final Vector3? magnetometer;
  final double? compass;
  final double? compassAccuracy;
  final bool? shouldCalibrate;
  final DateTime timestamp;

  SensorRecord({
    this.accelerometer,
    this.gyroscope,
    this.magnetometer,
    this.compass,
    this.compassAccuracy,
    this.shouldCalibrate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'accelerometer': accelerometer != null
            ? {
                'x': accelerometer!.x,
                'y': accelerometer!.y,
                'z': accelerometer!.z
              }
            : null,
        'gyroscope': gyroscope != null
            ? {'x': gyroscope!.x, 'y': gyroscope!.y, 'z': gyroscope!.z}
            : null,
        'magnetometer': magnetometer != null
            ? {'x': magnetometer!.x, 'y': magnetometer!.y, 'z': magnetometer!.z}
            : null,
        'compass': compass,
        'compassAccuracy': compassAccuracy,
        'shouldCalibrate': shouldCalibrate,
        'timestamp': timestamp.toIso8601String(),
      };
}

class SensorDataRecord {
  final Vector3? accelerometer;
  final Vector3? gyroscope;
  final Vector3? magnetometer;
  final double? compass;
  final double? compassAccuracy;
  final bool? shouldCalibrate;
  final DateTime timestamp;

  SensorDataRecord({
    this.accelerometer,
    this.gyroscope,
    this.magnetometer,
    this.compass,
    this.compassAccuracy,
    this.shouldCalibrate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'accelerometer': accelerometer != null
            ? {
                'x': accelerometer!.x,
                'y': accelerometer!.y,
                'z': accelerometer!.z
              }
            : null,
        'gyroscope': gyroscope != null
            ? {'x': gyroscope!.x, 'y': gyroscope!.y, 'z': gyroscope!.z}
            : null,
        'magnetometer': magnetometer != null
            ? {'x': magnetometer!.x, 'y': magnetometer!.y, 'z': magnetometer!.z}
            : null,
        'compass': compass,
        'compassAccuracy': compassAccuracy,
        'shouldCalibrate': shouldCalibrate,
        'timestamp': timestamp.toIso8601String(),
      };
}
