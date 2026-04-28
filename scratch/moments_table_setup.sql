-- Create a dedicated moments table with public/personal visibility
CREATE TABLE IF NOT EXISTS public.moments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT DEFAULT '',
  visibility TEXT NOT NULL DEFAULT 'personal' CHECK (visibility IN ('personal', 'public')),
  likes_count INT4 DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast queries
CREATE INDEX IF NOT EXISTS moments_user_id_idx ON public.moments(user_id);
CREATE INDEX IF NOT EXISTS moments_visibility_idx ON public.moments(visibility);
CREATE INDEX IF NOT EXISTS moments_created_at_idx ON public.moments(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.moments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see all PUBLIC moments (any logged-in user)
CREATE POLICY "Anyone can view public moments"
  ON public.moments FOR SELECT
  USING (visibility = 'public' OR auth.uid() = user_id);

-- Policy: Users can only insert their own moments
CREATE POLICY "Users can insert own moments"
  ON public.moments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update/delete their own moments
CREATE POLICY "Users can update own moments"
  ON public.moments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own moments"
  ON public.moments FOR DELETE
  USING (auth.uid() = user_id);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
