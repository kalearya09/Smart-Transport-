import 'package:get/get.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/nearby/nearby_screen.dart';
import '../../screens/route_planner/route_planner_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/driver_detail/driver_detail_screen.dart';

class AppRoutes {
  static const splash       = '/';
  static const login        = '/login';
  static const register     = '/register';
  static const home         = '/home';
  static const nearby       = '/nearby';
  static const routePlanner = '/route-planner';
  static const notifications= '/notifications';
  static const profile      = '/profile';
  static const driverDetail = '/driver-detail';

  static final pages = [
    GetPage(name: splash,        page: () => const SplashScreen()),
    GetPage(name: login,         page: () => const LoginScreen()),
    GetPage(name: register,      page: () => const RegisterScreen()),
    GetPage(name: home,          page: () => const HomeScreen(), transition: Transition.fadeIn),
    GetPage(name: nearby,        page: () => const NearbyScreen()),
    GetPage(name: routePlanner,  page: () => const RoutePlannerScreen()),
    GetPage(name: notifications, page: () => const NotificationsScreen()),
    GetPage(name: profile,       page: () => const ProfileScreen()),
    GetPage(name: driverDetail,  page: () => const DriverDetailScreen()),
  ];
}