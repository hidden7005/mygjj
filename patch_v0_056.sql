-- v0.056: 가입 후 닉네임 안내 팝업을 한 번만 보여주기 위한 표시
alter table profiles add column if not exists nickname_welcomed boolean not null default false;

create or replace function ack_nickname_welcome() returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception '로그인이 필요해요'; end if;
  update profiles set nickname_welcomed = true where id = auth.uid();
end $$;
revoke all on function ack_nickname_welcome() from public, anon;
grant execute on function ack_nickname_welcome() to authenticated;
