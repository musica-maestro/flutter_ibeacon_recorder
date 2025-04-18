import 'package:flutter/material.dart';
import 'package:flutter_ibeacon_recorder/services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = SettingsService();
  late RangeValues _pathLengthRange;
  late RangeValues _recordingDurationRange;
  late RangeValues _randomDurationRange;
  late double _defaultRecordingDuration;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _pathLengthRange = RangeValues(
      _settingsService.minPathLength.toDouble(),
      _settingsService.maxPathLength.toDouble(),
    );
    _recordingDurationRange = RangeValues(
      _settingsService.minRecordingDuration,
      _settingsService.maxRecordingDuration,
    );
    _randomDurationRange = RangeValues(
      _settingsService.minRandomDuration,
      _settingsService.maxRandomDuration,
    );
    _defaultRecordingDuration = _settingsService.recordingDuration;
  }

  void _updatePathLengthRange(RangeValues values) {
    setState(() {
      _pathLengthRange = values;
    });
    _settingsService.setPathLengthRange(
      values.start.round(),
      values.end.round(),
    );
  }

  void _updateRecordingDurationRange(RangeValues values) {
    setState(() {
      _recordingDurationRange = values;
      // Ensure default duration stays within the new range
      if (_defaultRecordingDuration < values.start) {
        _defaultRecordingDuration = values.start;
        _settingsService.setRecordingDuration(values.start);
      } else if (_defaultRecordingDuration > values.end) {
        _defaultRecordingDuration = values.end;
        _settingsService.setRecordingDuration(values.end);
      }
    });
    _settingsService.setRecordingDurationRange(
      values.start,
      values.end,
    );
  }

  void _updateDefaultDuration(double value) {
    setState(() {
      _defaultRecordingDuration = value;
    });
    _settingsService.setRecordingDuration(value);
  }

  void _updateRandomDurationRange(RangeValues values) {
    setState(() {
      _randomDurationRange = values;
    });
    _settingsService.setRandomDurationRange(
      values.start,
      values.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Path Length Range Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Path Length Range',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the minimum and maximum number of artworks in a path',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RangeSlider(
                          values: _pathLengthRange,
                          min: 2,
                          max: 10,
                          divisions: 8,
                          labels: RangeLabels(
                            _pathLengthRange.start.round().toString(),
                            _pathLengthRange.end.round().toString(),
                          ),
                          onChanged: _updatePathLengthRange,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${_pathLengthRange.start.round()}-${_pathLengthRange.end.round()} artworks',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Standing Duration Range Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standing Duration Range',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the minimum and maximum duration for standing recordings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RangeSlider(
                          values: _recordingDurationRange,
                          min: 5,
                          max: 60,
                          divisions: 55,
                          labels: RangeLabels(
                            '${_recordingDurationRange.start.round()}s',
                            '${_recordingDurationRange.end.round()}s',
                          ),
                          onChanged: _updateRecordingDurationRange,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${_recordingDurationRange.start.round()}-${_recordingDurationRange.end.round()}s',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Random Duration Range Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Random Duration Range',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the minimum and maximum duration for random recordings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RangeSlider(
                          values: _randomDurationRange,
                          min: 5,
                          max: 60,
                          divisions: 55,
                          labels: RangeLabels(
                            '${_randomDurationRange.start.round()}s',
                            '${_randomDurationRange.end.round()}s',
                          ),
                          onChanged: _updateRandomDurationRange,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${_randomDurationRange.start.round()}-${_randomDurationRange.end.round()}s',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Default Standing Duration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Standing Duration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the default duration for standing recordings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _defaultRecordingDuration,
                          min: _recordingDurationRange.start,
                          max: _recordingDurationRange.end,
                          divisions: (_recordingDurationRange.end -
                                  _recordingDurationRange.start)
                              .round(),
                          label: '${_defaultRecordingDuration.round()}s',
                          onChanged: _updateDefaultDuration,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${_defaultRecordingDuration.round()}s',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
