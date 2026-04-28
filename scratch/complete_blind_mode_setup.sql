-- ═══════════════════════════════════════════════════════════════
-- BLIND MODE COMPLETION SETUP
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Add missing unlock columns to matches ──────────────────
-- These allow us to track if user1 or user2 has clicked "Unlock"
ALTER TABLE public.matches 
  ADD COLUMN IF NOT EXISTS user1_unlocked BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS user2_unlocked BOOLEAN DEFAULT false;

-- ── 2. Update Blind Matches RPC ───────────────────────────────
-- Safely drop old version first to avoid return type errors
DROP FUNCTION IF EXISTS get_blind_matches(UUID, INT);

CREATE OR REPLACE FUNCTION get_blind_matches(current_user_uuid UUID, limit_count INT)
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
    FROM profiles 
    WHERE id = current_user_uuid;

    RETURN QUERY
    SELECT row_to_json(p)
    FROM profiles p
    WHERE p.id != current_user_uuid
      AND p.is_blocked = false
      -- Filter 1: Gender preference (Real Map searching requirement)
      AND (curr_pref_gender IS NULL OR p.gender = curr_pref_gender)
      -- Filter 2: Has not been liked/swiped on yet
      AND NOT EXISTS (
        SELECT 1 FROM likes l
        WHERE l.liker_id = current_user_uuid AND l.liked_id = p.id
      )
      -- Filter 3: Logic (2+ shared interests OR within 50km)
      AND (
        (
          (6371 * acos(
              least(1, cos(radians(curr_lat)) * cos(radians(p.latitude)) * 
              cos(radians(p.longitude) - radians(curr_lon)) + 
              sin(radians(curr_lat)) * sin(radians(p.latitude)))
          )) <= 50
        )
        OR
        (
          (SELECT count(*) FROM (
            SELECT unnest(curr_interests) INTERSECT SELECT jsonb_array_elements_text(p.interests)
          ) AS intersection) >= 2
        )
      )
    ORDER BY
      -- Sort by highest interest match first, then most recently active
      (SELECT count(*) FROM (
        SELECT unnest(curr_interests) INTERSECT SELECT jsonb_array_elements_text(p.interests)
      ) AS intersection) DESC,
      p.last_active_at DESC NULLS LAST
    LIMIT limit_count;
END;
$$;

NOTIFY pgrst, 'reload schema';
