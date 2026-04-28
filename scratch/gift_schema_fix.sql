-- First, drop the existing table and policies so we start completely fresh
DROP TABLE IF EXISTS public.physical_gifts CASCADE;

-- Now recreate it with the correct columns
CREATE TABLE public.physical_gifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    gift_item TEXT NOT NULL,
    price NUMERIC NOT NULL,
    personal_message TEXT,
    delivery_address TEXT,
    pincode TEXT,
    recipient_phone TEXT,
    status TEXT DEFAULT 'Awaiting Acceptance', -- Awaiting Acceptance, Pending Payment, Paid, Accepted, Out for Delivery, Delivered, Rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS
ALTER TABLE public.physical_gifts ENABLE ROW LEVEL SECURITY;

-- Recreate policies
CREATE POLICY "Users can view their sent or received gifts" 
ON public.physical_gifts FOR SELECT 
USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

CREATE POLICY "Users can insert sent gifts" 
ON public.physical_gifts FOR INSERT 
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Recipients and Senders can update gifts" 
ON public.physical_gifts FOR UPDATE 
USING (auth.uid() = recipient_id OR auth.uid() = sender_id);
