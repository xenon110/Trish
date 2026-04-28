-- ═══════════════════════════════════════════════════════════════
-- SWIPE FEED ALGORITHM SETUP
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Create Dislikes Table ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.dislikes (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dislike_count     INT DEFAULT 1,
  last_disliked_at  TIMESTAMPTZ DEFAULT NOW(),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, target_id)
);

CREATE INDEX IF NOT EXISTS dislikes_user_target_idx ON public.dislikes(user_id, target_id);

-- ── 2. Smart Recommendation Feed RPC ──────────────────────────
-- Requirements:
--   - Exclude Liked
--   - Exclude Matched
--   - Exclude Disliked (under cooldown)
--   - Rank by Interest Overlap, Distance, Activity
--   - Slight Randomness
DROP FUNCTION IF EXISTS public.get_recommended_feed(UUID, INT);

CREATE OR REPLACE FUNCTION public.get_recommended_feed(current_user_uuid UUID, limit_count INT DEFAULT 20)
RETURNS TABLE (profile_json JSON)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    curr_lat FLOAT;
    curr_lon FLOAT;
    curr_gender TEXT;
    curr_interests TEXT[];
    curr_pref_gender TEXT;
BEGIN
    -- Get current user info for comparison
    SELECT latitude, longitude, gender, interests, interested_in
    INTO curr_lat, curr_lon, curr_gender, curr_interests, curr_pref_gender
    FROM public.profiles 
    WHERE id = current_user_uuid;

    RETURN QUERY
    WITH potential_profiles AS (
      SELECT 
        p.*,
        -- Calculate shared interests count
        (SELECT count(*) FROM (
          SELECT unnest(curr_interests) INTERSECT SELECT jsonb_array_elements_text(p.interests)
        ) AS intersection) as shared_interests_count,
        -- Calculate distance (rough haversine if lat/lon exist)
        CASE 
          WHEN curr_lat IS NOT NULL AND curr_lon IS NOT NULL AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
          THEN (6371 * acos(
            least(1, cos(radians(curr_lat)) * cos(radians(p.latitude)) * 
            cos(radians(p.longitude) - radians(curr_lon)) + 
            sin(radians(curr_lat)) * sin(radians(p.latitude)))
          ))
          ELSE 9999 -- Far away if no location
        END as distance_km
      FROM public.profiles p
      WHERE p.id != current_user_uuid
        AND p.is_blocked = false
        -- Gender preference filter (if set)
        AND (curr_pref_gender IS NULL OR p.gender = curr_pref_gender)
        -- Exclude already liked
        AND NOT EXISTS (
          SELECT 1 FROM public.likes l
          WHERE l.liker_id = current_user_uuid AND l.liked_id = p.id
        )
        -- Exclude already matched
        AND NOT EXISTS (
          SELECT 1 FROM public.matches m
          WHERE (m.user1_id = current_user_uuid AND m.user2_id = p.id)
             OR (m.user1_id = p.id AND m.user2_id = current_user_uuid)
        )
        -- Exclude disliked under cooldown
        AND NOT EXISTS (
          SELECT 1 FROM public.dislikes d
          WHERE d.user_id = current_user_uuid 
            AND d.target_id = p.id
            AND (
              (d.dislike_count = 1 AND d.last_disliked_at > (now() - interval '3 days')) OR
              (d.dislike_count = 2 AND d.last_disliked_at > (now() - interval '7 days')) OR
              (d.dislike_count >= 3 AND d.last_disliked_at > (now() - interval '14 days'))
            )
        )
    )
    SELECT row_to_json(sub)
    FROM (
      SELECT * FROM potential_profiles
      ORDER BY
        -- Priority 1: High shared interests
        shared_interests_count DESC,
        -- Priority 2: Nearby
        distance_km ASC,
        -- Priority 3: Recently active
        last_active_at DESC NULLS LAST,
        -- Randomize slightly
        random()
      LIMIT limit_count
    ) sub;
END;
$$;

-- ── 3. Enable Realtime ──────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'dislikes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.dislikes;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
