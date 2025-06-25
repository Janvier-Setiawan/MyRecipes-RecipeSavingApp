-- Setup Storage for Recipe Images in Supabase
-- Run this SQL in your Supabase SQL Editor to set up storage buckets and policies

-- Note: In Supabase, the storage extension is already enabled by default
-- We don't need to create it manually

-- Create recipe_images bucket if it doesn't exist
-- Note: This is typically done through the Supabase dashboard UI or SDK
-- Using the correct Supabase storage.buckets function
DO $$
DECLARE
  bucket_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM storage.buckets WHERE name = 'recipe_images'
  ) INTO bucket_exists;
  
  IF NOT bucket_exists THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('recipe_images', 'recipe_images', TRUE);
  END IF;
END $$;

-- Set up bucket policies for recipe_images bucket

-- 1. Policy to allow authenticated users to INSERT/UPLOAD
BEGIN;
  INSERT INTO storage.policies (name, definition, bucket_id)
  SELECT 'Allow authenticated users to upload images', 
         '(auth.role() = ''authenticated''::text)', 
         id
  FROM storage.buckets
  WHERE name = 'recipe_images'
  ON CONFLICT DO NOTHING;

  -- Grant INSERT permission
  UPDATE storage.policies
  SET operation = 'INSERT'
  WHERE name = 'Allow authenticated users to upload images'
  AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'recipe_images');
COMMIT;

-- 2. Policy to allow public to SELECT/VIEW images
BEGIN;
  INSERT INTO storage.policies (name, definition, bucket_id)
  SELECT 'Allow public to view recipe images',
         'true',  -- Allow everyone
         id
  FROM storage.buckets
  WHERE name = 'recipe_images'
  ON CONFLICT DO NOTHING;

  -- Grant SELECT permission
  UPDATE storage.policies
  SET operation = 'SELECT'
  WHERE name = 'Allow public to view recipe images'
  AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'recipe_images');
COMMIT;

-- 3. Policy to allow users to UPDATE only their own images
BEGIN;
  INSERT INTO storage.policies (name, definition, bucket_id)
  SELECT 'Allow users to update their own images',
         '(auth.role() = ''authenticated''::text) AND (auth.uid()::text = (storage.foldername(name))[1])',
         id
  FROM storage.buckets
  WHERE name = 'recipe_images'
  ON CONFLICT DO NOTHING;

  -- Grant UPDATE permission
  UPDATE storage.policies
  SET operation = 'UPDATE'
  WHERE name = 'Allow users to update their own images'
  AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'recipe_images');
COMMIT;

-- 4. Policy to allow users to DELETE only their own images
BEGIN;
  INSERT INTO storage.policies (name, definition, bucket_id)
  SELECT 'Allow users to delete their own images',
         '(auth.role() = ''authenticated''::text) AND (auth.uid()::text = (storage.foldername(name))[1])',
         id
  FROM storage.buckets
  WHERE name = 'recipe_images'
  ON CONFLICT DO NOTHING;

  -- Grant DELETE permission
  UPDATE storage.policies
  SET operation = 'DELETE'
  WHERE name = 'Allow users to delete their own images'
  AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'recipe_images');
COMMIT;

-- Note: If you prefer a GUI approach, you can also set up storage through the Supabase Dashboard:
-- 1. Go to Storage in the Supabase dashboard
-- 2. Create a new bucket named 'recipe_images' and mark it as public
-- 3. Go to the Policies tab and add policies similar to those above

-- Verification query to check if bucket and policies were created successfully:
SELECT 
  b.name as bucket_name, 
  p.name as policy_name, 
  p.operation, 
  p.definition
FROM storage.buckets b
LEFT JOIN storage.policies p ON b.id = p.bucket_id
WHERE b.name = 'recipe_images'
ORDER BY p.name;
