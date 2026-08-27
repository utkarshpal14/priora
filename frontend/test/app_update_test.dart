import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/app_version_model.dart';
import 'package:frontend/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService Semantic Version Comparison (ENH-006 / TS-008)', () {
    test('Should return true when latest version is strictly higher (major/minor/patch)', () {
      expect(AppUpdateService.isUpdateAvailable('1.0.0', '1.1.0'), isTrue);
      expect(AppUpdateService.isUpdateAvailable('1.0.0', '2.0.0'), isTrue);
      expect(AppUpdateService.isUpdateAvailable('1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateService.isUpdateAvailable('1.1.0', '1.1.1'), isTrue);
      expect(AppUpdateService.isUpdateAvailable('1.1.0', '1.2.0'), isTrue);
    });

    test('Should return false when installed version is equal to latest (developer testing)', () {
      expect(AppUpdateService.isUpdateAvailable('1.1.0', '1.1.0'), isFalse);
      expect(AppUpdateService.isUpdateAvailable('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isUpdateAvailable('2.0.0', '2.0.0'), isFalse);
    });

    test('Should return false when installed version is higher than latest (private pre-release build)', () {
      expect(AppUpdateService.isUpdateAvailable('1.2.0', '1.1.0'), isFalse);
      expect(AppUpdateService.isUpdateAvailable('2.0.0', '1.9.9'), isFalse);
    });

    test('Should handle dirty / formatted version strings gracefully', () {
      expect(AppUpdateService.isUpdateAvailable('v1.0.0', 'v1.1.0'), isTrue);
      expect(AppUpdateService.isUpdateAvailable('1.0.0+1', '1.1.0+2'), isTrue);
    });
  });

  group('AppVersionModel Serialization', () {
    test('Should parse JSON payload correctly', () {
      final json = {
        'latest_version': '1.1.0',
        'min_supported_version': '1.0.0',
        'apk_download_url': 'https://example.com/priora.apk',
        'release_notes': '• New sounds\n• Theme sync',
        'force_update': false,
      };

      final model = AppVersionModel.fromJson(json);
      expect(model.latestVersion, '1.1.0');
      expect(model.minSupportedVersion, '1.0.0');
      expect(model.apkDownloadUrl, 'https://example.com/priora.apk');
      expect(model.releaseNotes, contains('New sounds'));
      expect(model.forceUpdate, isFalse);
    });
  });
}
