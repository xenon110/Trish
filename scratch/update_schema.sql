-- 1. Add Double Unlock columns to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS user1_unlocked BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS user2_unlocked BOOLEAN DEFAULT FALSE;

-- 2. Update the Messages SELECT policy to guarantee sender visibility
DROP POLICY IF EXISTS "Users can read messages of their matches" ON public.messages;

CREATE POLICY "Users can read messages of their matches" ON public.messages
FOR SELECT
USING (
    auth.uid() = sender_id OR
    EXISTS (
        SELECT 1 FROM matches 
        WHERE id = match_id 
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
);
