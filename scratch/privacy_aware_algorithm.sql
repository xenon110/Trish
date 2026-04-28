-- ═══════════════════════════════════════════════════════════════
-- UPDATED RECOMMENDATION ENGINE WITH PRIVACY RESPECT
-- ═══════════════════════════════════════════════════════════════

-- Ensure columns exist in profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_private_profile BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_show_online BOOLEAN DEFAULT TRUE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pref_read_receipts BOOLEAN DEFAULT TRUE;

CREATE OR REPLACE FUNCTION public.get_recommended_feed(
  current_user_uuid UUID, 
  limit_count INT DEFAULT 20,
  filters_json JSONB DEFAULT '{}'::jsonb
)
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
    curr_min_age INT;
    curr_max_age INT;
    curr_dist_pref FLOAT;
BEGIN
    -- Get current user info and their preferences
    SELECT 
      latitude, longitude, gender, interests, interested_in,
      min_age_preference, max_age_preference, distance_preference
    INTO 
      curr_lat, curr_lon, curr_gender, curr_interests, curr_pref_gender,
      curr_min_age, curr_max_age, curr_dist_pref
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
        -- ── PRIVACY FILTER ───────────────────────────────────────
        AND p.pref_private_profile = false -- Respect "Private Profile" setting
        -- ────────────────────────────────────────────────────────
        
        -- Gender preference filter
        AND (curr_pref_gender IS NULL OR p.gender = curr_pref_gender)
        
        -- Age range filter
        AND (curr_min_age IS NULL OR p.age >= curr_min_age)
        AND (curr_max_age IS NULL OR p.age <= curr_max_age)
        
        -- Advanced filters from DiscoveryFilterScreen
        AND (filters_json->>'religion' IS NULL OR p.religion = filters_json->>'religion')
        AND (filters_json->>'zodiac' IS NULL OR p.zodiac = filters_json->>'zodiac')
        AND (filters_json->>'relationship_type' IS NULL OR p.relationship_type = filters_json->>'relationship_type')
        
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
      WHERE (curr_dist_pref IS NULL OR distance_km <= curr_dist_pref)
      ORDER BY
        shared_interests_count DESC,
        distance_km ASC,
        last_active_at DESC NULLS LAST,
        random()
      LIMIT limit_count
    ) sub;
END;
$$;
