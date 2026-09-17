// اختبار حي (يدوي) ضد license.json الفعلي على GitHub — يُشغَّل عند الحاجة:
//   flutter test test/live_license_test.dart --run-skipped
// يقرأ الملف الحقيقي بلا Mock ويطبع الحالة.
@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeco_market/security/license_gate.dart';

void main() {
  test('live: read real license.json from GitHub', () async {
    SharedPreferences.setMockInitialValues({});
    final v = await LicenseGate.check();
    // ignore: avoid_print
    print('LIVE → state=${v.state.name} offline=${v.offline} message="${v.message}"');
    expect(v.offline, isFalse, reason: 'يجب أن يصل إلى GitHub');
    if (v.state == LicenseState.locked) {
      // ignore: avoid_print
      print('LIVE → unlock WRONG = ${await LicenseGate.unlock('WRONG')}');
      // ignore: avoid_print
      print('LIVE → unlock YECO-2026 = ${await LicenseGate.unlock('YECO-2026')}');
      final again = await LicenseGate.check();
      // ignore: avoid_print
      print('LIVE → after unlock state=${again.state.name}');
    }
  }, skip: true);
}
