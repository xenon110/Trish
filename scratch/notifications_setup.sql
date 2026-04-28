-- ── 1. Create Notifications Table ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Target user
  actor_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- User who triggered the notification
  type        TEXT NOT NULL, -- 'like', 'match', 'message', 'gift'
  content     TEXT,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see their own notifications
CREATE POLICY "Users can view their own notifications" 
  ON public.notifications FOR SELECT 
  TO authenticated 
  USING (auth.uid() = user_id);

-- ── 2. Create Trigger for Likes ─────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_like_notification()
RETURNS TRIGGER AS $$
DECLARE
  actor_name TEXT;
BEGIN
  -- Get actor's name for the notification message
  SELECT full_name INTO actor_name FROM public.profiles WHERE id = NEW.liker_id;
  
  INSERT INTO public.notifications (user_id, actor_id, type, content)
  VALUES (NEW.liked_id, NEW.liker_id, 'like', actor_name || ' liked your profile!');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_like_notification ON public.likes;
CREATE TRIGGER on_like_notification
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_like_notification();

-- ── 3. Create Trigger for Matches (Optional but good) ────────
CREATE OR REPLACE FUNCTION public.handle_new_match_notification()
RETURNS TRIGGER AS $$
DECLARE
  user1_name TEXT;
  user2_name TEXT;
BEGIN
  SELECT full_name INTO user1_name FROM public.profiles WHERE id = NEW.user1_id;
  SELECT full_name INTO user2_name FROM public.profiles WHERE id = NEW.user2_id;
  
  -- Notify user 1 about user 2
  INSERT INTO public.notifications (user_id, actor_id, type, content)
  VALUES (NEW.user1_id, NEW.user2_id, 'match', 'You matched with ' || user2_name || '!');
  
  -- Notify user 2 about user 1
  INSERT INTO public.notifications (user_id, actor_id, type, content)
  VALUES (NEW.user2_id, NEW.user1_id, 'match', 'You matched with ' || user1_name || '!');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_match_notification ON public.matches;
CREATE TRIGGER on_match_notification
  AFTER INSERT ON public.matches
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_match_notification();
