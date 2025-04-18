import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ibeacon_recorder/pages/path_recording_page.dart';
import 'package:flutter_ibeacon_recorder/pages/permissions_page.dart';
import 'package:flutter_ibeacon_recorder/pages/sensor_check_page.dart';
import 'package:flutter_ibeacon_recorder/pages/sensor_visualization_page.dart';
import 'package:flutter_ibeacon_recorder/pages/settings_page.dart';
import 'package:flutter_ibeacon_recorder/pages/standing_recording_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix orientation to portrait for better compass reading
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Request all required permissions at startup
  await _requestRequiredPermissions();

  runApp(const MyApp());
}

Future<void> _requestRequiredPermissions() async {
  if (Platform.isAndroid) {
    // For Android, request all necessary permissions
    await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.sensors,
    ].request();

    // Initialize flutter_beacon for Android
    try {
      await flutterBeacon.initializeScanning;
      print('FlutterBeacon initialized successfully on Android');
    } catch (e) {
      print('Failed to initialize FlutterBeacon on Android: $e');
    }
  } else if (Platform.isIOS) {
    // For iOS, use flutter_beacon to request authorization
    try {
      // Request authorization for beacon scanning
      await flutterBeacon.requestAuthorization;

      // Check if Bluetooth is enabled
      final bluetoothState = await flutterBeacon.bluetoothState;
      if (bluetoothState != BluetoothState.stateOn) {
        print('Bluetooth is not enabled on iOS. Please enable Bluetooth.');
      }

      // Check if location services are enabled
      final locationEnabled =
          await flutterBeacon.checkLocationServicesIfEnabled;
      if (!locationEnabled) {
        print(
            'Location services are not enabled on iOS. Please enable location services.');
      }

      print('Permissions requested successfully on iOS');
    } catch (e) {
      print('Failed to request permissions on iOS: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Museum Radiomap Recorder',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.red.shade700,
          background: Colors.black,
          surface: Colors.grey.shade900,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey.shade900,
        useMaterial3: true,
      ),
      // Define routes for navigation
      routes: {
        '/': (context) => const HomePageWrapper(),
        '/settings': (context) => const SettingsPage(),
        '/permissions': (context) => const PermissionsPage(),
      },
      initialRoute: '/',
    );
  }
}

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  bool _permissionsChecked = false;
  bool _hasAllPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final Map<String, bool> permissionsMap = {};

    if (Platform.isAndroid) {
      permissionsMap['Location'] = await Permission.location.isGranted;
      permissionsMap['Bluetooth Scan'] =
          await Permission.bluetoothScan.isGranted;
      permissionsMap['Bluetooth Connect'] =
          await Permission.bluetoothConnect.isGranted;

      // Check if Bluetooth is enabled
      try {
        final bluetoothState = await flutterBeacon.bluetoothState;
        permissionsMap['Bluetooth Enabled'] =
            bluetoothState == BluetoothState.stateOn;
      } catch (e) {
        permissionsMap['Bluetooth Enabled'] = false;
      }

      // Check if Location Services are enabled
      try {
        permissionsMap['Location Services'] =
            await flutterBeacon.checkLocationServicesIfEnabled;
      } catch (e) {
        permissionsMap['Location Services'] = false;
      }
    } else if (Platform.isIOS) {
      // Check authorization status
      try {
        final authStatus = await flutterBeacon.authorizationStatus;
        permissionsMap['Authorization'] =
            authStatus == AuthorizationStatus.allowed ||
                authStatus == AuthorizationStatus.always;
      } catch (e) {
        permissionsMap['Authorization'] = false;
      }

      // Check if Bluetooth is enabled
      try {
        final bluetoothState = await flutterBeacon.bluetoothState;
        permissionsMap['Bluetooth'] = bluetoothState == BluetoothState.stateOn;
      } catch (e) {
        permissionsMap['Bluetooth'] = false;
      }

      // Check if Location Services are enabled
      try {
        permissionsMap['Location'] =
            await flutterBeacon.checkLocationServicesIfEnabled;
      } catch (e) {
        permissionsMap['Location'] = false;
      }
    }

    final hasAll = permissionsMap.isNotEmpty &&
        permissionsMap.values.every((granted) => granted);

    setState(() {
      _permissionsChecked = true;
      _hasAllPermissions = hasAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasAllPermissions) {
      // Navigate to permissions page after the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamed('/permissions')
            .then((_) => _checkPermissions());
      });
    }

    return const HomePage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Museum Radiomap Recorder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          // Add a permissions check button
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              Navigator.pushNamed(context, '/permissions');
            },
            tooltip: 'Check Permissions',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMenuButton(
              context,
              'Standing Recording',
              'Record data while standing still',
              Icons.location_on,
              const StandingRecordingPage(),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Path Recording',
              'Record data while walking',
              Icons.timeline,
              const PathRecordingPage(),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Sensor & Beacon Check',
              'Test sensors and beacons',
              Icons.sensors,
              const SensorCheckPage(),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Sensor Visualization',
              'View real-time sensor data plots',
              Icons.show_chart,
              const SensorVisualizationPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, String subtitle,
      IconData icon, Widget page) {
    return Card(
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}
