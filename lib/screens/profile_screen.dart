import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../services/user_profile_service.dart';
import '../config/app_theme.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider);
    final userProfileAsyncValue = ref.watch(currentUserProfileProvider);
    final userStatsAsyncValue = ref.watch(userStatsProvider(userId ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              context.push('/edit-profile');
            },
          ),
        ],
      ),
      body: userProfileAsyncValue.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.secondaryColor.withOpacity(
                            0.2,
                          ),
                          backgroundImage: profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? Text(
                                  profile.initials,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (profile.username != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.username}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Card
                userStatsAsyncValue.when(
                  data: (stats) {
                    if (stats == null) return const SizedBox.shrink();

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              'Recipes',
                              stats['total_recipes']?.toString() ?? '0',
                              Icons.restaurant_menu_rounded,
                            ),
                            _buildStatItem(
                              context,
                              'Level',
                              profile.cookingLevel.capitalize(),
                              Icons.star_rounded,
                            ),
                            _buildStatItem(
                              context,
                              'Joined',
                              DateFormat('MMM yyyy').format(profile.createdAt),
                              Icons.calendar_today_rounded,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Profile Details
                Card(
                  child: Column(
                    children: [
                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Bio'),
                          subtitle: Text(profile.bio!),
                        ),

                      if (profile.phoneNumber != null &&
                          profile.phoneNumber!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(profile.phoneNumber!),
                        ),

                      if (profile.dateOfBirth != null)
                        ListTile(
                          leading: const Icon(Icons.cake),
                          title: const Text('Date of Birth'),
                          subtitle: Text(
                            DateFormat(
                              'MMMM d, yyyy',
                            ).format(profile.dateOfBirth!),
                          ),
                        ),

                      if (profile.favoriteCuisine != null &&
                          profile.favoriteCuisine!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.favorite),
                          title: const Text('Favorite Cuisine'),
                          subtitle: Text(profile.favoriteCuisine!),
                        ),

                      if (profile.dietaryPreferences.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.local_dining),
                          title: const Text('Dietary Preferences'),
                          subtitle: Wrap(
                            spacing: 4,
                            children: profile.dietaryPreferences
                                .map(
                                  (pref) => Chip(
                                    label: Text(pref.capitalize()),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Settings
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/edit-profile');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to settings
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          final authService = ref.read(authServiceProvider);
                          await authService.signOut();
                          ref.read(currentUserProvider.notifier).state = null;
                          if (context.mounted) {
                            context.go('/signin');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
