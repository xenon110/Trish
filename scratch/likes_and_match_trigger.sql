-- ─────────────────────────────────────────────────
-- 1. Drop old likes table if it exists (clean slate)
-- ─────────────────────────────────────────────────
DROP TABLE IF EXISTS public.likes CASCADE;

-- ─────────────────────────────────────────────────
-- 2. Create likes table
-- ─────────────────────────────────────────────────
CREATE TABLE public.likes (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  liker_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  liked_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (liker_id, liked_id)
);

CREATE INDEX likes_liked_id_idx ON public.likes(liked_id);
CREATE INDEX likes_liker_id_idx ON public.likes(liker_id);

-- ─────────────────────────────────────────────────
-- 3. RLS
-- ─────────────────────────────────────────────────
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "likes_insert"
  ON public.likes FOR INSERT
  WITH CHECK (auth.uid() = liker_id);

CREATE POLICY "likes_select"
  ON public.likes FOR SELECT
  USING (auth.uid() = liker_id OR auth.uid() = liked_id);

CREATE POLICY "likes_delete"
  ON public.likes FOR DELETE
  USING (auth.uid() = liker_id);

-- ─────────────────────────────────────────────────
-- 4. Auto-match trigger function
-- ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_match_on_mutual_like()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  mutual_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.likes
    WHERE liker_id = NEW.liked_id
      AND liked_id = NEW.liker_id
  ) INTO mutual_exists;

  IF mutual_exists THEN
    INSERT INTO public.matches (user1_id, user2_id, is_blind, is_unlocked)
    VALUES (
      LEAST(NEW.liker_id::text, NEW.liked_id::text)::UUID,
      GREATEST(NEW.liker_id::text, NEW.liked_id::text)::UUID,
      FALSE,
      TRUE
    )
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mutual_like_match ON public.likes;
CREATE TRIGGER trg_mutual_like_match
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.create_match_on_mutual_like();

-- ─────────────────────────────────────────────────
-- 5. Ensure matches has is_unlocked column
-- ─────────────────────────────────────────────────
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS is_unlocked BOOLEAN DEFAULT TRUE;

-- Unique constraint on matches (sorted user IDs)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'matches'
      AND indexname = 'matches_users_unique_idx'
  ) THEN
    CREATE UNIQUE INDEX matches_users_unique_idx
      ON public.matches (
        LEAST(user1_id::text, user2_id::text),
        GREATEST(user1_id::text, user2_id::text)
      );
  END IF;
END $$;

-- ─────────────────────────────────────────────────
-- 6. Enable Realtime on likes table
-- ─────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;

NOTIFY pgrst, 'reload schema';
