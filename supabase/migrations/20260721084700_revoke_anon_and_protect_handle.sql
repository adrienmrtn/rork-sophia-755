REVOKE ALL ON TABLE public.friendships FROM anon;
REVOKE ALL ON TABLE public.xp_events FROM anon;
GRANT SELECT, DELETE ON TABLE public.friendships TO authenticated;
GRANT SELECT, INSERT ON TABLE public.xp_events TO authenticated;

CREATE OR REPLACE FUNCTION public.protect_profile_handle()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.handle IS DISTINCT FROM OLD.handle
     AND current_user IN ('authenticated', 'anon') THEN
    RAISE EXCEPTION 'use_update_my_handle';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_handle ON public.profiles;
CREATE TRIGGER profiles_protect_handle
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_handle();

REVOKE ALL ON FUNCTION public.protect_profile_handle() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.protect_profile_handle() FROM anon;
REVOKE ALL ON FUNCTION public.protect_profile_handle() FROM authenticated;
