-- ── Update Smart Recommendation Feed RPC with Advanced Filters ──────────────────

DROP FUNCTION IF EXISTS public.get_recommended_feed(UUID, INT);
DROP FUNCTION IF EXISTS public.get_recommended_feed(UUID, INT, JSONB);

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
    curr_interests TEXT[];
    
    -- Filter vars
    f_interested_in TEXT;
    f_min_age INT;
    f_max_age INT;
    f_distance_km INT;
    f_verified_only BOOLEAN;
    f_height_min INT;
    f_height_max INT;
    f_religion TEXT;
    f_politics TEXT;
    f_smoking TEXT;
    f_drinking TEXT;
    f_exercise TEXT;
    f_zodiac TEXT;
    f_education TEXT;
    f_future_plans TEXT;
    f_have_kids TEXT;
    f_languages TEXT[];
    f_relationship_type TEXT[];
    f_interests TEXT[];
BEGIN
    -- Get current user info
    SELECT latitude, longitude, interests
    INTO curr_lat, curr_lon, curr_interests
    FROM public.profiles 
    WHERE id = current_user_uuid;

    -- Extract filters from JSONB
    f_interested_in := filters_json->>'interested_in';
    f_min_age := (filters_json->>'min_age')::int;
    f_max_age := (filters_json->>'max_age')::int;
    f_distance_km := (filters_json->>'distance_km')::int;
    f_verified_only := (filters_json->>'verified_only')::boolean;
    f_height_min := (filters_json->>'height_min')::int;
    f_height_max := (filters_json->>'height_max')::int;
    f_religion := filters_json->>'religion';
    f_politics := filters_json->>'politics';
    f_smoking := filters_json->>'smoking';
    f_drinking := filters_json->>'drinking';
    f_exercise := filters_json->>'exercise';
    f_zodiac := filters_json->>'zodiac';
    f_education := filters_json->>'education';
    f_future_plans := filters_json->>'future_plans';
    f_have_kids := filters_json->>'have_kids';
    
    -- Extract arrays
    IF filters_json ? 'languages' THEN
        SELECT ARRAY(SELECT jsonb_array_elements_text(filters_json->'languages')) INTO f_languages;
    END IF;
    IF filters_json ? 'relationship_type' THEN
        SELECT ARRAY(SELECT jsonb_array_elements_text(filters_json->'relationship_type')) INTO f_relationship_type;
    END IF;
    IF filters_json ? 'interests' THEN
        SELECT ARRAY(SELECT jsonb_array_elements_text(filters_json->'interests')) INTO f_interests;
    END IF;

    RETURN QUERY
    WITH potential_profiles AS (
      SELECT 
        p.*,
        (SELECT count(*) FROM (
          SELECT unnest(curr_interests) INTERSECT SELECT jsonb_array_elements_text(p.interests)
        ) AS intersection) as shared_interests_count,
        CASE 
          WHEN curr_lat IS NOT NULL AND curr_lon IS NOT NULL AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
          THEN (6371 * acos(
            least(1, cos(radians(curr_lat)) * cos(radians(p.latitude)) * 
            cos(radians(p.longitude) - radians(curr_lon)) + 
            sin(radians(curr_lat)) * sin(radians(p.latitude)))
          ))
          ELSE 9999
        END as distance_km
      FROM public.profiles p
      WHERE p.id != current_user_uuid
        AND p.is_blocked = false
        -- BASIC FILTERS
        AND (f_interested_in IS NULL OR f_interested_in = 'Everyone' OR p.gender = f_interested_in)
        AND (f_min_age IS NULL OR p.age >= f_min_age)
        AND (f_max_age IS NULL OR p.age <= f_max_age)
        AND (f_verified_only IS NULL OR f_verified_only = false OR p.is_verified = true)
        
        -- ADVANCED FILTERS
        AND (f_height_min IS NULL OR p.height >= f_height_min)
        AND (f_height_max IS NULL OR p.height <= f_height_max)
        AND (f_religion IS NULL OR p.religion = f_religion)
        AND (f_politics IS NULL OR p.politics = f_politics)
        AND (f_smoking IS NULL OR p.smoking = f_smoking)
        AND (f_drinking IS NULL OR p.drinking = f_drinking)
        AND (f_exercise IS NULL OR p.exercise = f_exercise)
        AND (f_zodiac IS NULL OR p.zodiac = f_zodiac)
        AND (f_education IS NULL OR p.education = f_education)
        AND (f_future_plans IS NULL OR p.future_plans = f_future_plans)
        AND (f_have_kids IS NULL OR p.have_kids = f_have_kids)
        
        -- ARRAY FILTERS
        AND (f_languages IS NULL OR cardinality(f_languages) = 0 OR p.languages && f_languages)
        AND (f_relationship_type IS NULL OR cardinality(f_relationship_type) = 0 OR p.relationship_type = ANY(f_relationship_type))
        AND (f_interests IS NULL OR cardinality(f_interests) = 0 OR EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(p.interests) i WHERE i = ANY(f_interests)
        ))

        -- EXCLUSIONS
        AND NOT EXISTS (SELECT 1 FROM public.likes l WHERE l.liker_id = current_user_uuid AND l.liked_id = p.id)
        AND NOT EXISTS (SELECT 1 FROM public.matches m WHERE (m.user1_id = current_user_uuid AND m.user2_id = p.id) OR (m.user1_id = p.id AND m.user2_id = current_user_uuid))
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
      WHERE (f_distance_km IS NULL OR distance_km <= f_distance_km)
      ORDER BY
        shared_interests_count DESC,
        distance_km ASC,
        last_active_at DESC NULLS LAST,
        random()
      LIMIT limit_count
    ) sub;
END;
$$;
