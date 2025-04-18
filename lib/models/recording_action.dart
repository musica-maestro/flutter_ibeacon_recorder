class RecordingAction {
  final String type; // walking, standing
  final DateTime startTime;
  final DateTime endTime;
  final String? artworkId;

  RecordingAction({
    required this.type,
    required this.startTime,
    required this.endTime,
    this.artworkId,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'artworkId': artworkId,
      'duration': duration.inSeconds,
    };
  }
}
