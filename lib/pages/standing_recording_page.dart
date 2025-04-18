import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ibeacon_recorder/models/artwork.dart';
import 'package:flutter_ibeacon_recorder/services/sensor_service.dart';
import 'package:flutter_ibeacon_recorder/services/beacon_service.dart';
import 'package:flutter_ibeacon_recorder/services/artwork_service.dart';
import 'package:flutter_ibeacon_recorder/services/settings_service.dart';
import 'package:flutter_ibeacon_recorder/services/mongo_service.dart';
import 'package:flutter_ibeacon_recorder/services/device_info_service.dart';
import 'package:flutter_ibeacon_recorder/pages/components/artwork_selection_view.dart';
import 'package:flutter_ibeacon_recorder/pages/components/recording_in_progress_view.dart';
import 'package:flutter_ibeacon_recorder/pages/components/recording_summary_view.dart';

class StandingRecordingPage extends StatefulWidget {
  const StandingRecordingPage({super.key});

  @override
  State<StandingRecordingPage> createState() => _StandingRecordingPageState();
}

class _StandingRecordingPageState extends State<StandingRecordingPage> {
  final _artworkService = ArtworkService();
  final _sensorService = SensorService();
  final _beaconService = BeaconService();
  final _settingsService = SettingsService();
  final _mongoService = MongoService();
  final _deviceInfoService = DeviceInfoService();

