-- Read-only, order-independent checksum of affected creator/default ACLs.
-- Scope matches the migration: postgres global/public/staging defaults.
select md5(coalesce(string_agg(
 row(pg_get_userbyid(d.defaclrole),coalesce(n.nspname,''),d.defaclobjtype,
  (select jsonb_agg(row(
    case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end,
    pg_get_userbyid(a.grantor),a.privilege_type,a.is_grantable
   )::text order by a.grantee,a.grantor,a.privilege_type,a.is_grantable)
   from aclexplode(d.defaclacl) a))::text,
 chr(10) order by pg_get_userbyid(d.defaclrole),coalesce(n.nspname,''),d.defaclobjtype
 ),'')) from pg_default_acl d left join pg_namespace n on n.oid=d.defaclnamespace
 where d.defaclrole=(select oid from pg_roles where rolname='postgres')
 and (d.defaclnamespace=0 or n.nspname in ('public','staging'));
