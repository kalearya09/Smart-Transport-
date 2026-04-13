/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/route_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox token — replace with your real token
  MapboxOptions.setAccessToken('pk.YOUR_MAPBOX_PUBLIC_TOKEN_HERE');

  // Firebase
  await Firebase.initializeApp();

  // Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('favorites');

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const SmartTransportApp());
}

class SmartTransportApp extends StatelessWidget {
  const SmartTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, tp, __) => GetMaterialApp(
          title: 'Smart Transport',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tp.themeMode,
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.pages,
        ),
      ),
    );
  }
}

// Firebase
await Firebase.initializeApp();

// Hive
await Hive.initFlutter();
await Hive.openBox('settings');
await Hive.openBox('favorites');

// Portrait only
await SystemChrome.setPreferredOrientations([
DeviceOrientation.portraitUp,
DeviceOrientation.portraitDown,
]);

SystemChrome.setSystemUIOverlayStyle(
const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
);

runApp(const SmartTransportApp());
}

class SmartTransportApp extends StatelessWidget {
const SmartTransportApp({super.key});

@override
Widget build(BuildContext context) {
return MultiProvider(
providers: [
ChangeNotifierProvider(create: (_) => ThemeProvider()),
ChangeNotifierProvider(create: (_) => AuthProvider()),
ChangeNotifierProvider(create: (_) => LocationProvider()),
ChangeNotifierProvider(create: (_) => VehicleProvider()),
ChangeNotifierProvider(create: (_) => RouteProvider()),
ChangeNotifierProvider(create: (_) => NotificationProvider()),
],
child: Consumer<ThemeProvider>(
builder: (_, tp, __) => GetMaterialApp(
title: 'Smart Transport',
debugShowCheckedModeBanner: false,
theme: AppTheme.light,
darkTheme: AppTheme.dark,
themeMode: tp.themeMode,
initialRoute: AppRoutes.splash,
getPages: AppRoutes.pages,
),
),
);
}
}*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/route_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox token — replace with your real token
  MapboxOptions.setAccessToken('pk.eyJ1IjoiYXJ5YWthbGUwOSIsImEiOiJjbW14dXYxNXoycXZiMnByMmFydmxwdnhnIn0.pKZ1Ow69I4f6Xf5PsDDD8Q');

  // Firebase
  //await Firebase.initializeApp();

  // Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('favorites');

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const SmartTransportApp());
}

class SmartTransportApp extends StatelessWidget {
  const SmartTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, tp, __) => GetMaterialApp(
          title: 'Smart Transport',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tp.themeMode,
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.pages,
        ),
      ),
    );
  }
}