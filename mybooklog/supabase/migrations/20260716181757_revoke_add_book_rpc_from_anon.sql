-- Defense in depth: only authenticated users may call the add-book RPC.
revoke execute on function public.add_book_to_shelf(text, text, text, text) from anon;
