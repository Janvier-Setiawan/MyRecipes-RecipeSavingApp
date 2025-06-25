# Recipe Ingredient Quantities and Image Upload Feature

This guide explains the new features added to the MyRecipes app:

1. Ingredient quantities support
2. Recipe image upload to Supabase Storage

## Database Changes

The following changes were made to support these features:

1. Added `image_url` column to the `recipes` table
2. Created a storage bucket (`recipe_images`) for recipe images
3. Set up storage policies for secure access to images

### SQL Migration Script

If you already have an existing database, run the `supabase_add_steps.sql` script to add the needed columns.

Then run the `supabase_storage_setup.sql` script to create the storage bucket with appropriate permissions.

## Ingredient Quantities

The app now supports storing quantities with each ingredient. Ingredients are stored in the format:

```
quantity|ingredient_name
```

For example: `"2 cups|flour"` or `"1/2 tsp|salt"`

This allows the app to display quantities separately from ingredient names in the UI.

## Image Storage Strategy

### Why Supabase Storage?

We chose Supabase Storage for recipe images because:

1. **Integration**: It's directly integrated with our Supabase backend
2. **Security**: We can leverage Supabase RLS (Row Level Security) policies
3. **Performance**: CDN-backed for fast image loading
4. **Simplicity**: No need for a separate image hosting service

### Image Organization

Images are stored with the following structure:

- Bucket: `recipe_images`
- Path Format: `userId/unique-filename`

This ensures:

- Each user's images are isolated in their own "folder"
- Filenames are unique (using UUID)
- Easy access control through policies

### Security Policies

The following security policies are applied to the images:

1. **Upload**: Only authenticated users can upload images
2. **Read**: Public read access (anyone can view recipe images)
3. **Update/Delete**: Users can only modify their own images

## Implementation Details

### Folder Structure

No new folders were added. These files were modified:

- `lib/models/recipe.dart` - Added `imageUrl` field and `Ingredient` class
- `lib/services/recipe_service.dart` - Added image upload methods
- `lib/screens/add_recipe_screen.dart` - Added UI for image upload and quantities
- `lib/screens/recipe_detail_screen.dart` - Display image and quantities

### Data Model

The `Recipe` model was updated to include:

- `imageUrl` (nullable string) - URL to the uploaded image
- `parsedIngredients` - Getter that parses ingredients with quantities

A new `Ingredient` class was created to handle the parsing and formatting of ingredients with quantities.

## Usage

1. When adding a recipe, you can now:

   - Add quantities for each ingredient
   - Upload a recipe image by tapping the image area

2. When viewing a recipe:
   - Recipe image appears at the top
   - Ingredients show both the name and quantity

## Limitations

1. Images are limited to 5MB in size
2. Currently only supports single image per recipe
3. No image editing features (cropping, filters, etc.)

## Future Enhancements

Possible future enhancements could include:

1. Multiple images per recipe
2. Image gallery view
3. Advanced ingredient management (units conversion)
4. Image editing features
