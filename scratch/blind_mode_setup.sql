-- Run this in your Supabase SQL Editor

-- 1. Add fields to track blind mode and unlock status
ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_unlocked BOOLEAN DEFAULT false;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS is_blind BOOLEAN DEFAULT false;

-- 2. Create the Smart Blind Matchmaking Algorithm (RPC)
CREATE OR REPLACE FUNCTION get_blind_matches(current_user_uuid UUID, limit_count INT)
RETURNS TABLE (profile_json JSON)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT row_to_json(p)
  FROM profiles p
  WHERE p.id != current_user_uuid
    -- Filter 1: Has not been swiped on yet (fresh faces only)
    AND NOT EXISTS (
      SELECT 1 FROM likes l
      WHERE l.user_id = current_user_uuid AND l.target_id = p.id
    )
  ORDER BY
    -- Priority 1: Exact match on Relationship Goal
    (p.goal = (SELECT goal FROM profiles WHERE id = current_user_uuid)) DESC,
    -- Priority 2: Most recently active users (crucial for real-time blind chatting)
    p.last_active_at DESC NULLS LAST
  LIMIT limit_count;
END;
$$;
