-- Rollback for 0004_content_core.sql.
-- NOT applied automatically. Drops the 3 new tables entirely — since they
-- are brand new (not a modification of an existing table), rollback is
-- simply removing them; content_ideas/content_tasks are completely
-- untouched by 0004 in either direction.

drop table if exists platform_publications;
drop table if exists content_items;
drop table if exists campaigns;
