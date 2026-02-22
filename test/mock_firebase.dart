import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseCoreMocksPlatform();
}

void setupFirebaseCoreMocksPlatform() {
  final platformApp = FirebaseAppPlatform(
    '[DEFAULT]',
    const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: 'test-app-id',
      messagingSenderId: 'test-sender-id',
      projectId: 'test-project-id',
    ),
  );

  final mock = MockFirebasePlatform(platformApp);
  FirebasePlatform.instance = mock;
}

class MockFirebasePlatform extends FirebasePlatform {
  final FirebaseAppPlatform _app;

  MockFirebasePlatform(this._app);

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return _app;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _app;
  }

  @override
  List<FirebaseAppPlatform> get apps => [_app];
}
