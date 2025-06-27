import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe.dart';
import '../screens/add_recipe_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/get_started_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/scaffold_with_nav_bar.dart';
import '../screens/sign_in_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/splash_screen.dart';
import '../services/shared_prefs_service.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isFirstLaunch = await SharedPrefsService.isFirstLaunch();
    final isLoggedIn = await SharedPrefsService.isUserLoggedIn();

    final location = state.uri.path;

    if (isFirstLaunch) {
      return '/get-started';
    }

    if (!isLoggedIn &&
        location != '/signin' &&
        location != '/signup' &&
        location != '/get-started') {
      return '/signin';
    }

    if (isLoggedIn &&
        (location == '/signin' ||
            location == '/signup' ||
            location == '/get-started' ||
            location == '/')) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/get-started',
      builder: (context, state) => const GetStartedScreen(),
    ),
    GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/add-recipe',
          builder: (context, state) => const AddRecipeScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/recipe-detail/:id',
      builder: (context, state) {
        final recipe = state.extra as Recipe;
        return RecipeDetailScreen(recipe: recipe);
      },
    ),
  ],
);
