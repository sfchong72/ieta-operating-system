-- Synthetic local-only fixtures for the Stage 5 restricted lead gate.
begin;

insert into public.marketing_lead_access_grants(profile_id,business_unit_id,department_id,can_manage,granted_by) values
 ('71000000-0000-0000-0000-000000000002','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001',true,'71000000-0000-0000-0000-000000000001'),
 ('71000000-0000-0000-0000-000000000003','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001',false,'71000000-0000-0000-0000-000000000001'),
 ('71000000-0000-0000-0000-000000000004','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001',false,'71000000-0000-0000-0000-000000000001'),
 ('71000000-0000-0000-0000-000000000008','00000000-0000-0000-0002-000000000002','a1000000-0000-0000-0000-000000000001',false,'71000000-0000-0000-0000-000000000001');

insert into public.marketing_leads(
 id,lead_number,date_received,business_unit_id,department_id,branch,source_slug,
 project_reference,name,contact_number,email,country,nationality,programme_interest,
 assigned_to_profile_id,status,last_contact_at,next_follow_up_at,contact_result,
 consultation_date,final_outcome,estimated_or_actual_value,source_reference_url,remarks,created_by
) values
 ('78000000-0000-0000-0000-000000000001','LEAD-TEST-001',now()-interval '30 hours','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001','Kuala Lumpur','website','Stage 5 Intake','TEST Lead One','+60 12-111 0001','lead.one@example.test','Malaysia','Malaysian','Japanese Diploma','71000000-0000-0000-0000-000000000003','new',null,null,null,null,null,2500,'https://example.test/private/source-one','Synthetic lead one.','71000000-0000-0000-0000-000000000001'),
 ('78000000-0000-0000-0000-000000000002','LEAD-TEST-002',now()-interval '5 days','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001','Kuala Lumpur','google_ads','Stage 5 Intake','TEST Lead Two','+60 12-222 0002','lead.two@example.test','Malaysia','Malaysian','English Programme','71000000-0000-0000-0000-000000000003','follow_up',now()-interval '3 days',now()-interval '1 day','Requested course schedule.',null,null,3200,'https://example.test/private/source-two','Synthetic lead two.','71000000-0000-0000-0000-000000000001'),
 ('78000000-0000-0000-0000-000000000003','LEAD-TEST-003',now()-interval '2 days','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001','Kuala Lumpur','whatsapp','Stage 5 Intake','TEST Intern Lead','+60 12-333 0003','intern.lead@example.test','Malaysia','Malaysian','Korean Programme','71000000-0000-0000-0000-000000000004','contacted',now()-interval '1 day',date_trunc('day',now())+interval '16 hours','Initial response sent.',null,null,null,'https://example.test/private/intern','Synthetic intern lead.','71000000-0000-0000-0000-000000000001'),
 ('78000000-0000-0000-0000-000000000004','LEAD-TEST-004',now()-interval '4 days','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001','Kuala Lumpur','open_day','Stage 5 Intake','TEST Consultation Lead','+60 12-444 0004','consultation@example.test','Malaysia','Malaysian','Mandarin Programme','71000000-0000-0000-0000-000000000003','consultation_booked',now()-interval '1 day',now()+interval '3 days','Consultation arranged.',now()+interval '3 days',null,4100,'https://example.test/private/open-day','Synthetic consultation.','71000000-0000-0000-0000-000000000001'),
 ('78000000-0000-0000-0000-000000000005','LEAD-TEST-005',now()-interval '10 days','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001','Kuala Lumpur','referral','Stage 5 Intake','TEST Signed Lead','+60 12-555 0005','signed@example.test','Malaysia','Malaysian','Japanese Diploma','71000000-0000-0000-0000-000000000003','signed_up',now()-interval '2 days',null,'Registration confirmed.',null,'Signed up',5000,'https://example.test/private/referral','Synthetic closed lead.','71000000-0000-0000-0000-000000000001'),
 ('78000000-0000-0000-0000-000000000006','LEAD-TEST-006',now()-interval '2 days','00000000-0000-0000-0002-000000000002','a1000000-0000-0000-0000-000000000001','Penang','school_fair',null,'TEST Foreign Lead','+60 12-666 0006','foreign@example.test','Malaysia','Malaysian','IEA Programme','71000000-0000-0000-0000-000000000008','new',null,null,null,null,null,null,'https://example.test/private/foreign','Synthetic cross-scope lead.','71000000-0000-0000-0000-000000000001'),
 ('78000000-0000-0000-0000-000000000007','LEAD-TEST-007',now()-interval '1 day','00000000-0000-0000-0002-000000000001','a0000000-0000-0000-0000-000000000001','Kuala Lumpur','meta_ads','Stage 5 Intake','TEST Lead Two','60122220002','lead.two@example.test','Malaysia','Malaysian','English Programme','71000000-0000-0000-0000-000000000003','new',null,null,null,null,null,null,'https://example.test/private/duplicate','Synthetic duplicate candidate.','71000000-0000-0000-0000-000000000001');

insert into public.lead_interactions(id,lead_id,interaction_at,interaction_type,performed_by,result,next_action,next_follow_up_at,evidence_reference_url) values
 ('79000000-0000-0000-0000-000000000001','78000000-0000-0000-0000-000000000002',now()-interval '3 days','call','71000000-0000-0000-0000-000000000003','Requested course schedule.','Send schedule and call again.',now()-interval '1 day','https://example.test/private/call-note'),
 ('79000000-0000-0000-0000-000000000002','78000000-0000-0000-0000-000000000004',now()-interval '1 day','whatsapp','71000000-0000-0000-0000-000000000003','Consultation arranged.','Prepare consultation.',now()+interval '3 days',null);

insert into public.marketing_lead_events(lead_id,actor_id,event_type,metadata)
select id,created_by,'created',jsonb_build_object('fixture',true) from public.marketing_leads where lead_number like 'LEAD-TEST-%';

commit;

