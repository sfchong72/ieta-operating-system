-- Stage 5 follow-up: make the existing Inter Excel companies selectable and
-- provide a tightly-scoped way for authorised lead managers to maintain the
-- campaign choices used by the Lead Register.

-- Company activation is a separate operational decision. All four units exist
-- already; disposable fixtures may activate them for cross-company tests.

create or replace function public.create_marketing_campaign(
  p_business_unit_id uuid,
  p_department_id uuid,
  p_name text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  campaign_id uuid;
begin
  if uid is null then
    raise exception using errcode = '42501', message = 'Sign in to create a campaign.';
  end if;

  if not public.fn_ml_can_manage_scope(uid, p_business_unit_id, p_department_id) then
    raise exception using errcode = '42501', message = 'Selected scope is outside your Lead Register access.';
  end if;

  if nullif(btrim(p_name), '') is null then
    raise exception using errcode = '22023', message = 'Enter a campaign name.';
  end if;

  if not exists (
    select 1
    from public.departments department
    where department.id = p_department_id
      and department.business_unit_id = p_business_unit_id
  ) then
    raise exception using errcode = '22023', message = 'Choose a department belonging to the selected business unit.';
  end if;

  if exists (
    select 1
    from public.campaigns campaign
    where campaign.business_unit_id = p_business_unit_id
      and campaign.department_id = p_department_id
      and lower(btrim(campaign.name)) = lower(btrim(p_name))
      and campaign.status <> 'archived'
  ) then
    raise exception using errcode = '23505', message = 'An active campaign with this name already exists in the selected scope.';
  end if;

  insert into public.campaigns (
    business_unit_id,
    department_id,
    name,
    status,
    user_id
  ) values (
    p_business_unit_id,
    p_department_id,
    btrim(p_name),
    'active',
    uid
  )
  returning id into campaign_id;

  return campaign_id;
end;
$$;

revoke all on function public.create_marketing_campaign(uuid, uuid, text) from public, anon;
grant execute on function public.create_marketing_campaign(uuid, uuid, text) to authenticated;
