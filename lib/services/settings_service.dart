import 'dart:async';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal() {
    // Ensure default recording duration is within the range
    if (_recordingDuration < _minRecordingDuration ||
        _recordingDuration > _maxRecordingDuration) {
      _recordingDuration = _minRecordingDuration;
    }

    // Ensure default K value is within the range
    if (_kValue < _minKValue || _kValue > _maxKValue) {
      _kValue = _defaultKValue;
    }
  }

  // Settings values
  double _recordingDuration = 15.0; // Changed to be within initial range
  int _minPathLength = 3;
  int _maxPathLength = 6;
  double _minRecordingDuration = 10.0;
  double _maxRecordingDuration = 30.0;

  // KNN settings
  int _kValue = 5; // Default K value
  final int _minKValue = 1;
  final int _maxKValue = 58;
  final int _defaultKValue = 5;

  // Random mode settings
  double _minRandomDuration = 10.0;
  double _maxRandomDuration = 30.0;

  // Stream controllers for settings changes
  final _recordingDurationController = StreamController<double>.broadcast();
  final _pathLengthController = StreamController<List<int>>.broadcast();
  final _recordingDurationRangeController =
      StreamController<List<double>>.broadcast();
  final _randomDurationRangeController =
      StreamController<List<double>>.broadcast();
  final _kValueController = StreamController<int>.broadcast();

  // Streams
  Stream<double> get recordingDurationStream =>
      _recordingDurationController.stream;
  Stream<List<int>> get pathLengthStream => _pathLengthController.stream;
  Stream<List<double>> get recordingDurationRangeStream =>
      _recordingDurationRangeController.stream;
  Stream<List<double>> get randomDurationRangeStream =>
      _randomDurationRangeController.stream;
  Stream<int> get kValueStream => _kValueController.stream;

  // Getters
  double get recordingDuration => _recordingDuration;
  int get minPathLength => _minPathLength;
  int get maxPathLength => _maxPathLength;
  double get minRecordingDuration => _minRecordingDuration;
  double get maxRecordingDuration => _maxRecordingDuration;
  double get minRandomDuration => _minRandomDuration;
  double get maxRandomDuration => _maxRandomDuration;

  // KNN getters
  int get kValue => _kValue;
  int get minKValue => _minKValue;
  int get maxKValue => _maxKValue;

  // Setters
  void setRecordingDuration(double duration) {
    if (duration >= _minRecordingDuration &&
        duration <= _maxRecordingDuration) {
      _recordingDuration = duration;
      _recordingDurationController.add(duration);
    }
  }

  void setPathLengthRange(int min, int max) {
    if (min <= max && min >= 2 && max <= 10) {
      _minPathLength = min;
      _maxPathLength = max;
      _pathLengthController.add([min, max]);
    }
  }

  void setRecordingDurationRange(double min, double max) {
    if (min <= max && min >= 5 && max <= 60) {
      _minRecordingDuration = min;
      _maxRecordingDuration = max;
      // Adjust default duration if needed
      if (_recordingDuration < min) {
        setRecordingDuration(min);
      } else if (_recordingDuration > max) {
        setRecordingDuration(max);
      }
      _recordingDurationRangeController.add([min, max]);
    }
  }

  void setRandomDurationRange(double min, double max) {
    if (min <= max && min >= 5 && max <= 60) {
      _minRandomDuration = min;
      _maxRandomDuration = max;
      _randomDurationRangeController.add([min, max]);
    }
  }

  // KNN setter
  void setKValue(int k) {
    if (k >= _minKValue && k <= _maxKValue) {
      _kValue = k;
      _kValueController.add(k);
    }
  }

  void dispose() {
    _recordingDurationController.close();
    _pathLengthController.close();
    _recordingDurationRangeController.close();
    _randomDurationRangeController.close();
    _kValueController.close();
  }
}
