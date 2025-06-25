# Supabase Storage Setup Instructions

Since the SQL approach is giving errors, let's set up storage using the Supabase UI:

## Step 1: Enable Storage in Supabase

1. Go to your Supabase project dashboard
2. Click on "Storage" in the left sidebar
3. If prompted, click "Enable Storage" to initialize the storage features

## Step 2: Create a Bucket

1. Once Storage is enabled, click "New Bucket"
2. Enter the bucket name: `recipe_images`
3. Check the "Public bucket" option to make images publicly accessible
4. Click "Create bucket"

## Step 3: Set Up Access Policies

For the `recipe_images` bucket, set up the following policies:

### Policy 1: Allow authenticated users to upload images

1. In the Storage section, select your `recipe_images` bucket
2. Go to the "Policies" tab
3. Click "Add policies"
4. Select "INSERT" operation (for uploads)
5. For the policy definition, use:
   ```sql
   (auth.role() = 'authenticated')
   ```
6. Name: "Allow authenticated users to upload images"
7. Click "Save policy"

### Policy 2: Allow public to view images

1. Click "Add policies" again
2. Select "SELECT" operation (for viewing)
3. For the policy definition, use:
   ```sql
   true
   ```
4. Name: "Allow public to view recipe images"
5. Click "Save policy"

### Policy 3: Allow users to update only their own images

1. Click "Add policies" again
2. Select "UPDATE" operation
3. For the policy definition, use:
   ```sql
   (auth.role() = 'authenticated') AND (auth.uid()::text = (storage.foldername(name))[1])
   ```
4. Name: "Allow users to update their own images"
5. Click "Save policy"

### Policy 4: Allow users to delete only their own images

1. Click "Add policies" again
2. Select "DELETE" operation
3. For the policy definition, use:
   ```sql
   (auth.role() = 'authenticated') AND (auth.uid()::text = (storage.foldername(name))[1])
   ```
4. Name: "Allow users to delete their own images"
5. Click "Save policy"

## Step 4: Update the Database Schema

Now that storage is set up, let's update the recipes table to include the image_url column:

1. Go to the "SQL Editor" in your Supabase dashboard
2. Run the following SQL:

```sql
-- Check if image_url column exists in recipes table, add it if not
DO $$
BEGIN
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

-- Verify the column was added
SELECT
  column_name,
  data_type
FROM
  information_schema.columns
WHERE
  table_name = 'recipes'
ORDER BY
  ordinal_position;
```

## Testing Your Storage Setup

After setting up the storage bucket and policies, you can test it by:

1. Going to the "Storage" section
2. Clicking on your `recipe_images` bucket
3. Uploading a test image manually
4. Verifying you can access it via its public URL

The image URLs from Supabase Storage will be in this format:
`https://<your-project-ref>.supabase.co/storage/v1/object/public/recipe_images/<path-to-file>`

Once this setup is complete, your app will be able to use the image upload functionality.
