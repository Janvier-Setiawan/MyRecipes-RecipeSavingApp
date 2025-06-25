-- =============================================
-- Test & Verification Queries for Authentication
-- =============================================

-- 1. CHECK AUTHENTICATION CONFIGURATION
-- Verify email confirmation is disabled
SELECT * FROM auth.config WHERE key LIKE '%CONFIRM%' OR key LIKE '%MAILER%';

-- 2. CHECK USERS TABLE
-- See all registered users and their confirmation status
SELECT 
    id,
    email,
    created_at,
    updated_at,
    email_confirmed_at,
    phone_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed'
        ELSE 'NOT Confirmed'
    END as email_status
FROM auth.users
ORDER BY created_at DESC;

-- 3. CHECK USER PROFILES
-- Verify profiles are created correctly
SELECT 
    up.user_id,
    up.email,
    up.full_name,
    up.username,
    up.created_at,
    u.email_confirmed_at
FROM public.user_profiles up
LEFT JOIN auth.users u ON up.user_id = u.id
ORDER BY up.created_at DESC;

-- 4. CHECK RECIPES WITH USER DATA
-- Verify data relationships
SELECT 
    r.id,
    r.name,
    r.user_id,
    up.email,
    up.full_name
FROM public.recipes r
JOIN public.user_profiles up ON r.user_id = up.user_id
ORDER BY r.created_at DESC;

-- =============================================
-- FIX COMMON ISSUES
-- =============================================

-- FIX 1: Confirm all unconfirmed emails (for testing)
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- FIX 2: Create missing profiles for existing users
INSERT INTO public.user_profiles (user_id, email, full_name)
SELECT 
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1))
FROM auth.users u
WHERE u.id NOT IN (SELECT user_id FROM public.user_profiles)
AND u.email_confirmed_at IS NOT NULL;

-- FIX 3: Delete test users (cleanup)
DELETE FROM public.recipes 
WHERE user_id IN (
    SELECT id FROM auth.users 
    WHERE email LIKE '%test%' OR email LIKE '%example%'
);

DELETE FROM public.user_profiles 
WHERE email LIKE '%test%' OR email LIKE '%example%';

DELETE FROM auth.users 
WHERE email LIKE '%test%' OR email LIKE '%example%';

-- =============================================
-- CREATE TEST USER (for development)
-- =============================================

-- Create a test user with confirmed email
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Insert test user
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        phone_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        'test@myrecipes.com',
        crypt('test123456', gen_salt('bf')),
        NOW(),
        NULL,
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Test User"}',
        false,
        '',
        '',
        '',
        ''
    ) RETURNING id INTO test_user_id;

    -- Create corresponding profile
    INSERT INTO public.user_profiles (user_id, email, full_name, cooking_level)
    VALUES (test_user_id, 'test@myrecipes.com', 'Test User', 'beginner');

    -- Create sample recipes for test user
    INSERT INTO public.recipes (user_id, name, description, ingredients)
    VALUES 
    (
        test_user_id,
        'Test Nasi Goreng',
        'Simple fried rice for testing',
        ARRAY['2 cups rice', '2 eggs', '1 tsp soy sauce', 'Salt to taste']
    ),
    (
        test_user_id,
        'Test Mie Ayam',
        'Chicken noodles for testing',
        ARRAY['200g noodles', '100g chicken', '2 cloves garlic', '1 tbsp oil']
    );

    RAISE NOTICE 'Test user created successfully with ID: %', test_user_id;
END $$;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Verify test user was created
SELECT 'SUCCESS: Test user created' as status
WHERE EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'test@myrecipes.com' 
    AND email_confirmed_at IS NOT NULL
);

-- Verify test profile was created
SELECT 'SUCCESS: Test profile created' as status
WHERE EXISTS (
    SELECT 1 FROM public.user_profiles 
    WHERE email = 'test@myrecipes.com'
);

-- Verify test recipes were created
SELECT 
    COUNT(*) || ' test recipes created' as status
FROM public.recipes r
JOIN public.user_profiles up ON r.user_id = up.user_id
WHERE up.email = 'test@myrecipes.com';

-- =============================================
-- AUTHENTICATION TEST CREDENTIALS
-- =============================================

/*
TEST USER CREDENTIALS:
Email: test@myrecipes.com
Password: test123456

You can use these credentials to test sign in functionality.
The user has 2 sample recipes for testing.
*/

-- =============================================
-- MONITORING QUERIES
-- =============================================

-- Count users by confirmation status
SELECT 
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed'
        ELSE 'Unconfirmed'
    END as status,
    COUNT(*) as count
FROM auth.users
GROUP BY CASE WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed' ELSE 'Unconfirmed' END;

-- Count profiles vs users
SELECT 
    'Users' as type, COUNT(*) as count FROM auth.users
UNION ALL
SELECT 
    'Profiles' as type, COUNT(*) as count FROM public.user_profiles
UNION ALL
SELECT 
    'Recipes' as type, COUNT(*) as count FROM public.recipes;

-- Recent sign-ups (last 24 hours)
SELECT 
    email,
    created_at,
    email_confirmed_at IS NOT NULL as is_confirmed
FROM auth.users
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
