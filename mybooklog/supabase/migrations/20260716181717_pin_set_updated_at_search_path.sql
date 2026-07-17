-- PLAIN ENGLISH: A small security hardening. This helper automatically
-- stamps the "last updated" time on records whenever they change. Here we
-- pin down exactly where it may look up names, closing a known trick where
-- an attacker plants a look-alike function for it to call by accident.
--
-- SEC-6: pin an immutable search_path on the trigger function.
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
