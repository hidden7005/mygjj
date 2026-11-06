-- v0.059: 회원 탈퇴. 계정·프로필은 삭제, 리뷰·별점·사진은 작성자 연결을 끊어 익명으로 남김
create or replace function delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception '로그인이 필요해요'; end if;
  update reviews set user_id = null where user_id = uid;   -- 익명 처리 (누가 썼는지 알 수 없게)
  update places set created_by = null where created_by = uid;
  delete from auth.users where id = uid;                   -- profiles, 즐겨찾기, 팔로우, 가격 투표는 연쇄 삭제
end $$;
revoke all on function delete_my_account() from public, anon;
grant execute on function delete_my_account() to authenticated;
