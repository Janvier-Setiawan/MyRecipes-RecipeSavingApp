import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../config/app_theme.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  int _calculateSelectedIndex() {
    final location = widget.location;

    if (location.startsWith('/home')) {
      return 0;
    } else if (location.startsWith('/add-recipe')) {
      return 1;
    } else if (location.startsWith('/profile')) {
      return 2;
    }

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/add-recipe');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(),
            onTap: (index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondaryColor,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _calculateSelectedIndex() == 0
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _calculateSelectedIndex() == 0
                        ? Icons.home
                        : Icons.home_outlined,
                    size: 24,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _calculateSelectedIndex() == 1
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _calculateSelectedIndex() == 1
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.add,
                      color: _calculateSelectedIndex() == 1
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                ),
                label: 'Add Recipe',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _calculateSelectedIndex() == 2
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _calculateSelectedIndex() == 2
                        ? Icons.person
                        : Icons.person_outline,
                    size: 24,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
