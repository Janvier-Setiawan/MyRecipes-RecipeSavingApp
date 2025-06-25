-- =============================================
-- User Profiles Table Setup for My Recipes App
-- =============================================

-- 1. Create user_profiles table to store additional user data
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    email TEXT NOT NULL,
    full_name TEXT,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    phone_number TEXT,
    date_of_birth DATE,
    cooking_level TEXT CHECK (cooking_level IN ('beginner', 'intermediate', 'advanced')) DEFAULT 'beginner',
    favorite_cuisine TEXT,
    dietary_preferences TEXT[], -- vegetarian, vegan, halal, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 2. Enable Row Level Security on user_profiles table
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for user_profiles table
-- Policy: Users can only view their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own profile
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own profile
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can only delete their own profile
CREATE POLICY "Users can delete own profile" ON public.user_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Create trigger to automatically update updated_at for user_profiles
CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS user_profiles_user_id_idx ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS user_profiles_email_idx ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS user_profiles_username_idx ON public.user_profiles(username);

-- 6. Create function to automatically create user profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (user_id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create trigger to automatically create profile when user signs up
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- Update recipes table to include user profile relationship
-- =============================================

-- Add user_email column to recipes for easier querying (optional)
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS user_email TEXT;

-- Create function to sync email from user_profiles to recipes
CREATE OR REPLACE FUNCTION public.sync_recipe_user_email()
RETURNS TRIGGER AS $$
BEGIN
    -- Update recipes table with user email when profile is updated
    UPDATE public.recipes 
    SET user_email = NEW.email 
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to sync email changes
CREATE TRIGGER sync_recipe_email_on_profile_update
    AFTER INSERT OR UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_recipe_user_email();

-- =============================================
-- Views for easier data access
-- =============================================

-- Create view to get user data with recipe count
CREATE OR REPLACE VIEW public.user_stats AS
SELECT 
    up.user_id,
    up.email,
    up.full_name,
    up.username,
    up.avatar_url,
    up.cooking_level,
    up.favorite_cuisine,
    up.created_at as profile_created_at,
    COUNT(r.id) as total_recipes,
    MAX(r.created_at) as last_recipe_created
FROM public.user_profiles up
LEFT JOIN public.recipes r ON up.user_id = r.user_id
GROUP BY up.user_id, up.email, up.full_name, up.username, up.avatar_url, 
         up.cooking_level, up.favorite_cuisine, up.created_at;

-- Create view to get recipes with user info
CREATE OR REPLACE VIEW public.recipes_with_user AS
SELECT 
    r.id,
    r.name,
    r.description,
    r.ingredients,
    r.created_at,
    r.updated_at,
    up.email as user_email,
    up.full_name as user_name,
    up.username,
    up.avatar_url as user_avatar
FROM public.recipes r
JOIN public.user_profiles up ON r.user_id = up.user_id;

-- =============================================
-- Functions for user management
-- =============================================

-- Function to get user profile by UID
CREATE OR REPLACE FUNCTION public.get_user_profile(user_uuid UUID)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    full_name TEXT,
    username TEXT,
    avatar_url TEXT,
    bio TEXT,
    phone_number TEXT,
    date_of_birth DATE,
    cooking_level TEXT,
    favorite_cuisine TEXT,
    dietary_preferences TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        up.email,
        up.full_name,
        up.username,
        up.avatar_url,
        up.bio,
        up.phone_number,
        up.date_of_birth,
        up.cooking_level,
        up.favorite_cuisine,
        up.dietary_preferences
    FROM public.user_profiles up
    WHERE up.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to update user profile
CREATE OR REPLACE FUNCTION public.update_user_profile(
    user_uuid UUID,
    new_full_name TEXT DEFAULT NULL,
    new_username TEXT DEFAULT NULL,
    new_avatar_url TEXT DEFAULT NULL,
    new_bio TEXT DEFAULT NULL,
    new_phone_number TEXT DEFAULT NULL,
    new_date_of_birth DATE DEFAULT NULL,
    new_cooking_level TEXT DEFAULT NULL,
    new_favorite_cuisine TEXT DEFAULT NULL,
    new_dietary_preferences TEXT[] DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.user_profiles
    SET
        full_name = COALESCE(new_full_name, full_name),
        username = COALESCE(new_username, username),
        avatar_url = COALESCE(new_avatar_url, avatar_url),
        bio = COALESCE(new_bio, bio),
        phone_number = COALESCE(new_phone_number, phone_number),
        date_of_birth = COALESCE(new_date_of_birth, date_of_birth),
        cooking_level = COALESCE(new_cooking_level, cooking_level),
        favorite_cuisine = COALESCE(new_favorite_cuisine, favorite_cuisine),
        dietary_preferences = COALESCE(new_dietary_preferences, dietary_preferences),
        updated_at = NOW()
    WHERE user_id = user_uuid;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to check if username is available
CREATE OR REPLACE FUNCTION public.is_username_available(check_username TEXT, exclude_user_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE username = check_username 
        AND (exclude_user_id IS NULL OR user_id != exclude_user_id)
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Sample data insertion (uncomment to use)
-- =============================================

/*
-- Insert sample user profiles (replace UUIDs with actual user IDs from auth.users)
INSERT INTO public.user_profiles (
    user_id, email, full_name, username, cooking_level, favorite_cuisine, dietary_preferences
) VALUES
(
    'user-uuid-1',
    'john@example.com',
    'John Doe',
    'johndoe',
    'intermediate',
    'Italian',
    ARRAY['vegetarian']
),
(
    'user-uuid-2',
    'jane@example.com',
    'Jane Smith',
    'janesmith',
    'advanced',
    'Asian',
    ARRAY['gluten-free', 'dairy-free']
);
*/

-- =============================================
-- Cleanup old data (if needed)
-- =============================================

-- Remove orphaned recipes (recipes without valid users)
-- DELETE FROM public.recipes 
-- WHERE user_id NOT IN (SELECT id FROM auth.users);

-- =============================================
-- Security and Performance Notes
-- =============================================
-- 1. RLS ensures users can only access their own profile data
-- 2. Automatic profile creation when user signs up
-- 3. Email sync between profiles and recipes for consistency
-- 4. Username uniqueness constraint
-- 5. Proper indexing for performance
-- 6. Views for complex queries
-- 7. Helper functions for common operations
