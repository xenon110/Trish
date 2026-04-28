-- 1. Fix Moments Relationship
-- Drop old constraint if it exists and point to profiles table
ALTER TABLE public.moments DROP CONSTRAINT IF EXISTS moments_user_id_fkey;
ALTER TABLE public.moments ADD CONSTRAINT moments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 2. Fix Profiles Selection Policy
-- This allows authenticated users to see basic profile info of others (needed for the Moments Join)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);

-- 3. Storage Bucket Configuration (Instructions)
-- You MUST ensure the 'moments' bucket is PUBLIC in your Supabase Dashboard.
-- Go to Storage -> Buckets -> moments -> Edit Bucket -> Toggle "Public bucket" to ON.

-- 4. Storage Policies
-- Ensure anyone can SELECT from the moments bucket
-- Run this in SQL Editor if policies are enabled for the bucket:
/*
CREATE POLICY "Allow public select on moments"
ON storage.objects FOR SELECT
USING (bucket_id = 'moments');
*/
