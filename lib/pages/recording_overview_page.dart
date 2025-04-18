import 'package:flutter/material.dart';
import 'package:flutter_ibeacon_recorder/models/artwork.dart';
import 'package:flutter_ibeacon_recorder/models/recording_action.dart';
import 'package:flutter_ibeacon_recorder/services/mongo_service.dart';
import 'package:flutter_ibeacon_recorder/services/device_info_service.dart';

class RecordingOverviewPage extends StatefulWidget {
  final List<RecordingAction> actions;
  final List<Artwork> artworks;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> sensorData;
  final Map<String, dynamic> bleData;

  const RecordingOverviewPage({
    super.key,
    required this.actions,
    required this.artworks,
    required this.startTime,
    required this.endTime,
    required this.sensorData,
    required this.bleData,
  });

  @override
  State<RecordingOverviewPage> createState() => _RecordingOverviewPageState();
}

class _RecordingOverviewPageState extends State<RecordingOverviewPage> {
  final _mongoService = MongoService();
  final _deviceInfoService = DeviceInfoService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeMongo();
  }

  Future<void> _initializeMongo() async {
    try {
      await _mongoService.connect('path');
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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRecording() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final recordingData = {
        'timestamp': DateTime.now().toIso8601String(),
        'recordingStartTime': widget.startTime.toIso8601String(),
        'recordingEndTime': widget.endTime.toIso8601String(),
        'recordingDurationSeconds':
            widget.endTime.difference(widget.startTime).inSeconds,
        'note': _noteController.text,
        'deviceInfo': deviceInfo,
        'artworks': widget.artworks.map((a) => a.toJson()).toList(),
        'activityData': widget.actions.map((a) => a.toJson()).toList(),
        'sensorReadings': widget.sensorData['summary'],
        'accelerometerData': widget.sensorData['accelerometerData'],
        'gyroscopeData': widget.sensorData['gyroscopeData'],
        'magnetometerData': widget.sensorData['magnetometerData'],
        'compassData': widget.sensorData['compassData'],
        'bleReadings': widget.bleData['bleReadings'],
        'bleData': widget.bleData['bleData'],
      };

      print(
          'Compass data included: ${widget.sensorData['compassData'] != null}');
      if (widget.sensorData['compassData'] != null) {
        print('Compass data count: ${widget.sensorData['compassData'].length}');
        if (widget.sensorData['compassData'].isNotEmpty) {
          print('Sample compass data: ${widget.sensorData['compassData'][0]}');
        }
      }

      await _mongoService.insertData(recordingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
    final totalDuration = widget.endTime.difference(widget.startTime);
    final walkingActions =
        widget.actions.where((a) => a.type == 'walking').toList();
    final standingActions =
        widget.actions.where((a) => a.type == 'standing').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Overall stats card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording Stats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  Text(
                    'Total Duration: ${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s',
                  ),
                  Text('Total Artworks: ${widget.artworks.length}'),
                  Text('Walking Segments: ${walkingActions.length}'),
                  Text('Standing Segments: ${standingActions.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sensor data card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensor Data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ...(widget.sensorData['summary'] as Map<String, dynamic>)
                      .entries
                      .map(
                        (entry) => Text(
                          '${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)}: ${entry.value} datapoints',
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Beacon data card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beacon Data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ...(widget.bleData['bleReadings'] as Map<String, dynamic>)
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Beacon ${entry.key}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('Count: ${entry.value['count']}'),
                              Text(
                                  'Last RSSI: ${entry.value['last_rssi']} dBm'),
                              Text(
                                  'Last Accuracy: ${entry.value['last_accuracy'].toStringAsFixed(2)}m'),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Timeline card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording Timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ...widget.actions.map((action) {
                    final artwork = action.artworkId != null
                        ? widget.artworks
                            .firstWhere((a) => a.id == action.artworkId)
                        : null;

                    // Define icon and color based on action type
                    IconData actionIcon;
                    Color actionColor;
                    String actionLabel;

                    switch (action.type) {
                      case 'walking':
                        actionIcon = Icons.directions_walk;
                        actionColor = Colors.blue;
                        actionLabel = 'Walking';
                        break;
                      case 'standing':
                        actionIcon = Icons.accessibility_new;
                        actionColor = Colors.orange;
                        actionLabel = 'Standing';
                        break;
                      case 'sitting':
                        actionIcon = Icons.chair;
                        actionColor = Colors.green;
                        actionLabel = 'Sitting';
                        break;
                      case 'standing_at_artwork':
                        actionIcon = Icons.pin_drop;
                        actionColor = Colors.purple;
                        actionLabel =
                            artwork?.displayTitle ?? 'At Point of Interest';
                        break;
                      default:
                        actionIcon = Icons.help_outline;
                        actionColor = Colors.grey;
                        actionLabel = action.type;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: actionColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              actionIcon,
                              color: actionColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Action details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  actionLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (artwork != null) ...[
                                  Text(
                                    artwork.authorName,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (artwork.room != null)
                                    Text(
                                      artwork.room!,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                                Text(
                                  '${action.duration.inSeconds}s',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Note input card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Note',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Add any additional notes about this recording...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRecording,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Submitting...'),
                    ],
                  )
                : const Text('Submit Recording'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
