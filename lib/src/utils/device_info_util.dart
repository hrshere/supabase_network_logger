import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoUtil {
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return {
        'os': 'Android',
        'version': android.version.release,
        'model': android.model,
        'brand': android.brand,
      };
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return {
        'os': 'iOS',
        'version': ios.systemVersion,
        'model': ios.utsname.machine,
        'name': ios.name,
      };
    }
    return {'os': Platform.operatingSystem};
  }

  static Future<Map<String, dynamic>> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'app_name': packageInfo.appName,
      'package_name': packageInfo.packageName,
    };
  }
}
