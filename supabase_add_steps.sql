-- Migration to add steps column and image_url column to recipes table
-- Run this SQL in your Supabase SQL Editor if you already created your recipes table

-- Check if the steps column already exists and add it if needed
DO $$
BEGIN
  -- If the steps column doesn't exist, add it
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns 
    WHERE table_name = 'recipes'
    AND column_name = 'steps'
  ) THEN
    -- Add steps column to the recipes table
    ALTER TABLE public.recipes 
    ADD COLUMN steps TEXT[] NOT NULL DEFAULT '{}';
    
    RAISE NOTICE 'Added steps column to recipes table';
  ELSE
    RAISE NOTICE 'steps column already exists in recipes table';
  END IF;
  
  -- If the image_url column doesn't exist, add it
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns 
    WHERE table_name = 'recipes'
    AND column_name = 'image_url'
  ) THEN
    -- Add image_url column to the recipes table
    ALTER TABLE public.recipes 
    ADD COLUMN image_url TEXT;
    
    RAISE NOTICE 'Added image_url column to recipes table';
  ELSE
    RAISE NOTICE 'image_url column already exists in recipes table';
  END IF;
END
$$;

-- Confirm column was added
SELECT 
  column_name, 
  data_type 
FROM 
  information_schema.columns 
WHERE 
  table_name = 'recipes'
ORDER BY 
  ordinal_position;
