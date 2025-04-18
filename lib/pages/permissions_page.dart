import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:app_settings/app_settings.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final Map<String, bool> _permissionStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() {
      _loading = true;
    });

    // Common permissions
    final Map<String, bool> permissions = {};

    if (Platform.isAndroid) {
      // Android specific permissions
      permissions['Location'] = await Permission.location.isGranted;
      permissions['Location Always'] =
          await Permission.locationAlways.isGranted;
      permissions['Bluetooth Scan'] = await Permission.bluetoothScan.isGranted;
      permissions['Bluetooth Connect'] =
          await Permission.bluetoothConnect.isGranted;
      permissions['Bluetooth Advertise'] =
          await Permission.bluetoothAdvertise.isGranted;
      permissions['Sensors'] = await Permission.sensors.isGranted;

      // Check if Bluetooth is enabled
      try {
        final bluetoothState = await flutterBeacon.bluetoothState;
        permissions['Bluetooth Enabled'] =
            bluetoothState == BluetoothState.stateOn;
      } catch (e) {
        permissions['Bluetooth Enabled'] = false;
      }

      // Check if Location Services are enabled
      try {
        permissions['Location Services'] =
            await flutterBeacon.checkLocationServicesIfEnabled;
      } catch (e) {
        permissions['Location Services'] = false;
      }
    } else if (Platform.isIOS) {
      // iOS specific checks
      // Check beacon authorization
      try {
        final authStatus = await flutterBeacon.authorizationStatus;
        permissions['Location Authorization'] =
            authStatus == AuthorizationStatus.allowed ||
                authStatus == AuthorizationStatus.always;
      } catch (e) {
        permissions['Location Authorization'] = false;
      }

      // Check if Bluetooth is enabled
      try {
        final bluetoothState = await flutterBeacon.bluetoothState;
        permissions['Bluetooth Enabled'] =
            bluetoothState == BluetoothState.stateOn;
      } catch (e) {
        permissions['Bluetooth Enabled'] = false;
      }

      // Check if Location Services are enabled
      try {
        permissions['Location Services'] =
            await flutterBeacon.checkLocationServicesIfEnabled;
      } catch (e) {
        permissions['Location Services'] = false;
      }
    }

    setState(() {
      _permissionStatus.clear();
      _permissionStatus.addAll(permissions);
      _loading = false;
    });
  }

  Future<void> _requestPermission(String permission) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      switch (permission) {
        case 'Location':
          status = await Permission.location.request();
          break;
        case 'Location Always':
          status = await Permission.locationAlways.request();
          break;
        case 'Bluetooth Scan':
          status = await Permission.bluetoothScan.request();
          break;
        case 'Bluetooth Connect':
          status = await Permission.bluetoothConnect.request();
          break;
        case 'Bluetooth Advertise':
          status = await Permission.bluetoothAdvertise.request();
          break;
        case 'Bluetooth Enabled':
          await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
          status = PermissionStatus.granted; // Just to avoid errors
          break;
        case 'Location Services':
          await AppSettings.openAppSettings(type: AppSettingsType.location);
          status = PermissionStatus.granted; // Just to avoid errors
          break;
        case 'Sensors':
          status = await Permission.sensors.request();
          break;
        default:
          status = PermissionStatus.denied;
      }
    } else if (Platform.isIOS) {
      switch (permission) {
        case 'Location Authorization':
          await flutterBeacon.requestAuthorization;
          status = PermissionStatus.granted; // Just to avoid errors
          break;
        case 'Bluetooth Enabled':
          await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
          status = PermissionStatus.granted; // Just to avoid errors
          break;
        case 'Location Services':
          await AppSettings.openAppSettings(type: AppSettingsType.location);
          status = PermissionStatus.granted; // Just to avoid errors
          break;
        default:
          status = PermissionStatus.denied;
      }
    } else {
      status = PermissionStatus.denied;
    }

    // Give a short delay for settings to update
    await Future.delayed(const Duration(seconds: 1));
    await _checkAllPermissions();
  }

  bool get allPermissionsGranted =>
      _permissionStatus.isNotEmpty &&
      _permissionStatus.values.every((granted) => granted);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllPermissions,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      const Text(
                        'The app requires the following permissions to function properly:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ..._permissionStatus.entries
                          .map((entry) => _buildPermissionTile(
                                entry.key,
                                entry.value,
                              )),
                    ],
                  ),
                ),
                if (allPermissionsGranted)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPermissionTile(String title, bool isGranted) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle : Icons.error,
          color: isGranted ? Colors.green : Colors.red,
          size: 28,
        ),
        title: Text(title),
        subtitle: Text(isGranted ? 'Granted' : 'Not Granted'),
        trailing: !isGranted
            ? TextButton(
                onPressed: () => _requestPermission(title),
                child: const Text('Request'),
              )
            : null,
      ),
    );
  }
}
