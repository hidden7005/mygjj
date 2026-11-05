-- v0.054: 닉네임 형식 변경 = 수식어(50) + 중국 요리(60 + 간짜장) + 숫자 001~999 → 3,046,950가지, 최대 11글자
-- 이미 가입한 계정의 닉네임은 바꾸지 않음. 새로 가입하는 계정부터 적용.
create or replace function gen_nickname() returns text
language plpgsql security definer set search_path = public as $$
declare
  m text[] := array['화끈한','삐진','신난','우울한','도도한','당당한','수줍은','냉정한','멍한','덜렁대는','꼼꼼한','친절한','배고픈','졸린','촉촉한','말랑한','듬직한','날씬한','뚱뚱한','털털한','똑똑한','엉뚱한','매콤한','고소한','달콤한','바삭한','쫄깃한','상큼한','짭짤한','뜨끈한','든든한','몽글한','포근한','행복한','씩씩한','용감한','느긋한','부지런한','궁금한','심심한','수상한','깜찍한','귀여운','상냥한','조용한','바쁜','빠른','반짝이는','시원한','신중한'];
  d text[] := array['탕수육','짬뽕','깐풍기','유린기','마파두부','군만두','볶음밥','울면','양장피','팔보채','크림새우','멘보샤','고추잡채','꿔바로우','깐쇼새우','라조육','라조기','유산슬','난자완스','동파육','마라탕','훠궈','딤섬','소룡포','춘권','물만두','찐만두','꽃빵','샹궈','깐풍육','칠리새우','홍소육','어향육슬','게살수프','샥스핀','북경오리','오향장육','냉채','잡채밥','잡탕밥','짬뽕밥','사천탕면','우육면','탄탄면','볶음면','고기만두','탕후루','월병','새우만두','하가우','차돌짬뽕','삼선짬뽕','깐풍새우','누룽지탕','양꼬치','부용게','해삼탕','전가복','어향가지','경장육슬','간짜장'];
  n text; i int := 0;
begin
  loop
    n := m[1 + floor(random() * array_length(m, 1))::int]
      || d[1 + floor(random() * array_length(d, 1))::int]
      || lpad((1 + floor(random() * 999))::int::text, 3, '0');
    exit when not exists (select 1 from profiles where username = n);
    i := i + 1;
    if i >= 30 then n := '간짜장' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8); exit; end if;
  end loop;
  return n;
end $$;
revoke all on function gen_nickname() from public, anon, authenticated;

-- 닉네임 다시 뽑기: 계정당 3번까지 (기존 계정 포함, 모두 0회에서 시작)
alter table profiles add column if not exists nickname_changes smallint not null default 0;

create or replace function reroll_nickname() returns json
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); used smallint; newname text;
begin
  if uid is null then raise exception '로그인이 필요해요'; end if;
  select nickname_changes into used from profiles where id = uid for update;
  if not found then raise exception '프로필을 찾을 수 없어요'; end if;
  if used >= 3 then raise exception '닉네임은 3번까지만 바꿀 수 있어요'; end if;
  newname := gen_nickname();
  update profiles set username = newname, nickname_changes = used + 1 where id = uid;
  return json_build_object('username', newname, 'left', 3 - (used + 1));
end $$;
revoke all on function reroll_nickname() from public, anon;
grant execute on function reroll_nickname() to authenticated;
