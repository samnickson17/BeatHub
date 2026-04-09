-- BeatHub initial Supabase schema.
-- Run with: supabase db push (or via SQL editor).

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  username text not null unique,
  display_name text not null,
  role text not null default 'buyer' check (role in ('buyer', 'producer', 'admin')),
  bio text not null default '',
  genres text[] not null default '{}',
  avatar_url text,
  followers_count integer not null default 0,
  following_count integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists profiles_username_lower_idx on public.profiles(lower(username));
create index if not exists profiles_display_name_lower_idx on public.profiles(lower(display_name));

create table if not exists public.beats (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  producer_id uuid not null references public.profiles(id) on delete cascade,
  producer_name text not null,
  genre text not null,
  bpm integer not null,
  basic_license_price numeric(12, 2) not null,
  premium_license_price numeric(12, 2) not null,
  exclusive_license_price numeric(12, 2) not null,
  description text not null default '',
  audio_url text not null,
  cover_art_url text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists beats_producer_id_idx on public.beats(producer_id);
create index if not exists beats_created_at_idx on public.beats(created_at desc);

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  beat_id uuid not null,
  beat_title text not null,
  beat_producer text not null,
  beat_producer_id uuid not null,
  beat_genre text not null,
  beat_bpm integer not null,
  beat_basic_price numeric(12, 2) not null,
  beat_premium_price numeric(12, 2) not null,
  beat_exclusive_price numeric(12, 2) not null,
  beat_description text not null,
  beat_audio_url text not null,
  beat_cover_art_url text,
  buyer_user_id uuid not null references public.profiles(id) on delete cascade,
  buyer_name text not null,
  buyer_username text not null,
  buyer_email text not null,
  license text not null,
  price_paid numeric(12, 2) not null,
  transaction_id text not null,
  purchased_at timestamptz not null default timezone('utc', now())
);

create index if not exists purchases_buyer_idx on public.purchases(buyer_user_id);
create index if not exists purchases_seller_idx on public.purchases(beat_producer_id);
create index if not exists purchases_purchased_at_idx on public.purchases(purchased_at desc);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

create index if not exists follows_followed_idx on public.follows(followed_id);

alter table public.profiles enable row level security;
alter table public.beats enable row level security;
alter table public.purchases enable row level security;
alter table public.follows enable row level security;

-- Profiles policies

drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated
on public.profiles
for select
to authenticated
using (true);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Beats policies

drop policy if exists beats_select_authenticated on public.beats;
create policy beats_select_authenticated
on public.beats
for select
to authenticated
using (true);

drop policy if exists beats_insert_own on public.beats;
create policy beats_insert_own
on public.beats
for insert
to authenticated
with check (producer_id = auth.uid());

drop policy if exists beats_update_own on public.beats;
create policy beats_update_own
on public.beats
for update
to authenticated
using (producer_id = auth.uid())
with check (producer_id = auth.uid());

drop policy if exists beats_delete_own on public.beats;
create policy beats_delete_own
on public.beats
for delete
to authenticated
using (producer_id = auth.uid());

-- Purchases policies

drop policy if exists purchases_select_owner_or_seller on public.purchases;
create policy purchases_select_owner_or_seller
on public.purchases
for select
to authenticated
using (buyer_user_id = auth.uid() or beat_producer_id = auth.uid());

drop policy if exists purchases_insert_owner on public.purchases;
create policy purchases_insert_owner
on public.purchases
for insert
to authenticated
with check (buyer_user_id = auth.uid());

-- Follows policies

drop policy if exists follows_select_authenticated on public.follows;
create policy follows_select_authenticated
on public.follows
for select
to authenticated
using (true);

drop policy if exists follows_insert_self on public.follows;
create policy follows_insert_self
on public.follows
for insert
to authenticated
with check (follower_id = auth.uid());

drop policy if exists follows_delete_self on public.follows;
create policy follows_delete_self
on public.follows
for delete
to authenticated
using (follower_id = auth.uid());

create or replace function public.refresh_follow_counts(target_uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set
    following_count = (
      select count(*)::int
      from public.follows
      where follower_id = target_uid
    ),
    followers_count = (
      select count(*)::int
      from public.follows
      where followed_id = target_uid
    )
  where id = target_uid;
end;
$$;

create or replace function public.follow_user(target_uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'Not authenticated';
  end if;
  if me = target_uid then
    raise exception 'Cannot follow yourself';
  end if;

  insert into public.follows(follower_id, followed_id)
  values (me, target_uid)
  on conflict do nothing;

  perform public.refresh_follow_counts(me);
  perform public.refresh_follow_counts(target_uid);
end;
$$;

create or replace function public.unfollow_user(target_uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.follows
  where follower_id = me and followed_id = target_uid;

  perform public.refresh_follow_counts(me);
  perform public.refresh_follow_counts(target_uid);
end;
$$;

grant execute on function public.follow_user(uuid) to authenticated;
grant execute on function public.unfollow_user(uuid) to authenticated;

do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit)
  values ('beats', 'beats', true, 52428800)
  on conflict (id) do nothing;

  insert into storage.buckets (id, name, public, file_size_limit)
  values ('avatars', 'avatars', true, 10485760)
  on conflict (id) do nothing;
end $$;

drop policy if exists storage_public_read_beats on storage.objects;
create policy storage_public_read_beats
on storage.objects
for select
to public
using (bucket_id = 'beats');

drop policy if exists storage_authenticated_write_beats on storage.objects;
create policy storage_authenticated_write_beats
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'beats'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists storage_authenticated_update_beats on storage.objects;
create policy storage_authenticated_update_beats
on storage.objects
for update
to authenticated
using (
  bucket_id = 'beats'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'beats'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists storage_authenticated_delete_beats on storage.objects;
create policy storage_authenticated_delete_beats
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'beats'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists storage_public_read_avatars on storage.objects;
create policy storage_public_read_avatars
on storage.objects
for select
to public
using (bucket_id = 'avatars');

drop policy if exists storage_authenticated_write_avatars on storage.objects;
create policy storage_authenticated_write_avatars
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists storage_authenticated_update_avatars on storage.objects;
create policy storage_authenticated_update_avatars
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists storage_authenticated_delete_avatars on storage.objects;
create policy storage_authenticated_delete_avatars
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);
