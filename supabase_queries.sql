-- =============================================
-- Additional Supabase Queries for My Recipes App
-- =============================================

-- =============================================
-- Authentication Queries
-- =============================================

-- View all registered users (Admin only)
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
ORDER BY created_at DESC;

-- Count total users
SELECT COUNT(*) as total_users FROM auth.users;

-- =============================================
-- Recipe Management Queries
-- =============================================

-- Get all recipes with user email
SELECT 
    r.id,
    r.name,
    r.description,
    array_length(r.ingredients, 1) as ingredient_count,
    r.created_at,
    u.email as user_email
FROM public.recipes r
JOIN auth.users u ON r.user_id = u.id
ORDER BY r.created_at DESC;

-- Get recipes for specific user (replace with actual email)
SELECT 
    r.id,
    r.name,
    r.description,
    r.ingredients,
    r.created_at
FROM public.recipes r
JOIN auth.users u ON r.user_id = u.id
WHERE u.email = 'user@example.com'
ORDER BY r.created_at DESC;

-- Count recipes per user
SELECT 
    u.email,
    COUNT(r.id) as recipe_count,
    MAX(r.created_at) as last_recipe_added
FROM auth.users u
LEFT JOIN public.recipes r ON u.id = r.user_id
GROUP BY u.id, u.email
ORDER BY recipe_count DESC;

-- Find recipes containing specific ingredient
SELECT 
    r.name,
    r.description,
    r.ingredients,
    u.email as user_email
FROM public.recipes r
JOIN auth.users u ON r.user_id = u.id
WHERE 'telur' = ANY(r.ingredients)
ORDER BY r.created_at DESC;

-- Get most popular ingredients
SELECT 
    ingredient,
    COUNT(*) as usage_count
FROM (
    SELECT unnest(ingredients) as ingredient
    FROM public.recipes
) ingredient_list
GROUP BY ingredient
ORDER BY usage_count DESC
LIMIT 20;

-- =============================================
-- Data Cleanup Queries
-- =============================================

-- Delete recipes older than 1 year (be careful!)
-- DELETE FROM public.recipes 
-- WHERE created_at < NOW() - INTERVAL '1 year';

-- Delete recipes with empty ingredients
-- DELETE FROM public.recipes 
-- WHERE ingredients = '{}' OR ingredients IS NULL;

-- Update recipe with new ingredients (example)
-- UPDATE public.recipes 
-- SET 
--     ingredients = ARRAY['new ingredient 1', 'new ingredient 2'],
--     updated_at = NOW()
-- WHERE id = 'recipe-uuid-here';

-- =============================================
-- Analytics Queries
-- =============================================

-- Recipe creation trends by month
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as recipes_created
FROM public.recipes
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- Average ingredients per recipe
SELECT 
    ROUND(AVG(array_length(ingredients, 1)), 2) as avg_ingredients_per_recipe
FROM public.recipes
WHERE ingredients IS NOT NULL;

-- User activity summary
SELECT 
    u.email,
    COUNT(r.id) as total_recipes,
    MIN(r.created_at) as first_recipe,
    MAX(r.created_at) as latest_recipe,
    EXTRACT(days FROM (MAX(r.created_at) - MIN(r.created_at))) as active_days
FROM auth.users u
LEFT JOIN public.recipes r ON u.id = r.user_id
GROUP BY u.id, u.email
HAVING COUNT(r.id) > 0
ORDER BY total_recipes DESC;

-- =============================================
-- Backup and Restore Queries
-- =============================================

-- Export recipes for a specific user (for backup)
SELECT 
    name,
    description,
    ingredients,
    created_at
FROM public.recipes r
JOIN auth.users u ON r.user_id = u.id
WHERE u.email = 'user@example.com'
ORDER BY created_at;

-- =============================================
-- Performance Monitoring Queries
-- =============================================

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'recipes';

-- Table statistics
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples
FROM pg_stat_user_tables
WHERE tablename = 'recipes';

-- =============================================
-- Testing Queries
-- =============================================

-- Test RLS policies (run as authenticated user)
-- These should only return recipes for the current user
SELECT * FROM public.recipes;

-- Test search function
-- SELECT * FROM public.search_recipes('nasi', auth.uid());

-- Test recipe count function
-- SELECT public.get_user_recipe_count(auth.uid());

-- =============================================
-- Migration Queries (if needed)
-- =============================================

-- Add new column (example)
-- ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS difficulty_level INTEGER DEFAULT 1;
-- ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS cooking_time_minutes INTEGER;
-- ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS serves INTEGER DEFAULT 1;

-- Create enum for difficulty levels
-- CREATE TYPE difficulty_enum AS ENUM ('easy', 'medium', 'hard');
-- ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS difficulty difficulty_enum DEFAULT 'easy';

-- =============================================
-- Maintenance Queries
-- =============================================

-- Vacuum and analyze tables for better performance
-- VACUUM ANALYZE public.recipes;

-- Reindex if needed
-- REINDEX TABLE public.recipes;
