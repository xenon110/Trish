-- Run this in your Supabase SQL Editor

-- 1. Add fields to track blind mode and unlock status
ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_unlocked BOOLEAN DEFAULT false;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_blind BOOLEAN DEFAULT false;

-- 2. Create the Smart Blind Matchmaking Algorithm (RPC)
-- This version filters by:
-- 1. Opposite gender
-- 2. Within 50km range OR has at least 2 shared interests
-- 3. Not already swiped on
CREATE OR REPLACE FUNCTION get_blind_matches(current_user_uuid UUID, limit_count INT)
RETURNS TABLE (profile_json JSON)
LANGUAGE plpgsql
AS $$
DECLARE
    curr_lat FLOAT;
    curr_lon FLOAT;
    curr_gender TEXT;
    curr_interests TEXT[];
BEGIN
    -- Get current user info for comparison
    SELECT latitude, longitude, gender, interests 
    INTO curr_lat, curr_lon, curr_gender, curr_interests
    FROM profiles 
    WHERE id = current_user_uuid;

    RETURN QUERY
    SELECT row_to_json(p)
    FROM profiles p
    WHERE p.id != current_user_uuid
      -- Filter 1: Opposite gender (Real Map searching requirement)
      AND p.gender != curr_gender
      -- Filter 2: Has not been swiped on yet (fresh faces only)
      AND NOT EXISTS (
        SELECT 1 FROM likes l
        WHERE l.user_id = current_user_uuid AND l.target_id = p.id
      )
      -- Filter 3: Logic (2+ shared interests OR within 50km)
      AND (
        (
          -- Haversine formula for distance in KM
          -- 6371 is Earth's radius in KM
          (6371 * acos(
              least(1, p_cos(radians(curr_lat)) * p_cos(radians(p.latitude)) * 
              p_cos(radians(p.longitude) - radians(curr_lon)) + 
              p_sin(radians(curr_lat)) * p_sin(radians(p.latitude)))
          )) <= 50
        )
        OR
        (
          -- Intersection of interests array count >= 2
          (SELECT count(*) FROM (
            SELECT unnest(curr_interests) INTERSECT SELECT unnest(p.interests)
          ) AS intersection) >= 2
        )
      )
    ORDER BY
      -- Sort by highest interest match first, then most recently active
      (SELECT count(*) FROM (
        SELECT unnest(curr_interests) INTERSECT SELECT unnest(p.interests)
      ) AS intersection) DESC,
      p.last_active_at DESC NULLS LAST
    LIMIT limit_count;
END;
$$;

-- Helper functions for Haversine if PostGIS is not available
CREATE OR REPLACE FUNCTION p_sin(x float) RETURNS float AS $$ SELECT sin(x); $$ LANGUAGE SQL IMMUTABLE;
CREATE OR REPLACE FUNCTION p_cos(x float) RETURNS float AS $$ SELECT cos(x); $$ LANGUAGE SQL IMMUTABLE;
