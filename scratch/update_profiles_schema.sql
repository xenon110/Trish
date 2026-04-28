-- Add new columns to the profiles table to support the detailed onboarding flow
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS birthday TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS interested_in TEXT,
ADD COLUMN IF NOT EXISTS min_age_preference INT4 DEFAULT 18,
ADD COLUMN IF NOT EXISTS max_age_preference INT4 DEFAULT 100,
ADD COLUMN IF NOT EXISTS distance_preference FLOAT8 DEFAULT 50.0,
ADD COLUMN IF NOT EXISTS job TEXT,
ADD COLUMN IF NOT EXISTS education TEXT,
ADD COLUMN IF NOT EXISTS lifestyle JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS religion TEXT,
ADD COLUMN IF NOT EXISTS relationship_type TEXT,
ADD COLUMN IF NOT EXISTS prompts JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS height FLOAT8,
ADD COLUMN IF NOT EXISTS languages TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS zodiac TEXT,
ADD COLUMN IF NOT EXISTS future_plans TEXT;

-- Refresh the schema cache (Supabase does this automatically, but sometimes a small delay occurs)
NOTIFY pgrst, 'reload schema';
