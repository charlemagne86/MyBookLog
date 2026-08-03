-- PLAIN ENGLISH: Belt-and-suspenders, again — the previous migration
-- (20260716181757) revoked anonymous execute access on the add-book
-- procedure, but the migration right before this one had to drop and
-- recreate that procedure (to add the new book-detail parameters), and this
-- project's default privileges automatically re-grant EXECUTE on every new
-- function to `anon` and `authenticated`. That silently undid the earlier
-- revoke. This puts it back: only logged-in users may call the RPC (it
-- already rejects anonymous callers internally — this removes their
-- permission to call it at all).
revoke execute on function public.add_book_to_shelf(
  text, text, text, text, text, integer, text, text, text[], numeric, integer
) from anon;
