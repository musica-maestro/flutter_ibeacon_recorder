import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_ibeacon_recorder/models/artwork.dart';
import 'package:flutter_ibeacon_recorder/models/recording_action.dart';
import 'package:flutter_ibeacon_recorder/pages/recording_overview_page.dart';
import 'package:flutter_ibeacon_recorder/services/artwork_service.dart';
import 'package:flutter_ibeacon_recorder/services/settings_service.dart';
import 'package:flutter_ibeacon_recorder/services/beacon_service.dart';
import 'package:flutter_ibeacon_recorder/services/sensor_service.dart';

class PathRecordingPage extends StatefulWidget {
  const PathRecordingPage({super.key});

  @override
  State<PathRecordingPage> createState() => _PathRecordingPageState();
}

class _PathRecordingPageState extends State<PathRecordingPage> {
  final _artworkService = ArtworkService();
  final _settingsService = SettingsService();
  final _beaconService = BeaconService();
  final _sensorService = SensorService();

  List<Artwork> _selectedPath = [];
  List<RecordingAction> _actions = [];
  bool _isRecording = false;
  int _currentArtworkIndex = 0;
  String _currentAction = 'walking';
  int _remainingSeconds = 0;
  DateTime? _recordingStartTime;
  DateTime? _currentActionStartTime;

  @override
  void initState() {
    super.initState();
    _generateRandomPath();
  }

  Future<void> _generateRandomPath() async {
    final allArtworks = await _artworkService.getArtworks();
    if (allArtworks.isEmpty) return;

    // Generate a random path length between min and max from settings
    final random = Random();
    final minLength = _settingsService.minPathLength;
    final maxLength = _settingsService.maxPathLength;
    final pathLength = minLength + random.nextInt(maxLength - minLength + 1);

    // Shuffle artworks and take the first pathLength items
    final shuffledArtworks = List<Artwork>.from(allArtworks)..shuffle(random);
    setState(() {
      _selectedPath = shuffledArtworks.take(pathLength).toList();
    });
  }

  void _startRecording() {
    final now = DateTime.now();
    setState(() {
      _isRecording = true;
      _currentArtworkIndex = 0;
      _currentAction = 'walking';
      _recordingStartTime = now;
      _currentActionStartTime = now;
      _actions = [
        RecordingAction(
          type: 'walking',
          startTime: now,
          endTime: now, // Will be updated when action changes
        ),
      ];
    });
    // Start sensors and BLE recording
    _beaconService.startScanning();
    _sensorService.startRecording();
  }

  void _changeAction(String newAction) {
    if (_currentAction == newAction) return;
    if (_remainingSeconds > 0) return; // Don't allow changes during countdown

    final now = DateTime.now();
    _endCurrentAction();

    setState(() {
      _currentAction = newAction;
      _actions.add(RecordingAction(
        type: newAction,
        startTime: now,
        endTime: now, // Will be updated when next action starts
        artworkId: newAction == 'standing_at_artwork'
            ? _selectedPath[_currentArtworkIndex].id
            : null,
      ));
    });

    // Only start countdown for standing at artwork
    if (newAction == 'standing_at_artwork') {
      _startArtworkCountdown();
    }
  }

