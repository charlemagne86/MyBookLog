-- PLAIN ENGLISH: Belt-and-suspenders — make doubly sure that visitors who
-- are not logged in cannot even attempt the add-book procedure. (It already
-- rejects them internally; this removes their permission to call it at all.)
--
-- Defense in depth: only authenticated users may call the add-book RPC.
revoke execute on function public.add_book_to_shelf(text, text, text, text) from anon;
