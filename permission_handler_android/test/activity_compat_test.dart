import 'package:flutter/services.dart';
import 'package:flutter_instance_manager/flutter_instance_manager.dart';
import 'package:flutter_instance_manager/test/test_instance_manager.pigeon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_android/permission_handler_android.dart';
import 'package:permission_handler_android/src/android_object_mirrors/package_manager.dart';
import 'package:permission_handler_android/src/android_permission_handler_api_impls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<List<Object?>> requestLog;
  late final MockTestInstanceManagerHostApi mockInstanceManagerHostApi;

  setUpAll(() {
    mockInstanceManagerHostApi = MockTestInstanceManagerHostApi();
    TestInstanceManagerHostApi.setup(mockInstanceManagerHostApi);
  });

  setUp(() {
    requestLog = <List<Object?>>[];
  });

  tearDown(() {
    TestInstanceManagerHostApi.setup(null);
  });

  group('shouldShowRationale', () {
    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'dev.flutter.pigeon.permission_handler_android.ActivityCompatHostApi.shouldShowRequestPermissionRationale',
        (ByteData? message) async {
          const MessageCodec codec = StandardMessageCodec();

          final List<Object?> request = codec.decodeMessage(message);
          requestLog.add(request);

          final response = [true];
          return codec.encodeMessage(response);
        },
      );
    });

    test('returns properly', () async {
      // > Arrange
      final instanceManager = InstanceManager(
        onWeakReferenceRemoved: (_) {},
      );
      ActivityCompat.api = ActivityCompatHostApiImpl(
        instanceManager: instanceManager,
      );
      final activity = Activity.detached();
      instanceManager.addHostCreatedInstance(
        activity,
        'activity_instance_id',
      );

      // > Act
      final shouldShowRequestPermissionRationale =
          await ActivityCompat.shouldShowRequestPermissionRationale(
        activity,
        Manifest.permission.readCalendar,
      );

      // > Assert
      expect(
        requestLog,
        [
          [
            'activity_instance_id',
            'android.permission.READ_CALENDAR',
          ],
        ],
      );
      expect(shouldShowRequestPermissionRationale, isTrue);
    });
  });

  group('checkPermissionStatus', () {
    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'dev.flutter.pigeon.permission_handler_android.ActivityCompatHostApi.checkSelfPermission',
        (ByteData? message) async {
          const MessageCodec codec = StandardMessageCodec();

          final List<Object?> request = codec.decodeMessage(message);
          requestLog.add(request);

          final response = [PackageManager.permissionGranted];
          return codec.encodeMessage(response);
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'dev.flutter.pigeon.permission_handler_android.ActivityCompatHostApi.shouldShowRequestPermissionRationale',
        (ByteData? message) async {
          const MessageCodec codec = StandardMessageCodec();

          final response = [true];
          return codec.encodeMessage(response);
        },
      );
    });

    test('returns properly', () async {
      // > Arrange
      final instanceManager = InstanceManager(
        onWeakReferenceRemoved: (_) {},
      );
      ActivityCompat.api = ActivityCompatHostApiImpl(
        instanceManager: instanceManager,
      );
      final activity = Activity.detached();
      instanceManager.addHostCreatedInstance(
        activity,
        'activity_instance_id',
      );

      SharedPreferences.setMockInitialValues({
        Manifest.permission.readCalendar: true,
      });

      // > Act
      final permissionStatus = await ActivityCompat.checkSelfPermission(
        activity,
        Manifest.permission.readCalendar,
      );

      // > Assert
      expect(
        requestLog,
        [
          [
            'activity_instance_id',
            'android.permission.READ_CALENDAR',
          ],
        ],
      );
      expect(permissionStatus, PackageManager.permissionGranted);
    });
  });
}