  Artwork? _selectedArtwork;
  String _searchText = '';
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  final List<String> _recordingLogs = [];
  Timer? _recordingTimer;
  String _elapsedTime = '00:00';
  final TextEditingController _noteController = TextEditingController();
  String? _selectedCrowdedness;
  bool _recordingComplete = false;
  Map<String, dynamic>? _recordedData;
  double _recordingProgress = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeMongo();
    _checkPermissions();
  }

  Future<void> _initializeMongo() async {
    try {
      await _mongoService.connect('stationary');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to database: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await _beaconService.checkPermissions();
      print('Initial permissions check result: $permissions');

      if (!permissions['authorization']! ||
          !permissions['bluetooth']! ||
          !permissions['location']!) {
        // Request permissions if not granted
        await _beaconService.checkPermissions();
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  @override
  void dispose() {
    _stopRecording();
    _noteController.dispose();
    super.dispose();
  }

  void _onArtworkSelected(Artwork artwork) {
    setState(() {
      _selectedArtwork = artwork;
    });
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      try {
        // First set up everything needed for recording
        final permissions = await _beaconService.checkPermissions();
        print('Permissions check result: $permissions');

        if (!permissions['authorization']!) {
          throw Exception('Location authorization not granted');
        }
        if (!permissions['bluetooth']!) {
          throw Exception('Bluetooth is not enabled');
        }
        if (!permissions['location']!) {
          throw Exception('Location services are not enabled');
        }

        // Prepare services before starting the recording
        print('Preparing services...');
        await Future.wait([
          _sensorService.prepare(),
          _beaconService.prepare(),
        ]);

        // Only after all services are ready, we start recording
        setState(() {
          _isRecording = true;
          _recordingLogs.clear();
          final recordingDuration = _settingsService.recordingDuration;
          _elapsedTime = recordingDuration.toInt().toString();
          _recordingProgress = 0.0;
        });

        // Start both services simultaneously
        await Future.wait([
          _sensorService.startRecording(),
          _beaconService.startScanning(),
        ]);

        // Set the start time only after everything is actually running
        setState(() {
          _recordingStartTime = DateTime.now();
        });

        print('All services started successfully');

        final recordingDuration = _settingsService.recordingDuration;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordingStartTime != null) {
            final duration = DateTime.now().difference(_recordingStartTime!);
            final remainingSeconds =
                (recordingDuration - duration.inSeconds).toInt();

            if (remainingSeconds <= 0) {
              _toggleRecording();
              return;
            }

            setState(() {
              _elapsedTime = remainingSeconds.toString();
              _recordingProgress = duration.inSeconds / recordingDuration;
            });
          }
        });
      } catch (e) {
        print('Error starting recording: $e');
        setState(() {
          _isRecording = false;
          _recordingStartTime = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start recording: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      try {
        // Create recording data before stopping
        final recordingData = _createRecordingData();
        print('Recording data created successfully'); // Debug print
        await _stopRecording();
        print('Recording stopped successfully'); // Debug print
        setState(() {
          _recordingComplete = true;
          _recordedData = recordingData;
        });
        print('State updated successfully'); // Debug print
      } catch (e) {
        print('Error in recording completion: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing recording: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _sensorService.stopRecording();
      await _beaconService.stopScanning();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
    }
  }

  Map<String, dynamic> _createRecordingData() {
    final bleReport = _beaconService.getReport();
    print('BLE Report structure: ${bleReport.keys}'); // Debug print

    final sensorDetailedReport = _sensorService.getDetailedReport();
    print(
        'Sensor Report structure: ${sensorDetailedReport.keys}'); // Debug print

    final data = {
      'artwork': _selectedArtwork?.displayTitle,
      'room': _selectedArtwork?.room,
      'artist': _selectedArtwork?.authorName,
      'crowdedness': _selectedCrowdedness,
      'timestamp': DateTime.now().toIso8601String(),
      'sensorReadings': sensorDetailedReport['summary'],
      'accelerometerData': sensorDetailedReport['accelerometerData'],
      'gyroscopeData': sensorDetailedReport['gyroscopeData'],
      'magnetometerData': sensorDetailedReport['magnetometerData'],
      'compassData': sensorDetailedReport['compassData'],
      'bleReadings': bleReport['bleReadings'],
      'bleData': bleReport['bleData'],
      'recordingStartTime': _recordingStartTime?.toIso8601String(),
      'recordingEndTime': DateTime.now().toIso8601String(),
      'recordingDurationSeconds': _settingsService.recordingDuration,
    };

    print('Created recording data successfully'); // Debug print
    // Debug print to verify compass data is included
    print(
        'Compass data included: ${sensorDetailedReport['compassData'] != null}');
    if (sensorDetailedReport['compassData'] != null) {
      print(
          'Compass data count: ${sensorDetailedReport['compassData'].length}');
      if (sensorDetailedReport['compassData'].isNotEmpty) {
        print('Sample compass data: ${sensorDetailedReport['compassData'][0]}');
      }
    }

    return data;
  }

  Future<void> _submitRecording() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final recordingData = {
        ..._recordedData!,
        'note': _noteController.text,
        'deviceInfo': deviceInfo,
        'artwork': _selectedArtwork?.toJson(),
      };

      await _mongoService.insertData(recordingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedArtwork = null;
          _selectedCrowdedness = null;
          _recordingComplete = false;
          _recordedData = null;
          _noteController.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      print('Error submitting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isRecording) {
          await _stopRecording();
          setState(() {
            _selectedArtwork = null;
            _selectedCrowdedness = null;
            _recordingComplete = false;
            _recordedData = null;
            _noteController.clear();
          });
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Standing Recording'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (!_recordingComplete && _selectedArtwork != null)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isRecording
                              ? 'Recording in progress...'
                              : 'Ready to record. Make sure you are standing in front of the artwork.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_recordingComplete) ...[
                        if (_selectedArtwork == null) ...[
                          Text(
                            'Select Artwork',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ArtworkSelectionView(
                              selectedArtwork: _selectedArtwork,
                              onArtworkSelected: _onArtworkSelected,
                              artworkService: _artworkService,
                              searchText: _searchText,
                              onSearchChanged: (value) =>
                                  setState(() => _searchText = value),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: RecordingInProgressView(
                              artwork: _selectedArtwork!,
                              isRecording: _isRecording,
                              elapsedTime: _elapsedTime,
                              recordingProgress: _recordingProgress,
                              onChangeArtwork: () => setState(() {
                                _selectedArtwork = null;
                              }),
                              onToggleRecording: _toggleRecording,
                            ),
                          ),
                        ],
                      ] else ...[
                        Expanded(
                          child: RecordingSummaryView(
                            recordedData: _recordedData!,
                            noteController: _noteController,
                            selectedCrowdedness: _selectedCrowdedness,
                            onCrowdednessChanged: (value) => setState(() {
                              _selectedCrowdedness = value;
                              if (_recordedData != null) {
                                _recordedData = {
                                  ..._recordedData!,
                                  'crowdedness': value,
                                };
                              }
                            }),
                            onDiscard: () => setState(() {
                              _selectedArtwork = null;
                              _selectedCrowdedness = null;
                              _recordingComplete = false;
                              _recordedData = null;
                              _noteController.clear();
                            }),
                            onSubmit: _submitRecording,
                            isSubmitting: _isSubmitting,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
