-- Run once in Supabase SQL Editor. Authenticated accounts are created by the owner.
create table if not exists public.suppliers(id bigint generated always as identity primary key,name text not null unique check(length(trim(name))>0));
create table if not exists public.receipts(id bigint generated always as identity primary key,supplier_id bigint not null references public.suppliers(id),lot text not null default '',total_kg integer not null check(total_kg>0),quantity integer not null check(quantity>0 and quantity<=10000),received_at timestamptz not null default now());
create table if not exists public.bales(id bigint generated always as identity primary key,code text generated always as ('BL-' || lpad(id::text,8,'0')) stored unique,receipt_id bigint not null references public.receipts(id) on delete cascade,weight_kg integer not null check(weight_kg>0),status text not null default 'CLOSED' check(status in ('CLOSED','OPEN')),opened_at timestamptz);
create index if not exists bales_receipt_idx on public.bales(receipt_id);
create index if not exists receipts_date_idx on public.receipts(received_at);
alter table public.suppliers enable row level security;
alter table public.receipts enable row level security;
alter table public.bales enable row level security;
create policy "signed in suppliers" on public.suppliers for all to authenticated using(true) with check(true);
create policy "signed in receipts" on public.receipts for select to authenticated using(true);
create policy "signed in bales" on public.bales for select to authenticated using(true);
create or replace function public.create_receipt(p_supplier bigint,p_lot text,p_total integer,p_quantity integer)
returns bigint language plpgsql security definer set search_path = '' as $$
declare rid bigint; base integer; rem integer;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if p_quantity is null or p_quantity<1 or p_quantity>10000 or p_total is null or p_total<p_quantity then raise exception 'Invalid quantity or weight'; end if;
 if not exists(select 1 from public.suppliers where id=p_supplier) then raise exception 'Supplier not found'; end if;
 insert into public.receipts(supplier_id,lot,total_kg,quantity) values(p_supplier,coalesce(p_lot,''),p_total,p_quantity) returning id into rid;
 base:=p_total/p_quantity;rem:=p_total%p_quantity;
 insert into public.bales(receipt_id,weight_kg) select rid,base+case when n<=rem then 1 else 0 end from generate_series(1,p_quantity) n;
 return rid;
end $$;
create or replace function public.set_bale_status(p_id bigint,p_status text)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if p_status not in ('OPEN','CLOSED') then raise exception 'Invalid status'; end if;
 update public.bales set status=p_status,opened_at=case when p_status='OPEN' then now() else opened_at end where id=p_id;
 if not found then raise exception 'Bale not found'; end if;
end $$;
create or replace function public.delete_bale(p_id bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare rid bigint;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select receipt_id into rid from public.bales where id=p_id for update;
 if rid is null then raise exception 'Bale not found'; end if;
 delete from public.bales where id=p_id;
 -- Preserve receipt as original receipt record; totals and quantity represent original intake.
end $$;
create or replace function public.delete_receipt(p_id bigint)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 delete from public.receipts where id=p_id;
 if not found then raise exception 'Receipt not found'; end if;
end $$;
revoke all on function public.create_receipt(bigint,text,integer,integer) from public,anon;
revoke all on function public.set_bale_status(bigint,text) from public,anon;
revoke all on function public.delete_bale(bigint) from public,anon;
revoke all on function public.delete_receipt(bigint) from public,anon;
grant execute on function public.create_receipt(bigint,text,integer,integer),public.set_bale_status(bigint,text),public.delete_bale(bigint),public.delete_receipt(bigint) to authenticated;
grant select on public.suppliers,public.receipts,public.bales to authenticated;
grant insert on public.suppliers to authenticated;
grant usage,select on sequence public.suppliers_id_seq to authenticated;
