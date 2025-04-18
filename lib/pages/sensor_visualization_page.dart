import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter_ibeacon_recorder/services/sensor_service.dart';
import 'package:compassx/compassx.dart';
import 'dart:io' show Platform;

class SensorVisualizationPage extends StatefulWidget {
  const SensorVisualizationPage({super.key});

  @override
  State<SensorVisualizationPage> createState() =>
      _SensorVisualizationPageState();
}

class _SensorVisualizationPageState extends State<SensorVisualizationPage>
    with SingleTickerProviderStateMixin {
  final SensorService _sensorService = SensorService();
  final List<SensorRecord> _records = [];
  StreamSubscription? _subscription;
  StreamSubscription<CompassXEvent>? _compassSubscription;
  static const int _maxDataPoints = 30; // Increased for smoother visualization
  Timer? _refreshTimer;
  late final AnimationController _animationController;
  bool _needsUpdate = false;
  final DateTime _startTime = DateTime.now();
  double _compassHeading = 0.0;
  bool _shouldCalibrate = false;
  double _compassAccuracyValue = -1.0; // Default value when accuracy is unknown

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();

    // Update UI at 30 FPS
    _animationController.addListener(_onAnimationTick);

    _startListening();

    // Listen to CompassX events directly for better accuracy information
    _compassSubscription = CompassX.events.listen((event) {
      setState(() {
        _compassHeading = event.heading;
        _shouldCalibrate = event.shouldCalibrate;

        // Store the numeric accuracy value for proper display
        // On iOS, this is in degrees. On Android, it depends on the sensor
        _compassAccuracyValue = event.accuracy;
      });
    });
  }

  void _onAnimationTick() {
    if (_needsUpdate) {
      setState(() {
        _needsUpdate = false;
      });
    }
  }

  void _startListening() {
    _subscription = _sensorService.sensorStream.listen((record) {
      _records.add(record);
      if (_records.length > _maxDataPoints) {
        _records.removeAt(0);
      }
      _needsUpdate = true;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _compassSubscription?.cancel();
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPlot(
      String title, List<List<FlSpot>> spots, List<Color> colors) {
    // Calculate min and max values for proper scaling
    double? minY, maxY;
    for (var spotList in spots) {
      for (var spot in spotList) {
        if (minY == null || maxY == null) {
          minY = spot.y;
          maxY = spot.y;
        } else {
          minY = minY < spot.y ? minY : spot.y;
          maxY = maxY > spot.y ? maxY : spot.y;
        }
      }
    }

    // If no data points, use default range
    if (minY == null || maxY == null) {
      minY = -1.0;
      maxY = 1.0;
    }

    // Add 10% padding to the range
    final range = (maxY - minY).abs();
    minY -= range * 0.1;
    maxY += range * 0.1;

    // Get current values
    List<double> currentValues = [0, 0, 0];
    if (spots.isNotEmpty && spots[0].isNotEmpty) {
      for (int i = 0; i < spots.length; i++) {
        if (spots[i].isNotEmpty) {
          currentValues[i] = spots[i].last.y;
        }
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              // Make chart wider for better visibility
              width: 600,
              child: RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: range / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: range / 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _maxDataPoints / 5,
                          getTitlesWidget: (value, meta) {
                            final time = _startTime.add(
                              Duration(milliseconds: (value * 100).toInt()),
                            );
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                _formatTime(time),
                                style: const TextStyle(fontSize: 8),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    ),
                    lineBarsData: [
                      for (int i = 0; i < spots.length; i++)
                        LineChartBarData(
                          spots: spots[i],
                          isCurved: true,
                          color: colors[i],
                          barWidth: 2,
                          dotData: FlDotData(
                            show: false,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 2,
                                color: colors[i],
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colors[i].withOpacity(0.1),
                          ),
                        ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.black.withOpacity(0.8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(3)}',
                              TextStyle(color: spot.bar.color),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: Duration.zero,
                ),
              ),
            ),
          ),
        ),
        // Current values display
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < 3; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${[
                        'X',
                        'Y',
                        'Z'
                      ][i]}: ${currentValues[i].toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors[i],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompass() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Compass',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Container(
              width: 250, // Fixed width for the compass
              height: 250, // Fixed height for the compass
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // Compass dial with North, East, South, West labels
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CompassPainter(),
                      ),
                    ),
                    // Compass needle
                    Center(
                      child: Transform.rotate(
                        angle: _compassHeading * (math.pi / 180),
                        child: Container(
                          width: 4,
                          height: double.infinity,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 80,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Calibration message if needed
                    if (_shouldCalibrate)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.red.withOpacity(0.7),
                          child: const Text(
                            'Please calibrate! Move in figure 8 pattern',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Heading: ${_compassHeading.toStringAsFixed(1)}°',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_getHeadingDirection(_compassHeading)} | ${_getAccuracyText()}',
          style: TextStyle(
            fontSize: 12,
            color: _getAccuracyColor(),
          ),
        ),
      ],
    );
  }

  String _getHeadingDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return directions[(((heading + 22.5) % 360) / 45).floor()];
  }

  // Get accuracy text based on platform specific values
  String _getAccuracyText() {
    if (Platform.isIOS) {
      // On iOS, accuracy is in degrees (headingAccuracy)
      if (_compassAccuracyValue < 0) {
        return 'Accuracy: Unknown';
      } else if (_compassAccuracyValue <= 5) {
        return 'Accuracy: High (±${_compassAccuracyValue.toStringAsFixed(1)}°)';
      } else if (_compassAccuracyValue <= 15) {
        return 'Accuracy: Medium (±${_compassAccuracyValue.toStringAsFixed(1)}°)';
      } else {
        return 'Accuracy: Low (±${_compassAccuracyValue.toStringAsFixed(1)}°)';
      }
    } else {
      // On Android, accuracy is based on sensor status
      if (_shouldCalibrate) {
        return 'Accuracy: Needs Calibration';
      } else {
        return 'Accuracy: Good';
      }
    }
  }

  Color _getAccuracyColor() {
    if (Platform.isIOS) {
      if (_compassAccuracyValue < 0) {
        return Colors.grey;
      } else if (_compassAccuracyValue <= 5) {
        return Colors.green;
      } else if (_compassAccuracyValue <= 15) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    } else {
      // On Android
      return _shouldCalibrate ? Colors.red : Colors.green;
    }
  }

  List<List<FlSpot>> _getSpots(
      vector.Vector3? Function(SensorRecord) getValue) {
    List<List<FlSpot>> allSpots = [[], [], []]; // X, Y, Z
    if (_records.isEmpty) return allSpots;

    // Use stride to reduce number of points
    final stride = 1;
    final startIdx =
        _records.length > _maxDataPoints ? _records.length - _maxDataPoints : 0;

    for (int i = startIdx; i < _records.length; i += stride) {
      final value = getValue(_records[i]);
      if (value != null) {
        final idx = (i - startIdx) / stride;
        allSpots[0].add(FlSpot(idx.toDouble(), value.x));
        allSpots[1].add(FlSpot(idx.toDouble(), value.y));
        allSpots[2].add(FlSpot(idx.toDouble(), value.z));
      }
    }
    return allSpots;
  }

  @override
  Widget build(BuildContext context) {
    final accelerometerData = _getSpots((r) => r.accelerometer);
    final gyroscopeData = _getSpots((r) => r.gyroscope);
    final magnetometerData = _getSpots((r) => r.magnetometer);

    final accelerometerColors = [
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.blue.shade400
    ];

    final gyroscopeColors = [
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.cyan.shade400
    ];

    final magnetometerColors = [
      Colors.pink.shade400,
      Colors.yellow.shade700,
      Colors.teal.shade400
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Visualization'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accelerometer
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _buildPlot(
                        'Accelerometer (m/s²)',
                        accelerometerData,
                        accelerometerColors,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Gyroscope
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _buildPlot(
                        'Gyroscope (rad/s)',
                        gyroscopeData,
                        gyroscopeColors,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Magnetometer
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _buildPlot(
                        'Magnetometer (µT)',
                        magnetometerData,
                        magnetometerColors,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Compass
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: _buildCompass(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for compass dial
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw outer circle
    canvas.drawCircle(center, radius - 10, paint);

    // Draw crosshairs
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 20),
      Offset(center.dx, center.dy + radius - 20),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius + 20, center.dy),
      Offset(center.dx + radius - 20, center.dy),
      paint,
    );

    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * math.pi / 180;
      final x = center.dx + (radius - 25) * math.sin(angle);
      final y = center.dy - (radius - 25) * math.cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directions[i] == 'N' ? Colors.red : Colors.black,
          fontSize: 16,
          fontWeight:
              directions[i] == 'N' ? FontWeight.bold : FontWeight.normal,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw angle marks
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final outerX = center.dx + (radius - 10) * math.sin(angle);
      final outerY = center.dy - (radius - 10) * math.cos(angle);

      final innerX =
          center.dx + (radius - (i % 3 == 0 ? 20 : 15)) * math.sin(angle);
      final innerY =
          center.dy - (radius - (i % 3 == 0 ? 20 : 15)) * math.cos(angle);

      canvas.drawLine(
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        paint..strokeWidth = i % 3 == 0 ? 1.5 : 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) => false;
}
