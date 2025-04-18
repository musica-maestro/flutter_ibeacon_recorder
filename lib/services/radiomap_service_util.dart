import 'dart:math';

class RadiomapServiceUtil {
  /// Returns the minimum RSSI value found in the radiomap
  static double getMinRssi(List<Map<String, dynamic>> radiomap,
      {String stanzaColumn = 'stanza', String labelColumn = 'label'}) {
    if (radiomap.isEmpty) return -100.0;

    double minRssi = double.infinity;
    for (var point in radiomap) {
      for (var entry in point.entries) {
        if (entry.key != labelColumn && entry.key != stanzaColumn) {
          minRssi = min(minRssi, entry.value as double);
        }
      }
    }
    return minRssi;
  }

  /// Returns the most common RSSI value in the radiomap
  static double getDefaultNonDetected(List<Map<String, dynamic>> radiomap,
      {String stanzaColumn = 'stanza', String labelColumn = 'label'}) {
    if (radiomap.isEmpty) return -100.0;

    Map<double, int> valueCounts = {};
    for (var point in radiomap) {
      for (var entry in point.entries) {
        if (entry.key != labelColumn && entry.key != stanzaColumn) {
          double value = entry.value as double;
          valueCounts[value] = (valueCounts[value] ?? 0) + 1;
        }
      }
    }

    return valueCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Returns a value one less than the minimum RSSI value
  static double getNewNonDetected(List<Map<String, dynamic>> radiomap,
      {String stanzaColumn = 'stanza', String labelColumn = 'label'}) {
    return getMinRssi(radiomap,
            stanzaColumn: stanzaColumn, labelColumn: labelColumn) -
        1;
  }

  /// Transforms the radiomap by replacing occurrences of oldNull with newNull
  static List<Map<String, dynamic>> transformNewNonDetected(
      List<Map<String, dynamic>> radiomap, double oldNull, double newNull,
      {String stanzaColumn = 'stanza', String labelColumn = 'label'}) {
    List<Map<String, dynamic>> transformedData = [];

    for (var point in radiomap) {
      Map<String, dynamic> newPoint = {};
      point.forEach((key, value) {
        if (key == labelColumn || key == stanzaColumn) {
          newPoint[key] = value;
        } else {
          newPoint[key] = (value as double) == oldNull ? newNull : value;
        }
      });
      transformedData.add(newPoint);
    }

    return transformedData;
  }

  /// Transform RSSI values by subtracting the minimum RSSI
  static List<Map<String, dynamic>> transformRssiPositive(
      List<Map<String, dynamic>> radiomap, double minRssi,
      {String stanzaColumn = 'stanza', String labelColumn = 'label'}) {
    List<Map<String, dynamic>> transformedData = [];

    for (var point in radiomap) {
      Map<String, dynamic> newPoint = {};
      point.forEach((key, value) {
        if (key == labelColumn || key == stanzaColumn) {
          newPoint[key] = value;
        } else {
          newPoint[key] = (value as double) - minRssi;
        }
      });
      transformedData.add(newPoint);
    }

    return transformedData;
  }

  /// Transform RSSI values using an exponential function
  static List<Map<String, dynamic>> transformRssiExponential(
      List<Map<String, dynamic>> radiomap, double minRssi,
      {double alpha = 24,
      String stanzaColumn = 'stanza',
      String labelColumn = 'label'}) {
    List<Map<String, dynamic>> transformedData = [];
    double baseNormalizer = exp(-minRssi / alpha);

    for (var point in radiomap) {
      Map<String, dynamic> newPoint = {};
      point.forEach((key, value) {
        if (key == labelColumn || key == stanzaColumn) {
          newPoint[key] = value;
        } else {
          double rssi = value as double;
          newPoint[key] = exp((rssi - minRssi) / alpha) / baseNormalizer;
        }
      });
      transformedData.add(newPoint);
    }

    return transformedData;
  }
}
