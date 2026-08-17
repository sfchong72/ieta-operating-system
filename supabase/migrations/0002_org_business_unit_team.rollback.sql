-- Rollback for 0002_org_business_unit_team.sql.
-- NOT applied automatically — kept here for reference and only run manually if
-- Milestone 1 needs to be reverted. Fully restores departments to its pre-0002
-- shape and removes only what 0002 added; touches nothing from 0001.

update departments set business_unit_id = null;
alter table departments drop column if exists business_unit_id;

drop table if exists teams;
drop table if exists business_units;
drop table if exists organisations;