  Future<void> _startArtworkCountdown() async {
    // Generate random recording duration between min and max from settings
    final random = Random();
    final minDuration = _settingsService.minRecordingDuration.round();
    final maxDuration = _settingsService.maxRecordingDuration.round();
    final recordingDuration =
        minDuration + random.nextInt(maxDuration - minDuration + 1);

    setState(() {
      _remainingSeconds = recordingDuration;
    });

    // Start countdown timer
    while (_remainingSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });
    }

    if (!mounted) return;
    _endCurrentAction();

    setState(() {
      _currentAction = 'walking';
      _currentArtworkIndex++;
      if (_currentArtworkIndex < _selectedPath.length) {
        _actions.add(RecordingAction(
          type: 'walking',
          startTime: DateTime.now(),
          endTime: DateTime.now(), // Will be updated when next action starts
        ));
      }
    });
  }

  void _endCurrentAction() {
    if (_currentActionStartTime != null) {
      final now = DateTime.now();
      // Update the end time of the last action
      if (_actions.isNotEmpty) {
        final lastAction = _actions.last;
        _actions[_actions.length - 1] = RecordingAction(
          type: lastAction.type,
          startTime: lastAction.startTime,
          endTime: now,
          artworkId: lastAction.artworkId,
        );
      }
      _currentActionStartTime = now;
    }
  }

  void _finishRecording() {
    _endCurrentAction();
    _beaconService.stopScanning();
    _sensorService.stopRecording();

    // Get sensor and beacon data
    final bleReport = _beaconService.getReport();
    final sensorDetailedReport = _sensorService.getDetailedReport();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingOverviewPage(
          actions: _actions,
          artworks: _selectedPath,
          startTime: _recordingStartTime!,
          endTime: DateTime.now(),
          sensorData: sensorDetailedReport,
          bleData: bleReport,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Path Recording'),
      ),
      body: _isRecording ? _buildRecordingView() : _buildPathOverview(),
    );
  }

  Widget _buildPathOverview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generated Path',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: _selectedPath.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _selectedPath.length,
                      itemBuilder: (context, index) {
                        final artwork = _selectedPath[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  child: Image.asset(
                                    'assets/pictures/${artwork.id}/url_1.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child:
                                              Icon(Icons.image_not_supported),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(artwork.displayTitle),
                                subtitle: Text(
                                  '${artwork.authorName} - ${artwork.room ?? "Unknown Room"}',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedPath.isEmpty ? null : _startRecording,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Start Recording'),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _generateRandomPath,
            child: const Text('Generate New Path'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView() {
    if (_currentArtworkIndex >= _selectedPath.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Recording Complete!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _finishRecording,
              child: const Text('View Summary'),
            ),
          ],
        ),
      );
    }

    final currentArtwork = _selectedPath[_currentArtworkIndex];

    return Column(
      children: [
        // Top half - Navigation and artwork info
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image section - reduced to 2/5 of the space
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    child: Image.asset(
                      'assets/pictures/${currentArtwork.id}/url_1.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Info section - increased to 3/5 of the space
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and step row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14, // Smaller circle
                              child: Text(
                                '${_currentArtworkIndex + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8), // Reduced spacing
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Target',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    currentArtwork.displayTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reduced spacing
                        // Location and artist info
                        Text(
                          'Location: ${currentArtwork.room ?? "Unknown Room"}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4), // Reduced spacing
                        Text(
                          'Artist: ${currentArtwork.authorName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_currentAction == 'standing_at_artwork' &&
                            _remainingSeconds > 0) ...[
                          const Spacer(),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom action buttons section
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Action',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_currentAction == 'standing_at_artwork' &&
                  _remainingSeconds > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Recording: ${_formatDuration(_remainingSeconds)}',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.directions_walk),
                          SizedBox(width: 8),
                          Text('Walking'),
                        ],
                      ),
                      value: 'walking',
                      groupValue: _currentAction,
                      onChanged: _remainingSeconds > 0
                          ? null
                          : (value) => _changeAction(value!),
                    ),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.accessibility_new),
                          SizedBox(width: 8),
                          Text('Standing'),
                        ],
                      ),
                      value: 'standing',
                      groupValue: _currentAction,
                      onChanged: _remainingSeconds > 0
                          ? null
                          : (value) => _changeAction(value!),
                    ),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.chair),
                          SizedBox(width: 8),
                          Text('Sitting'),
                        ],
                      ),
                      value: 'sitting',
                      groupValue: _currentAction,
                      onChanged: _remainingSeconds > 0
                          ? null
                          : (value) => _changeAction(value!),
                    ),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.pin_drop),
                          SizedBox(width: 8),
                          Text('At Point of Interest'),
                        ],
                      ),
                      value: 'standing_at_artwork',
                      groupValue: _currentAction,
                      onChanged: _remainingSeconds > 0
                          ? null
                          : (value) => _changeAction(value!),
                      tileColor: _currentAction == 'standing_at_artwork' &&
                              _remainingSeconds > 0
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _beaconService.stopScanning();
                  _sensorService.stopRecording();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Recording'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (_isRecording) {
      _beaconService.stopScanning();
      _sensorService.stopRecording();
    }
    super.dispose();
  }
}
