import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../services/user_profile_service.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(currentUserProfileProvider);
    final userProfileService = ref.watch(userProfileServiceProvider);

    final fullNameController = useTextEditingController();
    final usernameController = useTextEditingController();
    final bioController = useTextEditingController();
    final phoneController = useTextEditingController();

    final selectedImageFile = useState<File?>(null);
    final selectedImageUrl = useState<String?>(null);

    final selectedDate = useState<DateTime?>(null);
    final selectedCookingLevel = useState<String>('beginner');
    final selectedCuisine = useState<String?>(null);
    final selectedDietaryPreferences = useState<List<String>>([]);

    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final successMessage = useState<String?>(null);
    final isUsernameValid = useState<bool?>(null);
    final isCheckingUsername = useState(false);

    final userId = ref.watch(currentUserProvider);

    final availableCookingLevels = UserProfileService.getCookingLevelOptions();
    final availableCuisines = UserProfileService.getCuisineOptions();
    final availableDietaryPreferences =
        UserProfileService.getDietaryPreferencesOptions();

    // Initialize controllers when profile data is available
    useEffect(() {
      if (userProfileAsyncValue.value != null) {
        final profile = userProfileAsyncValue.value!;

        fullNameController.text = profile.fullName ?? '';
        usernameController.text = profile.username ?? '';
        bioController.text = profile.bio ?? '';
        phoneController.text = profile.phoneNumber ?? '';

        selectedImageUrl.value = profile.avatarUrl;
        selectedDate.value = profile.dateOfBirth;
        selectedCookingLevel.value = profile.cookingLevel;
        selectedCuisine.value = profile.favoriteCuisine;
        selectedDietaryPreferences.value = List.from(
          profile.dietaryPreferences,
        );
      }
      return null;
    }, [userProfileAsyncValue.value]);

    // Check if username is available
    Future<void> checkUsernameAvailability(String username) async {
      if (username.isEmpty) {
        isUsernameValid.value = null;
        return;
      }

      isCheckingUsername.value = true;

      try {
        final isAvailable = await userProfileService.isUsernameAvailable(
          username,
          userId, // Exclude current user's ID
        );
        isUsernameValid.value = isAvailable;
      } catch (e) {
        isUsernameValid.value = false;
      } finally {
        isCheckingUsername.value = false;
      }
    }

    // Pick image from gallery
    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        selectedImageFile.value = File(pickedFile.path);
      }
    }

    // Date picker
    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                onSurface: AppTheme.textPrimaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        selectedDate.value = picked;
      }
    }

    // Save profile changes
    Future<void> saveProfile() async {
      if (fullNameController.text.isEmpty) {
        errorMessage.value = 'Full name is required';
        return;
      }

      if (usernameController.text.isNotEmpty &&
          isUsernameValid.value == false) {
        errorMessage.value = 'Username is already taken or invalid';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      try {
        // Upload avatar if a new one was selected
        String? newAvatarUrl;
        if (selectedImageFile.value != null) {
          final bytes = await selectedImageFile.value!.readAsBytes();
          newAvatarUrl = await userProfileService.uploadAvatar(userId!, bytes);
        }

        // Update profile
        await userProfileService.updateUserProfile(
          userId: userId!,
          fullName: fullNameController.text.trim(),
          username: usernameController.text.trim().isEmpty
              ? null
              : usernameController.text.trim(),
          avatarUrl: newAvatarUrl ?? selectedImageUrl.value,
          bio: bioController.text.trim().isEmpty
              ? null
              : bioController.text.trim(),
          phoneNumber: phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
          dateOfBirth: selectedDate.value,
          cookingLevel: selectedCookingLevel.value,
          favoriteCuisine: selectedCuisine.value,
          dietaryPreferences: selectedDietaryPreferences.value,
        );

        // Refresh user profile
        ref.invalidate(currentUserProfileProvider);

        successMessage.value = 'Profile updated successfully';

        // Go back to profile screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            context.pop();
          }
        });
      } catch (e) {
        errorMessage.value = 'Failed to update profile: ${e.toString()}';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header without the app bar
            Container(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    Colors.white.withOpacity(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: userProfileAsyncValue.when(
                data: (profile) {
                  if (profile == null) {
                    return const Center(child: Text('Profile not found'));
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMessage.value != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade100.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade800,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    errorMessage.value!,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red.shade800,
                                    size: 18,
                                  ),
                                  onPressed: () => errorMessage.value = null,
                                ),
                              ],
                            ),
                          ),

                        if (successMessage.value != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade100.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade800,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    successMessage.value!,
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ), // Avatar section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: pickImage,
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 65,
                                        backgroundImage:
                                            selectedImageFile.value != null
                                            ? FileImage(
                                                selectedImageFile.value!,
                                              )
                                            : (selectedImageUrl.value != null
                                                  ? NetworkImage(
                                                      selectedImageUrl.value!,
                                                    )
                                                  : null),
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        child:
                                            (selectedImageFile.value == null &&
                                                selectedImageUrl.value == null)
                                            ? Text(
                                                profile.initials,
                                                style: TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Edit Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap photo to change avatar',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Basic Information
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: AppTheme.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Basic Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: fullNameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name *',
                                  prefixIcon: const Icon(Icons.badge),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  suffixIcon: isCheckingUsername.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : isUsernameValid.value == null
                                      ? null
                                      : Icon(
                                          isUsernameValid.value!
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: isUsernameValid.value!
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                  helperText: 'Choose a unique username',
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    checkUsernameAvailability(value);
                                  } else {
                                    isUsernameValid.value = null;
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: bioController,
                                decoration: InputDecoration(
                                  labelText: 'Bio',
                                  prefixIcon: const Icon(Icons.description),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => selectDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date of Birth',
                                    prefixIcon: const Icon(Icons.cake),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  child: selectedDate.value != null
                                      ? Text(
                                          DateFormat(
                                            'MMMM d, yyyy',
                                          ).format(selectedDate.value!),
                                        )
                                      : const Text('Select your date of birth'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cooking Preferences
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.restaurant,
                                      color: AppTheme.secondaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Cooking Preferences',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.secondaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Cooking Level
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rate_rounded,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Cooking Level',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: availableCookingLevels.map((level) {
                                    final isSelected =
                                        selectedCookingLevel.value == level;
                                    return ChoiceChip(
                                      label: Text(
                                        level.capitalize(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textPrimaryColor,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppTheme.secondaryColor,
                                      backgroundColor: Colors.grey.shade100,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppTheme.secondaryColor
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      elevation: isSelected ? 3 : 0,
                                      shadowColor: AppTheme.secondaryColor
                                          .withOpacity(0.3),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          selectedCookingLevel.value = level;
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Favorite Cuisine
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_dining_rounded,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Favorite Cuisine',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                child: DropdownButtonFormField<String>(
                                  value: selectedCuisine.value,
                                  decoration: InputDecoration(
                                    hintText: 'Select your favorite cuisine',
                                    prefixIcon: const Icon(Icons.fastfood),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('None selected'),
                                    ),
                                    ...availableCuisines.map((cuisine) {
                                      return DropdownMenuItem<String>(
                                        value: cuisine,
                                        child: Text(cuisine),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    selectedCuisine.value = value;
                                  },
                                ),
                              ),

                              // Dietary Preferences
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.set_meal_rounded,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Dietary Preferences',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: availableDietaryPreferences.map((
                                    preference,
                                  ) {
                                    final isSelected =
                                        selectedDietaryPreferences.value
                                            .contains(preference);
                                    return FilterChip(
                                      label: Text(
                                        preference.capitalize(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textPrimaryColor,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppTheme.accentColor,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppTheme.accentColor
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      elevation: isSelected ? 2 : 0,
                                      shadowColor: AppTheme.accentColor
                                          .withOpacity(0.3),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      onSelected: (selected) {
                                        final newPreferences =
                                            List<String>.from(
                                              selectedDietaryPreferences.value,
                                            );
                                        if (selected) {
                                          newPreferences.add(preference);
                                        } else {
                                          newPreferences.remove(preference);
                                        }
                                        selectedDietaryPreferences.value =
                                            newPreferences;
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Buttons
                        Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 55,
                                margin: const EdgeInsets.only(right: 8),
                                child: TextButton(
                                  onPressed: () => context.pop(),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Save Button
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 55,
                                margin: const EdgeInsets.only(left: 8),
                                child: ElevatedButton(
                                  onPressed: isLoading.value
                                      ? null
                                      : saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shadowColor: AppTheme.primaryColor
                                        .withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: isLoading.value
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Save Changes',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error loading profile: ${err.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
