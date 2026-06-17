import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentos_mobile/main.dart';
import 'package:parentos_mobile/providers/auth_provider.dart';
import 'package:parentos_mobile/services/token_storage.dart';

class _InMemorySecureStorage extends FlutterSecureStoragePlatform {
  final Map<String, String> _data = {};

  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async =>
      _data.containsKey(key);

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _data.clear();
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async => _data[key];

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async => Map.of(_data);

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    _data[key] = value;
  }
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = _InMemorySecureStorage();
  });

  testWidgets('Unauthenticated user lands on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(TokenStorage())],
        child: const ParentOSApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsWidgets);
  });
}
