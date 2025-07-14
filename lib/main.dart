import 'package:easy_vahan/services/auth_services.dart';
import 'package:easy_vahan/services/navigation_service.dart';
import 'package:easy_vahan/utils.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await setupFirebase();
    print('Firebase initialization completed');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue with app initialization even if Firebase fails
  }
  
  // Run the app
  runApp(
    MaterialApp(
      home: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // Show error UI if initialization failed
              return Scaffold(
                body: Center(
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }
            // Return the main app if initialization was successful
            return MyApp();
          }
          // Show a loading indicator while initializing
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    await registerServices();
    print('App services initialized');
  } catch (e) {
    print('Error initializing app services: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key) {
    _getIt = GetIt.instance;
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
  }

  late final GetIt _getIt;
  late final NavigationService _navigationService;
  late final AuthService _authService;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigationService.navigatorKey,
      title: 'Easy Wahan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      initialRoute: "/login",
      routes: _navigationService.routes,
    );
  }
}
