import 'package:easy_vahan/firebase_options.dart';
import 'package:easy_vahan/services/alert_service.dart';
import 'package:easy_vahan/services/auth_services.dart';
import 'package:easy_vahan/services/media_service.dart';
import 'package:easy_vahan/services/navigation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

Future<void> setupFirebase() async {
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isNotEmpty) {
      print('Firebase already initialized');
      return;
    }
    
    // Initialize Firebase with the default app
    await Firebase.initializeApp(
      name: 'EasyVahan',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // If the default app already exists, try to get it
      print('Default Firebase app already exists, using existing instance');
      await Firebase.app();
    } else {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }
}

Future<void> registerServices() async {
  final GetIt getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(
    AuthService(),
  );
  getIt.registerSingleton<NavigationService>(
    NavigationService(),
  );
  getIt.registerSingleton<AlertService>(
    AlertService(),
  );
  getIt.registerSingleton<MediaService>(
    MediaService(),
  );
}
