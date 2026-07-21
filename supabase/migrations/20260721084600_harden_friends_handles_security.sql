-- Tighten profiles SELECT and revoke anon execute on SECURITY DEFINER RPCs.

DROP POLICY IF EXISTS profiles_select_by_handle ON public.profiles;

DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

REVOKE ALL ON FUNCTION public.update_my_handle(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_my_handle(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_my_handle(text) TO authenticated;

REVOKE ALL ON FUNCTION public.add_friend_by_handle(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.add_friend_by_handle(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.add_friend_by_handle(text) TO authenticated;

REVOKE ALL ON FUNCTION public.remove_friend(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.remove_friend(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.remove_friend(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.friends_leaderboard(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.friends_leaderboard(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.friends_leaderboard(text) TO authenticated;

REVOKE ALL ON FUNCTION public.friend_public_stats(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.friend_public_stats(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.friend_public_stats(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.log_xp_event(int, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.log_xp_event(int, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.log_xp_event(int, text) TO authenticated;

REVOKE ALL ON FUNCTION public.are_friends(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.are_friends(uuid, uuid) FROM anon;
REVOKE ALL ON FUNCTION public.are_friends(uuid, uuid) FROM authenticated;

REVOKE ALL ON FUNCTION public.normalize_handle_base(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.normalize_handle_base(text) FROM anon;
REVOKE ALL ON FUNCTION public.normalize_handle_base(text) FROM authenticated;

REVOKE ALL ON FUNCTION public.random_handle_base() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.random_handle_base() FROM anon;
REVOKE ALL ON FUNCTION public.random_handle_base() FROM authenticated;

REVOKE ALL ON FUNCTION public.allocate_unique_handle(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.allocate_unique_handle(text) FROM anon;
REVOKE ALL ON FUNCTION public.allocate_unique_handle(text) FROM authenticated;

REVOKE ALL ON FUNCTION public.handle_from_email(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_from_email(text) FROM anon;
REVOKE ALL ON FUNCTION public.handle_from_email(text) FROM authenticated;
