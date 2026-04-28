-- ═══════════════════════════════════════════════════════════════
-- COMPATIBILITY MATCH SYSTEM
-- Two users can chat if:
--   1. They mutually liked each other, OR
--   2. Their profile compatibility score is >= 50
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Add match_type + compatibility_score to matches ──────────
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS match_type   TEXT DEFAULT 'mutual_like'
    CHECK (match_type IN ('mutual_like', 'compatibility', 'both')),
  ADD COLUMN IF NOT EXISTS compatibility_score INT4 DEFAULT 0;

-- ── 2. Compatibility scoring function ───────────────────────────
-- Returns 0-100. Criteria:
--   interests overlap     → up to 35 pts
--   relationship_type     → 20 pts
--   religion              → 15 pts
--   location (city)       → 15 pts
--   lifestyle (drink/smoke/fitness) → up to 15 pts
--                                      (5 pts each)
CREATE OR REPLACE FUNCTION public.profile_compatibility(uid1 UUID, uid2 UUID)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  p1 RECORD;
  p2 RECORD;
  score INT := 0;
  common_interests INT;
  max_interests INT;
  lifestyle1 JSONB;
  lifestyle2 JSONB;
BEGIN
  SELECT interests, relationship_type, religion, location, lifestyle, gender, interested_in
  INTO p1 FROM public.profiles WHERE id = uid1;

  SELECT interests, relationship_type, religion, location, lifestyle, gender, interested_in
  INTO p2 FROM public.profiles WHERE id = uid2;

  IF p1 IS NULL OR p2 IS NULL THEN RETURN 0; END IF;

  -- ── Interests overlap (up to 35 pts) ──────────────────────────
  IF p1.interests IS NOT NULL AND p2.interests IS NOT NULL
     AND array_length(p1.interests, 1) > 0
     AND array_length(p2.interests, 1) > 0
  THEN
    SELECT COUNT(*) INTO common_interests
    FROM unnest(p1.interests) AS i
    WHERE i = ANY(p2.interests);

    max_interests := GREATEST(
      array_length(p1.interests, 1),
      array_length(p2.interests, 1)
    );

    score := score + LEAST(35, (common_interests * 35 / max_interests));
  END IF;

  -- ── Relationship type (20 pts) ────────────────────────────────
  IF p1.relationship_type IS NOT NULL
     AND p2.relationship_type IS NOT NULL
     AND p1.relationship_type = p2.relationship_type
  THEN
    score := score + 20;
  END IF;

  -- ── Religion (15 pts) ─────────────────────────────────────────
  IF p1.religion IS NOT NULL
     AND p2.religion IS NOT NULL
     AND p1.religion = p2.religion
  THEN
    score := score + 15;
  END IF;

  -- ── Same city / location (15 pts) ────────────────────────────
  IF p1.location IS NOT NULL
     AND p2.location IS NOT NULL
     AND LOWER(p1.location) = LOWER(p2.location)
  THEN
    score := score + 15;
  END IF;

  -- ── Lifestyle (up to 15 pts, 5 each) ─────────────────────────
  lifestyle1 := COALESCE(p1.lifestyle, '{}'::jsonb);
  lifestyle2 := COALESCE(p2.lifestyle, '{}'::jsonb);

  IF lifestyle1->>'drinking' IS NOT NULL
     AND lifestyle1->>'drinking' = lifestyle2->>'drinking'
  THEN score := score + 5; END IF;

  IF lifestyle1->>'smoking' IS NOT NULL
     AND lifestyle1->>'smoking' = lifestyle2->>'smoking'
  THEN score := score + 5; END IF;

  IF lifestyle1->>'fitness' IS NOT NULL
     AND lifestyle1->>'fitness' = lifestyle2->>'fitness'
  THEN score := score + 5; END IF;

  RETURN LEAST(100, score);
END;
$$;

-- ── 3. Check compatibility for a user & create matches ──────────
-- Call this after a user updates their profile or on app open.
CREATE OR REPLACE FUNCTION public.check_compatibility_matches(target_uid UUID)
RETURNS TABLE(matched_user_id UUID, score INT) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  rec RECORD;
  compat INT;
  u1 UUID;
  u2 UUID;
  existing_match UUID;
BEGIN
  FOR rec IN
    SELECT id FROM public.profiles
    WHERE id != target_uid
  LOOP
    compat := public.profile_compatibility(target_uid, rec.id);

    IF compat >= 50 THEN
      -- Check for existing match
      SELECT id INTO existing_match
      FROM public.matches
      WHERE (user1_id = target_uid AND user2_id = rec.id)
         OR (user1_id = rec.id AND user2_id = target_uid);

      IF existing_match IS NULL THEN
        -- Create a new compatibility match
        u1 := LEAST(target_uid::text, rec.id::text)::UUID;
        u2 := GREATEST(target_uid::text, rec.id::text)::UUID;

        INSERT INTO public.matches (user1_id, user2_id, is_blind, is_unlocked, match_type, compatibility_score)
        VALUES (u1, u2, FALSE, TRUE, 'compatibility', compat)
        ON CONFLICT DO NOTHING;

      ELSE
        -- Update score on existing match; upgrade type to 'both' if it was 'mutual_like'
        UPDATE public.matches
        SET compatibility_score = compat,
            match_type = CASE
              WHEN match_type = 'mutual_like' THEN 'both'
              ELSE match_type
            END
        WHERE id = existing_match;
      END IF;

      matched_user_id := rec.id;
      score := compat;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

-- ── 4. Update mutual-like trigger to set match_type ────────────
CREATE OR REPLACE FUNCTION public.create_match_on_mutual_like()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  mutual_exists BOOLEAN;
  compat INT;
  u1 UUID;
  u2 UUID;
  existing_match UUID;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.likes
    WHERE liker_id = NEW.liked_id
      AND liked_id = NEW.liker_id
  ) INTO mutual_exists;

  IF mutual_exists THEN
    u1 := LEAST(NEW.liker_id::text, NEW.liked_id::text)::UUID;
    u2 := GREATEST(NEW.liker_id::text, NEW.liked_id::text)::UUID;
    compat := public.profile_compatibility(NEW.liker_id, NEW.liked_id);

    SELECT id INTO existing_match
    FROM public.matches
    WHERE (user1_id = u1 AND user2_id = u2);

    IF existing_match IS NULL THEN
      INSERT INTO public.matches (user1_id, user2_id, is_blind, is_unlocked, match_type, compatibility_score)
      VALUES (u1, u2, FALSE, TRUE,
        CASE WHEN compat >= 50 THEN 'both' ELSE 'mutual_like' END,
        compat
      )
      ON CONFLICT DO NOTHING;
    ELSE
      -- Upgrade existing compatibility match to 'both'
      UPDATE public.matches
      SET match_type = 'both', compatibility_score = compat
      WHERE id = existing_match AND match_type = 'compatibility';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Re-attach trigger
DROP TRIGGER IF EXISTS trg_mutual_like_match ON public.likes;
CREATE TRIGGER trg_mutual_like_match
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.create_match_on_mutual_like();

-- ── 5. Grant execute on functions ──────────────────────────────
GRANT EXECUTE ON FUNCTION public.profile_compatibility(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_compatibility_matches(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
