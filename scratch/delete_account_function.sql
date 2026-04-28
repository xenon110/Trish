-- Create a secure function to allow users to delete their own accounts
-- This function runs with service_role permissions (SECURITY DEFINER)
-- but only deletes the user who is currently authenticated (auth.uid())

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete the user from auth.users (This will also delete the profile if there's a cascade)
  -- Or explicitly delete from profiles if no cascade
  DELETE FROM public.profiles WHERE id = auth.uid();
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
