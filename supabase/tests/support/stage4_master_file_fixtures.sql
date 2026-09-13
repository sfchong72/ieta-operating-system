-- Synthetic fixtures for the local-only IEOS Stage 4 master-file gate.
-- Run after the Stage 1, Stage 2 and Stage 3 fixtures.
begin;

insert into public.master_files (
  id, file_number, file_name, business_unit_id, department_id, project_reference,
  category_slug, description, owner_profile_id, access_level, status,
  master_url, folder_url, source_system, created_by, last_verified_at, remarks
) values
  (
    '77000000-0000-0000-0000-000000000001', 'MF-TEST-001', 'Social Media Operating Guide',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    'Stage 4 Campaign', 'sop', 'Current operating guide for publishing work.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'current',
    'https://docs.google.com/document/d/stage4-guide', 'https://drive.google.com/drive/folders/stage4-guide',
    'google_docs', '71000000-0000-0000-0000-000000000002', now(), 'Synthetic operational record.'
  ),
  (
    '77000000-0000-0000-0000-000000000002', 'MF-TEST-002', 'Campaign Brief Template',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    'Stage 4 Campaign', 'template', 'Reusable full-time campaign briefing template.',
    '71000000-0000-0000-0000-000000000003', 'full_time_only', 'current',
    'https://docs.google.com/document/d/stage4-template', null,
    'google_docs', '71000000-0000-0000-0000-000000000002', now(), null
  ),
  (
    '77000000-0000-0000-0000-000000000003', 'MF-TEST-003', 'Management Partnership Proposal',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'proposal', 'Management-only partnership proposal.',
    '71000000-0000-0000-0000-000000000002', 'management_only', 'current',
    'https://docs.google.com/presentation/d/stage4-proposal', null,
    'google_slides', '71000000-0000-0000-0000-000000000001', now(), null
  ),
  (
    '77000000-0000-0000-0000-000000000004', 'MF-TEST-004', 'Appointed Campaign Artwork',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    'Stage 4 Campaign', 'design_artwork', 'Artwork limited to appointed personnel.',
    '71000000-0000-0000-0000-000000000003', 'appointed_personnel', 'current',
    'https://www.canva.com/design/stage4-artwork', null,
    'canva', '71000000-0000-0000-0000-000000000002', now(), null
  ),
  (
    '77000000-0000-0000-0000-000000000005', 'MF-TEST-005', 'Restricted Contract Reference',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'hr', 'P&C reference metadata only.',
    '71000000-0000-0000-0000-000000000003', 'pc_restricted', 'current',
    'https://drive.google.com/file/d/stage4-restricted', null,
    'google_drive', '71000000-0000-0000-0000-000000000001', now(), 'No personal data is stored here.'
  ),
  (
    '77000000-0000-0000-0000-000000000006', 'MF-TEST-006', 'IEA Research Library',
    '00000000-0000-0000-0002-000000000002', 'a1000000-0000-0000-0000-000000000001',
    null, 'research', 'Operational research in another business unit.',
    '71000000-0000-0000-0000-000000000008', 'operational', 'current',
    'https://www.notion.so/stage4-research', null,
    'notion', '71000000-0000-0000-0000-000000000001', now(), null
  ),
  (
    '77000000-0000-0000-0000-000000000007', 'MF-TEST-007', 'Lead Sheet Under Review',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'lead_source', 'Review record deliberately missing its master link.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'under_review',
    null, null, 'other_url', '71000000-0000-0000-0000-000000000002', null, null
  ),
  (
    '77000000-0000-0000-0000-000000000008', 'MF-TEST-008', 'Operating Guide Copy',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'other', 'Review record sharing an existing master URL.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'under_review',
    'https://docs.google.com/document/d/stage4-guide', null,
    'google_docs', '71000000-0000-0000-0000-000000000002', null, null
  ),
  (
    '77000000-0000-0000-0000-000000000009', 'MF-TEST-009', 'Historical Training Pack',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'training_material', 'Preserved historical version.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'superseded',
    'https://drive.google.com/file/d/stage4-training-old', null,
    'google_drive', '71000000-0000-0000-0000-000000000002', now() - interval '100 days', null
  ),
  (
    '77000000-0000-0000-0000-000000000010', 'MF-TEST-010', 'Current Training Pack',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'training_material', 'Current replacement training pack.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'current',
    'https://drive.google.com/file/d/stage4-training-current', null,
    'google_drive', '71000000-0000-0000-0000-000000000002', now(), null
  ),
  (
    '77000000-0000-0000-0000-000000000011', 'MF-TEST-011', 'Stale Brochure Record',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'brochure', 'Current record needing periodic verification.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'current',
    'https://drive.google.com/file/d/stage4-brochure', null,
    'google_drive', '71000000-0000-0000-0000-000000000002', now() - interval '120 days', null
  ),
  (
    '77000000-0000-0000-0000-000000000012', 'MF-TEST-012', 'Legacy Form Still Marked Current',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'form', 'Synthetic cleanup anomaly: a replacement already exists.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'current',
    'https://docs.google.com/document/d/stage4-form-old', null,
    'google_docs', '71000000-0000-0000-0000-000000000002', now(), null
  ),
  (
    '77000000-0000-0000-0000-000000000013', 'MF-TEST-013', 'Replacement Form Record',
    '00000000-0000-0000-0002-000000000001', 'a0000000-0000-0000-0000-000000000001',
    null, 'form', 'Synthetic replacement used to detect an unresolved status anomaly.',
    '71000000-0000-0000-0000-000000000003', 'operational', 'current',
    'https://docs.google.com/document/d/stage4-form-new', null,
    'google_docs', '71000000-0000-0000-0000-000000000002', now(), null
  );

update public.master_files
set supersedes_file_id = '77000000-0000-0000-0000-000000000009'
where id = '77000000-0000-0000-0000-000000000010';

update public.master_files
set supersedes_file_id = '77000000-0000-0000-0000-000000000012'
where id = '77000000-0000-0000-0000-000000000013';

insert into public.master_file_access_grants (
  master_file_id, profile_id, grant_type, grant_reason, granted_by
) values
  ('77000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000002', 'appointed_personnel', 'explicit', '71000000-0000-0000-0000-000000000001'),
  ('77000000-0000-0000-0000-000000000004', '71000000-0000-0000-0000-000000000003', 'appointed_personnel', 'owner', '71000000-0000-0000-0000-000000000001'),
  ('77000000-0000-0000-0000-000000000005', '71000000-0000-0000-0000-000000000003', 'pc_restricted', 'explicit', '71000000-0000-0000-0000-000000000001');

insert into public.master_file_tasks (master_file_id, task_id, linked_by) values
  ('77000000-0000-0000-0000-000000000001', '72000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000002');

insert into public.master_file_artifacts (master_file_id, task_artifact_id, linked_by) values
  ('77000000-0000-0000-0000-000000000001', '73000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000002');

insert into public.master_file_events (master_file_id, actor_id, event_type, metadata) values
  ('77000000-0000-0000-0000-000000000001', '71000000-0000-0000-0000-000000000002', 'created', '{"fixture":true}'),
  ('77000000-0000-0000-0000-000000000005', '71000000-0000-0000-0000-000000000001', 'created', '{"fixture":true}');

commit;
