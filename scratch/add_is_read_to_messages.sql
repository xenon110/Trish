-- Add is_read column to messages table to track read status
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Add index for performance on unread message queries
CREATE INDEX IF NOT EXISTS idx_messages_unread ON public.messages(match_id, is_read) WHERE is_read = false;
