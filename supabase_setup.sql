-- =============================================
-- Authentication Configuration (Important!)
-- =============================================

-- Disable email confirmation for development/testing
-- This allows users to sign in immediately after sign up
UPDATE auth.config 
SET value = 'false' 
WHERE key = 'MAILER_AUTOCONFIRM';

-- Alternative: Manually confirm all existing users
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- =============================================
-- Supabase Database Setup for My Recipes App
-- =============================================

-- Enable Row Level Security (RLS)
-- This ensures users can only access their own data

-- 1. Create recipes table
CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    ingredients TEXT[] NOT NULL DEFAULT '{}',
    steps TEXT[] NOT NULL DEFAULT '{}',
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 2. Enable Row Level Security on recipes table
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for recipes table
-- Policy: Users can only view their own recipes
CREATE POLICY "Users can view own recipes" ON public.recipes
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own recipes
CREATE POLICY "Users can insert own recipes" ON public.recipes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own recipes
CREATE POLICY "Users can update own recipes" ON public.recipes
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can only delete their own recipes
CREATE POLICY "Users can delete own recipes" ON public.recipes
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger to automatically update updated_at
CREATE TRIGGER handle_recipes_updated_at
    BEFORE UPDATE ON public.recipes
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS recipes_user_id_idx ON public.recipes(user_id);
CREATE INDEX IF NOT EXISTS recipes_created_at_idx ON public.recipes(created_at DESC);

-- =============================================
-- Optional: Create some sample data for testing
-- =============================================

-- Insert sample recipes (uncomment to use)
-- Note: Replace 'your-user-id-here' with actual user ID from auth.users table

/*
INSERT INTO public.recipes (user_id, name, description, ingredients) VALUES
(
    'your-user-id-here',
    'Nasi Goreng',
    'Nasi goreng sederhana dengan bumbu khas Indonesia',
    ARRAY['2 piring nasi putih', '2 butir telur', '3 siung bawang putih', '2 sdm kecap manis', '1 sdt garam', 'Minyak untuk menumis']
),
(
    'your-user-id-here',
    'Rendang Daging',
    'Rendang daging sapi dengan santan dan rempah-rempah',
    ARRAY['500g daging sapi', '400ml santan kental', '3 lembar daun jeruk', '2 batang serai', '5 siung bawang merah', '3 siung bawang putih', '3 buah cabai merah', '1 sdt ketumbar', '1 sdt jinten']
),
(
    'your-user-id-here',
    'Gado-gado',
    'Salad sayuran Indonesia dengan bumbu kacang',
    ARRAY['100g tauge', '2 buah tahu', '2 buah tempe', '1 buah ketimun', '2 lembar daun selada', '100g kacang tanah', '2 siung bawang putih', '1 buah cabai rawit', '1 sdm gula merah', '1 sdt garam']
);
*/

-- =============================================
-- Useful queries for development/debugging
-- =============================================

-- View all recipes with user information
-- SELECT r.*, u.email as user_email 
-- FROM recipes r 
-- JOIN auth.users u ON r.user_id = u.id 
-- ORDER BY r.created_at DESC;

-- Count recipes per user
-- SELECT u.email, COUNT(r.id) as recipe_count 
-- FROM auth.users u 
-- LEFT JOIN recipes r ON u.id = r.user_id 
-- GROUP BY u.id, u.email;

-- Find recipes by ingredient
-- SELECT * FROM recipes 
-- WHERE 'telur' = ANY(ingredients);

-- =============================================
-- Database Functions (Optional)
-- =============================================

-- Function to search recipes by name or description
CREATE OR REPLACE FUNCTION public.search_recipes(search_term TEXT, user_uuid UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    ingredients TEXT[],
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.user_id, r.name, r.description, r.ingredients, r.created_at, r.updated_at
    FROM public.recipes r
    WHERE r.user_id = user_uuid
    AND (
        LOWER(r.name) LIKE LOWER('%' || search_term || '%') OR
        LOWER(r.description) LIKE LOWER('%' || search_term || '%')
    )
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get recipe count for a user
CREATE OR REPLACE FUNCTION public.get_user_recipe_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.recipes
        WHERE user_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Security Notes:
-- =============================================
-- 1. RLS is enabled to ensure data isolation between users
-- 2. All policies check auth.uid() to ensure users can only access their own data
-- 3. Foreign key constraint ensures data integrity with auth.users table
-- 4. Indexes are created for better query performance
-- 5. Updated_at is automatically maintained via trigger
