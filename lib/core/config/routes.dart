import 'package:flutter/material.dart';

class CustomRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    debugPrint('Route: ${settings.name}');
    switch (settings.name) {
      // case SplashScreen.routeName:
      //   return SplashScreen.route();
      // case DashboardScreen.routeName:
      //   return DashboardScreen.route();
      default:
        return _errorRoute();
    }
  }

  static Route _errorRoute() {
    return MaterialPageRoute(
        settings: const RouteSettings(name: '/error'),
        builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Center(child: Text('Error Page')),
              ),
            ));
  }
}
