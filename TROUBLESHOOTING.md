# 🐛 Troubleshooting Guide - My Recipes App

## ❌ Common Authentication Issues

### Issue 1: "Invalid email or password" saat Sign In

**Possible Causes:**

1. **Email Confirmation Required** - Supabase default memerlukan konfirmasi email
2. **Typo dalam email/password** - Case sensitive
3. **User belum terdaftar** - Sign up gagal sebelumnya
4. **Network/Supabase connection issues**

**Solutions:**

#### 1. Disable Email Confirmation (Recommended for Development)

```sql
-- Run this in Supabase SQL Editor
UPDATE auth.users SET email_confirmed_at = NOW() WHERE email_confirmed_at IS NULL;
```

**OR** dalam Supabase Dashboard:

1. Go to **Authentication** > **Settings**
2. Scroll to **User Signups**
3. Turn OFF **Enable email confirmations**

#### 2. Check User Exists in Database

```sql
-- Check if user exists
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'your-email@example.com';
```

#### 3. Manual Email Confirmation

```sql
-- Manually confirm email for testing
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'your-email@example.com';
```

### Issue 2: Sign Up berhasil tapi Sign In gagal

**Check di Supabase Dashboard:**

1. Go to **Authentication** > **Users**
2. Cari email yang baru didaftar
3. Pastikan kolom **Email Confirmed** berisi tanggal (bukan kosong)

**Fix manually:**

```sql
-- Update email confirmation
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'user@example.com' AND email_confirmed_at IS NULL;
```

### Issue 3: Profile Creation Error

**Check user_profiles table:**

```sql
-- Check if profile was created
SELECT * FROM public.user_profiles WHERE email = 'user@example.com';
```

**Manually create profile if missing:**

```sql
-- Get user ID first
SELECT id FROM auth.users WHERE email = 'user@example.com';

-- Create profile manually (replace USER_ID)
INSERT INTO public.user_profiles (user_id, email, full_name)
VALUES ('USER_ID_HERE', 'user@example.com', 'User Name');
```

## 🔧 Debug Steps

### Step 1: Check Flutter Logs

```bash
flutter run --verbose
```

Look for these debug messages:

- "Attempting to sign in with email: ..."
- "Sign in response: ..."
- "User session saved successfully"
- "Sign in error: ..."

### Step 2: Check Supabase Configuration

Verify `lib/config/supabase_config.dart`:

```dart
const String supabaseUrl = 'https://your-project.supabase.co';
const String supabaseAnonKey = 'your-anon-key-here';
```

### Step 3: Test with Supabase Dashboard

1. Go to **Authentication** > **Users**
2. Click **Add User** manually
3. Try to sign in with that user

### Step 4: Check Network Connection

```bash
# Test connection to Supabase
curl -X GET "https://your-project.supabase.co/rest/v1/" \
-H "apikey: your-anon-key"
```

## 🧪 Testing Queries

### Test Authentication Directly

```sql
-- Test user creation
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test@example.com',
    crypt('testpassword', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{}'
);
```

### Check RLS Policies

```sql
-- Check if RLS is properly configured
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename IN ('recipes', 'user_profiles');

-- Should return 'true' for rowsecurity
```

### Test Profile Creation

```sql
-- Test profile creation trigger
INSERT INTO auth.users (
    id, email, encrypted_password, email_confirmed_at, created_at, updated_at
) VALUES (
    gen_random_uuid(),
    'triggertest@example.com',
    'dummy',
    NOW(),
    NOW(),
    NOW()
);

-- Check if profile was auto-created
SELECT * FROM public.user_profiles WHERE email = 'triggertest@example.com';
```

## 🔨 Quick Fixes

### Fix 1: Reset User Password

```sql
-- Reset password in database (for testing)
UPDATE auth.users
SET encrypted_password = crypt('newpassword', gen_salt('bf'))
WHERE email = 'user@example.com';
```

### Fix 2: Clear and Recreate User

```sql
-- Delete user and profile
DELETE FROM public.user_profiles WHERE email = 'user@example.com';
DELETE FROM auth.users WHERE email = 'user@example.com';

-- Then try sign up again
```

### Fix 3: Enable Auth Debugging

Add to `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable debug logging
  if (kDebugMode) {
    print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
    print('Debug mode enabled');
  }

  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: MainApp()));
}
```

## 📱 Flutter Specific Issues

### Issue: Hot Reload Issues

```bash
# Full restart
flutter clean
flutter pub get
flutter run
```

### Issue: Provider State Issues

```dart
// Force refresh providers in debug
ref.invalidate(currentUserProvider);
ref.invalidate(userProfileProvider);
```

## ✅ Test Checklist

### Before Testing:

- [ ] Supabase project is active
- [ ] Database tables are created (`supabase_setup.sql` executed)
- [ ] User profiles setup (`supabase_user_profiles.sql` executed)
- [ ] Email confirmations are disabled
- [ ] Supabase credentials are correct in `supabase_config.dart`

### Test Flow:

1. [ ] Sign up with new email
2. [ ] Check user appears in Supabase Dashboard
3. [ ] Check email_confirmed_at is set
4. [ ] Check profile was created in user_profiles table
5. [ ] Try sign in with same credentials
6. [ ] Check user session is saved
7. [ ] Navigate to home screen successfully

### Emergency Reset:

```sql
-- Clean slate - delete all test data
DELETE FROM public.recipes;
DELETE FROM public.user_profiles;
DELETE FROM auth.users WHERE email LIKE '%test%' OR email LIKE '%example%';
```

## 🆘 Contact & Support

If issues persist:

1. Check Supabase status: https://status.supabase.com/
2. Review Supabase docs: https://supabase.com/docs/guides/auth
3. Check Flutter Supabase package: https://pub.dev/packages/supabase_flutter

## 📝 Debug Log Format

When reporting issues, include:

```
App Version: [version]
Flutter Version: [version]
Supabase URL: [your-url]
Error: [exact error message]
Steps to Reproduce: [detailed steps]
Expected: [what should happen]
Actual: [what actually happened]
```
