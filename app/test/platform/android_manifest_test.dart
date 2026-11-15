import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// `flutter test`는 app/ 폴더에서 돌므로 상대 경로로 네이티브 설정 파일을 읽는다.
String _read(String path) => File(path).readAsStringSync();

void main() {
  test(
    'android manifest points to rules that exclude cloud backup and device transfer',
    () {
      final manifest = _read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      // API 26~30은 dataExtractionRules를 읽지 않고 이 값이 백업을 막는다.
      expect(manifest, contains('android:allowBackup="false"'));

      final rules = _read(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      );
      final cloud = RegExp(
        r'<cloud-backup[^>]*>(.*?)</cloud-backup>',
        dotAll: true,
      ).firstMatch(rules);
      final transfer = RegExp(
        r'<device-transfer[^>]*>(.*?)</device-transfer>',
        dotAll: true,
      ).firstMatch(rules);
      expect(cloud, isNotNull);
      expect(transfer, isNotNull);
      for (final section in [cloud!.group(1)!, transfer!.group(1)!]) {
        // 모든 도메인을 뺀다. root/file/database/sharedpref/external 모두 해당한다.
        for (final domain in const [
          'root',
          'file',
          'database',
          'sharedpref',
          'external',
          'device_root',
          'device_file',
          'device_database',
          'device_sharedpref',
        ]) {
          expect(
            section,
            contains('<exclude domain="$domain"'),
            reason: '$domain 도메인이 빠지지 않았다',
          );
        }
        expect(section, isNot(contains('<include')));
      }
    },
  );

  test('app name is Cora on both platforms', () {
    expect(
      _read('android/app/src/main/AndroidManifest.xml'),
      contains('android:label="Cora"'),
    );
    final plist = _read('ios/Runner/Info.plist');
    expect(
      plist,
      matches(RegExp(r'<key>CFBundleName</key>\s*<string>Cora</string>')),
    );
    expect(
      plist,
      matches(
        RegExp(r'<key>CFBundleDisplayName</key>\s*<string>Cora</string>'),
      ),
    );
  });
}
