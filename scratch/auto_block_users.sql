-- 1. Add is_blocked column to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;

-- 2. Create a function to check report count and block user
CREATE OR REPLACE FUNCTION public.fn_check_reports_and_block()
RETURNS TRIGGER AS $$
DECLARE
    report_count INT;
BEGIN
    -- Count how many reports the user has received
    SELECT count(*) INTO report_count
    FROM public.reports
    WHERE reported_id = NEW.reported_id;

    -- If 10 or more reports, block the user
    IF report_count >= 10 THEN
        UPDATE public.profiles
        SET is_blocked = true,
            updated_at = now()
        WHERE id = NEW.reported_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create trigger on reports table
DROP TRIGGER IF EXISTS trg_after_report_insert ON public.reports;
CREATE TRIGGER trg_after_report_insert
AFTER INSERT ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.fn_check_reports_and_block();

-- 4. Suggestion: Update your Discovery RPCs to filter out blocked users
-- If you have get_recommended_feed or get_blind_matches, add:
-- AND p.is_blocked = false
