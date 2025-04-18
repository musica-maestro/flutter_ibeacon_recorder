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
