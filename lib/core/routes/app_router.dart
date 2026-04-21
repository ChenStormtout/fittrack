import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/root/root_page.dart';
import '../../features/splash/splash_page.dart';
import 'app_routes.dart';

class AppRouter {
  static GoRouter router(AuthController authController) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authController,
      redirect: (context, state) {
        if (!authController.isInitialized) return AppRoutes.splash;

        final isAuthRoute = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register;

        if (authController.isLoggedIn && isAuthRoute) {
          return AppRoutes.root;
        }

        if (!authController.isLoggedIn &&
            state.matchedLocation == AppRoutes.root) {
          return AppRoutes.login;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const RootPage(),
        ),
      ],
    );
  }
}