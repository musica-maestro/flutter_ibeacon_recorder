import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final _deviceInfoPlugin = DeviceInfoPlugin();

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return {
          'platform': 'iOS',
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'utsname': {
            'sysname': iosInfo.utsname.sysname,
            'nodename': iosInfo.utsname.nodename,
            'release': iosInfo.utsname.release,
            'version': iosInfo.utsname.version,
            'machine': iosInfo.utsname.machine,
          },
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return {
          'platform': 'Android',
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'product': androidInfo.product,
          'version': {
            'sdkInt': androidInfo.version.sdkInt,
            'release': androidInfo.version.release,
            'codename': androidInfo.version.codename,
          },
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'androidId': androidInfo.id,
        };
      }
      return {
        'error': 'Unsupported platform',
        'platform': Platform.operatingSystem,
      };
    } catch (e) {
      print('Error getting device info: $e');
      return {
        'error': 'Failed to get device info',
        'platform': Platform.operatingSystem,
        'errorMessage': e.toString(),
      };
    }
  }
}
