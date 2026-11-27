CREATE TABLE "np_agent_actions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"run_id" uuid,
	"run_fingerprint" text,
	"run_source_release_id" uuid,
	"invocation_id" uuid,
	"invocation_fingerprint" text NOT NULL,
	"execution_invocation_id" uuid,
	"execution_invocation_fingerprint" text,
	"sequence" integer NOT NULL,
	"capability_id" text NOT NULL,
	"capability_contract_version" integer NOT NULL,
	"capability_fingerprint" text NOT NULL,
	"capability_definition_body" jsonb NOT NULL,
	"effect_profile_id" text NOT NULL,
	"effect_contract_version" integer NOT NULL,
	"risk" text NOT NULL,
	"state" text NOT NULL,
	"idempotency_key" text,
	"input_redacted" jsonb NOT NULL,
	"input_canonical" jsonb NOT NULL,
	"required_scopes" text[] NOT NULL,
	"target_refs" jsonb NOT NULL,
	"target_version_facts" jsonb NOT NULL,
	"input_hash" text NOT NULL,
	"output_redacted" jsonb,
	"output_hash" text,
	"effect_digest" text,
	"target_version_digest" text,
	"verifier_id" text,
	"verification_state" text,
	"verification_result_digest" text,
	"verification_evidence" jsonb,
	"verified_at" timestamp with time zone,
	"undo_ref" jsonb,
	"compensator_id" text,
	"compensation_result_digest" text,
	"compensation_evidence" jsonb,
	"compensated_at" timestamp with time zone,
	"error_code" text,
	"approval_id" uuid,
	"containment_id" uuid,
	"enforcement_adapter_id" text,
	"enforcement_adapter_contract_version" integer,
	"enforcement_adapter_fingerprint" text,
	"compensates_action_id" uuid,
	"audit_event_id" uuid,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_actions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_actions_run_binding_unique" UNIQUE("site_id","run_id","id"),
	CONSTRAINT "np_agent_actions_invocation_sequence_unique" UNIQUE("invocation_id","sequence"),
	CONSTRAINT "np_agent_actions_sequence_check" CHECK ("np_agent_actions"."sequence" > 0),
	CONSTRAINT "np_agent_actions_contract_check" CHECK ("np_agent_actions"."capability_contract_version" > 0 and "np_agent_actions"."effect_contract_version" > 0),
	CONSTRAINT "np_agent_actions_risk_check" CHECK ("np_agent_actions"."risk" in ('read', 'reversible', 'sensitive', 'destructive')),
	CONSTRAINT "np_agent_actions_state_check" CHECK ("np_agent_actions"."state" in ('proposed', 'policy_blocked', 'approval_pending', 'approved', 'executing', 'succeeded', 'failed', 'compensated')),
	CONSTRAINT "np_agent_actions_attribution_check" CHECK (((("np_agent_actions"."run_id" is not null and "np_agent_actions"."run_fingerprint" is not null and "np_agent_actions"."run_source_release_id" is null) or
        ("np_agent_actions"."run_id" is null and "np_agent_actions"."run_fingerprint" is null and "np_agent_actions"."run_source_release_id" is null) or
        ("np_agent_actions"."run_id" is null and "np_agent_actions"."run_fingerprint" is not null and "np_agent_actions"."run_source_release_id" is not null)) and
        ("np_agent_actions"."execution_invocation_id" is null) = ("np_agent_actions"."execution_invocation_fingerprint" is null)) is true),
	CONSTRAINT "np_agent_actions_output_check" CHECK (("np_agent_actions"."output_redacted" is null) = ("np_agent_actions"."output_hash" is null)),
	CONSTRAINT "np_agent_actions_read_effect_check" CHECK ("np_agent_actions"."effect_profile_id" <> 'domain.read' or (
        "np_agent_actions"."risk" = 'read' and "np_agent_actions"."verifier_id" is null and "np_agent_actions"."verification_state" is null and
        "np_agent_actions"."verification_result_digest" is null and "np_agent_actions"."verification_evidence" is null and
        "np_agent_actions"."verified_at" is null and "np_agent_actions"."effect_digest" is null and "np_agent_actions"."target_version_digest" is null and
        "np_agent_actions"."undo_ref" is null and "np_agent_actions"."compensator_id" is null and
        "np_agent_actions"."compensation_result_digest" is null and "np_agent_actions"."compensation_evidence" is null and
        "np_agent_actions"."compensated_at" is null and "np_agent_actions"."approval_id" is null and "np_agent_actions"."containment_id" is null and
        "np_agent_actions"."enforcement_adapter_id" is null and "np_agent_actions"."enforcement_adapter_contract_version" is null and
        "np_agent_actions"."enforcement_adapter_fingerprint" is null and "np_agent_actions"."compensates_action_id" is null
      )),
	CONSTRAINT "np_agent_actions_terminal_check" CHECK ((("np_agent_actions"."state" in ('policy_blocked', 'succeeded', 'failed', 'compensated')) = ("np_agent_actions"."finished_at" is not null)) and
        (("np_agent_actions"."state" in ('policy_blocked', 'failed')) = ("np_agent_actions"."error_code" is not null)))
);
--> statement-breakpoint
CREATE TABLE "np_agent_actor_restrictions" (
	"id" uuid PRIMARY KEY NOT NULL,
	"site_id" text NOT NULL,
	"incident_id" uuid NOT NULL,
	"source_action_id" uuid NOT NULL,
	"removal_action_id" uuid,
	"descriptor" jsonb NOT NULL,
	"restriction_hash" text NOT NULL,
	"subject_key" text NOT NULL,
	"scope_digest" text NOT NULL,
	"adapter_id" text NOT NULL,
	"adapter_contract_version" integer NOT NULL,
	"adapter_fingerprint" text NOT NULL,
	"state" text NOT NULL,
	"install_receipt" jsonb,
	"removal_receipt" jsonb,
	"row_version" integer DEFAULT 1 NOT NULL,
	"last_error_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"activated_at" timestamp with time zone,
	"removed_at" timestamp with time zone,
	"revoked_at" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_actor_restrictions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_actor_restrictions_source_action_unique" UNIQUE("source_action_id"),
	CONSTRAINT "np_agent_actor_restrictions_removal_action_unique" UNIQUE("removal_action_id"),
	CONSTRAINT "np_agent_actor_restrictions_descriptor_check" CHECK ((jsonb_typeof("np_agent_actor_restrictions"."descriptor")='object' and octet_length("np_agent_actor_restrictions"."descriptor"::text)<=8192 and "np_agent_actor_restrictions"."descriptor"->>'restrictionId'="np_agent_actor_restrictions"."id"::text and "np_agent_actor_restrictions"."descriptor"->>'siteId'="np_agent_actor_restrictions"."site_id" and "np_agent_actor_restrictions"."descriptor"->>'schemaVersion'='np.agent-restriction.v1' and ("np_agent_actor_restrictions"."descriptor"->>'expiresAt')::timestamptz="np_agent_actor_restrictions"."expires_at") is true),
	CONSTRAINT "np_agent_actor_restrictions_bounds_check" CHECK (("np_agent_actor_restrictions"."restriction_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_actor_restrictions"."scope_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and length("np_agent_actor_restrictions"."subject_key") between 1 and 512 and length("np_agent_actor_restrictions"."adapter_id") between 1 and 128 and "np_agent_actor_restrictions"."adapter_contract_version">0 and length("np_agent_actor_restrictions"."adapter_fingerprint") between 1 and 256 and "np_agent_actor_restrictions"."row_version">0 and ("np_agent_actor_restrictions"."last_error_code" is null or "np_agent_actor_restrictions"."last_error_code" ~ '^[A-Z][A-Z0-9_]{0,63}$') and ("np_agent_actor_restrictions"."install_receipt" is null or (jsonb_typeof("np_agent_actor_restrictions"."install_receipt")='object' and octet_length("np_agent_actor_restrictions"."install_receipt"::text)<=4096)) and ("np_agent_actor_restrictions"."removal_receipt" is null or (jsonb_typeof("np_agent_actor_restrictions"."removal_receipt")='object' and octet_length("np_agent_actor_restrictions"."removal_receipt"::text)<=4096))) is true),
	CONSTRAINT "np_agent_actor_restrictions_state_check" CHECK (("np_agent_actor_restrictions"."state" in ('pending','active','removing','removed','expired','failed') and ("np_agent_actor_restrictions"."state"<>'active' or ("np_agent_actor_restrictions"."activated_at" is not null and "np_agent_actor_restrictions"."install_receipt" is not null)) and ("np_agent_actor_restrictions"."state" in ('removed','expired'))=("np_agent_actor_restrictions"."removed_at" is not null) and ("np_agent_actor_restrictions"."removed_at" is null or "np_agent_actor_restrictions"."removal_receipt" is not null) and ("np_agent_actor_restrictions"."removal_action_id" is null or "np_agent_actor_restrictions"."removal_action_id"<>"np_agent_actor_restrictions"."source_action_id")) is true),
	CONSTRAINT "np_agent_actor_restrictions_time_check" CHECK (("np_agent_actor_restrictions"."updated_at">="np_agent_actor_restrictions"."created_at" and "np_agent_actor_restrictions"."expires_at">("np_agent_actor_restrictions"."descriptor"->>'startsAt')::timestamptz and "np_agent_actor_restrictions"."expires_at">=("np_agent_actor_restrictions"."descriptor"->>'startsAt')::timestamptz+interval '60 seconds' and "np_agent_actor_restrictions"."expires_at"<=("np_agent_actor_restrictions"."descriptor"->>'startsAt')::timestamptz+interval '3600 seconds' and ("np_agent_actor_restrictions"."activated_at" is null or "np_agent_actor_restrictions"."activated_at">="np_agent_actor_restrictions"."created_at") and ("np_agent_actor_restrictions"."removed_at" is null or "np_agent_actor_restrictions"."removed_at">="np_agent_actor_restrictions"."created_at") and ("np_agent_actor_restrictions"."revoked_at" is null or "np_agent_actor_restrictions"."revoked_at">="np_agent_actor_restrictions"."created_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_approvals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"target_kind" text NOT NULL,
	"target_id" uuid NOT NULL,
	"target_changeset_id" uuid,
	"target_action_id" uuid,
	"target_rollback_plan_id" uuid,
	"generation" integer NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"plan_hash" text NOT NULL,
	"capability_id" text NOT NULL,
	"capability_contract_version" integer NOT NULL,
	"capability_fingerprint" text NOT NULL,
	"required_scopes" text[] NOT NULL,
	"required_human_capabilities" text[] NOT NULL,
	"required_human_predicates" text[] NOT NULL,
	"policy_hashes" text[] NOT NULL,
	"requires_live_preview" boolean NOT NULL,
	"preview_id" uuid,
	"preview_digest" text,
	"required_reauth_mode" text NOT NULL,
	"required_reauth_max_age_seconds" integer,
	"statement_body" jsonb NOT NULL,
	"statement_hash" text NOT NULL,
	"statement_mac" text NOT NULL,
	"integrity_key_id" text NOT NULL,
	"challenge_generation" integer DEFAULT 0 NOT NULL,
	"challenge_purpose" text,
	"challenge_hash" text,
	"challenge_hash_key_id" text,
	"challenge_issued_to_user_id" uuid,
	"challenge_session_fingerprint" text,
	"challenge_expires_at" timestamp with time zone,
	"challenge_consumed_at" timestamp with time zone,
	"state" text DEFAULT 'pending' NOT NULL,
	"risk" text NOT NULL,
	"requester_kind" text NOT NULL,
	"requested_by_principal_id" uuid,
	"requested_by_user_id" uuid,
	"requester_fingerprint" text NOT NULL,
	"requested_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"decided_by_user_id" uuid,
	"decider_fingerprint" text,
	"decision_body" jsonb,
	"decision_hash" text,
	"decision_mac" text,
	"decision_reauth_fingerprint" text,
	"decision_reauthenticated_at" timestamp with time zone,
	"decided_at" timestamp with time zone,
	"reason" text,
	"revocation_kind" text,
	"revoked_by_user_id" uuid,
	"revoker_fingerprint" text,
	"revocation_code" text,
	"revocation_reason" text,
	"revocation_body" jsonb,
	"revocation_hash" text,
	"revocation_mac" text,
	"revocation_integrity_key_id" text,
	"revoked_at" timestamp with time zone,
	"consumed_at" timestamp with time zone,
	CONSTRAINT "np_agent_approvals_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_approvals_generation_unique" UNIQUE("site_id","target_kind","target_id","plan_hash","generation"),
	CONSTRAINT "np_agent_approvals_target_check" CHECK ((("np_agent_approvals"."target_kind"='changeset' and "np_agent_approvals"."target_changeset_id"="np_agent_approvals"."target_id" and "np_agent_approvals"."target_action_id" is null and "np_agent_approvals"."target_rollback_plan_id" is null) or ("np_agent_approvals"."target_kind"='action' and "np_agent_approvals"."target_action_id"="np_agent_approvals"."target_id" and "np_agent_approvals"."target_changeset_id" is null and "np_agent_approvals"."target_rollback_plan_id" is null) or ("np_agent_approvals"."target_kind"='changeset_rollback' and "np_agent_approvals"."target_rollback_plan_id"="np_agent_approvals"."target_id" and "np_agent_approvals"."target_changeset_id" is not null and "np_agent_approvals"."target_action_id" is null)) is true),
	CONSTRAINT "np_agent_approvals_version_check" CHECK (("np_agent_approvals"."generation">0 and "np_agent_approvals"."version">0 and "np_agent_approvals"."capability_contract_version">0 and "np_agent_approvals"."challenge_generation">=0) is true),
	CONSTRAINT "np_agent_approvals_state_check" CHECK (("np_agent_approvals"."state" in ('pending','approved','rejected','expired','consumed','revoked') and "np_agent_approvals"."risk" in ('reversible','sensitive','destructive')) is true),
	CONSTRAINT "np_agent_approvals_requester_check" CHECK ((("np_agent_approvals"."requester_kind"='staff' and "np_agent_approvals"."requested_by_principal_id" is null) or ("np_agent_approvals"."requester_kind"='principal' and "np_agent_approvals"."requested_by_principal_id" is not null and "np_agent_approvals"."requested_by_user_id" is null)) is true),
	CONSTRAINT "np_agent_approvals_scope_check" CHECK ((cardinality("np_agent_approvals"."required_scopes") between 1 and 64 and array_position("np_agent_approvals"."required_scopes",null) is null and cardinality("np_agent_approvals"."required_human_capabilities") between 1 and 5 and "np_agent_approvals"."required_human_capabilities"<@array['site.access','content.author','content.publish','community.moderate','admin.manage']::text[] and array_position("np_agent_approvals"."required_human_capabilities",null) is null and "np_agent_approvals"."required_human_predicates"<@array['is-super-admin']::text[] and array_position("np_agent_approvals"."required_human_predicates",null) is null) is true),
	CONSTRAINT "np_agent_approvals_preview_check" CHECK ((("np_agent_approvals"."requires_live_preview" and "np_agent_approvals"."preview_id" is not null and "np_agent_approvals"."preview_digest" is not null) or (not "np_agent_approvals"."requires_live_preview" and "np_agent_approvals"."preview_id" is null and "np_agent_approvals"."preview_digest" is null)) is true),
	CONSTRAINT "np_agent_approvals_reauth_check" CHECK ((("np_agent_approvals"."required_reauth_mode"='none' and "np_agent_approvals"."required_reauth_max_age_seconds" is null) or ("np_agent_approvals"."required_reauth_mode"='recent-staff-primary' and "np_agent_approvals"."required_reauth_max_age_seconds" between 1 and 300)) is true),
	CONSTRAINT "np_agent_approvals_statement_check" CHECK ((jsonb_typeof("np_agent_approvals"."statement_body")='object' and "np_agent_approvals"."statement_body"->>'version'='np.agent-approval-statement.v1' and "np_agent_approvals"."statement_body"->>'siteId'="np_agent_approvals"."site_id" and "np_agent_approvals"."statement_body"->>'approvalId'="np_agent_approvals"."id"::text and "np_agent_approvals"."statement_body"->>'capabilityId'="np_agent_approvals"."capability_id" and "np_agent_approvals"."statement_body"->>'capabilityContractVersion'="np_agent_approvals"."capability_contract_version"::text and "np_agent_approvals"."statement_body"->>'capabilityFingerprint'="np_agent_approvals"."capability_fingerprint" and "np_agent_approvals"."statement_body"->'target'->>'kind'="np_agent_approvals"."target_kind" and
 (("np_agent_approvals"."target_kind"='changeset' and "np_agent_approvals"."statement_body"->'target'->>'changeSetId'="np_agent_approvals"."target_id"::text and "np_agent_approvals"."statement_body"->'target'->>'planHash'="np_agent_approvals"."plan_hash") or ("np_agent_approvals"."target_kind"='changeset_rollback' and "np_agent_approvals"."statement_body"->'target'->>'rollbackPlanId'="np_agent_approvals"."target_id"::text and "np_agent_approvals"."statement_body"->'target'->>'changeSetId'="np_agent_approvals"."target_changeset_id"::text and "np_agent_approvals"."statement_body"->'target'->>'planHash'="np_agent_approvals"."plan_hash") or ("np_agent_approvals"."target_kind"='action' and "np_agent_approvals"."statement_body"->'target'->>'actionId'="np_agent_approvals"."target_id"::text and "np_agent_approvals"."statement_body"->'target'->>'proposalHash'="np_agent_approvals"."plan_hash"))) is true),
	CONSTRAINT "np_agent_approvals_challenge_check" CHECK ((("np_agent_approvals"."challenge_hash" is null and "np_agent_approvals"."challenge_purpose" is null and "np_agent_approvals"."challenge_hash_key_id" is null and "np_agent_approvals"."challenge_issued_to_user_id" is null and "np_agent_approvals"."challenge_session_fingerprint" is null and "np_agent_approvals"."challenge_expires_at" is null) or
 ("np_agent_approvals"."challenge_generation">0 and "np_agent_approvals"."challenge_hash" is not null and "np_agent_approvals"."challenge_purpose" in ('approve','reject','revoke') and "np_agent_approvals"."challenge_hash_key_id" is not null and "np_agent_approvals"."challenge_issued_to_user_id" is not null and "np_agent_approvals"."challenge_session_fingerprint" is not null and "np_agent_approvals"."challenge_expires_at" is not null and "np_agent_approvals"."challenge_expires_at"<="np_agent_approvals"."expires_at")) is true),
	CONSTRAINT "np_agent_approvals_decision_check" CHECK (((
 ("np_agent_approvals"."decision_body" is null and "np_agent_approvals"."decision_hash" is null and "np_agent_approvals"."decision_mac" is null and "np_agent_approvals"."decider_fingerprint" is null and "np_agent_approvals"."decided_by_user_id" is null and "np_agent_approvals"."decided_at" is null and "np_agent_approvals"."decision_reauth_fingerprint" is null and "np_agent_approvals"."decision_reauthenticated_at" is null) or
 ("np_agent_approvals"."decision_body" is not null and "np_agent_approvals"."decision_hash" is not null and "np_agent_approvals"."decision_mac" is not null and "np_agent_approvals"."decider_fingerprint" is not null and "np_agent_approvals"."decided_at" is not null and
 "np_agent_approvals"."decision_body"->>'schemaVersion'='np.agent-approval-decision.v1' and "np_agent_approvals"."decision_body"->>'siteId'="np_agent_approvals"."site_id" and "np_agent_approvals"."decision_body"->>'approvalId'="np_agent_approvals"."id"::text and "np_agent_approvals"."decision_body"->>'approvalGeneration'="np_agent_approvals"."generation"::text and "np_agent_approvals"."decision_body"->>'statementHash'="np_agent_approvals"."statement_hash" and
 (("np_agent_approvals"."decision_body"->>'decision'='reject' and "np_agent_approvals"."decision_body"->'reauthentication'->>'mode'='none' and "np_agent_approvals"."decision_reauth_fingerprint" is null and "np_agent_approvals"."decision_reauthenticated_at" is null) or ("np_agent_approvals"."decision_body"->>'decision'='approve' and (("np_agent_approvals"."required_reauth_mode"='none' and "np_agent_approvals"."decision_body"->'reauthentication'->>'mode'='none' and "np_agent_approvals"."decision_reauth_fingerprint" is null and "np_agent_approvals"."decision_reauthenticated_at" is null) or ("np_agent_approvals"."required_reauth_mode"='recent-staff-primary' and "np_agent_approvals"."decision_body"->'reauthentication'->>'mode'='recent' and "np_agent_approvals"."decision_reauth_fingerprint" is not null and "np_agent_approvals"."decision_reauthenticated_at" is not null)))))) and
 ("np_agent_approvals"."state" not in ('approved','rejected','consumed') or "np_agent_approvals"."decision_body" is not null) and ("np_agent_approvals"."state"<>'pending' or "np_agent_approvals"."decision_body" is null) and
 ("np_agent_approvals"."state" not in ('approved','consumed') or "np_agent_approvals"."decision_body"->>'decision'='approve') and ("np_agent_approvals"."state"<>'rejected' or "np_agent_approvals"."decision_body"->>'decision'='reject')) is true),
	CONSTRAINT "np_agent_approvals_revocation_check" CHECK ((("np_agent_approvals"."state"='revoked' and "np_agent_approvals"."revocation_kind" in ('human','authority_loss','site_deleting','integrity_key_retired','target_invalidated') and "np_agent_approvals"."revoker_fingerprint" is not null and "np_agent_approvals"."revocation_code" is not null and "np_agent_approvals"."revocation_body" is not null and "np_agent_approvals"."revocation_hash" is not null and "np_agent_approvals"."revocation_mac" is not null and "np_agent_approvals"."revocation_integrity_key_id" is not null and "np_agent_approvals"."revoked_at" is not null and "np_agent_approvals"."revocation_body"->>'schemaVersion'='np.agent-approval-revocation.v1' and "np_agent_approvals"."revocation_body"->>'siteId'="np_agent_approvals"."site_id" and "np_agent_approvals"."revocation_body"->>'approvalId'="np_agent_approvals"."id"::text and "np_agent_approvals"."revocation_body"->>'approvalGeneration'="np_agent_approvals"."generation"::text and "np_agent_approvals"."revocation_body"->>'statementHash'="np_agent_approvals"."statement_hash" and ("np_agent_approvals"."revocation_kind"='human' or ("np_agent_approvals"."revoked_by_user_id" is null and "np_agent_approvals"."revocation_reason" is null))) or
 ("np_agent_approvals"."state"<>'revoked' and "np_agent_approvals"."revocation_kind" is null and "np_agent_approvals"."revoked_by_user_id" is null and "np_agent_approvals"."revoker_fingerprint" is null and "np_agent_approvals"."revocation_code" is null and "np_agent_approvals"."revocation_reason" is null and "np_agent_approvals"."revocation_body" is null and "np_agent_approvals"."revocation_hash" is null and "np_agent_approvals"."revocation_mac" is null and "np_agent_approvals"."revocation_integrity_key_id" is null and "np_agent_approvals"."revoked_at" is null)) is true),
	CONSTRAINT "np_agent_approvals_time_check" CHECK (("np_agent_approvals"."expires_at">"np_agent_approvals"."requested_at" and "np_agent_approvals"."expires_at"<="np_agent_approvals"."requested_at"+interval '7 days' and ("np_agent_approvals"."decided_at" is null or ("np_agent_approvals"."decided_at">="np_agent_approvals"."requested_at" and "np_agent_approvals"."decided_at"<"np_agent_approvals"."expires_at")) and ("np_agent_approvals"."revoked_at" is null or "np_agent_approvals"."revoked_at">="np_agent_approvals"."requested_at") and (("np_agent_approvals"."state"='consumed')=("np_agent_approvals"."consumed_at" is not null)) and ("np_agent_approvals"."consumed_at" is null or ("np_agent_approvals"."consumed_at">="np_agent_approvals"."decided_at" and "np_agent_approvals"."consumed_at"<"np_agent_approvals"."expires_at")) and ("np_agent_approvals"."reason" is null or char_length("np_agent_approvals"."reason")<=4000) and ("np_agent_approvals"."revocation_reason" is null or char_length("np_agent_approvals"."revocation_reason")<=4000)) is true),
	CONSTRAINT "np_agent_approvals_hash_check" CHECK (("np_agent_approvals"."plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_approvals"."capability_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_approvals"."statement_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_approvals"."requester_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and char_length("np_agent_approvals"."statement_mac") between 1 and 256 and char_length("np_agent_approvals"."integrity_key_id") between 1 and 128) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_changeset_executions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"changeset_id" uuid NOT NULL,
	"purpose" text DEFAULT 'apply' NOT NULL,
	"rollback_plan_id" uuid,
	"plan_hash" text NOT NULL,
	"approval_id" uuid NOT NULL,
	"invocation_id" uuid,
	"invocation_fingerprint" text NOT NULL,
	"verification_contract_fingerprint" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"scheduled_for" timestamp with time zone,
	"state" text DEFAULT 'reserved' NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"result_digest" text,
	"result_body" jsonb,
	"error_code" text,
	"reserved_at" timestamp with time zone DEFAULT now() NOT NULL,
	"committed_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"lease_owner" text,
	"lease_token" uuid,
	"lease_until" timestamp with time zone,
	"attempts" integer DEFAULT 0 NOT NULL,
	"verification_state" text,
	"verification_body" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"verification_digest" text,
	"verification_completed_at" timestamp with time zone,
	"effects" jsonb DEFAULT '[]'::jsonb NOT NULL,
	CONSTRAINT "np_agent_changeset_executions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changeset_executions_plan_unique" UNIQUE("site_id","changeset_id","purpose","plan_hash"),
	CONSTRAINT "np_agent_changeset_executions_approval_unique" UNIQUE("site_id","approval_id"),
	CONSTRAINT "np_agent_changeset_executions_invocation_unique" UNIQUE("site_id","invocation_id"),
	CONSTRAINT "np_agent_changeset_executions_idempotency_unique" UNIQUE("site_id","changeset_id","idempotency_key"),
	CONSTRAINT "np_agent_changeset_executions_target_check" CHECK ((("np_agent_changeset_executions"."purpose"='apply' and "np_agent_changeset_executions"."rollback_plan_id" is null) or ("np_agent_changeset_executions"."purpose"='rollback' and "np_agent_changeset_executions"."rollback_plan_id" is not null and "np_agent_changeset_executions"."scheduled_for" is null)) is true),
	CONSTRAINT "np_agent_changeset_executions_state_check" CHECK (("np_agent_changeset_executions"."purpose" in ('apply','rollback') and "np_agent_changeset_executions"."state" in ('reserved','committed','verifying','succeeded','failed','ambiguous') and "np_agent_changeset_executions"."version">0 and "np_agent_changeset_executions"."attempts">=0) is true),
	CONSTRAINT "np_agent_changeset_executions_hash_check" CHECK (("np_agent_changeset_executions"."verification_contract_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_executions"."plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_executions"."invocation_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_changeset_executions"."result_digest" is null or "np_agent_changeset_executions"."result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_changeset_executions"."verification_digest" is null or "np_agent_changeset_executions"."verification_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and char_length("np_agent_changeset_executions"."idempotency_key") between 1 and 128 and ("np_agent_changeset_executions"."error_code" is null or "np_agent_changeset_executions"."error_code" ~ '^[A-Z][A-Z0-9_]{0,63}$')) is true),
	CONSTRAINT "np_agent_changeset_executions_lease_check" CHECK ((("np_agent_changeset_executions"."lease_owner" is null and "np_agent_changeset_executions"."lease_token" is null and "np_agent_changeset_executions"."lease_until" is null) or ("np_agent_changeset_executions"."lease_owner" is not null and char_length("np_agent_changeset_executions"."lease_owner") between 1 and 128 and "np_agent_changeset_executions"."lease_token" is not null and "np_agent_changeset_executions"."lease_until">"np_agent_changeset_executions"."reserved_at" and "np_agent_changeset_executions"."attempts">0 and "np_agent_changeset_executions"."state" in ('reserved','committed','verifying'))) is true),
	CONSTRAINT "np_agent_changeset_executions_time_check" CHECK ((("np_agent_changeset_executions"."committed_at" is null or "np_agent_changeset_executions"."committed_at">="np_agent_changeset_executions"."reserved_at") and ("np_agent_changeset_executions"."finished_at" is null or ("np_agent_changeset_executions"."finished_at">="np_agent_changeset_executions"."reserved_at" and ("np_agent_changeset_executions"."committed_at" is null or "np_agent_changeset_executions"."finished_at">="np_agent_changeset_executions"."committed_at"))) and ("np_agent_changeset_executions"."verification_completed_at" is null or ("np_agent_changeset_executions"."committed_at" is not null and "np_agent_changeset_executions"."verification_completed_at">="np_agent_changeset_executions"."committed_at"))) is true),
	CONSTRAINT "np_agent_changeset_executions_terminal_check" CHECK (((("np_agent_changeset_executions"."committed_at" is null)=("np_agent_changeset_executions"."result_digest" is null)) and ("np_agent_changeset_executions"."state"<>'reserved' or ("np_agent_changeset_executions"."committed_at" is null and "np_agent_changeset_executions"."error_code" is null)) and ("np_agent_changeset_executions"."state" not in ('committed','verifying','succeeded') or ("np_agent_changeset_executions"."committed_at" is not null and "np_agent_changeset_executions"."error_code" is null)) and (("np_agent_changeset_executions"."state" in ('succeeded','failed','ambiguous'))=("np_agent_changeset_executions"."finished_at" is not null)) and ("np_agent_changeset_executions"."state" not in ('failed','ambiguous') or "np_agent_changeset_executions"."error_code" is not null) and ("np_agent_changeset_executions"."state"<>'succeeded' or "np_agent_changeset_executions"."verification_state"='passed')) is true),
	CONSTRAINT "np_agent_changeset_executions_verification_check" CHECK ((jsonb_typeof("np_agent_changeset_executions"."verification_body")='array' and jsonb_array_length("np_agent_changeset_executions"."verification_body")<=1000 and octet_length("np_agent_changeset_executions"."verification_body"::text)<=1048576 and (( "np_agent_changeset_executions"."verification_state" is null and "np_agent_changeset_executions"."verification_digest" is null and "np_agent_changeset_executions"."verification_completed_at" is null and jsonb_array_length("np_agent_changeset_executions"."verification_body")=0) or ("np_agent_changeset_executions"."committed_at" is not null and "np_agent_changeset_executions"."verification_state" in ('queued','running') and "np_agent_changeset_executions"."verification_digest" is null and "np_agent_changeset_executions"."verification_completed_at" is null) or ("np_agent_changeset_executions"."committed_at" is not null and "np_agent_changeset_executions"."verification_state" in ('passed','failed') and "np_agent_changeset_executions"."verification_digest" is not null and "np_agent_changeset_executions"."verification_completed_at" is not null))) is true),
	CONSTRAINT "np_agent_changeset_executions_result_check" CHECK (((("np_agent_changeset_executions"."result_body" is null)=("np_agent_changeset_executions"."committed_at" is null)) and ("np_agent_changeset_executions"."result_body" is null or (jsonb_typeof("np_agent_changeset_executions"."result_body")='object' and jsonb_typeof("np_agent_changeset_executions"."result_body"->'operations')='array' and jsonb_array_length("np_agent_changeset_executions"."result_body"->'operations') between 1 and 500 and octet_length("np_agent_changeset_executions"."result_body"::text)<=33554432))) is true),
	CONSTRAINT "np_agent_changeset_executions_effects_check" CHECK ((jsonb_typeof("np_agent_changeset_executions"."effects")='array' and jsonb_array_length("np_agent_changeset_executions"."effects")<=4096 and octet_length("np_agent_changeset_executions"."effects"::text)<=4194304) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_changeset_operations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"changeset_id" uuid NOT NULL,
	"ordinal" integer NOT NULL,
	"client_operation_id" text NOT NULL,
	"resource_kind" text NOT NULL,
	"resource_key" jsonb NOT NULL,
	"operation" text NOT NULL,
	"input" jsonb NOT NULL,
	"base_version" jsonb,
	"before_hash" text,
	"before_snapshot" jsonb,
	"snapshot_hash" text,
	"after_hash" text,
	"state" text DEFAULT 'draft' NOT NULL,
	"issues" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"result_digest" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_changeset_operations_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changeset_operations_ordinal_unique" UNIQUE("site_id","changeset_id","ordinal"),
	CONSTRAINT "np_agent_changeset_operations_client_id_unique" UNIQUE("site_id","changeset_id","client_operation_id"),
	CONSTRAINT "np_agent_changeset_operations_ordinal_check" CHECK (("np_agent_changeset_operations"."ordinal" between 1 and 500 and char_length("np_agent_changeset_operations"."client_operation_id") between 1 and 128) is true),
	CONSTRAINT "np_agent_changeset_operations_kind_check" CHECK ((("np_agent_changeset_operations"."resource_kind"='document' and "np_agent_changeset_operations"."operation" in ('create','update','publish','schedule','archive')) or ("np_agent_changeset_operations"."resource_kind" in ('navigation','theme_tokens') and "np_agent_changeset_operations"."operation"='replace') or ("np_agent_changeset_operations"."resource_kind"='setting' and "np_agent_changeset_operations"."operation" in ('replace','remove')) or ("np_agent_changeset_operations"."resource_kind"='media_ref' and "np_agent_changeset_operations"."operation" in ('attach','detach'))) is true),
	CONSTRAINT "np_agent_changeset_operations_body_check" CHECK ((jsonb_typeof("np_agent_changeset_operations"."resource_key")='object' and "np_agent_changeset_operations"."resource_key"->>'kind'="np_agent_changeset_operations"."resource_kind" and jsonb_typeof("np_agent_changeset_operations"."input")='object' and "np_agent_changeset_operations"."input"->>'kind'="np_agent_changeset_operations"."resource_kind" and "np_agent_changeset_operations"."input"->>'operation'="np_agent_changeset_operations"."operation" and "np_agent_changeset_operations"."input"->>'clientOperationId'="np_agent_changeset_operations"."client_operation_id") is true),
	CONSTRAINT "np_agent_changeset_operations_state_check" CHECK (("np_agent_changeset_operations"."state" in ('draft','valid','invalid','applied','verified','failed')) is true),
	CONSTRAINT "np_agent_changeset_operations_snapshot_check" CHECK ((("np_agent_changeset_operations"."before_snapshot" is null and "np_agent_changeset_operations"."snapshot_hash" is null) or ("np_agent_changeset_operations"."before_snapshot" is not null and "np_agent_changeset_operations"."snapshot_hash" is not null and "np_agent_changeset_operations"."snapshot_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and jsonb_typeof("np_agent_changeset_operations"."before_snapshot")='object' and "np_agent_changeset_operations"."before_snapshot"->>'schemaVersion'='np.agent-changeset-snapshot.v1' and "np_agent_changeset_operations"."before_snapshot"->>'siteId'="np_agent_changeset_operations"."site_id" and "np_agent_changeset_operations"."before_snapshot"->>'changeSetId'="np_agent_changeset_operations"."changeset_id"::text and "np_agent_changeset_operations"."before_snapshot"->>'operationOrdinal'="np_agent_changeset_operations"."ordinal"::text and "np_agent_changeset_operations"."before_snapshot"->'canonicalResourceKey'="np_agent_changeset_operations"."resource_key")) is true),
	CONSTRAINT "np_agent_changeset_operations_time_check" CHECK (("np_agent_changeset_operations"."updated_at">="np_agent_changeset_operations"."created_at") is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_changeset_previews" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"changeset_id" uuid NOT NULL,
	"plan_hash" text NOT NULL,
	"generation" integer NOT NULL,
	"preview_contract_body" jsonb NOT NULL,
	"preview_contract_fingerprint" text NOT NULL,
	"admitting_invocation_id" uuid NOT NULL,
	"authorization_context_body" jsonb NOT NULL,
	"authorization_context_fingerprint" text NOT NULL,
	"authority_ref" jsonb NOT NULL,
	"requester_kind" text NOT NULL,
	"requester_id" uuid NOT NULL,
	"requester_fingerprint" text NOT NULL,
	"state" text DEFAULT 'queued' NOT NULL,
	"diff_summary" jsonb,
	"check_summary" jsonb,
	"risk_summary" jsonb,
	"allowed_routes" jsonb NOT NULL,
	"allowed_routes_digest" text NOT NULL,
	"digest" text,
	"expected_artifact_count" integer,
	"upload_set_digest" text,
	"artifact_reserved_at" timestamp with time zone,
	"render_bootstrap_jti" uuid,
	"render_attempt_id" uuid,
	"render_session_id" uuid,
	"render_bootstrap_issued_at" timestamp with time zone,
	"render_bootstrap_expires_at" timestamp with time zone,
	"render_bootstrap_consumed_at" timestamp with time zone,
	"run_id" uuid,
	"job_id" uuid,
	"error_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"rendering_started_at" timestamp with time zone,
	"completed_at" timestamp with time zone,
	"expires_at" timestamp with time zone,
	CONSTRAINT "np_agent_changeset_previews_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changeset_previews_contract_unique" UNIQUE("site_id","id","preview_contract_fingerprint"),
	CONSTRAINT "np_agent_changeset_previews_generation_unique" UNIQUE("site_id","changeset_id","plan_hash","generation"),
	CONSTRAINT "np_agent_changeset_previews_invocation_unique" UNIQUE("site_id","admitting_invocation_id"),
	CONSTRAINT "np_agent_changeset_previews_render_reservation_unique" UNIQUE("site_id","id","render_session_id","render_attempt_id"),
	CONSTRAINT "np_agent_changeset_previews_state_check" CHECK ("np_agent_changeset_previews"."state" in ('queued','rendering','ready','failed','expired') and "np_agent_changeset_previews"."generation">0),
	CONSTRAINT "np_agent_changeset_previews_hash_check" CHECK ("np_agent_changeset_previews"."plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_previews"."preview_contract_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_previews"."authorization_context_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_previews"."requester_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_previews"."allowed_routes_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_changeset_previews"."digest" is null or "np_agent_changeset_previews"."digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')),
	CONSTRAINT "np_agent_changeset_previews_authority_check" CHECK (("np_agent_changeset_previews"."authorization_context_body"->>'siteId'="np_agent_changeset_previews"."site_id" and "np_agent_changeset_previews"."authorization_context_body"->>'schemaVersion'='np.agent-authorization-context.v1' and "np_agent_changeset_previews"."authorization_context_body"->'authorityRef'="np_agent_changeset_previews"."authority_ref" and "np_agent_changeset_previews"."authorization_context_body"->'actor'->>'kind'="np_agent_changeset_previews"."requester_kind" and "np_agent_changeset_previews"."authorization_context_body"->'actor'->>'actorFingerprint'="np_agent_changeset_previews"."requester_fingerprint" and (("np_agent_changeset_previews"."requester_kind"='staff' and "np_agent_changeset_previews"."authorization_context_body"->'actor'->>'userId'="np_agent_changeset_previews"."requester_id"::text and "np_agent_changeset_previews"."authority_ref"->>'kind'='staff-session' and "np_agent_changeset_previews"."authority_ref"->>'userId'="np_agent_changeset_previews"."requester_id"::text) or ("np_agent_changeset_previews"."requester_kind"='principal' and "np_agent_changeset_previews"."authorization_context_body"->'actor'->>'principalId'="np_agent_changeset_previews"."requester_id"::text and "np_agent_changeset_previews"."authority_ref"->>'principalId'="np_agent_changeset_previews"."requester_id"::text and "np_agent_changeset_previews"."authority_ref"->>'kind' in ('service-family','oauth-grant','runtime-run')))) is true),
	CONSTRAINT "np_agent_changeset_previews_contract_check" CHECK (("np_agent_changeset_previews"."preview_contract_body"->>'schemaVersion'='np.agent-preview-contract.v1' and octet_length("np_agent_changeset_previews"."preview_contract_body"::text)<=65536 and jsonb_typeof("np_agent_changeset_previews"."allowed_routes")='array' and octet_length("np_agent_changeset_previews"."allowed_routes"::text)<=262144) is true),
	CONSTRAINT "np_agent_changeset_previews_reservation_check" CHECK ((("np_agent_changeset_previews"."expected_artifact_count" is null and "np_agent_changeset_previews"."upload_set_digest" is null and "np_agent_changeset_previews"."artifact_reserved_at" is null) or ("np_agent_changeset_previews"."expected_artifact_count" between 0 and 24 and "np_agent_changeset_previews"."upload_set_digest" ~ '^aus1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_previews"."artifact_reserved_at" is not null)) is true),
	CONSTRAINT "np_agent_changeset_previews_bootstrap_check" CHECK ((("np_agent_changeset_previews"."render_bootstrap_jti" is null and "np_agent_changeset_previews"."render_attempt_id" is null and "np_agent_changeset_previews"."render_session_id" is null and "np_agent_changeset_previews"."render_bootstrap_issued_at" is null and "np_agent_changeset_previews"."render_bootstrap_expires_at" is null and "np_agent_changeset_previews"."render_bootstrap_consumed_at" is null) or ("np_agent_changeset_previews"."render_bootstrap_jti" is not null and "np_agent_changeset_previews"."render_attempt_id" is not null and "np_agent_changeset_previews"."render_session_id" is not null and "np_agent_changeset_previews"."render_bootstrap_issued_at" is not null and "np_agent_changeset_previews"."render_bootstrap_expires_at">"np_agent_changeset_previews"."render_bootstrap_issued_at" and "np_agent_changeset_previews"."render_bootstrap_expires_at"<="np_agent_changeset_previews"."render_bootstrap_issued_at"+interval '120 seconds' and ("np_agent_changeset_previews"."render_bootstrap_consumed_at" is null or "np_agent_changeset_previews"."render_bootstrap_consumed_at">="np_agent_changeset_previews"."render_bootstrap_issued_at"))) is true),
	CONSTRAINT "np_agent_changeset_previews_started_check" CHECK (("np_agent_changeset_previews"."state"<>'queued' or "np_agent_changeset_previews"."rendering_started_at" is null) and ("np_agent_changeset_previews"."state" not in ('rendering','ready') or "np_agent_changeset_previews"."rendering_started_at" is not null) and ("np_agent_changeset_previews"."rendering_started_at" is null or "np_agent_changeset_previews"."rendering_started_at">="np_agent_changeset_previews"."created_at")),
	CONSTRAINT "np_agent_changeset_previews_terminal_check" CHECK ((("np_agent_changeset_previews"."state" in ('queued','rendering') and "np_agent_changeset_previews"."completed_at" is null and "np_agent_changeset_previews"."expires_at" is null and "np_agent_changeset_previews"."digest" is null) or ("np_agent_changeset_previews"."state"='ready' and "np_agent_changeset_previews"."completed_at" is not null and "np_agent_changeset_previews"."expires_at">"np_agent_changeset_previews"."completed_at" and "np_agent_changeset_previews"."expires_at"<="np_agent_changeset_previews"."completed_at"+interval '7 days' and "np_agent_changeset_previews"."digest" is not null and "np_agent_changeset_previews"."expected_artifact_count" is not null and "np_agent_changeset_previews"."error_code" is null) or ("np_agent_changeset_previews"."state"='failed' and "np_agent_changeset_previews"."completed_at" is not null and "np_agent_changeset_previews"."expires_at" is null and "np_agent_changeset_previews"."digest" is null and "np_agent_changeset_previews"."error_code" is not null) or ("np_agent_changeset_previews"."state"='expired' and "np_agent_changeset_previews"."completed_at" is not null and (("np_agent_changeset_previews"."expires_at" is null and "np_agent_changeset_previews"."digest" is null) or ("np_agent_changeset_previews"."expires_at" is not null and "np_agent_changeset_previews"."digest" is not null)))) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_changeset_rollback_operations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"changeset_id" uuid NOT NULL,
	"rollback_plan_id" uuid NOT NULL,
	"ordinal" integer NOT NULL,
	"original_operation_id" uuid NOT NULL,
	"original_operation_ordinal" integer NOT NULL,
	"canonical_resource_key" jsonb NOT NULL,
	"before_snapshot" jsonb NOT NULL,
	"before_hash" text,
	"snapshot_hash" text NOT NULL,
	"expected_current_hash" text NOT NULL,
	"expected_current_version" text NOT NULL,
	"compensation_operation" jsonb NOT NULL,
	"proposed_after_hash" text NOT NULL,
	"rollback_class" text NOT NULL,
	"residual_codes" text[] DEFAULT '{}' NOT NULL,
	"state" text DEFAULT 'draft' NOT NULL,
	"issues" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"after_hash" text,
	"result_digest" text,
	"error_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_changeset_rollback_operations_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changeset_rollback_operations_ordinal_unique" UNIQUE("site_id","rollback_plan_id","ordinal"),
	CONSTRAINT "np_agent_changeset_rollback_operations_original_unique" UNIQUE("site_id","rollback_plan_id","original_operation_id"),
	CONSTRAINT "np_agent_changeset_rollback_operations_state_check" CHECK (("np_agent_changeset_rollback_operations"."state" in ('draft','valid','invalid','applied','verified','failed') and "np_agent_changeset_rollback_operations"."ordinal" between 1 and 500 and "np_agent_changeset_rollback_operations"."original_operation_ordinal" between 1 and 500 and "np_agent_changeset_rollback_operations"."rollback_class" in ('full','residual','unavailable') and cardinality("np_agent_changeset_rollback_operations"."residual_codes")<=64) is true),
	CONSTRAINT "np_agent_changeset_rollback_operations_hash_check" CHECK (("np_agent_changeset_rollback_operations"."snapshot_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_rollback_operations"."expected_current_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_rollback_operations"."proposed_after_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_changeset_rollback_operations"."before_hash" is null or "np_agent_changeset_rollback_operations"."before_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_changeset_rollback_operations"."after_hash" is null or "np_agent_changeset_rollback_operations"."after_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_changeset_rollback_operations"."result_digest" is null or "np_agent_changeset_rollback_operations"."result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and char_length("np_agent_changeset_rollback_operations"."expected_current_version") between 1 and 512) is true),
	CONSTRAINT "np_agent_changeset_rollback_operations_snapshot_check" CHECK (("np_agent_changeset_rollback_operations"."before_snapshot"->>'schemaVersion'='np.agent-changeset-snapshot.v1' and "np_agent_changeset_rollback_operations"."before_snapshot"->>'siteId'="np_agent_changeset_rollback_operations"."site_id" and "np_agent_changeset_rollback_operations"."before_snapshot"->>'changeSetId'="np_agent_changeset_rollback_operations"."changeset_id"::text and "np_agent_changeset_rollback_operations"."before_snapshot"->>'operationOrdinal'="np_agent_changeset_rollback_operations"."original_operation_ordinal"::text and "np_agent_changeset_rollback_operations"."before_snapshot"->'canonicalResourceKey'="np_agent_changeset_rollback_operations"."canonical_resource_key" and "np_agent_changeset_rollback_operations"."compensation_operation"->>'kind'="np_agent_changeset_rollback_operations"."canonical_resource_key"->>'kind') is true),
	CONSTRAINT "np_agent_changeset_rollback_operations_bounds_check" CHECK ((jsonb_typeof("np_agent_changeset_rollback_operations"."issues")='array' and jsonb_array_length("np_agent_changeset_rollback_operations"."issues")<=1000 and octet_length("np_agent_changeset_rollback_operations"."issues"::text)<=262144 and octet_length("np_agent_changeset_rollback_operations"."before_snapshot"::text)<=4194304 and octet_length("np_agent_changeset_rollback_operations"."compensation_operation"::text)<=4194304 and ("np_agent_changeset_rollback_operations"."error_code" is null or "np_agent_changeset_rollback_operations"."error_code" ~ '^[A-Z][A-Z0-9_]{0,63}$')) is true),
	CONSTRAINT "np_agent_changeset_rollback_operations_time_check" CHECK (("np_agent_changeset_rollback_operations"."updated_at">="np_agent_changeset_rollback_operations"."created_at") is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_changeset_rollback_plans" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"changeset_id" uuid NOT NULL,
	"generation" integer NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"admitting_invocation_id" uuid NOT NULL,
	"authorization_context_body" jsonb NOT NULL,
	"authorization_context_fingerprint" text NOT NULL,
	"authority_ref" jsonb NOT NULL,
	"requester_kind" text NOT NULL,
	"requester_id" uuid NOT NULL,
	"requester_fingerprint" text NOT NULL,
	"compensates_execution_id" uuid NOT NULL,
	"original_plan_hash" text NOT NULL,
	"applied_result_digest" text NOT NULL,
	"state" text DEFAULT 'preparing' NOT NULL,
	"base_fingerprint" text,
	"plan_hash" text,
	"sealed_plan_body" jsonb,
	"risk_summary" jsonb,
	"policy_refs" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"issues" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"approval_id" uuid,
	"result_digest" text,
	"verification_digest" text,
	"terminal_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"approved_at" timestamp with time zone,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_changeset_rollback_plans_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changeset_rollback_plans_generation_unique" UNIQUE("site_id","changeset_id","generation"),
	CONSTRAINT "np_agent_changeset_rollback_plans_invocation_unique" UNIQUE("site_id","admitting_invocation_id"),
	CONSTRAINT "np_agent_changeset_rollback_plans_state_check" CHECK (("np_agent_changeset_rollback_plans"."state" in ('preparing','invalid','ready','approval_pending','approved','executing','verified','failed','conflicted','expired') and "np_agent_changeset_rollback_plans"."generation">0 and "np_agent_changeset_rollback_plans"."version">0) is true),
	CONSTRAINT "np_agent_changeset_rollback_plans_hash_check" CHECK (("np_agent_changeset_rollback_plans"."original_plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_rollback_plans"."applied_result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_rollback_plans"."authorization_context_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_rollback_plans"."requester_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_changeset_rollback_plans"."plan_hash" is null or "np_agent_changeset_rollback_plans"."plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_changeset_rollback_plans"."base_fingerprint" is null or "np_agent_changeset_rollback_plans"."base_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_changeset_rollback_plans"."result_digest" is null or "np_agent_changeset_rollback_plans"."result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_changeset_rollback_plans"."verification_digest" is null or "np_agent_changeset_rollback_plans"."verification_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')) is true),
	CONSTRAINT "np_agent_changeset_rollback_plans_authority_check" CHECK ((jsonb_typeof("np_agent_changeset_rollback_plans"."authorization_context_body")='object' and "np_agent_changeset_rollback_plans"."authorization_context_body"->>'schemaVersion'='np.agent-authorization-context.v1' and "np_agent_changeset_rollback_plans"."authorization_context_body"->>'siteId'="np_agent_changeset_rollback_plans"."site_id" and "np_agent_changeset_rollback_plans"."authorization_context_body"->'authorityRef'="np_agent_changeset_rollback_plans"."authority_ref" and "np_agent_changeset_rollback_plans"."authorization_context_body"->'actor'->>'kind'="np_agent_changeset_rollback_plans"."requester_kind" and "np_agent_changeset_rollback_plans"."authorization_context_body"->'actor'->>'actorFingerprint'="np_agent_changeset_rollback_plans"."requester_fingerprint" and (("np_agent_changeset_rollback_plans"."requester_kind"='staff' and "np_agent_changeset_rollback_plans"."authorization_context_body"->'actor'->>'userId'="np_agent_changeset_rollback_plans"."requester_id"::text and "np_agent_changeset_rollback_plans"."authority_ref"->>'kind'='staff-session' and "np_agent_changeset_rollback_plans"."authority_ref"->>'userId'="np_agent_changeset_rollback_plans"."requester_id"::text) or ("np_agent_changeset_rollback_plans"."requester_kind"='principal' and "np_agent_changeset_rollback_plans"."authorization_context_body"->'actor'->>'principalId'="np_agent_changeset_rollback_plans"."requester_id"::text and "np_agent_changeset_rollback_plans"."authority_ref"->>'kind' in ('service-family','oauth-grant','runtime-run') and "np_agent_changeset_rollback_plans"."authority_ref"->>'principalId'="np_agent_changeset_rollback_plans"."requester_id"::text))) is true),
	CONSTRAINT "np_agent_changeset_rollback_plans_sealed_check" CHECK (((("np_agent_changeset_rollback_plans"."plan_hash" is null and "np_agent_changeset_rollback_plans"."base_fingerprint" is null and "np_agent_changeset_rollback_plans"."sealed_plan_body" is null) or ("np_agent_changeset_rollback_plans"."plan_hash" is not null and "np_agent_changeset_rollback_plans"."base_fingerprint" is not null and "np_agent_changeset_rollback_plans"."sealed_plan_body" is not null and "np_agent_changeset_rollback_plans"."sealed_plan_body"->>'schemaVersion'='np.agent-changeset-plan.v1' and "np_agent_changeset_rollback_plans"."sealed_plan_body"->>'planKind'='rollback' and "np_agent_changeset_rollback_plans"."sealed_plan_body"->>'siteId'="np_agent_changeset_rollback_plans"."site_id" and "np_agent_changeset_rollback_plans"."sealed_plan_body"->>'changeSetId'="np_agent_changeset_rollback_plans"."changeset_id"::text and "np_agent_changeset_rollback_plans"."sealed_plan_body"->'body'->>'rollbackPlanId'="np_agent_changeset_rollback_plans"."id"::text and "np_agent_changeset_rollback_plans"."sealed_plan_body"->'body'->>'generation'="np_agent_changeset_rollback_plans"."generation"::text and "np_agent_changeset_rollback_plans"."sealed_plan_body"->'body'->>'compensatesExecutionId'="np_agent_changeset_rollback_plans"."compensates_execution_id"::text and "np_agent_changeset_rollback_plans"."sealed_plan_body"->'body'->>'originalPlanHash'="np_agent_changeset_rollback_plans"."original_plan_hash" and "np_agent_changeset_rollback_plans"."sealed_plan_body"->'body'->>'appliedResultDigest'="np_agent_changeset_rollback_plans"."applied_result_digest" and "np_agent_changeset_rollback_plans"."sealed_plan_body"->'body'->>'baseFingerprint'="np_agent_changeset_rollback_plans"."base_fingerprint")) and ("np_agent_changeset_rollback_plans"."state" not in ('ready','approval_pending','approved','executing','verified') or "np_agent_changeset_rollback_plans"."sealed_plan_body" is not null)) is true),
	CONSTRAINT "np_agent_changeset_rollback_plans_approval_check" CHECK (("np_agent_changeset_rollback_plans"."state" not in ('approval_pending','approved','executing','verified') or "np_agent_changeset_rollback_plans"."approval_id" is not null) and ("np_agent_changeset_rollback_plans"."terminal_reason" is null or "np_agent_changeset_rollback_plans"."terminal_reason" not in ('approval_rejected','approval_revoked','approval_expired') or "np_agent_changeset_rollback_plans"."approval_id" is not null)),
	CONSTRAINT "np_agent_changeset_rollback_plans_time_check" CHECK (("np_agent_changeset_rollback_plans"."expires_at">"np_agent_changeset_rollback_plans"."created_at" and "np_agent_changeset_rollback_plans"."expires_at"<="np_agent_changeset_rollback_plans"."created_at"+interval '90 days' and ("np_agent_changeset_rollback_plans"."approved_at" is null or "np_agent_changeset_rollback_plans"."approved_at">="np_agent_changeset_rollback_plans"."created_at") and ("np_agent_changeset_rollback_plans"."started_at" is null or ("np_agent_changeset_rollback_plans"."approved_at" is not null and "np_agent_changeset_rollback_plans"."started_at">="np_agent_changeset_rollback_plans"."approved_at")) and ("np_agent_changeset_rollback_plans"."finished_at" is null or ("np_agent_changeset_rollback_plans"."finished_at">="np_agent_changeset_rollback_plans"."created_at" and ("np_agent_changeset_rollback_plans"."started_at" is null or "np_agent_changeset_rollback_plans"."finished_at">="np_agent_changeset_rollback_plans"."started_at")))) is true),
	CONSTRAINT "np_agent_changeset_rollback_plans_terminal_check" CHECK (((("np_agent_changeset_rollback_plans"."state" in ('invalid','verified','failed','conflicted','expired'))=("np_agent_changeset_rollback_plans"."finished_at" is not null)) and (("np_agent_changeset_rollback_plans"."state" in ('invalid','failed','conflicted','expired'))=("np_agent_changeset_rollback_plans"."terminal_reason" is not null)) and ("np_agent_changeset_rollback_plans"."terminal_reason" is null or "np_agent_changeset_rollback_plans"."terminal_reason" in ('validation_failed','snapshot_expired','conflict','policy_blocked','approval_rejected','approval_revoked','approval_expired','operator_cancelled','execution_cancelled','execution_failed','verification_failed')) and ("np_agent_changeset_rollback_plans"."state"<>'verified' or ("np_agent_changeset_rollback_plans"."result_digest" is not null and "np_agent_changeset_rollback_plans"."verification_digest" is not null)) and ("np_agent_changeset_rollback_plans"."state"<>'executing' or "np_agent_changeset_rollback_plans"."started_at" is not null)) is true),
	CONSTRAINT "np_agent_changeset_rollback_plans_bounds_check" CHECK ((jsonb_typeof("np_agent_changeset_rollback_plans"."issues")='array' and jsonb_array_length("np_agent_changeset_rollback_plans"."issues")<=1000 and octet_length("np_agent_changeset_rollback_plans"."issues"::text)<=262144 and jsonb_typeof("np_agent_changeset_rollback_plans"."policy_refs")='array' and octet_length("np_agent_changeset_rollback_plans"."policy_refs"::text)<=65536 and ("np_agent_changeset_rollback_plans"."sealed_plan_body" is null or octet_length("np_agent_changeset_rollback_plans"."sealed_plan_body"::text)<=33554432)) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_changeset_validation_attempts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"changeset_id" uuid NOT NULL,
	"generation" integer NOT NULL,
	"draft_version" integer NOT NULL,
	"draft_hash" text NOT NULL,
	"admitting_invocation_id" uuid NOT NULL,
	"authorization_context_body" jsonb NOT NULL,
	"authorization_context_fingerprint" text NOT NULL,
	"authority_ref" jsonb NOT NULL,
	"requester_kind" text NOT NULL,
	"requester_id" uuid NOT NULL,
	"requester_fingerprint" text NOT NULL,
	"state" text DEFAULT 'queued' NOT NULL,
	"issues" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"risk_summary" jsonb,
	"result_digest" text,
	"error_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_changeset_validation_attempts_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changeset_validation_attempts_generation_unique" UNIQUE("site_id","changeset_id","generation"),
	CONSTRAINT "np_agent_changeset_validation_attempts_invocation_unique" UNIQUE("site_id","admitting_invocation_id"),
	CONSTRAINT "np_agent_changeset_validation_attempts_version_check" CHECK ("np_agent_changeset_validation_attempts"."generation">0 and "np_agent_changeset_validation_attempts"."draft_version">0),
	CONSTRAINT "np_agent_changeset_validation_attempts_state_check" CHECK ("np_agent_changeset_validation_attempts"."state" in ('queued','validating','ready','invalid','failed')),
	CONSTRAINT "np_agent_changeset_validation_attempts_hash_check" CHECK ("np_agent_changeset_validation_attempts"."draft_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_validation_attempts"."authorization_context_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changeset_validation_attempts"."requester_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_changeset_validation_attempts"."result_digest" is null or "np_agent_changeset_validation_attempts"."result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')),
	CONSTRAINT "np_agent_changeset_validation_attempts_authority_check" CHECK ((jsonb_typeof("np_agent_changeset_validation_attempts"."authorization_context_body")='object' and "np_agent_changeset_validation_attempts"."authorization_context_body"->>'schemaVersion'='np.agent-authorization-context.v1' and "np_agent_changeset_validation_attempts"."authorization_context_body"->>'siteId'="np_agent_changeset_validation_attempts"."site_id" and "np_agent_changeset_validation_attempts"."authorization_context_body"->'authorityRef'="np_agent_changeset_validation_attempts"."authority_ref" and "np_agent_changeset_validation_attempts"."authorization_context_body"->'actor'->>'kind'="np_agent_changeset_validation_attempts"."requester_kind" and "np_agent_changeset_validation_attempts"."authorization_context_body"->'actor'->>'actorFingerprint'="np_agent_changeset_validation_attempts"."requester_fingerprint" and (("np_agent_changeset_validation_attempts"."requester_kind"='staff' and "np_agent_changeset_validation_attempts"."authorization_context_body"->'actor'->>'userId'="np_agent_changeset_validation_attempts"."requester_id"::text and "np_agent_changeset_validation_attempts"."authority_ref"->>'kind'='staff-session' and "np_agent_changeset_validation_attempts"."authority_ref"->>'userId'="np_agent_changeset_validation_attempts"."requester_id"::text) or ("np_agent_changeset_validation_attempts"."requester_kind"='principal' and "np_agent_changeset_validation_attempts"."authorization_context_body"->'actor'->>'principalId'="np_agent_changeset_validation_attempts"."requester_id"::text and "np_agent_changeset_validation_attempts"."authority_ref"->>'kind' in ('service-family','oauth-grant','runtime-run') and "np_agent_changeset_validation_attempts"."authority_ref"->>'principalId'="np_agent_changeset_validation_attempts"."requester_id"::text))) is true),
	CONSTRAINT "np_agent_changeset_validation_attempts_result_check" CHECK ((jsonb_typeof("np_agent_changeset_validation_attempts"."issues")='array' and jsonb_array_length("np_agent_changeset_validation_attempts"."issues")<=1000 and octet_length("np_agent_changeset_validation_attempts"."issues"::text)<=262144 and ("np_agent_changeset_validation_attempts"."risk_summary" is null or (jsonb_typeof("np_agent_changeset_validation_attempts"."risk_summary")='object' and octet_length("np_agent_changeset_validation_attempts"."risk_summary"::text)<=65536)) and ("np_agent_changeset_validation_attempts"."error_code" is null or "np_agent_changeset_validation_attempts"."error_code" ~ '^[A-Z][A-Z0-9_]{0,63}$')) is true),
	CONSTRAINT "np_agent_changeset_validation_attempts_time_check" CHECK ("np_agent_changeset_validation_attempts"."expires_at">="np_agent_changeset_validation_attempts"."created_at"+interval '60 seconds' and "np_agent_changeset_validation_attempts"."expires_at"<="np_agent_changeset_validation_attempts"."created_at"+interval '24 hours' and ("np_agent_changeset_validation_attempts"."started_at" is null or "np_agent_changeset_validation_attempts"."started_at">="np_agent_changeset_validation_attempts"."created_at") and ("np_agent_changeset_validation_attempts"."finished_at" is null or ("np_agent_changeset_validation_attempts"."finished_at">="np_agent_changeset_validation_attempts"."created_at" and ("np_agent_changeset_validation_attempts"."started_at" is null or "np_agent_changeset_validation_attempts"."finished_at">="np_agent_changeset_validation_attempts"."started_at")))),
	CONSTRAINT "np_agent_changeset_validation_attempts_terminal_check" CHECK ((
      ("np_agent_changeset_validation_attempts"."state"='queued' and "np_agent_changeset_validation_attempts"."started_at" is null and "np_agent_changeset_validation_attempts"."finished_at" is null and "np_agent_changeset_validation_attempts"."result_digest" is null and "np_agent_changeset_validation_attempts"."risk_summary" is null and "np_agent_changeset_validation_attempts"."error_code" is null and "np_agent_changeset_validation_attempts"."issues"='[]'::jsonb) or
      ("np_agent_changeset_validation_attempts"."state"='validating' and "np_agent_changeset_validation_attempts"."started_at" is not null and "np_agent_changeset_validation_attempts"."finished_at" is null and "np_agent_changeset_validation_attempts"."result_digest" is null and "np_agent_changeset_validation_attempts"."risk_summary" is null and "np_agent_changeset_validation_attempts"."error_code" is null and "np_agent_changeset_validation_attempts"."issues"='[]'::jsonb) or
      ("np_agent_changeset_validation_attempts"."state"='ready' and "np_agent_changeset_validation_attempts"."started_at" is not null and "np_agent_changeset_validation_attempts"."finished_at" is not null and "np_agent_changeset_validation_attempts"."result_digest" is not null and "np_agent_changeset_validation_attempts"."risk_summary" is not null and "np_agent_changeset_validation_attempts"."error_code" is null) or
      ("np_agent_changeset_validation_attempts"."state"='invalid' and "np_agent_changeset_validation_attempts"."started_at" is not null and "np_agent_changeset_validation_attempts"."finished_at" is not null and "np_agent_changeset_validation_attempts"."result_digest" is not null and "np_agent_changeset_validation_attempts"."error_code" is null) or
      ("np_agent_changeset_validation_attempts"."state"='failed' and "np_agent_changeset_validation_attempts"."finished_at" is not null and "np_agent_changeset_validation_attempts"."error_code" is not null and "np_agent_changeset_validation_attempts"."risk_summary" is null)
    ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_changesets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"creator_kind" text NOT NULL,
	"principal_id" uuid,
	"created_by_user_id" uuid,
	"actor_deleted_at" timestamp with time zone,
	"actor_fingerprint" text NOT NULL,
	"source_operation_id" text NOT NULL,
	"source_input_hash" text NOT NULL,
	"source_idempotency_fingerprint" text NOT NULL,
	"agent_id" uuid,
	"agent_version_id" uuid,
	"agent_config_hash" text,
	"run_id" uuid,
	"run_fingerprint" text,
	"run_source_release_id" uuid,
	"invocation_id" uuid,
	"invocation_fingerprint" text,
	"title" text NOT NULL,
	"summary" text,
	"state" text DEFAULT 'draft' NOT NULL,
	"draft_version" integer DEFAULT 1 NOT NULL,
	"draft_hash" text NOT NULL,
	"validation_generation" integer DEFAULT 0 NOT NULL,
	"base_fingerprint" text,
	"plan_hash" text,
	"sealed_plan_body" jsonb,
	"risk_summary" jsonb,
	"policy_refs" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"scheduled_for" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	"rollback_window_seconds" integer,
	"rollback_eligible_until" timestamp with time zone,
	"cancellation_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"applied_at" timestamp with time zone,
	"verified_at" timestamp with time zone,
	"rolled_back_at" timestamp with time zone,
	CONSTRAINT "np_agent_changesets_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_changesets_source_unique" UNIQUE("site_id","actor_fingerprint","source_operation_id","source_idempotency_fingerprint"),
	CONSTRAINT "np_agent_changesets_state_check" CHECK (("np_agent_changesets"."state" in ('draft','validating','invalid','ready','approval_pending','approved','scheduled','applying','applied','verifying','verified','rejected','cancelled','apply_failed','verification_failed','rolling_back','rolled_back','rollback_failed')) is true),
	CONSTRAINT "np_agent_changesets_version_check" CHECK (("np_agent_changesets"."draft_version">0 and "np_agent_changesets"."validation_generation">=0) is true),
	CONSTRAINT "np_agent_changesets_actor_check" CHECK (((
 ("np_agent_changesets"."creator_kind"='staff' and "np_agent_changesets"."principal_id" is null and (("np_agent_changesets"."created_by_user_id" is not null and "np_agent_changesets"."actor_deleted_at" is null) or ("np_agent_changesets"."created_by_user_id" is null and "np_agent_changesets"."actor_deleted_at" is not null))) or
 ("np_agent_changesets"."creator_kind" in ('external','runtime') and "np_agent_changesets"."principal_id" is not null and "np_agent_changesets"."created_by_user_id" is null and "np_agent_changesets"."actor_deleted_at" is null)) and
 (("np_agent_changesets"."creator_kind"='runtime' and "np_agent_changesets"."agent_id" is not null and "np_agent_changesets"."agent_version_id" is not null and "np_agent_changesets"."agent_config_hash" is not null) or
 ("np_agent_changesets"."creator_kind"<>'runtime' and "np_agent_changesets"."agent_id" is null and "np_agent_changesets"."agent_version_id" is null and "np_agent_changesets"."agent_config_hash" is null))) is true),
	CONSTRAINT "np_agent_changesets_attribution_check" CHECK ((("np_agent_changesets"."run_id" is null or "np_agent_changesets"."run_fingerprint" is not null) and ("np_agent_changesets"."run_source_release_id" is null or ("np_agent_changesets"."run_id" is null and "np_agent_changesets"."run_fingerprint" is not null)) and ("np_agent_changesets"."invocation_id" is null or "np_agent_changesets"."invocation_fingerprint" is not null)) is true),
	CONSTRAINT "np_agent_changesets_text_check" CHECK ((char_length("np_agent_changesets"."title") between 1 and 4000 and "np_agent_changesets"."title"=btrim("np_agent_changesets"."title") and ("np_agent_changesets"."summary" is null or char_length("np_agent_changesets"."summary")<=4000) and char_length("np_agent_changesets"."source_operation_id") between 1 and 128) is true),
	CONSTRAINT "np_agent_changesets_hash_check" CHECK (("np_agent_changesets"."actor_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changesets"."source_input_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changesets"."source_idempotency_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_changesets"."draft_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_changesets"."plan_hash" is null or "np_agent_changesets"."plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')) is true),
	CONSTRAINT "np_agent_changesets_sealed_check" CHECK (((
 ("np_agent_changesets"."sealed_plan_body" is null and "np_agent_changesets"."plan_hash" is null and "np_agent_changesets"."rollback_window_seconds" is null) or
 ("np_agent_changesets"."sealed_plan_body" is not null and "np_agent_changesets"."plan_hash" is not null and "np_agent_changesets"."rollback_window_seconds" between 60 and 7776000 and "np_agent_changesets"."validation_generation">0 and
 jsonb_typeof("np_agent_changesets"."sealed_plan_body")='object' and "np_agent_changesets"."sealed_plan_body"->>'schemaVersion'='np.agent-changeset-plan.v1' and "np_agent_changesets"."sealed_plan_body"->>'planKind'='changeset' and
 "np_agent_changesets"."sealed_plan_body"->>'siteId'="np_agent_changesets"."site_id" and "np_agent_changesets"."sealed_plan_body"->>'changeSetId'="np_agent_changesets"."id"::text and
 "np_agent_changesets"."sealed_plan_body"->'body'->>'rollbackWindowSeconds'="np_agent_changesets"."rollback_window_seconds"::text)) and
 ("np_agent_changesets"."state" not in ('draft','validating','invalid') or "np_agent_changesets"."sealed_plan_body" is null) and
 ("np_agent_changesets"."state" in ('draft','validating','invalid','cancelled','rejected') or "np_agent_changesets"."sealed_plan_body" is not null)) is true),
	CONSTRAINT "np_agent_changesets_time_check" CHECK (("np_agent_changesets"."updated_at">="np_agent_changesets"."created_at" and "np_agent_changesets"."expires_at">"np_agent_changesets"."created_at" and "np_agent_changesets"."expires_at"<="np_agent_changesets"."created_at"+interval '90 days' and
 ("np_agent_changesets"."scheduled_for" is null or ("np_agent_changesets"."scheduled_for">="np_agent_changesets"."created_at" and "np_agent_changesets"."scheduled_for"<"np_agent_changesets"."expires_at")) and
 ("np_agent_changesets"."applied_at" is null or "np_agent_changesets"."applied_at">="np_agent_changesets"."created_at") and ("np_agent_changesets"."verified_at" is null or ("np_agent_changesets"."applied_at" is not null and "np_agent_changesets"."verified_at">="np_agent_changesets"."applied_at")) and
 ("np_agent_changesets"."rolled_back_at" is null or ("np_agent_changesets"."applied_at" is not null and "np_agent_changesets"."rolled_back_at">="np_agent_changesets"."applied_at")) and
 (("np_agent_changesets"."rollback_eligible_until" is null and "np_agent_changesets"."applied_at" is null) or ("np_agent_changesets"."applied_at" is not null and "np_agent_changesets"."rollback_window_seconds" is not null and "np_agent_changesets"."rollback_eligible_until"="np_agent_changesets"."applied_at"+make_interval(secs=>"np_agent_changesets"."rollback_window_seconds")))) is true),
	CONSTRAINT "np_agent_changesets_cancel_check" CHECK ((("np_agent_changesets"."state"='cancelled')=("np_agent_changesets"."cancellation_code" is not null)) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_circuit_breakers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"scope_kind" text NOT NULL,
	"scope_ref" text NOT NULL,
	"state" text NOT NULL,
	"reason_code" text,
	"failure_count" integer NOT NULL,
	"window_started_at" timestamp with time zone NOT NULL,
	"opened_at" timestamp with time zone,
	"retry_at" timestamp with time zone,
	"probe_lease_until" timestamp with time zone,
	"version_number" integer DEFAULT 1 NOT NULL,
	"updated_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_circuit_breakers_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_circuit_breakers_scope_unique" UNIQUE("site_id","scope_kind","scope_ref"),
	CONSTRAINT "np_agent_circuit_breakers_scope_check" CHECK ((("np_agent_circuit_breakers"."scope_kind"='site' and "np_agent_circuit_breakers"."scope_ref"="np_agent_circuit_breakers"."site_id") or ("np_agent_circuit_breakers"."scope_kind" in ('agent','connection') and "np_agent_circuit_breakers"."scope_ref" ~ '^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$') or ("np_agent_circuit_breakers"."scope_kind"='subject' and "np_agent_circuit_breakers"."scope_ref" ~ '^[A-Za-z0-9_-]{43}$')) is true),
	CONSTRAINT "np_agent_circuit_breakers_state_check" CHECK ("np_agent_circuit_breakers"."state" in ('closed','open','half_open') and "np_agent_circuit_breakers"."version_number">0 and "np_agent_circuit_breakers"."failure_count">=0 and ("np_agent_circuit_breakers"."reason_code" is null or "np_agent_circuit_breakers"."reason_code" ~ '^[A-Z][A-Z0-9_]{0,63}$')),
	CONSTRAINT "np_agent_circuit_breakers_time_check" CHECK (("np_agent_circuit_breakers"."updated_at">="np_agent_circuit_breakers"."window_started_at" and ((
      "np_agent_circuit_breakers"."state"='closed' and "np_agent_circuit_breakers"."opened_at" is null and "np_agent_circuit_breakers"."retry_at" is null and "np_agent_circuit_breakers"."probe_lease_until" is null
    ) or (
      "np_agent_circuit_breakers"."state"='open' and "np_agent_circuit_breakers"."reason_code" is not null and "np_agent_circuit_breakers"."opened_at">="np_agent_circuit_breakers"."window_started_at" and "np_agent_circuit_breakers"."retry_at">"np_agent_circuit_breakers"."opened_at" and "np_agent_circuit_breakers"."probe_lease_until" is null
    ) or (
      "np_agent_circuit_breakers"."state"='half_open' and "np_agent_circuit_breakers"."reason_code" is not null and "np_agent_circuit_breakers"."opened_at">="np_agent_circuit_breakers"."window_started_at" and "np_agent_circuit_breakers"."retry_at" is null and "np_agent_circuit_breakers"."probe_lease_until">"np_agent_circuit_breakers"."opened_at"
    ))) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_connection_auth_requests" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"connection_id" uuid NOT NULL,
	"mode" text NOT NULL,
	"expected_connection_status" text NOT NULL,
	"provider" text NOT NULL,
	"adapter_contract_version" integer NOT NULL,
	"adapter_contract_fingerprint" text NOT NULL,
	"oauth_client_config_digest" text NOT NULL,
	"connection_config_version" integer NOT NULL,
	"connection_config_hash" text NOT NULL,
	"config_snapshot_id" uuid NOT NULL,
	"expected_secret_version_id" uuid,
	"expected_credential_version" integer,
	"expected_account_subject_key_id" text,
	"expected_account_subject_digest" text,
	"staff_session_id" uuid NOT NULL,
	"redirect_uri" text NOT NULL,
	"state_hash" text NOT NULL,
	"hash_key_id" text NOT NULL,
	"pkce_secret_version_id" uuid NOT NULL,
	"code_secret_version_id" uuid,
	"code_vault_operation_id" uuid,
	"connection_operation_id" uuid,
	"requested_permissions" text[] NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"consumed_at" timestamp with time zone,
	"denied_at" timestamp with time zone,
	"last_error_code" text,
	CONSTRAINT "np_agent_connection_auth_requests_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_connection_auth_requests_state_hash_unique" UNIQUE("state_hash"),
	CONSTRAINT "np_agent_connection_auth_requests_code_secret_unique" UNIQUE("code_secret_version_id"),
	CONSTRAINT "np_agent_connection_auth_requests_code_vault_operation_unique" UNIQUE("code_vault_operation_id"),
	CONSTRAINT "np_agent_connection_auth_requests_operation_unique" UNIQUE("connection_operation_id"),
	CONSTRAINT "np_agent_connection_auth_requests_mode_check" CHECK ("np_agent_connection_auth_requests"."mode" in ('initial', 'replace')),
	CONSTRAINT "np_agent_connection_auth_requests_expected_status_check" CHECK ("np_agent_connection_auth_requests"."expected_connection_status" in ('pending', 'ready', 'error', 'disabled')),
	CONSTRAINT "np_agent_connection_auth_requests_status_check" CHECK ("np_agent_connection_auth_requests"."status" in ('pending', 'consumed', 'denied', 'failed', 'expired', 'revoked')),
	CONSTRAINT "np_agent_connection_auth_requests_versions_check" CHECK ("np_agent_connection_auth_requests"."adapter_contract_version" > 0 and "np_agent_connection_auth_requests"."connection_config_version" > 0 and
        ("np_agent_connection_auth_requests"."expected_credential_version" is null or "np_agent_connection_auth_requests"."expected_credential_version" > 0)),
	CONSTRAINT "np_agent_connection_auth_requests_expected_secret_check" CHECK ((
        "np_agent_connection_auth_requests"."mode" = 'initial' and "np_agent_connection_auth_requests"."expected_secret_version_id" is null and "np_agent_connection_auth_requests"."expected_credential_version" is null and
          "np_agent_connection_auth_requests"."expected_account_subject_key_id" is null and "np_agent_connection_auth_requests"."expected_account_subject_digest" is null
      ) or (
        "np_agent_connection_auth_requests"."mode" = 'replace' and "np_agent_connection_auth_requests"."expected_secret_version_id" is not null and "np_agent_connection_auth_requests"."expected_credential_version" is not null and
          "np_agent_connection_auth_requests"."expected_account_subject_key_id" is not null and "np_agent_connection_auth_requests"."expected_account_subject_digest" is not null
      )),
	CONSTRAINT "np_agent_connection_auth_requests_permissions_check" CHECK (cardinality("np_agent_connection_auth_requests"."requested_permissions") between 1 and 128 and array_position("np_agent_connection_auth_requests"."requested_permissions", null) is null),
	CONSTRAINT "np_agent_connection_auth_requests_expiry_check" CHECK ("np_agent_connection_auth_requests"."expires_at" > "np_agent_connection_auth_requests"."created_at" and "np_agent_connection_auth_requests"."expires_at" <= "np_agent_connection_auth_requests"."created_at" + interval '10 minutes'),
	CONSTRAINT "np_agent_connection_auth_requests_callback_links_check" CHECK ((
        "np_agent_connection_auth_requests"."status" = 'consumed' and "np_agent_connection_auth_requests"."consumed_at" is not null and "np_agent_connection_auth_requests"."denied_at" is null and
          "np_agent_connection_auth_requests"."code_secret_version_id" is not null and "np_agent_connection_auth_requests"."code_vault_operation_id" is not null and "np_agent_connection_auth_requests"."connection_operation_id" is not null
      ) or (
        "np_agent_connection_auth_requests"."status" = 'denied' and "np_agent_connection_auth_requests"."denied_at" is not null and "np_agent_connection_auth_requests"."consumed_at" is null and
          "np_agent_connection_auth_requests"."code_secret_version_id" is null and "np_agent_connection_auth_requests"."code_vault_operation_id" is null and "np_agent_connection_auth_requests"."connection_operation_id" is null and
          "np_agent_connection_auth_requests"."last_error_code" = 'AUTHORIZATION_DENIED'
      ) or (
        "np_agent_connection_auth_requests"."status" in ('pending', 'failed', 'expired', 'revoked') and "np_agent_connection_auth_requests"."consumed_at" is null and "np_agent_connection_auth_requests"."denied_at" is null and
          "np_agent_connection_auth_requests"."code_secret_version_id" is null and "np_agent_connection_auth_requests"."code_vault_operation_id" is null and "np_agent_connection_auth_requests"."connection_operation_id" is null
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_connection_config_versions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"connection_id" uuid NOT NULL,
	"version" integer NOT NULL,
	"adapter_id" text NOT NULL,
	"adapter_contract_version" integer NOT NULL,
	"adapter_fingerprint" text NOT NULL,
	"config" jsonb NOT NULL,
	"config_hash" text NOT NULL,
	"pricing_catalog" jsonb NOT NULL,
	"pricing_catalog_fingerprint" text NOT NULL,
	"data_processing_ceiling" text NOT NULL,
	"state" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"activated_at" timestamp with time zone,
	"retired_at" timestamp with time zone,
	"rejected_at" timestamp with time zone,
	CONSTRAINT "np_agent_connection_config_versions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_connection_config_versions_binding_unique" UNIQUE("site_id","connection_id","id","version","config_hash"),
	CONSTRAINT "np_agent_connection_config_versions_number_unique" UNIQUE("site_id","connection_id","version"),
	CONSTRAINT "np_agent_connection_config_versions_version_check" CHECK ("np_agent_connection_config_versions"."version" > 0),
	CONSTRAINT "np_agent_connection_config_versions_adapter_version_check" CHECK ("np_agent_connection_config_versions"."adapter_contract_version" > 0),
	CONSTRAINT "np_agent_connection_config_versions_data_class_check" CHECK ("np_agent_connection_config_versions"."data_processing_ceiling" in ('public-only', 'internal-redacted', 'sensitive-approved')),
	CONSTRAINT "np_agent_connection_config_versions_state_check" CHECK ("np_agent_connection_config_versions"."state" in ('candidate', 'active', 'retired', 'rejected')),
	CONSTRAINT "np_agent_connection_config_versions_state_time_check" CHECK ((
        ("np_agent_connection_config_versions"."state" = 'candidate' and "np_agent_connection_config_versions"."activated_at" is null and "np_agent_connection_config_versions"."retired_at" is null and "np_agent_connection_config_versions"."rejected_at" is null)
        or ("np_agent_connection_config_versions"."state" = 'active' and "np_agent_connection_config_versions"."activated_at" is not null and "np_agent_connection_config_versions"."retired_at" is null and "np_agent_connection_config_versions"."rejected_at" is null)
        or ("np_agent_connection_config_versions"."state" = 'retired' and "np_agent_connection_config_versions"."activated_at" is not null and "np_agent_connection_config_versions"."retired_at" is not null and "np_agent_connection_config_versions"."rejected_at" is null)
        or ("np_agent_connection_config_versions"."state" = 'rejected' and "np_agent_connection_config_versions"."activated_at" is null and "np_agent_connection_config_versions"."retired_at" is null and "np_agent_connection_config_versions"."rejected_at" is not null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_connection_operations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"connection_id" uuid NOT NULL,
	"source" text NOT NULL,
	"invocation_id" uuid,
	"run_id" uuid,
	"kind" text NOT NULL,
	"state" text NOT NULL,
	"expected_config_version" integer NOT NULL,
	"expected_config_hash" text NOT NULL,
	"config_snapshot_id" uuid NOT NULL,
	"adapter_contract_version" integer NOT NULL,
	"adapter_fingerprint" text NOT NULL,
	"auth_request_id" uuid,
	"input_secret_version_ids" uuid[] NOT NULL,
	"expected_secret_version_id" uuid,
	"expected_credential_version" integer,
	"expected_refresh_generation" integer,
	"idempotency_key" text NOT NULL,
	"request_hash" text NOT NULL,
	"attempt" integer DEFAULT 1 NOT NULL,
	"result_redacted" jsonb,
	"result_digest" text,
	"last_error_code" text,
	"deadline_at" timestamp with time zone,
	"lease_until" timestamp with time zone,
	"created_by_user_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	CONSTRAINT "np_agent_connection_operations_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_connection_operations_invocation_unique" UNIQUE("invocation_id"),
	CONSTRAINT "np_agent_connection_operations_auth_request_unique" UNIQUE("auth_request_id"),
	CONSTRAINT "np_agent_connection_operations_idempotency_unique" UNIQUE("site_id","connection_id","idempotency_key"),
	CONSTRAINT "np_agent_connection_operations_source_check" CHECK ("np_agent_connection_operations"."source" in ('admin-invocation', 'oauth-setup', 'runtime-refresh')),
	CONSTRAINT "np_agent_connection_operations_kind_check" CHECK ("np_agent_connection_operations"."kind" in ('probe', 'activate-secret', 'activate-config', 'oauth-exchange', 'oauth-refresh', 'destroy-secret')),
	CONSTRAINT "np_agent_connection_operations_state_check" CHECK ("np_agent_connection_operations"."state" in ('awaiting_secret', 'queued', 'running', 'succeeded', 'failed', 'ambiguous', 'cancelled')),
	CONSTRAINT "np_agent_connection_operations_versions_check" CHECK ("np_agent_connection_operations"."expected_config_version" > 0 and "np_agent_connection_operations"."adapter_contract_version" > 0 and "np_agent_connection_operations"."attempt" between 1 and 65535 and
        ("np_agent_connection_operations"."expected_credential_version" is null or "np_agent_connection_operations"."expected_credential_version" > 0) and
        ("np_agent_connection_operations"."expected_refresh_generation" is null or "np_agent_connection_operations"."expected_refresh_generation" > 0)),
	CONSTRAINT "np_agent_connection_operations_source_authority_check" CHECK ((
        ("np_agent_connection_operations"."source" = 'admin-invocation' and "np_agent_connection_operations"."invocation_id" is not null and "np_agent_connection_operations"."auth_request_id" is null and "np_agent_connection_operations"."run_id" is null)
        or ("np_agent_connection_operations"."source" = 'oauth-setup' and "np_agent_connection_operations"."invocation_id" is null and "np_agent_connection_operations"."auth_request_id" is not null and "np_agent_connection_operations"."run_id" is null)
        or ("np_agent_connection_operations"."source" = 'runtime-refresh' and "np_agent_connection_operations"."invocation_id" is null and "np_agent_connection_operations"."auth_request_id" is null and "np_agent_connection_operations"."run_id" is not null)
      )),
	CONSTRAINT "np_agent_connection_operations_refresh_check" CHECK ((
        "np_agent_connection_operations"."kind" = 'oauth-refresh' and "np_agent_connection_operations"."expected_secret_version_id" is not null and
          "np_agent_connection_operations"."expected_credential_version" is not null and "np_agent_connection_operations"."expected_refresh_generation" is not null
      ) or (
        "np_agent_connection_operations"."kind" <> 'oauth-refresh' and "np_agent_connection_operations"."expected_refresh_generation" is null
      )),
	CONSTRAINT "np_agent_connection_operations_result_pair_check" CHECK (("np_agent_connection_operations"."result_redacted" is null) = ("np_agent_connection_operations"."result_digest" is null)),
	CONSTRAINT "np_agent_connection_operations_state_time_check" CHECK ((
        ("np_agent_connection_operations"."state" = 'awaiting_secret' and "np_agent_connection_operations"."source" = 'oauth-setup' and "np_agent_connection_operations"."kind" = 'oauth-exchange' and
          "np_agent_connection_operations"."deadline_at" is null and "np_agent_connection_operations"."lease_until" is null and "np_agent_connection_operations"."started_at" is null and "np_agent_connection_operations"."finished_at" is null)
        or ("np_agent_connection_operations"."state" = 'queued' and "np_agent_connection_operations"."deadline_at" is not null and "np_agent_connection_operations"."lease_until" is null and "np_agent_connection_operations"."started_at" is null and "np_agent_connection_operations"."finished_at" is null)
        or ("np_agent_connection_operations"."state" = 'running' and "np_agent_connection_operations"."deadline_at" is not null and "np_agent_connection_operations"."lease_until" is not null and "np_agent_connection_operations"."started_at" is not null and "np_agent_connection_operations"."finished_at" is null)
        or ("np_agent_connection_operations"."state" = 'succeeded' and "np_agent_connection_operations"."deadline_at" is not null and "np_agent_connection_operations"."finished_at" is not null and "np_agent_connection_operations"."last_error_code" is null and "np_agent_connection_operations"."result_digest" is not null)
        or ("np_agent_connection_operations"."state" in ('failed', 'ambiguous', 'cancelled') and "np_agent_connection_operations"."finished_at" is not null and "np_agent_connection_operations"."last_error_code" is not null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_connection_secret_versions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"connection_id" uuid NOT NULL,
	"version" integer NOT NULL,
	"status" text NOT NULL,
	"purpose" text NOT NULL,
	"vault_adapter" text NOT NULL,
	"vault_adapter_contract_version" integer NOT NULL,
	"vault_adapter_fingerprint" text NOT NULL,
	"seal_operation_id" uuid NOT NULL,
	"secret_ref" text,
	"material_kind" text NOT NULL,
	"credential_envelope_version" integer NOT NULL,
	"vault_algorithm" text NOT NULL,
	"aad_body" jsonb NOT NULL,
	"aad_digest" text NOT NULL,
	"expires_at" timestamp with time zone,
	"access_expires_at" timestamp with time zone,
	"refresh_token_present" boolean,
	"refresh_expires_at" timestamp with time zone,
	"refresh_generation" integer,
	"permission_digest" text,
	"account_subject_key_id" text,
	"account_subject_digest" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"activated_at" timestamp with time zone,
	"retired_at" timestamp with time zone,
	"destroyed_at" timestamp with time zone,
	CONSTRAINT "np_agent_connection_secret_versions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_connection_secret_versions_binding_unique" UNIQUE("site_id","connection_id","id","version"),
	CONSTRAINT "np_agent_connection_secret_versions_number_unique" UNIQUE("site_id","connection_id","purpose","version"),
	CONSTRAINT "np_agent_connection_secret_versions_seal_operation_unique" UNIQUE("seal_operation_id"),
	CONSTRAINT "np_agent_connection_secret_versions_version_check" CHECK ("np_agent_connection_secret_versions"."version" > 0),
	CONSTRAINT "np_agent_connection_secret_versions_status_check" CHECK ("np_agent_connection_secret_versions"."status" in ('pending', 'active', 'retiring', 'revoked', 'destroyed')),
	CONSTRAINT "np_agent_connection_secret_versions_purpose_check" CHECK ("np_agent_connection_secret_versions"."purpose" in ('connection-credential', 'provider-oauth-pkce', 'provider-oauth-code')),
	CONSTRAINT "np_agent_connection_secret_versions_material_check" CHECK ("np_agent_connection_secret_versions"."material_kind" in ('api_key', 'oauth', 'provider_oauth_pkce', 'provider_oauth_code')),
	CONSTRAINT "np_agent_connection_secret_versions_envelope_check" CHECK ("np_agent_connection_secret_versions"."vault_adapter_contract_version" > 0 and "np_agent_connection_secret_versions"."credential_envelope_version" = 1),
	CONSTRAINT "np_agent_connection_secret_versions_purpose_material_check" CHECK ((
        "np_agent_connection_secret_versions"."purpose" = 'connection-credential' and "np_agent_connection_secret_versions"."material_kind" in ('api_key', 'oauth')
      ) or (
        "np_agent_connection_secret_versions"."purpose" = 'provider-oauth-pkce' and "np_agent_connection_secret_versions"."material_kind" = 'provider_oauth_pkce'
      ) or (
        "np_agent_connection_secret_versions"."purpose" = 'provider-oauth-code' and "np_agent_connection_secret_versions"."material_kind" = 'provider_oauth_code'
      )),
	CONSTRAINT "np_agent_connection_secret_versions_temporary_expiry_check" CHECK ((
        "np_agent_connection_secret_versions"."purpose" = 'connection-credential' and "np_agent_connection_secret_versions"."expires_at" is null
      ) or (
        "np_agent_connection_secret_versions"."purpose" in ('provider-oauth-pkce', 'provider-oauth-code') and "np_agent_connection_secret_versions"."expires_at" is not null and
        "np_agent_connection_secret_versions"."expires_at" > "np_agent_connection_secret_versions"."created_at" and "np_agent_connection_secret_versions"."expires_at" <= "np_agent_connection_secret_versions"."created_at" + interval '10 minutes'
      )),
	CONSTRAINT "np_agent_connection_secret_versions_subject_check" CHECK ((
        "np_agent_connection_secret_versions"."purpose" = 'connection-credential' and
          (("np_agent_connection_secret_versions"."account_subject_key_id" is null and "np_agent_connection_secret_versions"."account_subject_digest" is null and
             "np_agent_connection_secret_versions"."status" in ('pending', 'revoked', 'destroyed') and "np_agent_connection_secret_versions"."activated_at" is null) or
           ("np_agent_connection_secret_versions"."account_subject_key_id" is not null and "np_agent_connection_secret_versions"."account_subject_digest" is not null))
      ) or (
        "np_agent_connection_secret_versions"."purpose" <> 'connection-credential' and "np_agent_connection_secret_versions"."account_subject_key_id" is null and "np_agent_connection_secret_versions"."account_subject_digest" is null
      )),
	CONSTRAINT "np_agent_connection_secret_versions_oauth_metadata_check" CHECK ((
        "np_agent_connection_secret_versions"."material_kind" = 'oauth' and "np_agent_connection_secret_versions"."access_expires_at" is not null and
          "np_agent_connection_secret_versions"."refresh_token_present" is not null and "np_agent_connection_secret_versions"."refresh_generation" is not null and "np_agent_connection_secret_versions"."refresh_generation" > 0 and
          "np_agent_connection_secret_versions"."permission_digest" is not null and ("np_agent_connection_secret_versions"."refresh_token_present" = true or "np_agent_connection_secret_versions"."refresh_expires_at" is null)
      ) or (
        "np_agent_connection_secret_versions"."material_kind" <> 'oauth' and "np_agent_connection_secret_versions"."access_expires_at" is null and "np_agent_connection_secret_versions"."refresh_token_present" is null and
          "np_agent_connection_secret_versions"."refresh_expires_at" is null and "np_agent_connection_secret_versions"."refresh_generation" is null and "np_agent_connection_secret_versions"."permission_digest" is null
      )),
	CONSTRAINT "np_agent_connection_secret_versions_locator_check" CHECK (("np_agent_connection_secret_versions"."status" = 'destroyed' and "np_agent_connection_secret_versions"."secret_ref" is null) or
        ("np_agent_connection_secret_versions"."status" <> 'destroyed' and
          ("np_agent_connection_secret_versions"."secret_ref" is not null or "np_agent_connection_secret_versions"."status" in ('pending', 'revoked')))),
	CONSTRAINT "np_agent_connection_secret_versions_state_time_check" CHECK ((
        ("np_agent_connection_secret_versions"."status" = 'pending' and "np_agent_connection_secret_versions"."activated_at" is null and "np_agent_connection_secret_versions"."retired_at" is null and "np_agent_connection_secret_versions"."destroyed_at" is null)
        or ("np_agent_connection_secret_versions"."status" = 'active' and "np_agent_connection_secret_versions"."purpose" = 'connection-credential' and "np_agent_connection_secret_versions"."activated_at" is not null and "np_agent_connection_secret_versions"."retired_at" is null and "np_agent_connection_secret_versions"."destroyed_at" is null)
        or ("np_agent_connection_secret_versions"."status" = 'retiring' and "np_agent_connection_secret_versions"."purpose" = 'connection-credential' and "np_agent_connection_secret_versions"."activated_at" is not null and "np_agent_connection_secret_versions"."retired_at" is not null and "np_agent_connection_secret_versions"."destroyed_at" is null)
        or ("np_agent_connection_secret_versions"."status" = 'revoked' and "np_agent_connection_secret_versions"."destroyed_at" is null and
          (("np_agent_connection_secret_versions"."purpose" = 'connection-credential') or ("np_agent_connection_secret_versions"."activated_at" is null and "np_agent_connection_secret_versions"."retired_at" is null)))
        or ("np_agent_connection_secret_versions"."status" = 'destroyed' and "np_agent_connection_secret_versions"."destroyed_at" is not null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_connections" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"kind" text NOT NULL,
	"provider" text NOT NULL,
	"adapter_contract_version" integer NOT NULL,
	"name" text NOT NULL,
	"auth_kind" text NOT NULL,
	"active_secret_version_id" uuid,
	"active_config_snapshot_id" uuid NOT NULL,
	"credential_version" integer,
	"active_account_subject_key_id" text,
	"active_account_subject_digest" text,
	"active_destination_key_id" text,
	"active_destination_descriptor" jsonb,
	"active_destination_fingerprint" text,
	"config" jsonb NOT NULL,
	"config_version" integer NOT NULL,
	"config_hash" text NOT NULL,
	"pricing_catalog_fingerprint" text NOT NULL,
	"data_processing_ceiling" text NOT NULL,
	"status" text NOT NULL,
	"last_verified_at" timestamp with time zone,
	"last_verified_config_version" integer,
	"last_verified_credential_version" integer,
	"last_probe_result_digest" text,
	"last_error_code" text,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_connections_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_connections_kind_check" CHECK ("np_agent_connections"."kind" in ('model', 'notification')),
	CONSTRAINT "np_agent_connections_auth_kind_check" CHECK ("np_agent_connections"."auth_kind" in ('api_key', 'oauth')),
	CONSTRAINT "np_agent_connections_status_check" CHECK ("np_agent_connections"."status" in ('pending', 'ready', 'error', 'disabled', 'revoked')),
	CONSTRAINT "np_agent_connections_data_class_check" CHECK ("np_agent_connections"."data_processing_ceiling" in ('public-only', 'internal-redacted', 'sensitive-approved')),
	CONSTRAINT "np_agent_connections_versions_check" CHECK ("np_agent_connections"."adapter_contract_version" > 0 and "np_agent_connections"."config_version" > 0 and ("np_agent_connections"."credential_version" is null or "np_agent_connections"."credential_version" > 0)),
	CONSTRAINT "np_agent_connections_name_check" CHECK (char_length("np_agent_connections"."name") between 1 and 120 and "np_agent_connections"."name" = btrim("np_agent_connections"."name")),
	CONSTRAINT "np_agent_connections_credential_tuple_check" CHECK ((
        "np_agent_connections"."active_secret_version_id" is null and "np_agent_connections"."credential_version" is null and
        "np_agent_connections"."active_account_subject_key_id" is null and "np_agent_connections"."active_account_subject_digest" is null
      ) or (
        "np_agent_connections"."active_secret_version_id" is not null and "np_agent_connections"."credential_version" is not null and
        "np_agent_connections"."active_account_subject_key_id" is not null and "np_agent_connections"."active_account_subject_digest" is not null
      )),
	CONSTRAINT "np_agent_connections_destination_check" CHECK ((
        "np_agent_connections"."kind" = 'notification' and (
          ("np_agent_connections"."active_secret_version_id" is null and "np_agent_connections"."active_destination_key_id" is null and
            "np_agent_connections"."active_destination_descriptor" is null and "np_agent_connections"."active_destination_fingerprint" is null)
          or
          ("np_agent_connections"."active_secret_version_id" is not null and "np_agent_connections"."active_destination_key_id" is not null and
            "np_agent_connections"."active_destination_descriptor" is not null and "np_agent_connections"."active_destination_fingerprint" is not null)
        )
      ) or (
        "np_agent_connections"."kind" = 'model' and "np_agent_connections"."active_destination_key_id" is null and
        "np_agent_connections"."active_destination_descriptor" is null and "np_agent_connections"."active_destination_fingerprint" is null
      )),
	CONSTRAINT "np_agent_connections_probe_tuple_check" CHECK ((
        "np_agent_connections"."last_verified_at" is null and "np_agent_connections"."last_verified_config_version" is null and
        "np_agent_connections"."last_verified_credential_version" is null and "np_agent_connections"."last_probe_result_digest" is null
      ) or (
        "np_agent_connections"."last_verified_at" is not null and "np_agent_connections"."last_verified_config_version" is not null and
        "np_agent_connections"."last_verified_credential_version" is not null and "np_agent_connections"."last_probe_result_digest" is not null
      )),
	CONSTRAINT "np_agent_connections_state_matrix_check" CHECK ((
        ("np_agent_connections"."status" = 'pending' and "np_agent_connections"."active_secret_version_id" is null and "np_agent_connections"."last_verified_at" is null and "np_agent_connections"."last_error_code" is null)
        or ("np_agent_connections"."status" = 'ready' and "np_agent_connections"."active_secret_version_id" is not null and "np_agent_connections"."last_verified_at" is not null and
          "np_agent_connections"."last_verified_config_version" = "np_agent_connections"."config_version" and "np_agent_connections"."last_verified_credential_version" = "np_agent_connections"."credential_version" and "np_agent_connections"."last_error_code" is null)
        or ("np_agent_connections"."status" = 'disabled' and "np_agent_connections"."active_secret_version_id" is not null and "np_agent_connections"."last_verified_at" is not null and
          "np_agent_connections"."last_verified_config_version" = "np_agent_connections"."config_version" and "np_agent_connections"."last_verified_credential_version" = "np_agent_connections"."credential_version" and "np_agent_connections"."last_error_code" is null)
        or ("np_agent_connections"."status" = 'error' and "np_agent_connections"."last_error_code" is not null and
          (("np_agent_connections"."active_secret_version_id" is null and "np_agent_connections"."last_verified_at" is null) or
           ("np_agent_connections"."active_secret_version_id" is not null and "np_agent_connections"."last_verified_at" is not null)))
        or ("np_agent_connections"."status" = 'revoked' and "np_agent_connections"."active_secret_version_id" is null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_containments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"kind" text NOT NULL,
	"target_kind" text NOT NULL,
	"target_ref" jsonb NOT NULL,
	"target_version_digest" text NOT NULL,
	"source_action_id" uuid NOT NULL,
	"restore_action_id" uuid,
	"incident_id" uuid,
	"state" text NOT NULL,
	"original_state" jsonb NOT NULL,
	"expires_at" timestamp with time zone,
	"activated_at" timestamp with time zone,
	"restored_at" timestamp with time zone,
	"last_error_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_containments_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_containments_source_action_unique" UNIQUE("source_action_id"),
	CONSTRAINT "np_agent_containments_restore_action_unique" UNIQUE("restore_action_id"),
	CONSTRAINT "np_agent_containments_kind_check" CHECK (("np_agent_containments"."kind"='content_quarantine' and "np_agent_containments"."target_kind" in ('document','comment') and "np_agent_containments"."target_ref"->>'kind'="np_agent_containments"."target_kind") is true),
	CONSTRAINT "np_agent_containments_state_check" CHECK (("np_agent_containments"."state" in ('pending','active','restoring','restored','expired','failed') and ("np_agent_containments"."state" not in ('active','restoring','restored','expired') or "np_agent_containments"."activated_at" is not null) and ("np_agent_containments"."state"='restored')=("np_agent_containments"."restored_at" is not null) and ("np_agent_containments"."restore_action_id" is null or "np_agent_containments"."restore_action_id"<>"np_agent_containments"."source_action_id")) is true),
	CONSTRAINT "np_agent_containments_bounds_check" CHECK ((jsonb_typeof("np_agent_containments"."target_ref")='object' and octet_length("np_agent_containments"."target_ref"::text)<=4096 and "np_agent_containments"."target_version_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and jsonb_typeof("np_agent_containments"."original_state")='object' and octet_length("np_agent_containments"."original_state"::text)<=16384 and ("np_agent_containments"."last_error_code" is null or "np_agent_containments"."last_error_code" ~ '^[A-Z][A-Z0-9_]{0,63}$')) is true),
	CONSTRAINT "np_agent_containments_time_check" CHECK (("np_agent_containments"."updated_at">="np_agent_containments"."created_at" and ("np_agent_containments"."expires_at" is null or ("np_agent_containments"."expires_at">"np_agent_containments"."created_at" and "np_agent_containments"."expires_at"<="np_agent_containments"."created_at"+interval '30 days')) and ("np_agent_containments"."activated_at" is null or "np_agent_containments"."activated_at">="np_agent_containments"."created_at") and ("np_agent_containments"."restored_at" is null or "np_agent_containments"."restored_at">="np_agent_containments"."activated_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_content_receipts" (
	"id" uuid PRIMARY KEY NOT NULL,
	"site_id" text NOT NULL,
	"body" jsonb NOT NULL,
	"body_hash" text NOT NULL,
	"key_id" text NOT NULL,
	"source_mac" text NOT NULL,
	"occurred_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"state" text DEFAULT 'pending' NOT NULL,
	"next_attempt_at" timestamp with time zone DEFAULT now() NOT NULL,
	"failure_code" text,
	"emitted_event_id" uuid,
	"emitted_at" timestamp with time zone,
	CONSTRAINT "np_agent_content_receipts_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_content_receipts_source_check" CHECK (("np_agent_content_receipts"."body"->>'schemaVersion'='np.agent-guardian-content-activity.v1'
        and "np_agent_content_receipts"."body"->>'siteId'="np_agent_content_receipts"."site_id" and "np_agent_content_receipts"."body"->>'writeId'="np_agent_content_receipts"."id"::text
        and "np_agent_content_receipts"."body"->>'occurredAt'=to_char("np_agent_content_receipts"."occurred_at" at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
        and octet_length("np_agent_content_receipts"."body"::text)<=8192
        and "np_agent_content_receipts"."body_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$'
        and "np_agent_content_receipts"."key_id" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$'
        and "np_agent_content_receipts"."source_mac" ~ '^hmac-sha256:[A-Za-z0-9_-]{43}$') is true),
	CONSTRAINT "np_agent_content_receipts_delivery_check" CHECK ((("np_agent_content_receipts"."state"='emitted' and "np_agent_content_receipts"."emitted_event_id" is not null
          and "np_agent_content_receipts"."emitted_at" is not null and "np_agent_content_receipts"."failure_code" is null)
        or ("np_agent_content_receipts"."state"='pending' and "np_agent_content_receipts"."emitted_event_id" is null
          and "np_agent_content_receipts"."emitted_at" is null and "np_agent_content_receipts"."failure_code" is null)
        or ("np_agent_content_receipts"."state"='blocked' and "np_agent_content_receipts"."emitted_event_id" is null
          and "np_agent_content_receipts"."emitted_at" is null
          and "np_agent_content_receipts"."failure_code" in ('KEY_UNAVAILABLE','SOURCE_INTEGRITY','DELIVERY_UNAVAILABLE'))
        or ("np_agent_content_receipts"."state"='sampled' and "np_agent_content_receipts"."emitted_event_id" is null
          and "np_agent_content_receipts"."emitted_at" is null and "np_agent_content_receipts"."failure_code"='COVERAGE_CAPPED')
        or ("np_agent_content_receipts"."state"='held' and "np_agent_content_receipts"."emitted_event_id" is null
          and "np_agent_content_receipts"."emitted_at" is null and "np_agent_content_receipts"."failure_code"='DELIVERY_CLOSED')) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_evaluation_reviews" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"source_id" uuid NOT NULL,
	"version_number" integer NOT NULL,
	"case_id" text NOT NULL,
	"case_version" integer NOT NULL,
	"case_hash" text NOT NULL,
	"prediction_hash" text NOT NULL,
	"previous_revision_id" uuid,
	"recorded_by_user_id" uuid,
	"actor_fingerprint" text NOT NULL,
	"label_body" jsonb,
	"revision_hash" text NOT NULL,
	"invocation_id" uuid NOT NULL,
	"audit_event_id" uuid NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_evaluation_reviews_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_evaluation_reviews_source_id_id_unique" UNIQUE("site_id","source_id","id"),
	CONSTRAINT "np_agent_evaluation_reviews_version_unique" UNIQUE("site_id","source_id","version_number"),
	CONSTRAINT "np_agent_evaluation_reviews_invocation_unique" UNIQUE("site_id","invocation_id"),
	CONSTRAINT "np_agent_evaluation_reviews_bounds_check" CHECK (("np_agent_evaluation_reviews"."version_number" between 1 and 10000 and "np_agent_evaluation_reviews"."case_version" between 1 and 2147483646 and char_length("np_agent_evaluation_reviews"."case_id") between 1 and 128 and "np_agent_evaluation_reviews"."case_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_evaluation_reviews"."prediction_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_evaluation_reviews"."actor_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_evaluation_reviews"."revision_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_evaluation_reviews"."previous_revision_id" is null or "np_agent_evaluation_reviews"."previous_revision_id"<>"np_agent_evaluation_reviews"."id") and ("np_agent_evaluation_reviews"."label_body" is null or (jsonb_typeof("np_agent_evaluation_reviews"."label_body")='object' and octet_length("np_agent_evaluation_reviews"."label_body"::text)<=393216 and "np_agent_evaluation_reviews"."label_body"->>'reviewer'='staff:'||"np_agent_evaluation_reviews"."actor_fingerprint" and "np_agent_evaluation_reviews"."label_body"->>'caseId'="np_agent_evaluation_reviews"."case_id" and "np_agent_evaluation_reviews"."label_body"->>'caseHash'="np_agent_evaluation_reviews"."case_hash" and "np_agent_evaluation_reviews"."label_body"->>'predictionHash'="np_agent_evaluation_reviews"."prediction_hash"))) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_evaluation_sources" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"recipe" text NOT NULL,
	"source_hash" text NOT NULL,
	"evaluation_body" jsonb NOT NULL,
	"version_number" integer NOT NULL,
	"case_count" integer NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_evaluation_sources_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_evaluation_sources_source_unique" UNIQUE("site_id","recipe","source_hash"),
	CONSTRAINT "np_agent_evaluation_sources_bounds_check" CHECK (("np_agent_evaluation_sources"."version_number" between 0 and 10000 and "np_agent_evaluation_sources"."case_count" between 1 and 100 and "np_agent_evaluation_sources"."recipe" in ('moderator','moderator-proposal','operator','publisher','moderator-assessment','publisher-selection','guardian') and "np_agent_evaluation_sources"."source_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and jsonb_typeof("np_agent_evaluation_sources"."evaluation_body")='object' and octet_length("np_agent_evaluation_sources"."evaluation_body"::text)<=4194304) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"kind" text NOT NULL,
	"source_kind" text NOT NULL,
	"source_component" text NOT NULL,
	"subject" jsonb,
	"actor" jsonb,
	"causation" jsonb,
	"causal_root_run_id" uuid,
	"causal_run_id" uuid,
	"causal_action_id" uuid,
	"causal_depth" integer,
	"correlation_id" text,
	"deduplication_key" text,
	"event_hash" text NOT NULL,
	"privacy" text NOT NULL,
	"payload" jsonb NOT NULL,
	"occurred_at" timestamp with time zone NOT NULL,
	"recorded_at" timestamp with time zone DEFAULT now() NOT NULL,
	"dispatched_at" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_events_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_events_kind_check" CHECK ("np_agent_events"."kind" in ('api.rate-limited','agent.action.changed','agent.policy.blocked','agent.policy.changed','agent.run.changed','agent.runtime.activity.observed','http.response.observed','auth.login.failed','auth.login.succeeded','auth.session.revoked','authz.denied','authz.role.changed','community.content.created','community.content.moderated','community.content.reported','community.member.reported','content.document.changed','content.activity.observed','content.document.published','jobs.backlog.threshold','jobs.handler.failed','jobs.worker.stale','ops.backup.failed','ops.backup.stale','ops.check.changed','security.edge.signal','security.error.signal','security.authority.changed','security.credential.changed','security.plugin.changed')),
	CONSTRAINT "np_agent_events_source_check" CHECK ("np_agent_events"."source_kind" in ('auth','api','community','content','jobs','ops','storage','plugin','integration','agent') and "np_agent_events"."source_component" ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]{0,127}$' and ("np_agent_events"."correlation_id" is null or "np_agent_events"."correlation_id" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$') and ("np_agent_events"."deduplication_key" is null or "np_agent_events"."deduplication_key" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$')),
	CONSTRAINT "np_agent_events_body_check" CHECK (("np_agent_events"."privacy" in ('public','internal','sensitive') and "np_agent_events"."event_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_events"."payload"->>'kind'="np_agent_events"."kind" and octet_length("np_agent_events"."payload"::text)<=65536 and ("np_agent_events"."subject" is null or octet_length("np_agent_events"."subject"::text)<=4096) and ("np_agent_events"."actor" is null or octet_length("np_agent_events"."actor"::text)<=4096)) is true),
	CONSTRAINT "np_agent_events_causation_check" CHECK ((((
      "np_agent_events"."causal_root_run_id" is null and "np_agent_events"."causal_run_id" is null and "np_agent_events"."causal_action_id" is null and "np_agent_events"."causal_depth" is null
    ) or (
      "np_agent_events"."causal_root_run_id" is not null and "np_agent_events"."causal_run_id" is not null and "np_agent_events"."causal_action_id" is not null and "np_agent_events"."causal_depth" between 0 and 4 and "np_agent_events"."causation"->>'rootRunId'="np_agent_events"."causal_root_run_id"::text and "np_agent_events"."causation"->>'sourceRunId'="np_agent_events"."causal_run_id"::text and "np_agent_events"."causation"->>'sourceActionId'="np_agent_events"."causal_action_id"::text and "np_agent_events"."causation"->>'depth'="np_agent_events"."causal_depth"::text
    )) and ("np_agent_events"."causation" is null or (jsonb_typeof("np_agent_events"."causation")='object' and octet_length("np_agent_events"."causation"::text)<=4096))) is true),
	CONSTRAINT "np_agent_events_time_check" CHECK ("np_agent_events"."expires_at">"np_agent_events"."recorded_at" and ("np_agent_events"."dispatched_at" is null or "np_agent_events"."dispatched_at">="np_agent_events"."recorded_at"))
);
--> statement-breakpoint
CREATE TABLE "np_agent_feedback" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"target_kind" text NOT NULL,
	"target_id" uuid,
	"target_fingerprint" text NOT NULL,
	"label" text NOT NULL,
	"detector_id" text,
	"detector_version" integer,
	"agent_version_id" uuid,
	"provider_call_id" uuid,
	"policy_hashes" text[] NOT NULL,
	"recorded_by_user_id" uuid,
	"actor_fingerprint" text NOT NULL,
	"note" text,
	"supersedes_id" uuid,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_feedback_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_feedback_kind_check" CHECK (("np_agent_feedback"."target_kind" in ('action','run','incident','agent_assessment') and "np_agent_feedback"."label" in ('confirmed-spam','false-positive','useful','incorrect')) is true),
	CONSTRAINT "np_agent_feedback_bounds_check" CHECK ((length("np_agent_feedback"."target_fingerprint") between 1 and 256 and length("np_agent_feedback"."actor_fingerprint") between 1 and 256 and ("np_agent_feedback"."detector_id" is null)=("np_agent_feedback"."detector_version" is null) and ("np_agent_feedback"."detector_version" is null or "np_agent_feedback"."detector_version">0) and cardinality("np_agent_feedback"."policy_hashes")<=64 and ("np_agent_feedback"."note" is null or length("np_agent_feedback"."note")<=4096) and ("np_agent_feedback"."supersedes_id" is null or "np_agent_feedback"."supersedes_id"<>"np_agent_feedback"."id")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_incident_signals" (
	"id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"incident_id" uuid NOT NULL,
	"signal_id" uuid NOT NULL,
	CONSTRAINT "np_agent_incident_signals_site_id_incident_id_signal_id_pk" PRIMARY KEY("site_id","incident_id","signal_id"),
	CONSTRAINT "np_agent_incident_signals_id_unique" UNIQUE("id")
);
--> statement-breakpoint
CREATE TABLE "np_agent_incident_timeline" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"incident_id" uuid NOT NULL,
	"sequence" integer NOT NULL,
	"kind" text NOT NULL,
	"source_kind" text NOT NULL,
	"source_id" uuid,
	"source_fingerprint" text NOT NULL,
	"event_id" uuid,
	"signal_id" uuid,
	"run_id" uuid,
	"action_id" uuid,
	"approval_id" uuid,
	"provider_call_id" uuid,
	"audit_event_id" uuid,
	"summary" text NOT NULL,
	"details" jsonb NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_incident_timeline_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_incident_timeline_sequence_unique" UNIQUE("site_id","incident_id","sequence"),
	CONSTRAINT "np_agent_incident_timeline_kind_check" CHECK (("np_agent_incident_timeline"."kind" in ('observed','correlated','agent_assessment','human_note','state_transition','action','verification','notification') and "np_agent_incident_timeline"."source_kind" in ('system','agent','staff','integration') and ("np_agent_incident_timeline"."kind"<>'agent_assessment' or ("np_agent_incident_timeline"."run_id" is not null and "np_agent_incident_timeline"."provider_call_id" is not null))) is true),
	CONSTRAINT "np_agent_incident_timeline_bounds_check" CHECK (("np_agent_incident_timeline"."sequence">0 and length("np_agent_incident_timeline"."source_fingerprint") between 1 and 256 and length("np_agent_incident_timeline"."summary") between 1 and 2000 and jsonb_typeof("np_agent_incident_timeline"."details")='object' and octet_length("np_agent_incident_timeline"."details"::text)<=16384) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_incidents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"category" text NOT NULL,
	"status" text NOT NULL,
	"severity" text NOT NULL,
	"fingerprint" text NOT NULL,
	"title" text NOT NULL,
	"summary" text NOT NULL,
	"primary_subject" jsonb,
	"signal_count" integer DEFAULT 0 NOT NULL,
	"event_count" integer DEFAULT 0 NOT NULL,
	"assigned_agent_id" uuid,
	"first_observed_at" timestamp with time zone NOT NULL,
	"last_observed_at" timestamp with time zone NOT NULL,
	"contained_at" timestamp with time zone,
	"resolved_at" timestamp with time zone,
	"resolution_code" text,
	"version_number" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_incidents_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_incidents_state_check" CHECK (("np_agent_incidents"."category" in ('spam','abuse','authentication','authorization','traffic','integrity','availability','cost','agent-abuse') and "np_agent_incidents"."severity" in ('info','low','medium','high','critical') and "np_agent_incidents"."status" in ('open','investigating','contained','monitoring','resolved','dismissed') and ("np_agent_incidents"."status" in ('resolved','dismissed'))=("np_agent_incidents"."resolved_at" is not null) and ("np_agent_incidents"."status"<>'contained' or "np_agent_incidents"."contained_at" is not null)) is true),
	CONSTRAINT "np_agent_incidents_bounds_check" CHECK ((length("np_agent_incidents"."fingerprint") between 1 and 256 and length("np_agent_incidents"."title") between 1 and 200 and length("np_agent_incidents"."summary") between 1 and 2000 and "np_agent_incidents"."signal_count">=0 and "np_agent_incidents"."event_count">=0 and "np_agent_incidents"."version_number">0 and ("np_agent_incidents"."primary_subject" is null or octet_length("np_agent_incidents"."primary_subject"::text)<=4096) and ("np_agent_incidents"."resolution_code" is null or "np_agent_incidents"."resolution_code" ~ '^[A-Z][A-Z0-9_]{0,63}$')) is true),
	CONSTRAINT "np_agent_incidents_time_check" CHECK (("np_agent_incidents"."last_observed_at">="np_agent_incidents"."first_observed_at" and ("np_agent_incidents"."contained_at" is null or "np_agent_incidents"."contained_at">="np_agent_incidents"."first_observed_at") and ("np_agent_incidents"."resolved_at" is null or "np_agent_incidents"."resolved_at">="np_agent_incidents"."first_observed_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_invocations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"actor_kind" text NOT NULL,
	"principal_id" uuid,
	"staff_user_id" uuid,
	"actor_fingerprint" text NOT NULL,
	"authorization_context_body" jsonb NOT NULL,
	"authorization_context_fingerprint" text NOT NULL,
	"authority_ref" jsonb NOT NULL,
	"actor_deleted_at" timestamp with time zone,
	"operation_kind" text NOT NULL,
	"operation_id" text NOT NULL,
	"contract_version" integer NOT NULL,
	"contract_fingerprint" text NOT NULL,
	"capability_definition_body" jsonb,
	"effect_profile_id" text,
	"effect_contract_version" integer,
	"transport" text NOT NULL,
	"mcp_execution_mode" text,
	"mcp_requested_task_ttl_ms" bigint,
	"idempotency_key" text,
	"request_body" jsonb NOT NULL,
	"request_hash" text NOT NULL,
	"state" text NOT NULL,
	"run_id" uuid,
	"result_kind" text,
	"result_id" uuid,
	"output_redacted" jsonb,
	"output_hash" text,
	"one_time_value_issued" boolean DEFAULT false NOT NULL,
	"one_time_resource_id" uuid,
	"one_time_recovery_operation_id" text,
	"audit_event_id" uuid NOT NULL,
	"error_code" text,
	"requested_at" timestamp with time zone DEFAULT now() NOT NULL,
	"completed_at" timestamp with time zone,
	"expires_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_invocations_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_invocations_actor_kind_check" CHECK ("np_agent_invocations"."actor_kind" in ('principal', 'staff')),
	CONSTRAINT "np_agent_invocations_operation_kind_check" CHECK ("np_agent_invocations"."operation_kind" in ('capability', 'admin')),
	CONSTRAINT "np_agent_invocations_transport_check" CHECK ("np_agent_invocations"."transport" in ('mcp-oauth', 'mcp-service', 'stdio', 'agent-api', 'runtime', 'admin')),
	CONSTRAINT "np_agent_invocations_state_check" CHECK ("np_agent_invocations"."state" in ('started', 'accepted', 'approval_required', 'completed', 'failed')),
	CONSTRAINT "np_agent_invocations_result_kind_check" CHECK ("np_agent_invocations"."result_kind" is null or "np_agent_invocations"."result_kind" in ('action', 'changeset', 'approval', 'admin_resource')),
	CONSTRAINT "np_agent_invocations_contract_version_check" CHECK ("np_agent_invocations"."contract_version" > 0),
	CONSTRAINT "np_agent_invocations_actor_check" CHECK ((
        ("np_agent_invocations"."actor_kind" = 'principal' and "np_agent_invocations"."principal_id" is not null and "np_agent_invocations"."staff_user_id" is null and "np_agent_invocations"."actor_deleted_at" is null)
        or ("np_agent_invocations"."actor_kind" = 'staff' and "np_agent_invocations"."principal_id" is null and
          (("np_agent_invocations"."staff_user_id" is not null and "np_agent_invocations"."actor_deleted_at" is null) or
           ("np_agent_invocations"."staff_user_id" is null and "np_agent_invocations"."actor_deleted_at" is not null)))
      )),
	CONSTRAINT "np_agent_invocations_operation_contract_check" CHECK ((
        ("np_agent_invocations"."operation_kind" = 'capability' and "np_agent_invocations"."capability_definition_body" is not null and
          "np_agent_invocations"."effect_profile_id" is not null and "np_agent_invocations"."effect_contract_version" is not null and "np_agent_invocations"."effect_contract_version" > 0)
        or ("np_agent_invocations"."operation_kind" = 'admin' and "np_agent_invocations"."capability_definition_body" is null and
          "np_agent_invocations"."effect_profile_id" is null and "np_agent_invocations"."effect_contract_version" is null)
      )),
	CONSTRAINT "np_agent_invocations_admin_transport_check" CHECK (("np_agent_invocations"."operation_kind" = 'admin') = ("np_agent_invocations"."transport" = 'admin')),
	CONSTRAINT "np_agent_invocations_mcp_mode_check" CHECK ((
        ("np_agent_invocations"."transport" in ('mcp-oauth', 'mcp-service', 'stdio') and "np_agent_invocations"."mcp_execution_mode" in ('normal', 'task') and
          (("np_agent_invocations"."mcp_execution_mode" = 'task' and "np_agent_invocations"."mcp_requested_task_ttl_ms" is not null and "np_agent_invocations"."mcp_requested_task_ttl_ms" > 0) or
           ("np_agent_invocations"."mcp_execution_mode" = 'normal' and "np_agent_invocations"."mcp_requested_task_ttl_ms" is null)))
        or ("np_agent_invocations"."transport" not in ('mcp-oauth', 'mcp-service') and "np_agent_invocations"."mcp_execution_mode" is null and "np_agent_invocations"."mcp_requested_task_ttl_ms" is null)
      )),
	CONSTRAINT "np_agent_invocations_result_pair_check" CHECK (("np_agent_invocations"."result_kind" is null) = ("np_agent_invocations"."result_id" is null)),
	CONSTRAINT "np_agent_invocations_output_pair_check" CHECK (("np_agent_invocations"."output_redacted" is null) = ("np_agent_invocations"."output_hash" is null)),
	CONSTRAINT "np_agent_invocations_one_time_check" CHECK ((
        ("np_agent_invocations"."one_time_value_issued" = false and "np_agent_invocations"."one_time_resource_id" is null and "np_agent_invocations"."one_time_recovery_operation_id" is null)
        or ("np_agent_invocations"."one_time_value_issued" = true and "np_agent_invocations"."one_time_resource_id" is not null and "np_agent_invocations"."one_time_recovery_operation_id" is not null and "np_agent_invocations"."output_redacted" is null)
      )),
	CONSTRAINT "np_agent_invocations_state_time_check" CHECK ((
        ("np_agent_invocations"."state" in ('started', 'accepted', 'approval_required') and "np_agent_invocations"."completed_at" is null and "np_agent_invocations"."error_code" is null)
        or ("np_agent_invocations"."state" = 'completed' and "np_agent_invocations"."completed_at" is not null and "np_agent_invocations"."error_code" is null)
        or ("np_agent_invocations"."state" = 'failed' and "np_agent_invocations"."completed_at" is not null and "np_agent_invocations"."error_code" is not null)
      ) and "np_agent_invocations"."expires_at" > "np_agent_invocations"."requested_at")
);
--> statement-breakpoint
CREATE TABLE "np_agent_mcp_tasks" (
	"id" text PRIMARY KEY NOT NULL,
	"site_id" text NOT NULL,
	"invocation_id" uuid NOT NULL,
	"run_id" uuid,
	"principal_id" uuid NOT NULL,
	"authorization_context_body" jsonb NOT NULL,
	"authorization_context_fingerprint" text NOT NULL,
	"authority_ref" jsonb NOT NULL,
	"status" text NOT NULL,
	"requested_ttl_ms" bigint,
	"ttl_ms" bigint NOT NULL,
	"poll_interval_ms" integer NOT NULL,
	"terminal_result" jsonb,
	"terminal_result_digest" text,
	"safe_status_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"cancelled_at" timestamp with time zone,
	CONSTRAINT "np_agent_mcp_tasks_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_mcp_tasks_invocation_unique" UNIQUE("invocation_id"),
	CONSTRAINT "np_agent_mcp_tasks_id_check" CHECK ("np_agent_mcp_tasks"."id" ~ '^npt1_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'),
	CONSTRAINT "np_agent_mcp_tasks_status_check" CHECK ("np_agent_mcp_tasks"."status" in ('working', 'completed', 'failed', 'cancelled')),
	CONSTRAINT "np_agent_mcp_tasks_ttl_check" CHECK ("np_agent_mcp_tasks"."ttl_ms" between 60000 and 86400000 and
        ("np_agent_mcp_tasks"."requested_ttl_ms" is null or "np_agent_mcp_tasks"."requested_ttl_ms" between 60000 and 86400000) and
        "np_agent_mcp_tasks"."ttl_ms" <= coalesce("np_agent_mcp_tasks"."requested_ttl_ms", 3600000) and
        "np_agent_mcp_tasks"."poll_interval_ms" between 1000 and 10000),
	CONSTRAINT "np_agent_mcp_tasks_result_check" CHECK ((
        "np_agent_mcp_tasks"."status" = 'working' and "np_agent_mcp_tasks"."terminal_result" is null and
          "np_agent_mcp_tasks"."terminal_result_digest" is null and "np_agent_mcp_tasks"."safe_status_code" is null and
          "np_agent_mcp_tasks"."cancelled_at" is null
      ) or (
        "np_agent_mcp_tasks"."status" in ('completed', 'failed') and "np_agent_mcp_tasks"."terminal_result" is not null and
          "np_agent_mcp_tasks"."terminal_result_digest" is not null and "np_agent_mcp_tasks"."cancelled_at" is null
      ) or (
        "np_agent_mcp_tasks"."status" = 'cancelled' and "np_agent_mcp_tasks"."terminal_result" is not null and
          "np_agent_mcp_tasks"."terminal_result_digest" is not null and "np_agent_mcp_tasks"."safe_status_code" is not null and
          "np_agent_mcp_tasks"."cancelled_at" is not null
      )),
	CONSTRAINT "np_agent_mcp_tasks_time_check" CHECK ("np_agent_mcp_tasks"."last_updated_at" >= "np_agent_mcp_tasks"."created_at" and
        "np_agent_mcp_tasks"."last_updated_at" <= "np_agent_mcp_tasks"."expires_at" and
        "np_agent_mcp_tasks"."expires_at" = "np_agent_mcp_tasks"."created_at" + ("np_agent_mcp_tasks"."ttl_ms"::text || ' milliseconds')::interval)
);
--> statement-breakpoint
CREATE TABLE "np_agent_notifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"channel" text NOT NULL,
	"connection_id" uuid,
	"connection_config_snapshot_id" uuid,
	"incident_id" uuid,
	"run_id" uuid,
	"action_id" uuid,
	"adapter_id" text,
	"adapter_fingerprint" text,
	"connection_config_hash" text,
	"account_subject_key_id" text,
	"account_subject_digest" text,
	"destination_key_id" text,
	"destination_fingerprint" text,
	"adapter_idempotency" text,
	"adapter_contract_version" integer,
	"connection_config_version" integer,
	"destination_descriptor" jsonb,
	"transition_version" integer NOT NULL,
	"deduplication_key" text NOT NULL,
	"state" text NOT NULL,
	"payload_redacted" jsonb NOT NULL,
	"attempts" integer DEFAULT 0 NOT NULL,
	"provider_message_id" text,
	"delivery_digest_body" jsonb,
	"delivery_result_digest" text,
	"last_error_code" text,
	"next_attempt_at" timestamp with time zone,
	"sent_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_notifications_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_notifications_dedup_unique" UNIQUE("site_id","deduplication_key"),
	CONSTRAINT "np_agent_notifications_state_check" CHECK (("np_agent_notifications"."channel" in ('admin','email','slack','webhook','siem') and "np_agent_notifications"."state" in ('queued','sending','sent','failed','suppressed') and ("np_agent_notifications"."state"='sent')=("np_agent_notifications"."sent_at" is not null) and ("np_agent_notifications"."delivery_digest_body" is null)=("np_agent_notifications"."delivery_result_digest" is null) and ("np_agent_notifications"."state"<>'sent' or "np_agent_notifications"."delivery_result_digest" is not null)) is true),
	CONSTRAINT "np_agent_notifications_channel_check" CHECK ((("np_agent_notifications"."channel"='admin' and "np_agent_notifications"."connection_id" is null and "np_agent_notifications"."connection_config_snapshot_id" is null and "np_agent_notifications"."adapter_id" is null and "np_agent_notifications"."adapter_fingerprint" is null and "np_agent_notifications"."connection_config_hash" is null and "np_agent_notifications"."account_subject_key_id" is null and "np_agent_notifications"."account_subject_digest" is null and "np_agent_notifications"."destination_key_id" is null and "np_agent_notifications"."destination_fingerprint" is null and "np_agent_notifications"."adapter_idempotency" is null and "np_agent_notifications"."adapter_contract_version" is null and "np_agent_notifications"."connection_config_version" is null and "np_agent_notifications"."destination_descriptor" is null and "np_agent_notifications"."state"='sent' and "np_agent_notifications"."attempts"=0 and "np_agent_notifications"."provider_message_id" is null and "np_agent_notifications"."last_error_code" is null and "np_agent_notifications"."next_attempt_at" is null and "np_agent_notifications"."sent_at"="np_agent_notifications"."created_at") or ("np_agent_notifications"."channel"<>'admin' and "np_agent_notifications"."connection_id" is not null and "np_agent_notifications"."connection_config_snapshot_id" is not null and "np_agent_notifications"."adapter_id" is not null and "np_agent_notifications"."adapter_fingerprint" is not null and "np_agent_notifications"."connection_config_hash" is not null and "np_agent_notifications"."account_subject_key_id" is not null and "np_agent_notifications"."account_subject_digest" is not null and "np_agent_notifications"."destination_key_id" is not null and "np_agent_notifications"."destination_fingerprint" is not null and "np_agent_notifications"."adapter_idempotency" is not null and "np_agent_notifications"."adapter_contract_version" is not null and "np_agent_notifications"."connection_config_version" is not null and "np_agent_notifications"."destination_descriptor" is not null and "np_agent_notifications"."adapter_idempotency" in ('enforced','none') and "np_agent_notifications"."adapter_contract_version">0 and "np_agent_notifications"."connection_config_version">0)) is true),
	CONSTRAINT "np_agent_notifications_bounds_check" CHECK (("np_agent_notifications"."transition_version">0 and "np_agent_notifications"."attempts" between 0 and 5 and length("np_agent_notifications"."deduplication_key") between 1 and 256 and jsonb_typeof("np_agent_notifications"."payload_redacted")='object' and octet_length("np_agent_notifications"."payload_redacted"::text)<=16384 and ("np_agent_notifications"."provider_message_id" is null or length("np_agent_notifications"."provider_message_id") between 1 and 256) and ("np_agent_notifications"."delivery_result_digest" is null or "np_agent_notifications"."delivery_result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') and ("np_agent_notifications"."delivery_digest_body" is null or octet_length("np_agent_notifications"."delivery_digest_body"::text)<=65536)) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_oauth_clients" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"client_id" text NOT NULL,
	"name" text NOT NULL,
	"redirect_uris" text[] NOT NULL,
	"metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"registration_source" text NOT NULL,
	"status" text NOT NULL,
	"row_version" integer DEFAULT 1 NOT NULL,
	"created_by_user_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "np_agent_oauth_clients_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_oauth_clients_site_client_id_unique" UNIQUE("site_id","client_id"),
	CONSTRAINT "np_agent_oauth_clients_status_check" CHECK ("np_agent_oauth_clients"."status" in ('active', 'revoked')),
	CONSTRAINT "np_agent_oauth_clients_version_check" CHECK ("np_agent_oauth_clients"."row_version" > 0),
	CONSTRAINT "np_agent_oauth_clients_source_check" CHECK ("np_agent_oauth_clients"."registration_source" in ('admin', 'dynamic')),
	CONSTRAINT "np_agent_oauth_clients_redirects_check" CHECK (cardinality("np_agent_oauth_clients"."redirect_uris") between 1 and 32 and array_position("np_agent_oauth_clients"."redirect_uris", null) is null),
	CONSTRAINT "np_agent_oauth_clients_revocation_check" CHECK (("np_agent_oauth_clients"."status" = 'revoked') = ("np_agent_oauth_clients"."revoked_at" is not null))
);
--> statement-breakpoint
CREATE TABLE "np_agent_oauth_codes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"request_id" uuid NOT NULL,
	"grant_id" uuid NOT NULL,
	"staff_session_id" uuid,
	"client_id" uuid NOT NULL,
	"redirect_uri" text NOT NULL,
	"scopes" text[] NOT NULL,
	"exposure_mode" text NOT NULL,
	"resource" text NOT NULL,
	"pkce_method" text NOT NULL,
	"pkce_challenge" text NOT NULL,
	"code_hash" text NOT NULL,
	"hash_key_id" text NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"consumed_at" timestamp with time zone,
	"revoked_at" timestamp with time zone,
	"expired_at" timestamp with time zone,
	CONSTRAINT "np_agent_oauth_codes_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_oauth_codes_request_unique" UNIQUE("request_id"),
	CONSTRAINT "np_agent_oauth_codes_hash_unique" UNIQUE("code_hash"),
	CONSTRAINT "np_agent_oauth_codes_status_check" CHECK ("np_agent_oauth_codes"."status" in ('active', 'consumed', 'revoked', 'expired')),
	CONSTRAINT "np_agent_oauth_codes_exposure_check" CHECK ("np_agent_oauth_codes"."exposure_mode" in ('read', 'propose', 'approved-execute')),
	CONSTRAINT "np_agent_oauth_codes_pkce_check" CHECK ("np_agent_oauth_codes"."pkce_method" = 'S256'),
	CONSTRAINT "np_agent_oauth_codes_scopes_check" CHECK (cardinality("np_agent_oauth_codes"."scopes") between 1 and 64 and "np_agent_oauth_codes"."scopes" @> array['site:read']::text[] and array_position("np_agent_oauth_codes"."scopes", null) is null),
	CONSTRAINT "np_agent_oauth_codes_expiry_check" CHECK ("np_agent_oauth_codes"."expires_at" > "np_agent_oauth_codes"."created_at"),
	CONSTRAINT "np_agent_oauth_codes_state_time_check" CHECK ((
        ("np_agent_oauth_codes"."status" = 'active' and "np_agent_oauth_codes"."consumed_at" is null and "np_agent_oauth_codes"."revoked_at" is null and "np_agent_oauth_codes"."expired_at" is null)
        or ("np_agent_oauth_codes"."status" = 'consumed' and "np_agent_oauth_codes"."consumed_at" is not null and "np_agent_oauth_codes"."revoked_at" is null and "np_agent_oauth_codes"."expired_at" is null)
        or ("np_agent_oauth_codes"."status" = 'revoked' and "np_agent_oauth_codes"."revoked_at" is not null and "np_agent_oauth_codes"."expired_at" is null)
        or ("np_agent_oauth_codes"."status" = 'expired' and "np_agent_oauth_codes"."expired_at" is not null and "np_agent_oauth_codes"."revoked_at" is null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_oauth_grants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"client_id" uuid NOT NULL,
	"staff_user_id" uuid,
	"principal_id" uuid NOT NULL,
	"scopes" text[] NOT NULL,
	"scope_hash" text NOT NULL,
	"exposure_mode" text NOT NULL,
	"resource" text NOT NULL,
	"audience" text NOT NULL,
	"token_version" integer DEFAULT 1 NOT NULL,
	"consent_generation" integer DEFAULT 1 NOT NULL,
	"authority_version" integer DEFAULT 1 NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	"expired_at" timestamp with time zone,
	CONSTRAINT "np_agent_oauth_grants_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_oauth_grants_generation_unique" UNIQUE("site_id","client_id","staff_user_id","resource","scope_hash","exposure_mode","consent_generation"),
	CONSTRAINT "np_agent_oauth_grants_status_check" CHECK ("np_agent_oauth_grants"."status" in ('active', 'revoked', 'expired')),
	CONSTRAINT "np_agent_oauth_grants_exposure_check" CHECK ("np_agent_oauth_grants"."exposure_mode" in ('read', 'propose', 'approved-execute')),
	CONSTRAINT "np_agent_oauth_grants_versions_check" CHECK ("np_agent_oauth_grants"."token_version" > 0 and "np_agent_oauth_grants"."consent_generation" > 0 and "np_agent_oauth_grants"."authority_version" > 0),
	CONSTRAINT "np_agent_oauth_grants_scopes_check" CHECK (cardinality("np_agent_oauth_grants"."scopes") between 1 and 64 and "np_agent_oauth_grants"."scopes" @> array['site:read']::text[] and array_position("np_agent_oauth_grants"."scopes", null) is null),
	CONSTRAINT "np_agent_oauth_grants_expiry_check" CHECK ("np_agent_oauth_grants"."expires_at" > "np_agent_oauth_grants"."created_at"),
	CONSTRAINT "np_agent_oauth_grants_state_time_check" CHECK ((
        ("np_agent_oauth_grants"."status" = 'active' and "np_agent_oauth_grants"."staff_user_id" is not null and "np_agent_oauth_grants"."revoked_at" is null and "np_agent_oauth_grants"."expired_at" is null)
        or ("np_agent_oauth_grants"."status" = 'revoked' and "np_agent_oauth_grants"."revoked_at" is not null and "np_agent_oauth_grants"."expired_at" is null)
        or ("np_agent_oauth_grants"."status" = 'expired' and "np_agent_oauth_grants"."expired_at" is not null and "np_agent_oauth_grants"."revoked_at" is null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_oauth_refresh_tokens" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"grant_id" uuid NOT NULL,
	"family_id" uuid NOT NULL,
	"token_id" uuid NOT NULL,
	"parent_token_id" uuid,
	"replacement_token_id" uuid,
	"token_hash" text NOT NULL,
	"hash_key_id" text NOT NULL,
	"grant_authority_version" integer NOT NULL,
	"family_generation" integer NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"consumed_at" timestamp with time zone,
	"revoked_at" timestamp with time zone,
	"expired_at" timestamp with time zone,
	CONSTRAINT "np_agent_oauth_refresh_tokens_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_token_id_unique" UNIQUE("token_id"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_site_token_id_unique" UNIQUE("site_id","token_id"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_hash_unique" UNIQUE("token_hash"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_parent_unique" UNIQUE("parent_token_id"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_replacement_unique" UNIQUE("replacement_token_id"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_family_generation_unique" UNIQUE("site_id","family_id","family_generation"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_status_check" CHECK ("np_agent_oauth_refresh_tokens"."status" in ('active', 'consumed', 'revoked', 'expired')),
	CONSTRAINT "np_agent_oauth_refresh_tokens_versions_check" CHECK ("np_agent_oauth_refresh_tokens"."grant_authority_version" > 0 and "np_agent_oauth_refresh_tokens"."family_generation" > 0),
	CONSTRAINT "np_agent_oauth_refresh_tokens_expiry_check" CHECK ("np_agent_oauth_refresh_tokens"."expires_at" > "np_agent_oauth_refresh_tokens"."created_at"),
	CONSTRAINT "np_agent_oauth_refresh_tokens_state_time_check" CHECK ((
        ("np_agent_oauth_refresh_tokens"."status" = 'active' and "np_agent_oauth_refresh_tokens"."consumed_at" is null and "np_agent_oauth_refresh_tokens"."revoked_at" is null and "np_agent_oauth_refresh_tokens"."expired_at" is null)
        or ("np_agent_oauth_refresh_tokens"."status" = 'consumed' and "np_agent_oauth_refresh_tokens"."consumed_at" is not null and "np_agent_oauth_refresh_tokens"."revoked_at" is null and "np_agent_oauth_refresh_tokens"."expired_at" is null)
        or ("np_agent_oauth_refresh_tokens"."status" = 'revoked' and "np_agent_oauth_refresh_tokens"."revoked_at" is not null and "np_agent_oauth_refresh_tokens"."expired_at" is null)
        or ("np_agent_oauth_refresh_tokens"."status" = 'expired' and "np_agent_oauth_refresh_tokens"."expired_at" is not null and "np_agent_oauth_refresh_tokens"."revoked_at" is null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_oauth_requests" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"client_id" uuid NOT NULL,
	"staff_user_id" uuid,
	"staff_session_id" uuid,
	"redirect_uri" text NOT NULL,
	"client_state" text NOT NULL,
	"requested_scopes" text[] NOT NULL,
	"resource" text NOT NULL,
	"exposure_mode" text NOT NULL,
	"pkce_method" text NOT NULL,
	"pkce_challenge" text NOT NULL,
	"consent_challenge_hash" text NOT NULL,
	"consent_hash_key_id" text NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"authorized_at" timestamp with time zone,
	"denied_at" timestamp with time zone,
	"consumed_at" timestamp with time zone,
	"expired_at" timestamp with time zone,
	CONSTRAINT "np_agent_oauth_requests_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_oauth_requests_consent_hash_unique" UNIQUE("consent_challenge_hash"),
	CONSTRAINT "np_agent_oauth_requests_status_check" CHECK ("np_agent_oauth_requests"."status" in ('pending', 'authorized', 'denied', 'consumed', 'expired')),
	CONSTRAINT "np_agent_oauth_requests_exposure_check" CHECK ("np_agent_oauth_requests"."exposure_mode" in ('read', 'propose', 'approved-execute')),
	CONSTRAINT "np_agent_oauth_requests_pkce_check" CHECK ("np_agent_oauth_requests"."pkce_method" = 'S256'),
	CONSTRAINT "np_agent_oauth_requests_scopes_check" CHECK (cardinality("np_agent_oauth_requests"."requested_scopes") between 1 and 64 and "np_agent_oauth_requests"."requested_scopes" @> array['site:read']::text[] and array_position("np_agent_oauth_requests"."requested_scopes", null) is null),
	CONSTRAINT "np_agent_oauth_requests_expiry_check" CHECK ("np_agent_oauth_requests"."expires_at" > "np_agent_oauth_requests"."created_at" and "np_agent_oauth_requests"."expires_at" <= "np_agent_oauth_requests"."created_at" + interval '10 minutes'),
	CONSTRAINT "np_agent_oauth_requests_state_time_check" CHECK ((
        ("np_agent_oauth_requests"."status" = 'pending' and "np_agent_oauth_requests"."authorized_at" is null and "np_agent_oauth_requests"."denied_at" is null and "np_agent_oauth_requests"."consumed_at" is null and "np_agent_oauth_requests"."expired_at" is null)
        or ("np_agent_oauth_requests"."status" = 'authorized' and "np_agent_oauth_requests"."authorized_at" is not null and "np_agent_oauth_requests"."denied_at" is null and "np_agent_oauth_requests"."consumed_at" is null and "np_agent_oauth_requests"."expired_at" is null)
        or ("np_agent_oauth_requests"."status" = 'denied' and "np_agent_oauth_requests"."denied_at" is not null and "np_agent_oauth_requests"."authorized_at" is null and "np_agent_oauth_requests"."consumed_at" is null and "np_agent_oauth_requests"."expired_at" is null)
        or ("np_agent_oauth_requests"."status" = 'consumed' and "np_agent_oauth_requests"."authorized_at" is not null and "np_agent_oauth_requests"."consumed_at" is not null and "np_agent_oauth_requests"."denied_at" is null and "np_agent_oauth_requests"."expired_at" is null)
        or ("np_agent_oauth_requests"."status" = 'expired' and "np_agent_oauth_requests"."expired_at" is not null and "np_agent_oauth_requests"."denied_at" is null and "np_agent_oauth_requests"."consumed_at" is null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_operator_executions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"plan_id" uuid NOT NULL,
	"invocation_id" uuid NOT NULL,
	"action_id" uuid NOT NULL,
	"source_run_id" uuid,
	"result_run_id" uuid,
	"state" text NOT NULL,
	"reserved_at" timestamp with time zone NOT NULL,
	"dispatched_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"result_canonical" jsonb,
	"evidence_canonical" jsonb,
	"result_digest" text,
	CONSTRAINT "np_agent_operator_executions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_operator_executions_plan_unique" UNIQUE("plan_id"),
	CONSTRAINT "np_agent_operator_executions_invocation_unique" UNIQUE("invocation_id"),
	CONSTRAINT "np_agent_operator_executions_state_check" CHECK ("np_agent_operator_executions"."state" in ('reserved','dispatching','succeeded','failed','conflicted','unknown')),
	CONSTRAINT "np_agent_operator_executions_body_check" CHECK ((("np_agent_operator_executions"."result_canonical" is null and "np_agent_operator_executions"."result_digest" is null) or (jsonb_typeof("np_agent_operator_executions"."result_canonical")='object' and octet_length("np_agent_operator_executions"."result_canonical"::text)<=65536 and "np_agent_operator_executions"."result_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')) is true and ("np_agent_operator_executions"."evidence_canonical" is null or (jsonb_typeof("np_agent_operator_executions"."evidence_canonical")='object' and octet_length("np_agent_operator_executions"."evidence_canonical"::text)<=1048576))),
	CONSTRAINT "np_agent_operator_executions_time_check" CHECK (("np_agent_operator_executions"."dispatched_at" is null or "np_agent_operator_executions"."dispatched_at">="np_agent_operator_executions"."reserved_at") and ("np_agent_operator_executions"."finished_at" is null or "np_agent_operator_executions"."finished_at">="np_agent_operator_executions"."reserved_at") and ("np_agent_operator_executions"."state" not in ('succeeded','failed','conflicted') or ("np_agent_operator_executions"."finished_at" is not null and "np_agent_operator_executions"."result_canonical" is not null))),
	CONSTRAINT "np_agent_operator_executions_run_check" CHECK ("np_agent_operator_executions"."result_run_id" is null or ("np_agent_operator_executions"."source_run_id" is not null and "np_agent_operator_executions"."result_run_id"<>"np_agent_operator_executions"."source_run_id"))
);
--> statement-breakpoint
CREATE TABLE "np_agent_operator_plans" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"invocation_id" uuid NOT NULL,
	"approval_action_id" uuid,
	"audit_event_id" uuid NOT NULL,
	"operation" jsonb NOT NULL,
	"contract_id" text NOT NULL,
	"artifact_canonical" jsonb NOT NULL,
	"artifact_digest" text NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_operator_plans_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_operator_plans_invocation_unique" UNIQUE("invocation_id"),
	CONSTRAINT "np_agent_operator_plans_approval_action_unique" UNIQUE("approval_action_id"),
	CONSTRAINT "np_agent_operator_plans_bounds_check" CHECK ((length("np_agent_operator_plans"."contract_id") between 1 and 128 and jsonb_typeof("np_agent_operator_plans"."operation")='object' and octet_length("np_agent_operator_plans"."operation"::text)<=4096 and jsonb_typeof("np_agent_operator_plans"."artifact_canonical")='object' and octet_length("np_agent_operator_plans"."artifact_canonical"::text)<=1048576 and "np_agent_operator_plans"."artifact_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') is true),
	CONSTRAINT "np_agent_operator_plans_time_check" CHECK (("np_agent_operator_plans"."expires_at">"np_agent_operator_plans"."created_at" and "np_agent_operator_plans"."expires_at"<="np_agent_operator_plans"."created_at"+interval '24 hours') is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_policies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"agent_id" uuid,
	"version" integer NOT NULL,
	"row_version" integer DEFAULT 1 NOT NULL,
	"status" text NOT NULL,
	"name" text NOT NULL,
	"instructions" text NOT NULL,
	"rules" jsonb NOT NULL,
	"content_hash" text NOT NULL,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"activated_at" timestamp with time zone,
	CONSTRAINT "np_agent_policies_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_policies_status_check" CHECK ("np_agent_policies"."status" in ('draft','active','retired')),
	CONSTRAINT "np_agent_policies_version_check" CHECK ("np_agent_policies"."version">0 and "np_agent_policies"."row_version">0),
	CONSTRAINT "np_agent_policies_body_check" CHECK ((char_length("np_agent_policies"."name") between 1 and 120 and "np_agent_policies"."name"=btrim("np_agent_policies"."name") and octet_length("np_agent_policies"."instructions")<=262144 and "np_agent_policies"."rules"->>'schemaVersion'='np.agent-policy-rules.v1' and octet_length("np_agent_policies"."rules"::text)<=262144 and "np_agent_policies"."content_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') is true),
	CONSTRAINT "np_agent_policies_time_check" CHECK ((("np_agent_policies"."status"='draft' and "np_agent_policies"."activated_at" is null) or ("np_agent_policies"."status" in ('active','retired') and "np_agent_policies"."activated_at">="np_agent_policies"."created_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_preview_artifact_uploads" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"preview_id" uuid NOT NULL,
	"artifact_id" uuid NOT NULL,
	"upload_set_digest" text NOT NULL,
	"upload_request_digest" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"state" text DEFAULT 'queued' NOT NULL,
	"attempt" integer DEFAULT 0 NOT NULL,
	"row_version" integer DEFAULT 1 NOT NULL,
	"lease_until" timestamp with time zone,
	"call_deadline_at" timestamp with time zone,
	"adapter_operation_status" text DEFAULT 'not_dispatched' NOT NULL,
	"adapter_operation_ref" text,
	"adapter_operation_receipt_digest" text,
	"adapter_operation_resolved_at" timestamp with time zone,
	"observed_object_state" text DEFAULT 'unknown' NOT NULL,
	"ever_observed_present" boolean DEFAULT false NOT NULL,
	"verified_at" timestamp with time zone,
	"last_error_code" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"prune_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_preview_artifact_uploads_artifact_unique" UNIQUE("artifact_id"),
	CONSTRAINT "np_agent_preview_artifact_uploads_idempotency_unique" UNIQUE("idempotency_key"),
	CONSTRAINT "np_agent_preview_artifact_uploads_bounds_check" CHECK ("np_agent_preview_artifact_uploads"."attempt" between 0 and 255 and "np_agent_preview_artifact_uploads"."row_version">0 and "np_agent_preview_artifact_uploads"."prune_at">="np_agent_preview_artifact_uploads"."created_at"+interval '365 days' and ("np_agent_preview_artifact_uploads"."adapter_operation_ref" is null or char_length("np_agent_preview_artifact_uploads"."adapter_operation_ref") between 1 and 512) and "np_agent_preview_artifact_uploads"."upload_set_digest" ~ '^aus1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_artifact_uploads"."upload_request_digest" ~ '^aur1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_artifact_uploads"."idempotency_key" ~ '^npau1_[A-Za-z0-9_-]{43}$'),
	CONSTRAINT "np_agent_preview_artifact_uploads_state_check" CHECK ("np_agent_preview_artifact_uploads"."state" in ('queued','running','waiting_inspection','succeeded','failed','cancelled') and "np_agent_preview_artifact_uploads"."adapter_operation_status" in ('not_dispatched','pending','unknown','not_started','committed','failed_no_effect') and "np_agent_preview_artifact_uploads"."observed_object_state" in ('unknown','present','absent') and ("np_agent_preview_artifact_uploads"."observed_object_state"<>'present' or "np_agent_preview_artifact_uploads"."ever_observed_present")),
	CONSTRAINT "np_agent_preview_artifact_uploads_receipt_check" CHECK ((("np_agent_preview_artifact_uploads"."adapter_operation_status" in ('not_dispatched','pending','unknown') and "np_agent_preview_artifact_uploads"."adapter_operation_receipt_digest" is null and "np_agent_preview_artifact_uploads"."adapter_operation_resolved_at" is null) or ("np_agent_preview_artifact_uploads"."adapter_operation_status" in ('not_started','committed','failed_no_effect') and "np_agent_preview_artifact_uploads"."adapter_operation_receipt_digest" ~ '^auo1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_artifact_uploads"."adapter_operation_resolved_at" is not null)) is true),
	CONSTRAINT "np_agent_preview_artifact_uploads_lifecycle_check" CHECK ((
    ("np_agent_preview_artifact_uploads"."state"='queued' and "np_agent_preview_artifact_uploads"."attempt"=0 and "np_agent_preview_artifact_uploads"."adapter_operation_status"='not_dispatched' and not "np_agent_preview_artifact_uploads"."ever_observed_present" and "np_agent_preview_artifact_uploads"."observed_object_state"='unknown' and "np_agent_preview_artifact_uploads"."started_at" is null and "np_agent_preview_artifact_uploads"."lease_until" is null and "np_agent_preview_artifact_uploads"."call_deadline_at" is null and "np_agent_preview_artifact_uploads"."finished_at" is null and "np_agent_preview_artifact_uploads"."verified_at" is null) or
    ("np_agent_preview_artifact_uploads"."state"='running' and "np_agent_preview_artifact_uploads"."attempt">0 and "np_agent_preview_artifact_uploads"."started_at" is not null and "np_agent_preview_artifact_uploads"."lease_until" is not null and "np_agent_preview_artifact_uploads"."call_deadline_at" is not null and "np_agent_preview_artifact_uploads"."finished_at" is null and "np_agent_preview_artifact_uploads"."verified_at" is null) or
    ("np_agent_preview_artifact_uploads"."state"='waiting_inspection' and "np_agent_preview_artifact_uploads"."attempt">0 and "np_agent_preview_artifact_uploads"."started_at" is not null and "np_agent_preview_artifact_uploads"."lease_until" is null and "np_agent_preview_artifact_uploads"."call_deadline_at" is not null and "np_agent_preview_artifact_uploads"."finished_at" is null and "np_agent_preview_artifact_uploads"."verified_at" is null) or
    ("np_agent_preview_artifact_uploads"."state"='succeeded' and "np_agent_preview_artifact_uploads"."attempt">0 and "np_agent_preview_artifact_uploads"."started_at" is not null and "np_agent_preview_artifact_uploads"."lease_until" is null and "np_agent_preview_artifact_uploads"."call_deadline_at" is not null and "np_agent_preview_artifact_uploads"."finished_at" is not null and "np_agent_preview_artifact_uploads"."adapter_operation_status"='committed' and "np_agent_preview_artifact_uploads"."observed_object_state"='present' and "np_agent_preview_artifact_uploads"."ever_observed_present" and "np_agent_preview_artifact_uploads"."verified_at" is not null) or
    ("np_agent_preview_artifact_uploads"."state" in ('failed','cancelled') and "np_agent_preview_artifact_uploads"."lease_until" is null and "np_agent_preview_artifact_uploads"."finished_at" is not null and "np_agent_preview_artifact_uploads"."verified_at" is null and (("np_agent_preview_artifact_uploads"."adapter_operation_status" in ('not_started','failed_no_effect') and "np_agent_preview_artifact_uploads"."observed_object_state"='absent') or ("np_agent_preview_artifact_uploads"."adapter_operation_status"='committed' and "np_agent_preview_artifact_uploads"."observed_object_state" in ('present','absent')) or ("np_agent_preview_artifact_uploads"."state"='cancelled' and "np_agent_preview_artifact_uploads"."attempt"=0 and "np_agent_preview_artifact_uploads"."adapter_operation_status"='not_dispatched' and "np_agent_preview_artifact_uploads"."started_at" is null and "np_agent_preview_artifact_uploads"."call_deadline_at" is null and not "np_agent_preview_artifact_uploads"."ever_observed_present" and "np_agent_preview_artifact_uploads"."observed_object_state"='absent')))
  ) is true),
	CONSTRAINT "np_agent_preview_artifact_uploads_time_check" CHECK (("np_agent_preview_artifact_uploads"."started_at" is null or "np_agent_preview_artifact_uploads"."started_at">="np_agent_preview_artifact_uploads"."created_at") and ("np_agent_preview_artifact_uploads"."call_deadline_at" is null or ("np_agent_preview_artifact_uploads"."call_deadline_at">"np_agent_preview_artifact_uploads"."started_at" and "np_agent_preview_artifact_uploads"."call_deadline_at"<="np_agent_preview_artifact_uploads"."started_at"+interval '60 seconds')) and ("np_agent_preview_artifact_uploads"."finished_at" is null or "np_agent_preview_artifact_uploads"."finished_at">="np_agent_preview_artifact_uploads"."created_at"))
);
--> statement-breakpoint
CREATE TABLE "np_agent_preview_artifacts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"preview_id" uuid NOT NULL,
	"ordinal" integer NOT NULL,
	"kind" text NOT NULL,
	"preview_contract_fingerprint" text NOT NULL,
	"route" text,
	"locale" text,
	"viewport" jsonb,
	"report_part" integer,
	"report_total_parts" integer,
	"storage_key" text NOT NULL,
	"content_digest" text NOT NULL,
	"mime" text NOT NULL,
	"bytes" integer NOT NULL,
	"storage_adapter_id" text NOT NULL,
	"storage_adapter_contract_version" integer NOT NULL,
	"storage_adapter_fingerprint" text NOT NULL,
	"object_state" text DEFAULT 'absent' NOT NULL,
	"object_expires_at" timestamp with time zone,
	"metadata_prune_at" timestamp with time zone NOT NULL,
	"delete_attempt" integer DEFAULT 0 NOT NULL,
	"delete_receipt_digest" text,
	"delete_status" text,
	"delete_error_code" text,
	"deleted_at" timestamp with time zone,
	"row_version" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_preview_artifacts_site_preview_id_unique" UNIQUE("site_id","preview_id","id"),
	CONSTRAINT "np_agent_preview_artifacts_site_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_preview_artifacts_ordinal_unique" UNIQUE("preview_id","ordinal"),
	CONSTRAINT "np_agent_preview_artifacts_storage_key_unique" UNIQUE("storage_adapter_id","storage_key"),
	CONSTRAINT "np_agent_preview_artifacts_metadata_check" CHECK (("np_agent_preview_artifacts"."ordinal" between 1 and 24 and "np_agent_preview_artifacts"."bytes" between 0 and 2097152 and "np_agent_preview_artifacts"."storage_adapter_contract_version">0 and "np_agent_preview_artifacts"."row_version">0 and "np_agent_preview_artifacts"."delete_attempt" between 0 and 255 and char_length("np_agent_preview_artifacts"."storage_key") between 1 and 2048 and char_length("np_agent_preview_artifacts"."storage_adapter_id") between 1 and 128 and "np_agent_preview_artifacts"."content_digest" ~ '^ac1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_artifacts"."storage_adapter_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$') is true),
	CONSTRAINT "np_agent_preview_artifacts_kind_check" CHECK ((("np_agent_preview_artifacts"."kind"='screenshot' and "np_agent_preview_artifacts"."mime" in ('image/png','image/webp') and "np_agent_preview_artifacts"."route" is not null and "np_agent_preview_artifacts"."viewport"->>'name' in ('desktop','mobile') and "np_agent_preview_artifacts"."report_part" is null and "np_agent_preview_artifacts"."report_total_parts" is null) or ("np_agent_preview_artifacts"."kind"='report' and "np_agent_preview_artifacts"."mime"='application/json' and "np_agent_preview_artifacts"."bytes"<=524288 and "np_agent_preview_artifacts"."route" is null and "np_agent_preview_artifacts"."locale" is null and "np_agent_preview_artifacts"."viewport" is null and "np_agent_preview_artifacts"."report_part" between 1 and 4 and "np_agent_preview_artifacts"."report_total_parts" between "np_agent_preview_artifacts"."report_part" and 4)) is true),
	CONSTRAINT "np_agent_preview_artifacts_state_check" CHECK ("np_agent_preview_artifacts"."object_state" in ('ready','delete_pending','absent') and ("np_agent_preview_artifacts"."object_state"<>'ready' or "np_agent_preview_artifacts"."object_expires_at" is not null) and ("np_agent_preview_artifacts"."object_state"='absent' or "np_agent_preview_artifacts"."deleted_at" is null)),
	CONSTRAINT "np_agent_preview_artifacts_delete_check" CHECK ((("np_agent_preview_artifacts"."delete_receipt_digest" is null and "np_agent_preview_artifacts"."delete_status" is null and "np_agent_preview_artifacts"."deleted_at" is null) or ("np_agent_preview_artifacts"."delete_receipt_digest" ~ '^adr1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_artifacts"."delete_status" in ('deleted','already_absent') and "np_agent_preview_artifacts"."deleted_at" is not null and "np_agent_preview_artifacts"."object_state"='absent' and "np_agent_preview_artifacts"."delete_attempt">0)) is true),
	CONSTRAINT "np_agent_preview_artifacts_retention_check" CHECK ("np_agent_preview_artifacts"."metadata_prune_at">="np_agent_preview_artifacts"."created_at"+interval '365 days' and ("np_agent_preview_artifacts"."object_expires_at" is null or "np_agent_preview_artifacts"."object_expires_at">"np_agent_preview_artifacts"."created_at"))
);
--> statement-breakpoint
CREATE TABLE "np_agent_preview_render_sessions" (
	"id" uuid PRIMARY KEY NOT NULL,
	"site_id" text NOT NULL,
	"preview_id" uuid NOT NULL,
	"generation" integer NOT NULL,
	"plan_hash" text NOT NULL,
	"render_attempt_id" uuid NOT NULL,
	"allowed_routes_digest" text NOT NULL,
	"preview_contract_fingerprint" text NOT NULL,
	"state" text DEFAULT 'active' NOT NULL,
	"cookie_verifier" text NOT NULL,
	"cookie_verifier_key_id" text NOT NULL,
	"issued_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"closed_at" timestamp with time zone,
	"close_reason" text,
	"capture_plan" jsonb NOT NULL,
	"consumed_ordinals" jsonb NOT NULL,
	CONSTRAINT "np_agent_preview_render_sessions_attempt_unique" UNIQUE("preview_id","generation","render_attempt_id"),
	CONSTRAINT "np_agent_preview_render_sessions_claims_check" CHECK (("np_agent_preview_render_sessions"."generation">0 and "np_agent_preview_render_sessions"."expires_at">"np_agent_preview_render_sessions"."issued_at" and "np_agent_preview_render_sessions"."expires_at"<="np_agent_preview_render_sessions"."issued_at"+interval '120 seconds' and "np_agent_preview_render_sessions"."cookie_verifier" ~ '^rcv1:hmac-sha256:[A-Za-z0-9][A-Za-z0-9._-]{0,63}:[A-Za-z0-9_-]{43}$' and split_part("np_agent_preview_render_sessions"."cookie_verifier",':',3)="np_agent_preview_render_sessions"."cookie_verifier_key_id" and "np_agent_preview_render_sessions"."plan_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_render_sessions"."allowed_routes_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and jsonb_typeof("np_agent_preview_render_sessions"."capture_plan")='array' and jsonb_array_length("np_agent_preview_render_sessions"."capture_plan") between 1 and 20 and jsonb_typeof("np_agent_preview_render_sessions"."consumed_ordinals")='array' and jsonb_array_length("np_agent_preview_render_sessions"."capture_plan")=jsonb_array_length("np_agent_preview_render_sessions"."consumed_ordinals") and octet_length("np_agent_preview_render_sessions"."capture_plan"::text)<=65536) is true),
	CONSTRAINT "np_agent_preview_render_sessions_state_check" CHECK ((("np_agent_preview_render_sessions"."state"='active' and "np_agent_preview_render_sessions"."closed_at" is null and "np_agent_preview_render_sessions"."close_reason" is null) or ("np_agent_preview_render_sessions"."state"='completed' and "np_agent_preview_render_sessions"."closed_at" is not null and "np_agent_preview_render_sessions"."close_reason" is null and not "np_agent_preview_render_sessions"."consumed_ordinals" @> '[false]'::jsonb) or ("np_agent_preview_render_sessions"."state" in ('failed','cancelled','expired') and "np_agent_preview_render_sessions"."closed_at" is not null and "np_agent_preview_render_sessions"."close_reason" in ('CAPTURE_FAILED','PREVIEW_INVALIDATED','SITE_DELETING','SESSION_EXPIRED'))) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_preview_viewer_launches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"preview_id" uuid NOT NULL,
	"staff_user_id" uuid NOT NULL,
	"staff_session_id" uuid NOT NULL,
	"session_fingerprint" text NOT NULL,
	"session_fingerprint_key_id" text NOT NULL,
	"generation" integer NOT NULL,
	"admitting_invocation_id" uuid NOT NULL,
	"idempotency_key" text NOT NULL,
	"request_hash" text NOT NULL,
	"signing_kid" text NOT NULL,
	"allowed_routes_digest" text NOT NULL,
	"site_authorization_body" jsonb NOT NULL,
	"site_authorization_digest" text NOT NULL,
	"iat" integer NOT NULL,
	"exp" integer NOT NULL,
	"launch_path" text NOT NULL,
	"exchange_verifier" text NOT NULL,
	"exchange_key_id" text NOT NULL,
	"exchange_expires_at" timestamp with time zone NOT NULL,
	"exchange_consumed_at" timestamp with time zone,
	"one_time_value_issued" boolean DEFAULT true NOT NULL,
	"state" text DEFAULT 'exchange_pending' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"activated_at" timestamp with time zone,
	"superseded_at" timestamp with time zone,
	"expired_at" timestamp with time zone,
	"terminal_reason" text,
	CONSTRAINT "np_agent_preview_viewer_launches_generation_unique" UNIQUE("preview_id","staff_session_id","generation"),
	CONSTRAINT "np_agent_preview_viewer_launches_invocation_unique" UNIQUE("site_id","admitting_invocation_id"),
	CONSTRAINT "np_agent_preview_viewer_launches_claims_check" CHECK (("np_agent_preview_viewer_launches"."generation">0 and "np_agent_preview_viewer_launches"."iat">=0 and "np_agent_preview_viewer_launches"."exp">"np_agent_preview_viewer_launches"."iat" and "np_agent_preview_viewer_launches"."exp"<="np_agent_preview_viewer_launches"."iat"+300 and "np_agent_preview_viewer_launches"."one_time_value_issued" and "np_agent_preview_viewer_launches"."site_authorization_body"->>'siteId'="np_agent_preview_viewer_launches"."site_id" and "np_agent_preview_viewer_launches"."site_authorization_body"->>'userId'="np_agent_preview_viewer_launches"."staff_user_id"::text and "np_agent_preview_viewer_launches"."site_authorization_body"->>'schemaVersion'='np.agent-staff-site-authorization.v1' and "np_agent_preview_viewer_launches"."session_fingerprint" ~ '^psf1:hmac-sha256:[A-Za-z0-9][A-Za-z0-9._-]{0,63}:[A-Za-z0-9_-]{43}$' and split_part("np_agent_preview_viewer_launches"."session_fingerprint",':',3)="np_agent_preview_viewer_launches"."session_fingerprint_key_id" and "np_agent_preview_viewer_launches"."site_authorization_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_viewer_launches"."allowed_routes_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_viewer_launches"."request_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_preview_viewer_launches"."exchange_verifier" ~ '^lxv1:hmac-sha256:[A-Za-z0-9][A-Za-z0-9._-]{0,63}:[A-Za-z0-9_-]{43}$' and split_part("np_agent_preview_viewer_launches"."exchange_verifier",':',3)="np_agent_preview_viewer_launches"."exchange_key_id" and "np_agent_preview_viewer_launches"."exchange_expires_at">"np_agent_preview_viewer_launches"."created_at" and "np_agent_preview_viewer_launches"."exchange_expires_at"<="np_agent_preview_viewer_launches"."created_at"+interval '30 seconds') is true),
	CONSTRAINT "np_agent_preview_viewer_launches_state_check" CHECK ((("np_agent_preview_viewer_launches"."state"='exchange_pending' and "np_agent_preview_viewer_launches"."activated_at" is null and "np_agent_preview_viewer_launches"."exchange_consumed_at" is null and "np_agent_preview_viewer_launches"."superseded_at" is null and "np_agent_preview_viewer_launches"."expired_at" is null and "np_agent_preview_viewer_launches"."terminal_reason" is null) or ("np_agent_preview_viewer_launches"."state"='active' and "np_agent_preview_viewer_launches"."activated_at" is not null and "np_agent_preview_viewer_launches"."exchange_consumed_at" is not null and "np_agent_preview_viewer_launches"."superseded_at" is null and "np_agent_preview_viewer_launches"."expired_at" is null and "np_agent_preview_viewer_launches"."terminal_reason" is null) or ("np_agent_preview_viewer_launches"."state"='superseded' and "np_agent_preview_viewer_launches"."superseded_at" is not null and "np_agent_preview_viewer_launches"."expired_at" is null and "np_agent_preview_viewer_launches"."terminal_reason" in ('REPLACED','SESSION_REVOKED','PREVIEW_INVALIDATED','SITE_DELETING')) or ("np_agent_preview_viewer_launches"."state"='expired' and "np_agent_preview_viewer_launches"."expired_at" is not null and "np_agent_preview_viewer_launches"."superseded_at" is null and "np_agent_preview_viewer_launches"."terminal_reason" in ('REPLACED','SESSION_REVOKED','PREVIEW_INVALIDATED','SITE_DELETING'))) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_principals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"kind" text NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"status" text NOT NULL,
	"scopes" text[] NOT NULL,
	"authority_kind" text NOT NULL,
	"authority_user_id" uuid,
	"authority_policy_id" text,
	"authority_fingerprint" text NOT NULL,
	"authority_deleted_at" timestamp with time zone,
	"row_version" integer DEFAULT 1 NOT NULL,
	"token_version" integer DEFAULT 1 NOT NULL,
	"owner_user_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "np_agent_principals_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_principals_kind_check" CHECK ("np_agent_principals"."kind" in ('runtime', 'external')),
	CONSTRAINT "np_agent_principals_status_check" CHECK ("np_agent_principals"."status" in ('active', 'suspended', 'revoked')),
	CONSTRAINT "np_agent_principals_authority_kind_check" CHECK ("np_agent_principals"."authority_kind" in ('user', 'deployment')),
	CONSTRAINT "np_agent_principals_versions_check" CHECK ("np_agent_principals"."row_version" > 0 and "np_agent_principals"."token_version" > 0),
	CONSTRAINT "np_agent_principals_name_check" CHECK (char_length("np_agent_principals"."name") between 1 and 120 and "np_agent_principals"."name" = btrim("np_agent_principals"."name")),
	CONSTRAINT "np_agent_principals_description_check" CHECK ("np_agent_principals"."description" is null or char_length("np_agent_principals"."description") <= 4096),
	CONSTRAINT "np_agent_principals_scopes_check" CHECK (cardinality("np_agent_principals"."scopes") between (case when "np_agent_principals"."kind" = 'runtime' and "np_agent_principals"."status" <> 'active' then 0 else 1 end) and 64 and array_position("np_agent_principals"."scopes", null) is null),
	CONSTRAINT "np_agent_principals_active_scope_check" CHECK ("np_agent_principals"."status" <> 'active' or "np_agent_principals"."scopes" @> array['site:read']::text[]),
	CONSTRAINT "np_agent_principals_revocation_check" CHECK (("np_agent_principals"."status" = 'revoked') = ("np_agent_principals"."revoked_at" is not null)),
	CONSTRAINT "np_agent_principals_authority_check" CHECK ((
        ("np_agent_principals"."authority_kind" = 'user' and "np_agent_principals"."authority_policy_id" is null and
          (("np_agent_principals"."authority_user_id" is not null and "np_agent_principals"."authority_deleted_at" is null) or
           ("np_agent_principals"."authority_user_id" is null and "np_agent_principals"."authority_deleted_at" is not null)))
        or
        ("np_agent_principals"."authority_kind" = 'deployment' and "np_agent_principals"."authority_user_id" is null and
          "np_agent_principals"."authority_deleted_at" is null and "np_agent_principals"."authority_policy_id" is not null)
      )),
	CONSTRAINT "np_agent_principals_active_authority_check" CHECK ("np_agent_principals"."status" <> 'active' or ("np_agent_principals"."authority_kind" = 'deployment' or "np_agent_principals"."authority_user_id" is not null))
);
--> statement-breakpoint
CREATE TABLE "np_agent_provider_calls" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"run_id" uuid NOT NULL,
	"sequence" integer NOT NULL,
	"retry_of_id" uuid,
	"connection_id" uuid NOT NULL,
	"connection_config_snapshot_id" uuid NOT NULL,
	"secret_version_id" uuid NOT NULL,
	"credential_version" integer NOT NULL,
	"connection_config_version" integer NOT NULL,
	"connection_config_hash" text NOT NULL,
	"provider_data_class_ceiling" text NOT NULL,
	"request_data_class" text NOT NULL,
	"classification_manifest" jsonb NOT NULL,
	"classification_manifest_digest" text NOT NULL,
	"recipe_id" text NOT NULL,
	"recipe_version" integer NOT NULL,
	"recipe_fingerprint" text NOT NULL,
	"instruction_template_id" text NOT NULL,
	"instruction_template_version" integer NOT NULL,
	"instruction_digest" text NOT NULL,
	"response_schema_digest" text NOT NULL,
	"provider" text NOT NULL,
	"model" text NOT NULL,
	"pricing_id" text NOT NULL,
	"pricing_version" integer NOT NULL,
	"pricing_fingerprint" text NOT NULL,
	"pricing_effective_at" timestamp with time zone NOT NULL,
	"state" text NOT NULL,
	"dispatch_state" text NOT NULL,
	"usage_reservation_id" uuid NOT NULL,
	"request_digest" text NOT NULL,
	"request_redacted" jsonb,
	"response_digest" text,
	"response_redacted" jsonb,
	"decision" jsonb,
	"provider_request_id" text,
	"idempotency_key" text NOT NULL,
	"error_class" text,
	"retryable" boolean DEFAULT false NOT NULL,
	"input_tokens" integer,
	"cached_input_tokens" integer,
	"output_tokens" integer,
	"usage_source" text,
	"cost_micros" bigint,
	"cost_source" text,
	"cost_currency" text,
	"finish_reason" text,
	"latency_ms" integer,
	"started_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	"diagnostic_expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_provider_calls_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_provider_calls_run_id_unique" UNIQUE("site_id","run_id","id"),
	CONSTRAINT "np_agent_provider_calls_sequence_unique" UNIQUE("site_id","run_id","sequence"),
	CONSTRAINT "np_agent_provider_calls_idempotency_unique" UNIQUE("site_id","run_id","idempotency_key"),
	CONSTRAINT "np_agent_provider_calls_reservation_unique" UNIQUE("usage_reservation_id"),
	CONSTRAINT "np_agent_provider_calls_state_check" CHECK ("np_agent_provider_calls"."state" in ('reserved','in_flight','succeeded','failed','ambiguous','cancelled')),
	CONSTRAINT "np_agent_provider_calls_dispatch_check" CHECK (("np_agent_provider_calls"."dispatch_state" in ('not-dispatched','dispatched','unknown') and (("np_agent_provider_calls"."state"='reserved' and "np_agent_provider_calls"."dispatch_state"='not-dispatched') or ("np_agent_provider_calls"."state" in ('in_flight','ambiguous') and "np_agent_provider_calls"."dispatch_state"='unknown') or ("np_agent_provider_calls"."state"='succeeded' and "np_agent_provider_calls"."dispatch_state"='dispatched') or ("np_agent_provider_calls"."state" in ('failed','cancelled') and "np_agent_provider_calls"."dispatch_state" in ('not-dispatched','dispatched')))) is true),
	CONSTRAINT "np_agent_provider_calls_versions_check" CHECK ("np_agent_provider_calls"."sequence">0 and "np_agent_provider_calls"."credential_version">0 and "np_agent_provider_calls"."connection_config_version">0 and "np_agent_provider_calls"."recipe_version">0 and "np_agent_provider_calls"."instruction_template_version">0 and "np_agent_provider_calls"."pricing_version">0 and ("np_agent_provider_calls"."retry_of_id" is null or "np_agent_provider_calls"."retry_of_id"<>"np_agent_provider_calls"."id")),
	CONSTRAINT "np_agent_provider_calls_identity_check" CHECK (char_length("np_agent_provider_calls"."provider") between 1 and 128 and char_length("np_agent_provider_calls"."model") between 1 and 128 and char_length("np_agent_provider_calls"."recipe_id") between 1 and 128 and char_length("np_agent_provider_calls"."instruction_template_id") between 1 and 128 and char_length("np_agent_provider_calls"."pricing_id") between 1 and 128 and "np_agent_provider_calls"."idempotency_key" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,255}$' and ("np_agent_provider_calls"."provider_request_id" is null or "np_agent_provider_calls"."provider_request_id" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,255}$')),
	CONSTRAINT "np_agent_provider_calls_hash_check" CHECK ("np_agent_provider_calls"."connection_config_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_provider_calls"."recipe_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_provider_calls"."instruction_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_provider_calls"."response_schema_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_provider_calls"."request_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_provider_calls"."classification_manifest_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_provider_calls"."pricing_fingerprint" ~ '^pr1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_provider_calls"."response_digest" is null or "np_agent_provider_calls"."response_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')),
	CONSTRAINT "np_agent_provider_calls_data_class_check" CHECK ("np_agent_provider_calls"."provider_data_class_ceiling" in ('public-only','internal-redacted','sensitive-approved') and "np_agent_provider_calls"."request_data_class" in ('public-only','internal-redacted','sensitive-approved') and (case "np_agent_provider_calls"."request_data_class" when 'public-only' then 0 when 'internal-redacted' then 1 else 2 end)<=(case "np_agent_provider_calls"."provider_data_class_ceiling" when 'public-only' then 0 when 'internal-redacted' then 1 else 2 end)),
	CONSTRAINT "np_agent_provider_calls_body_check" CHECK ((jsonb_typeof("np_agent_provider_calls"."classification_manifest")='object' and octet_length("np_agent_provider_calls"."classification_manifest"::text)<=262144 and ("np_agent_provider_calls"."request_redacted" is null or (jsonb_typeof("np_agent_provider_calls"."request_redacted")='object' and octet_length("np_agent_provider_calls"."request_redacted"::text)<=65536)) and ("np_agent_provider_calls"."response_redacted" is null or (jsonb_typeof("np_agent_provider_calls"."response_redacted")='object' and octet_length("np_agent_provider_calls"."response_redacted"::text)<=65536)) and (("np_agent_provider_calls"."request_redacted" is null and "np_agent_provider_calls"."response_redacted" is null) or "np_agent_provider_calls"."diagnostic_expires_at" is not null) and ("np_agent_provider_calls"."decision" is null or octet_length("np_agent_provider_calls"."decision"::text)<=262144)) is true),
	CONSTRAINT "np_agent_provider_calls_usage_bounds_check" CHECK (("np_agent_provider_calls"."input_tokens" is null or "np_agent_provider_calls"."input_tokens">=0) and ("np_agent_provider_calls"."cached_input_tokens" is null or "np_agent_provider_calls"."cached_input_tokens" between 0 and "np_agent_provider_calls"."input_tokens") and ("np_agent_provider_calls"."output_tokens" is null or "np_agent_provider_calls"."output_tokens">=0) and ("np_agent_provider_calls"."cost_micros" is null or "np_agent_provider_calls"."cost_micros" between 0 and 9007199254740991) and ("np_agent_provider_calls"."latency_ms" is null or "np_agent_provider_calls"."latency_ms">=0)),
	CONSTRAINT "np_agent_provider_calls_usage_check" CHECK (((
      "np_agent_provider_calls"."input_tokens" is null and "np_agent_provider_calls"."cached_input_tokens" is null and "np_agent_provider_calls"."output_tokens" is null and "np_agent_provider_calls"."cost_micros" is null and "np_agent_provider_calls"."cost_currency" is null and "np_agent_provider_calls"."finish_reason" is null and (("np_agent_provider_calls"."state"='ambiguous' and "np_agent_provider_calls"."usage_source"='unknown' and "np_agent_provider_calls"."cost_source"='unknown') or ("np_agent_provider_calls"."state"<>'ambiguous' and "np_agent_provider_calls"."usage_source" is null and "np_agent_provider_calls"."cost_source" is null))
    ) or (
      "np_agent_provider_calls"."state" in ('succeeded','failed','cancelled') and "np_agent_provider_calls"."dispatch_state"='dispatched' and "np_agent_provider_calls"."input_tokens" is not null and "np_agent_provider_calls"."cached_input_tokens" is not null and "np_agent_provider_calls"."output_tokens" is not null and "np_agent_provider_calls"."cost_micros" is not null and "np_agent_provider_calls"."cost_currency"='USD' and "np_agent_provider_calls"."usage_source" in ('provider','adapter-estimate') and "np_agent_provider_calls"."cost_source" in ('provider','adapter-estimate') and ("np_agent_provider_calls"."finish_reason" in ('stop','length','tool','content-filter','cancelled') or ("np_agent_provider_calls"."state" in ('failed','cancelled') and "np_agent_provider_calls"."finish_reason" is null))
    )) is true),
	CONSTRAINT "np_agent_provider_calls_outcome_check" CHECK ((((
      "np_agent_provider_calls"."state" in ('reserved','in_flight') and "np_agent_provider_calls"."response_digest" is null and "np_agent_provider_calls"."decision" is null and "np_agent_provider_calls"."error_class" is null and "np_agent_provider_calls"."retryable"=false and "np_agent_provider_calls"."latency_ms" is null and "np_agent_provider_calls"."input_tokens" is null
    ) or (
      "np_agent_provider_calls"."state"='succeeded' and "np_agent_provider_calls"."response_digest" is not null and "np_agent_provider_calls"."decision" is not null and "np_agent_provider_calls"."error_class" is null and "np_agent_provider_calls"."retryable"=false and "np_agent_provider_calls"."input_tokens" is not null and "np_agent_provider_calls"."latency_ms" is not null and "np_agent_provider_calls"."finish_reason" in ('stop','length','tool')
    ) or (
      "np_agent_provider_calls"."state" in ('failed','cancelled') and "np_agent_provider_calls"."response_digest" is not null and "np_agent_provider_calls"."decision" is null and "np_agent_provider_calls"."error_class" in ('authentication','rate-limited','transient','timeout','invalid-request','invalid-output','content-policy','cancelled','unknown') and "np_agent_provider_calls"."latency_ms" is not null and ("np_agent_provider_calls"."finish_reason" is null or "np_agent_provider_calls"."finish_reason" in ('content-filter','cancelled'))
    ) or (
      "np_agent_provider_calls"."state"='ambiguous' and "np_agent_provider_calls"."response_digest" is not null and "np_agent_provider_calls"."decision" is null and "np_agent_provider_calls"."error_class" in ('timeout','unknown') and "np_agent_provider_calls"."retryable"=false and "np_agent_provider_calls"."latency_ms" is not null
    )) and ("np_agent_provider_calls"."dispatch_state"<>'not-dispatched' or "np_agent_provider_calls"."provider_request_id" is null)) is true),
	CONSTRAINT "np_agent_provider_calls_time_check" CHECK ((((
      "np_agent_provider_calls"."state"='reserved' and "np_agent_provider_calls"."started_at" is null and "np_agent_provider_calls"."finished_at" is null
    ) or (
      "np_agent_provider_calls"."state"='in_flight' and "np_agent_provider_calls"."started_at">="np_agent_provider_calls"."created_at" and "np_agent_provider_calls"."finished_at" is null
    ) or (
      "np_agent_provider_calls"."state" in ('succeeded','failed','ambiguous','cancelled') and "np_agent_provider_calls"."finished_at">="np_agent_provider_calls"."created_at" and ("np_agent_provider_calls"."started_at" is null or "np_agent_provider_calls"."finished_at">="np_agent_provider_calls"."started_at") and ("np_agent_provider_calls"."dispatch_state"='not-dispatched' or "np_agent_provider_calls"."started_at">="np_agent_provider_calls"."created_at")
    )) and ("np_agent_provider_calls"."diagnostic_expires_at" is null or "np_agent_provider_calls"."diagnostic_expires_at">"np_agent_provider_calls"."created_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_reference_fence" (
	"id" integer PRIMARY KEY NOT NULL,
	"epoch" bigint DEFAULT 0 NOT NULL,
	CONSTRAINT "np_agent_reference_fence_singleton_check" CHECK ("np_agent_reference_fence"."id"=1 and "np_agent_reference_fence"."epoch">=0)
);
--> statement-breakpoint
CREATE TABLE "np_agent_restriction_enforcements" (
	"id" uuid PRIMARY KEY NOT NULL,
	"site_id" text NOT NULL,
	"descriptor" jsonb NOT NULL,
	"restriction_hash" text NOT NULL,
	"subject_key" text NOT NULL,
	"action_scopes" text[] NOT NULL,
	"install_key" text NOT NULL,
	"remove_key" text,
	"expected_row_version" integer NOT NULL,
	"state" text NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_restriction_enforcements_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_restriction_enforcements_descriptor_check" CHECK ((jsonb_typeof("np_agent_restriction_enforcements"."descriptor")='object' and octet_length("np_agent_restriction_enforcements"."descriptor"::text)<=8192 and "np_agent_restriction_enforcements"."descriptor"->>'restrictionId'="np_agent_restriction_enforcements"."id"::text and "np_agent_restriction_enforcements"."descriptor"->>'siteId'="np_agent_restriction_enforcements"."site_id" and "np_agent_restriction_enforcements"."descriptor"->>'schemaVersion'='np.agent-restriction.v1' and ("np_agent_restriction_enforcements"."descriptor"->>'startsAt')::timestamptz="np_agent_restriction_enforcements"."starts_at" and ("np_agent_restriction_enforcements"."descriptor"->>'expiresAt')::timestamptz="np_agent_restriction_enforcements"."expires_at") is true),
	CONSTRAINT "np_agent_restriction_enforcements_bounds_check" CHECK (("np_agent_restriction_enforcements"."restriction_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and length("np_agent_restriction_enforcements"."subject_key") between 1 and 512 and cardinality("np_agent_restriction_enforcements"."action_scopes") between 1 and 5 and "np_agent_restriction_enforcements"."action_scopes"<@ARRAY['auth.staff','auth.member','agent.gateway','community.write','content.write']::text[] and "np_agent_restriction_enforcements"."expected_row_version">0 and length("np_agent_restriction_enforcements"."install_key") between 1 and 256 and ("np_agent_restriction_enforcements"."remove_key" is null or length("np_agent_restriction_enforcements"."remove_key") between 1 and 256)) is true),
	CONSTRAINT "np_agent_restriction_enforcements_state_check" CHECK (("np_agent_restriction_enforcements"."state" in ('installed','removed') and ("np_agent_restriction_enforcements"."state"='removed')=("np_agent_restriction_enforcements"."remove_key" is not null)) is true),
	CONSTRAINT "np_agent_restriction_enforcements_time_check" CHECK (("np_agent_restriction_enforcements"."updated_at">="np_agent_restriction_enforcements"."created_at" and "np_agent_restriction_enforcements"."expires_at">="np_agent_restriction_enforcements"."starts_at"+interval '60 seconds' and "np_agent_restriction_enforcements"."expires_at"<="np_agent_restriction_enforcements"."starts_at"+interval '3600 seconds') is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_runs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"origin" text NOT NULL,
	"agent_id" uuid,
	"agent_version_id" uuid,
	"agent_config_hash" text,
	"principal_id" uuid NOT NULL,
	"invocation_id" uuid,
	"admission_fingerprint" text NOT NULL,
	"trigger_id" uuid,
	"root_run_id" uuid NOT NULL,
	"parent_run_id" uuid,
	"causal_depth" integer NOT NULL,
	"causal_event_id" uuid,
	"causal_action_id" uuid,
	"recipe_id" text,
	"recipe_version" integer,
	"recipe_fingerprint" text,
	"instruction_template_id" text,
	"instruction_template_version" integer,
	"instruction_digest" text,
	"response_schema_digest" text,
	"manual_input_schema_digest" text,
	"manual_input" jsonb,
	"manual_input_digest" text,
	"state" text NOT NULL,
	"goal" text NOT NULL,
	"event_ref" jsonb,
	"policy_refs" jsonb NOT NULL,
	"runtime_admission_sources" jsonb,
	"run_limits" jsonb NOT NULL,
	"run_limits_hash" text NOT NULL,
	"budget_snapshot" jsonb NOT NULL,
	"budget_snapshot_hash" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"attempt" integer NOT NULL,
	"provider_request_id" text,
	"connection_id" uuid,
	"connection_config_snapshot_id" uuid,
	"connection_config_version" integer,
	"connection_config_hash" text,
	"provider_data_class_ceiling" text,
	"pricing_id" text,
	"pricing_version" integer,
	"pricing_fingerprint" text,
	"pricing_effective_at" timestamp with time zone,
	"usage" jsonb NOT NULL,
	"result" jsonb,
	"error_code" text,
	"error_message" text,
	"queued_at" timestamp with time zone NOT NULL,
	"deadline_at" timestamp with time zone NOT NULL,
	"started_at" timestamp with time zone,
	"lease_until" timestamp with time zone,
	"runtime_retry_at" timestamp with time zone,
	"finished_at" timestamp with time zone,
	CONSTRAINT "np_agent_runs_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_runs_agent_binding_unique" UNIQUE("site_id","agent_id","id"),
	CONSTRAINT "np_agent_runs_causation_unique" UNIQUE("site_id","id","root_run_id","causal_depth"),
	CONSTRAINT "np_agent_runs_connection_binding_unique" UNIQUE("site_id","id","connection_id","connection_config_snapshot_id"),
	CONSTRAINT "np_agent_runs_invocation_unique" UNIQUE("invocation_id"),
	CONSTRAINT "np_agent_runs_admission_unique" UNIQUE("site_id","origin","principal_id","admission_fingerprint"),
	CONSTRAINT "np_agent_runs_origin_check" CHECK ("np_agent_runs"."origin" in ('gateway', 'runtime')),
	CONSTRAINT "np_agent_runs_runtime_admission_sources_check" CHECK ((("np_agent_runs"."origin"='gateway' and "np_agent_runs"."runtime_admission_sources" is null) or ("np_agent_runs"."origin"='runtime' and "np_agent_runs"."runtime_admission_sources"->>'schemaVersion'='np.agent-runtime-admission-sources.v1' and "np_agent_runs"."runtime_admission_sources"->'frameworkPolicy'->>'schemaVersion'='np.agent-policy.v1' and "np_agent_runs"."runtime_admission_sources"->'frameworkPolicy'->>'instructions'='' and "np_agent_runs"."runtime_admission_sources"->'frameworkPolicy'->'rules'->>'schemaVersion'='np.agent-policy-rules.v1' and "np_agent_runs"."runtime_admission_sources"->>'frameworkPolicyVersion' ~ '^[1-9][0-9]{0,9}$' and ("np_agent_runs"."runtime_admission_sources"->>'frameworkPolicyVersion')::numeric<=2147483647 and "np_agent_runs"."runtime_admission_sources"->'sitePolicy'->>'schemaVersion'='np.agent-policy.v1' and "np_agent_runs"."runtime_admission_sources"->'sitePolicy'->>'instructions'='' and "np_agent_runs"."runtime_admission_sources"->'sitePolicy'->'rules'->>'schemaVersion'='np.agent-policy-rules.v1' and "np_agent_runs"."runtime_admission_sources"->'deploymentBudget'->>'schemaVersion'='np.agent-budget.v1' and "np_agent_runs"."runtime_admission_sources"->'siteBudget'->>'schemaVersion'='np.agent-budget.v1' and octet_length("np_agent_runs"."runtime_admission_sources"::text)<=1048576)) is true),
	CONSTRAINT "np_agent_runs_manual_input_check" CHECK ((("np_agent_runs"."manual_input" is null and "np_agent_runs"."manual_input_digest" is null) or
        ("np_agent_runs"."origin"='runtime' and "np_agent_runs"."manual_input" is not null and jsonb_typeof("np_agent_runs"."manual_input")='object'
        and octet_length("np_agent_runs"."manual_input"::text)<=16384 and "np_agent_runs"."manual_input_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$'
        and "np_agent_runs"."manual_input_schema_digest" is not null and "np_agent_runs"."trigger_id" is not null
        and "np_agent_runs"."connection_id" is not null and "np_agent_runs"."provider_data_class_ceiling"='sensitive-approved')) is true),
	CONSTRAINT "np_agent_runs_runtime_shape_check" CHECK (("np_agent_runs"."origin"<>'runtime' or ("np_agent_runs"."agent_id" is not null and "np_agent_runs"."agent_version_id" is not null and "np_agent_runs"."agent_config_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_runs"."recipe_id" is not null and "np_agent_runs"."recipe_version">0 and "np_agent_runs"."recipe_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_runs"."response_schema_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and ("np_agent_runs"."manual_input_schema_digest" is null or "np_agent_runs"."manual_input_schema_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$'))) is true),
	CONSTRAINT "np_agent_runs_provider_shape_check" CHECK (((
      "np_agent_runs"."connection_id" is null and "np_agent_runs"."connection_config_snapshot_id" is null and "np_agent_runs"."connection_config_version" is null and "np_agent_runs"."connection_config_hash" is null and "np_agent_runs"."provider_data_class_ceiling" is null and "np_agent_runs"."pricing_id" is null and "np_agent_runs"."pricing_version" is null and "np_agent_runs"."pricing_fingerprint" is null and "np_agent_runs"."pricing_effective_at" is null and "np_agent_runs"."provider_request_id" is null
    ) or (
      "np_agent_runs"."origin"='runtime' and "np_agent_runs"."connection_id" is not null and "np_agent_runs"."connection_config_snapshot_id" is not null and "np_agent_runs"."connection_config_version">0 and "np_agent_runs"."connection_config_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_runs"."provider_data_class_ceiling" in ('public-only','internal-redacted','sensitive-approved') and char_length("np_agent_runs"."pricing_id") between 1 and 128 and "np_agent_runs"."pricing_version">0 and "np_agent_runs"."pricing_fingerprint" ~ '^pr1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_runs"."pricing_effective_at" is not null
    )) is true),
	CONSTRAINT "np_agent_runs_instruction_check" CHECK ((( "np_agent_runs"."instruction_template_id" is null and "np_agent_runs"."instruction_template_version" is null and "np_agent_runs"."instruction_digest" is null ) or ( "np_agent_runs"."origin"='runtime' and char_length("np_agent_runs"."instruction_template_id") between 1 and 128 and "np_agent_runs"."instruction_template_version">0 and "np_agent_runs"."instruction_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' )) is true),
	CONSTRAINT "np_agent_runs_runtime_time_check" CHECK ("np_agent_runs"."origin"<>'runtime' or ("np_agent_runs"."deadline_at"<="np_agent_runs"."queued_at"+interval '86400 seconds' and ("np_agent_runs"."started_at" is null or "np_agent_runs"."started_at">="np_agent_runs"."queued_at") and ("np_agent_runs"."lease_until" is null or ("np_agent_runs"."started_at" is not null and "np_agent_runs"."lease_until"<="np_agent_runs"."deadline_at")) and ("np_agent_runs"."finished_at" is null or "np_agent_runs"."finished_at">="np_agent_runs"."queued_at"))),
	CONSTRAINT "np_agent_runs_runtime_retry_check" CHECK ((("np_agent_runs"."origin"='gateway' and "np_agent_runs"."runtime_retry_at" is null) or ("np_agent_runs"."origin"='runtime' and (("np_agent_runs"."state"='waiting_retry')=("np_agent_runs"."runtime_retry_at" is not null)) and ("np_agent_runs"."runtime_retry_at" is null or ("np_agent_runs"."runtime_retry_at">="np_agent_runs"."queued_at" and "np_agent_runs"."runtime_retry_at"<"np_agent_runs"."deadline_at")) and ("np_agent_runs"."lease_until" is null or "np_agent_runs"."state" in ('running','verifying')))) is true),
	CONSTRAINT "np_agent_runs_state_check" CHECK ("np_agent_runs"."state" in ('queued', 'running', 'waiting_approval', 'waiting_retry', 'verifying', 'succeeded', 'failed', 'cancelled', 'policy_blocked', 'budget_blocked')),
	CONSTRAINT "np_agent_runs_gateway_shape_check" CHECK ("np_agent_runs"."origin" <> 'gateway' or (
        "np_agent_runs"."agent_id" is null and "np_agent_runs"."agent_version_id" is null and "np_agent_runs"."agent_config_hash" is null and
        "np_agent_runs"."invocation_id" is not null and "np_agent_runs"."trigger_id" is null and "np_agent_runs"."recipe_id" is null and
        "np_agent_runs"."recipe_version" is null and "np_agent_runs"."recipe_fingerprint" is null and
        "np_agent_runs"."instruction_template_id" is null and "np_agent_runs"."instruction_template_version" is null and
        "np_agent_runs"."instruction_digest" is null and "np_agent_runs"."response_schema_digest" is null and
        "np_agent_runs"."manual_input_schema_digest" is null and "np_agent_runs"."connection_id" is null and
        "np_agent_runs"."connection_config_snapshot_id" is null and "np_agent_runs"."connection_config_version" is null and
        "np_agent_runs"."connection_config_hash" is null and "np_agent_runs"."provider_data_class_ceiling" is null and
        "np_agent_runs"."provider_request_id" is null and
        "np_agent_runs"."pricing_id" is null and "np_agent_runs"."pricing_version" is null and
        "np_agent_runs"."pricing_fingerprint" is null and "np_agent_runs"."pricing_effective_at" is null
      )),
	CONSTRAINT "np_agent_runs_lineage_check" CHECK (("np_agent_runs"."parent_run_id" is null and "np_agent_runs"."root_run_id" = "np_agent_runs"."id" and "np_agent_runs"."causal_depth" = 0 and "np_agent_runs"."causal_action_id" is null)
        or ("np_agent_runs"."parent_run_id" is not null and "np_agent_runs"."parent_run_id" <> "np_agent_runs"."id" and "np_agent_runs"."root_run_id" <> "np_agent_runs"."id" and "np_agent_runs"."causal_depth" between 1 and 4)),
	CONSTRAINT "np_agent_runs_attempt_check" CHECK ("np_agent_runs"."attempt" > 0),
	CONSTRAINT "np_agent_runs_deadline_check" CHECK ("np_agent_runs"."deadline_at" > "np_agent_runs"."queued_at"),
	CONSTRAINT "np_agent_runs_terminal_check" CHECK ((("np_agent_runs"."state" in ('succeeded', 'failed', 'cancelled', 'policy_blocked', 'budget_blocked')) = ("np_agent_runs"."finished_at" is not null)) and
        ("np_agent_runs"."error_code" is null) = ("np_agent_runs"."error_message" is null))
);
--> statement-breakpoint
CREATE TABLE "np_agent_runtime_receipts" (
	"id" uuid PRIMARY KEY NOT NULL,
	"site_id" text NOT NULL,
	"agent_id" uuid NOT NULL,
	"agent_version_id" uuid NOT NULL,
	"run_id" uuid NOT NULL,
	"principal_id" uuid NOT NULL,
	"body" jsonb NOT NULL,
	"body_hash" text NOT NULL,
	"key_id" text NOT NULL,
	"source_mac" text NOT NULL,
	"occurred_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"state" text DEFAULT 'pending' NOT NULL,
	"next_attempt_at" timestamp with time zone DEFAULT now() NOT NULL,
	"failure_code" text,
	"emitted_event_id" uuid,
	"emitted_at" timestamp with time zone,
	CONSTRAINT "np_agent_runtime_receipts_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_runtime_receipts_source_check" CHECK (("np_agent_runtime_receipts"."body"->>'schemaVersion'='np.agent-guardian-runtime-activity.v1'
    and "np_agent_runtime_receipts"."body"->>'siteId'="np_agent_runtime_receipts"."site_id" and "np_agent_runtime_receipts"."body"->>'observationId'="np_agent_runtime_receipts"."id"::text
    and "np_agent_runtime_receipts"."body"->>'agentId'="np_agent_runtime_receipts"."agent_id"::text and "np_agent_runtime_receipts"."body"->>'agentVersionId'="np_agent_runtime_receipts"."agent_version_id"::text
    and "np_agent_runtime_receipts"."body"->>'runId'="np_agent_runtime_receipts"."run_id"::text and "np_agent_runtime_receipts"."body"->>'principalId'="np_agent_runtime_receipts"."principal_id"::text
    and "np_agent_runtime_receipts"."body"->>'occurredAt'=to_char("np_agent_runtime_receipts"."occurred_at" at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
    and octet_length("np_agent_runtime_receipts"."body"::text)<=8192 and "np_agent_runtime_receipts"."body_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$'
    and "np_agent_runtime_receipts"."key_id" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$' and "np_agent_runtime_receipts"."source_mac" ~ '^hmac-sha256:[A-Za-z0-9_-]{43}$') is true),
	CONSTRAINT "np_agent_runtime_receipts_delivery_check" CHECK (((
    "np_agent_runtime_receipts"."state"='emitted' and "np_agent_runtime_receipts"."emitted_event_id" is not null and "np_agent_runtime_receipts"."emitted_at" is not null and "np_agent_runtime_receipts"."failure_code" is null)
    or ("np_agent_runtime_receipts"."state"='pending' and "np_agent_runtime_receipts"."emitted_event_id" is null and "np_agent_runtime_receipts"."emitted_at" is null and "np_agent_runtime_receipts"."failure_code" is null)
    or ("np_agent_runtime_receipts"."state"='blocked' and "np_agent_runtime_receipts"."emitted_event_id" is null and "np_agent_runtime_receipts"."emitted_at" is null and "np_agent_runtime_receipts"."failure_code" in ('KEY_UNAVAILABLE','SOURCE_INTEGRITY','DELIVERY_UNAVAILABLE'))
    or ("np_agent_runtime_receipts"."state"='sampled' and "np_agent_runtime_receipts"."emitted_event_id" is null and "np_agent_runtime_receipts"."emitted_at" is null and "np_agent_runtime_receipts"."failure_code"='COVERAGE_CAPPED')
    or ("np_agent_runtime_receipts"."state"='held' and "np_agent_runtime_receipts"."emitted_event_id" is null and "np_agent_runtime_receipts"."emitted_at" is null and "np_agent_runtime_receipts"."failure_code"='DELIVERY_CLOSED')) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_service_tokens" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"principal_id" uuid NOT NULL,
	"name" text NOT NULL,
	"prefix" text NOT NULL,
	"token_hash" text NOT NULL,
	"hash_key_id" text NOT NULL,
	"rotation_family_id" uuid NOT NULL,
	"family_authority_version" integer DEFAULT 1 NOT NULL,
	"family_generation" integer DEFAULT 1 NOT NULL,
	"principal_token_version" integer NOT NULL,
	"replaces_token_id" uuid,
	"row_version" integer DEFAULT 1 NOT NULL,
	"status" text NOT NULL,
	"scopes" text[] NOT NULL,
	"transport" text NOT NULL,
	"exposure_mode" text NOT NULL,
	"audience" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"last_used_at" timestamp with time zone,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"overlap_expires_at" timestamp with time zone,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "np_agent_service_tokens_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_service_tokens_prefix_unique" UNIQUE("prefix"),
	CONSTRAINT "np_agent_service_tokens_token_hash_unique" UNIQUE("token_hash"),
	CONSTRAINT "np_agent_service_tokens_replaces_unique" UNIQUE("replaces_token_id"),
	CONSTRAINT "np_agent_service_tokens_family_generation_unique" UNIQUE("site_id","rotation_family_id","family_generation"),
	CONSTRAINT "np_agent_service_tokens_status_check" CHECK ("np_agent_service_tokens"."status" in ('active_head', 'overlap', 'revoked', 'expired')),
	CONSTRAINT "np_agent_service_tokens_transport_check" CHECK ("np_agent_service_tokens"."transport" in ('stdio', 'mcp-http', 'agent-http')),
	CONSTRAINT "np_agent_service_tokens_exposure_check" CHECK ("np_agent_service_tokens"."exposure_mode" in ('read', 'propose', 'approved-execute')),
	CONSTRAINT "np_agent_service_tokens_versions_check" CHECK ("np_agent_service_tokens"."family_authority_version" > 0 and "np_agent_service_tokens"."family_generation" > 0 and "np_agent_service_tokens"."principal_token_version" > 0 and "np_agent_service_tokens"."row_version" > 0),
	CONSTRAINT "np_agent_service_tokens_prefix_check" CHECK ("np_agent_service_tokens"."prefix" = 'npst1_' || "np_agent_service_tokens"."id"::text),
	CONSTRAINT "np_agent_service_tokens_scopes_check" CHECK (cardinality("np_agent_service_tokens"."scopes") between 1 and 64 and "np_agent_service_tokens"."scopes" @> array['site:read']::text[] and array_position("np_agent_service_tokens"."scopes", null) is null),
	CONSTRAINT "np_agent_service_tokens_time_check" CHECK ("np_agent_service_tokens"."expires_at" > "np_agent_service_tokens"."created_at" and ("np_agent_service_tokens"."last_used_at" is null or "np_agent_service_tokens"."last_used_at" >= "np_agent_service_tokens"."created_at")),
	CONSTRAINT "np_agent_service_tokens_state_time_check" CHECK ((
        ("np_agent_service_tokens"."status" = 'active_head' and "np_agent_service_tokens"."overlap_expires_at" is null and "np_agent_service_tokens"."revoked_at" is null)
        or ("np_agent_service_tokens"."status" = 'overlap' and "np_agent_service_tokens"."overlap_expires_at" is not null and "np_agent_service_tokens"."revoked_at" is null and "np_agent_service_tokens"."overlap_expires_at" <= "np_agent_service_tokens"."expires_at")
        or ("np_agent_service_tokens"."status" in ('revoked', 'expired') and "np_agent_service_tokens"."revoked_at" is not null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_signals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"detector_id" text NOT NULL,
	"detector_version" integer NOT NULL,
	"category" text NOT NULL,
	"severity" text NOT NULL,
	"confidence_basis" text NOT NULL,
	"score_basis_points" integer,
	"fingerprint" text NOT NULL,
	"subject" jsonb,
	"evidence" jsonb NOT NULL,
	"evidence_digest" text NOT NULL,
	"status" text NOT NULL,
	"incident_id" uuid,
	"window_started_at" timestamp with time zone NOT NULL,
	"window_ended_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_signals_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_signals_state_check" CHECK (("np_agent_signals"."category" in ('spam','abuse','authentication','authorization','traffic','integrity','availability','cost','agent-abuse') and "np_agent_signals"."severity" in ('info','low','medium','high','critical') and "np_agent_signals"."confidence_basis" in ('exact-rule','statistical','external') and "np_agent_signals"."status" in ('open','attached','suppressed','resolved') and ("np_agent_signals"."status"<>'attached' or "np_agent_signals"."incident_id" is not null)) is true),
	CONSTRAINT "np_agent_signals_bounds_check" CHECK (("np_agent_signals"."detector_id" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$' and "np_agent_signals"."detector_version">0 and ("np_agent_signals"."score_basis_points" is null or "np_agent_signals"."score_basis_points" between 0 and 10000) and length("np_agent_signals"."fingerprint") between 1 and 256 and "np_agent_signals"."evidence_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and jsonb_typeof("np_agent_signals"."evidence")='array' and jsonb_array_length("np_agent_signals"."evidence") between 1 and 100 and octet_length("np_agent_signals"."evidence"::text)<=524288 and ("np_agent_signals"."subject" is null or octet_length("np_agent_signals"."subject"::text)<=4096)) is true),
	CONSTRAINT "np_agent_signals_time_check" CHECK (("np_agent_signals"."window_ended_at">="np_agent_signals"."window_started_at" and "np_agent_signals"."expires_at">"np_agent_signals"."created_at") is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_site_deletion_sagas" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"state" text NOT NULL,
	"plan_body" jsonb NOT NULL,
	"plan_hash" text NOT NULL,
	"site_version_digest" text NOT NULL,
	"prepared_at" timestamp with time zone NOT NULL,
	"cursor" jsonb NOT NULL,
	"requested_by_user_id" uuid,
	"requester_fingerprint" text NOT NULL,
	"last_error_code" text,
	"lease_until" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"cleanup_completed_at" timestamp with time zone,
	CONSTRAINT "np_agent_site_deletion_sagas_site_unique" UNIQUE("site_id"),
	CONSTRAINT "np_agent_site_deletion_sagas_state_check" CHECK ("np_agent_site_deletion_sagas"."state" in ('prepared', 'cleaning', 'ready_to_commit', 'failed', 'committing')),
	CONSTRAINT "np_agent_site_deletion_sagas_completion_check" CHECK (("np_agent_site_deletion_sagas"."state" in ('ready_to_commit', 'committing')) = ("np_agent_site_deletion_sagas"."cleanup_completed_at" is not null))
);
--> statement-breakpoint
CREATE TABLE "np_agent_source_release_edges" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"source_release_id" uuid NOT NULL,
	"owner_kind" text NOT NULL,
	"owner_id" uuid NOT NULL,
	"edge_code" text NOT NULL,
	"owner_evidence_digest" text NOT NULL,
	"verifier_version" integer DEFAULT 1 NOT NULL,
	"released_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_source_release_edges_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_source_release_edges_owner_unique" UNIQUE("site_id","source_release_id","owner_kind","owner_id","edge_code"),
	CONSTRAINT "np_agent_source_release_edges_owner_check" CHECK ("np_agent_source_release_edges"."owner_kind" in ('runtime-audit','read-action','read-invocation','studio-audit','admin-invocation','changeset-action','changeset-invocation','changeset-source','changeset-audit','changeset-validation','changeset-preview','changeset-approval','guardian-audit','guardian-closure-audit')),
	CONSTRAINT "np_agent_source_release_edges_code_check" CHECK (("np_agent_source_release_edges"."owner_kind"='runtime-audit' and "np_agent_source_release_edges"."edge_code" in ('audit-target','audit-run','audit-reservation')) or ("np_agent_source_release_edges"."owner_kind"='read-action' and "np_agent_source_release_edges"."edge_code"='action-run') or ("np_agent_source_release_edges"."owner_kind"='read-invocation' and "np_agent_source_release_edges"."edge_code"='invocation-authority-run') or ("np_agent_source_release_edges"."owner_kind"='studio-audit' and "np_agent_source_release_edges"."edge_code"='audit-target') or ("np_agent_source_release_edges"."owner_kind"='admin-invocation' and "np_agent_source_release_edges"."edge_code"='invocation-result') or ("np_agent_source_release_edges"."owner_kind"='changeset-action' and "np_agent_source_release_edges"."edge_code"='action-run') or ("np_agent_source_release_edges"."owner_kind"='changeset-invocation' and "np_agent_source_release_edges"."edge_code"='invocation-authority-run') or ("np_agent_source_release_edges"."owner_kind"='changeset-source' and "np_agent_source_release_edges"."edge_code"='changeset-run') or ("np_agent_source_release_edges"."owner_kind"='changeset-audit' and "np_agent_source_release_edges"."edge_code"='audit-changeset') or ("np_agent_source_release_edges"."owner_kind"='changeset-validation' and "np_agent_source_release_edges"."edge_code"='validation-authority-run') or ("np_agent_source_release_edges"."owner_kind"='changeset-preview' and "np_agent_source_release_edges"."edge_code"='preview-authority-run') or ("np_agent_source_release_edges"."owner_kind"='changeset-approval' and "np_agent_source_release_edges"."edge_code"='approval-history') or ("np_agent_source_release_edges"."owner_kind"='guardian-audit' and "np_agent_source_release_edges"."edge_code"='guardian-event') or ("np_agent_source_release_edges"."owner_kind"='guardian-closure-audit' and "np_agent_source_release_edges"."edge_code"='guardian-closure')),
	CONSTRAINT "np_agent_source_release_edges_digest_check" CHECK ("np_agent_source_release_edges"."owner_evidence_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_source_release_edges"."verifier_version"=1)
);
--> statement-breakpoint
CREATE TABLE "np_agent_source_releases" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"source_kind" text NOT NULL,
	"source_id" uuid NOT NULL,
	"evidence_body" jsonb NOT NULL,
	"evidence_digest" text NOT NULL,
	"principal_id" uuid,
	"admission_key_digest" text,
	"released_at" timestamp with time zone NOT NULL,
	CONSTRAINT "np_agent_source_releases_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_source_releases_source_unique" UNIQUE("site_id","source_kind","source_id"),
	CONSTRAINT "np_agent_source_releases_kind_check" CHECK ("np_agent_source_releases"."source_kind" in ('runtime-run','provider-call','usage-reservation','circuit-breaker','guardian-event')),
	CONSTRAINT "np_agent_source_releases_body_check" CHECK ((jsonb_typeof("np_agent_source_releases"."evidence_body")='object' and octet_length("np_agent_source_releases"."evidence_body"::text)<=16384 and "np_agent_source_releases"."evidence_body"->>'schemaVersion'='np.agent-source-release.v1' and "np_agent_source_releases"."evidence_body"->>'kind'="np_agent_source_releases"."source_kind" and "np_agent_source_releases"."evidence_body"->>'siteId'="np_agent_source_releases"."site_id" and "np_agent_source_releases"."evidence_body"->>'sourceId'="np_agent_source_releases"."source_id"::text and ("np_agent_source_releases"."evidence_body"->>'releasedAt')::timestamptz="np_agent_source_releases"."released_at" and "np_agent_source_releases"."evidence_body"->>'verifierVersion'='1') is true),
	CONSTRAINT "np_agent_source_releases_key_check" CHECK (((("np_agent_source_releases"."source_kind"='runtime-run') and "np_agent_source_releases"."principal_id" is not null and "np_agent_source_releases"."admission_key_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_source_releases"."evidence_body"->>'principalId'="np_agent_source_releases"."principal_id"::text and "np_agent_source_releases"."evidence_body"->>'admissionKeyDigest'="np_agent_source_releases"."admission_key_digest") or ("np_agent_source_releases"."source_kind"<>'runtime-run' and "np_agent_source_releases"."principal_id" is null and "np_agent_source_releases"."admission_key_digest" is null)) is true),
	CONSTRAINT "np_agent_source_releases_digest_check" CHECK ("np_agent_source_releases"."evidence_digest" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$')
);
--> statement-breakpoint
CREATE TABLE "np_agent_triggers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"agent_id" uuid NOT NULL,
	"agent_version_id" uuid NOT NULL,
	"kind" text NOT NULL,
	"event_type" text,
	"cron" text,
	"catch_up" text,
	"next_run_at" timestamp with time zone,
	"last_enqueued_at" timestamp with time zone,
	"filter" jsonb NOT NULL,
	"filter_hash" text NOT NULL,
	"coalesce_seconds" integer NOT NULL,
	"enabled" boolean NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agent_triggers_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_triggers_version_binding_unique" UNIQUE("site_id","agent_id","agent_version_id","id"),
	CONSTRAINT "np_agent_triggers_kind_check" CHECK ("np_agent_triggers"."kind" in ('event','schedule','manual')),
	CONSTRAINT "np_agent_triggers_event_check" CHECK ("np_agent_triggers"."event_type" is null or "np_agent_triggers"."event_type" in ('api.rate-limited','agent.action.changed','agent.policy.blocked','agent.policy.changed','agent.run.changed','agent.runtime.activity.observed','http.response.observed','auth.login.failed','auth.login.succeeded','auth.session.revoked','authz.denied','authz.role.changed','community.content.created','community.content.moderated','community.content.reported','community.member.reported','content.document.changed','content.activity.observed','content.document.published','jobs.backlog.threshold','jobs.handler.failed','jobs.worker.stale','ops.backup.failed','ops.backup.stale','ops.check.changed','security.edge.signal','security.error.signal','security.authority.changed','security.credential.changed','security.plugin.changed')),
	CONSTRAINT "np_agent_triggers_shape_check" CHECK ((("np_agent_triggers"."kind"='event' and "np_agent_triggers"."event_type" is not null and "np_agent_triggers"."cron" is null and "np_agent_triggers"."catch_up" is null and "np_agent_triggers"."next_run_at" is null and "np_agent_triggers"."last_enqueued_at" is null) or ("np_agent_triggers"."kind"='schedule' and "np_agent_triggers"."event_type" is null and "np_agent_triggers"."cron" ~ '^[^[:space:]]+ [^[:space:]]+ [^[:space:]]+ [^[:space:]]+ [^[:space:]]+$' and char_length("np_agent_triggers"."cron")<=128 and "np_agent_triggers"."catch_up" in ('skip','once') and ("np_agent_triggers"."enabled"=false or "np_agent_triggers"."next_run_at" is not null)) or ("np_agent_triggers"."kind"='manual' and "np_agent_triggers"."event_type" is null and "np_agent_triggers"."cron" is null and "np_agent_triggers"."catch_up" is null and "np_agent_triggers"."next_run_at" is null and "np_agent_triggers"."last_enqueued_at" is null)) is true),
	CONSTRAINT "np_agent_triggers_filter_check" CHECK ((jsonb_typeof("np_agent_triggers"."filter")='object' and octet_length("np_agent_triggers"."filter"::text)<=16384 and "np_agent_triggers"."filter_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_triggers"."coalesce_seconds" between 0 and 86400) is true),
	CONSTRAINT "np_agent_triggers_time_check" CHECK ("np_agent_triggers"."updated_at">="np_agent_triggers"."created_at")
);
--> statement-breakpoint
CREATE TABLE "np_agent_usage_daily" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"agent_id" uuid NOT NULL,
	"connection_id" uuid NOT NULL,
	"usage_date" date NOT NULL,
	"provider_calls" integer DEFAULT 0 NOT NULL,
	"reported_input_tokens" integer DEFAULT 0 NOT NULL,
	"reported_cached_input_tokens" integer DEFAULT 0 NOT NULL,
	"reported_output_tokens" integer DEFAULT 0 NOT NULL,
	"estimated_input_tokens" integer DEFAULT 0 NOT NULL,
	"estimated_cached_input_tokens" integer DEFAULT 0 NOT NULL,
	"estimated_output_tokens" integer DEFAULT 0 NOT NULL,
	"reported_cost_micros" bigint DEFAULT 0 NOT NULL,
	"estimated_cost_micros" bigint DEFAULT 0 NOT NULL,
	"budget_charge_cost_micros" bigint DEFAULT 0 NOT NULL,
	"unknown_calls" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "np_agent_usage_daily_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_usage_daily_bucket_unique" UNIQUE("site_id","agent_id","connection_id","usage_date"),
	CONSTRAINT "np_agent_usage_daily_tokens_check" CHECK ("np_agent_usage_daily"."provider_calls">=0 and "np_agent_usage_daily"."reported_input_tokens">=0 and "np_agent_usage_daily"."reported_cached_input_tokens" between 0 and "np_agent_usage_daily"."reported_input_tokens" and "np_agent_usage_daily"."reported_output_tokens">=0 and "np_agent_usage_daily"."estimated_input_tokens">=0 and "np_agent_usage_daily"."estimated_cached_input_tokens" between 0 and "np_agent_usage_daily"."estimated_input_tokens" and "np_agent_usage_daily"."estimated_output_tokens">=0 and "np_agent_usage_daily"."unknown_calls" between 0 and "np_agent_usage_daily"."provider_calls"),
	CONSTRAINT "np_agent_usage_daily_cost_check" CHECK ("np_agent_usage_daily"."reported_cost_micros" between 0 and 9007199254740991 and "np_agent_usage_daily"."estimated_cost_micros" between 0 and 9007199254740991 and "np_agent_usage_daily"."budget_charge_cost_micros" between 0 and 9007199254740991 and "np_agent_usage_daily"."budget_charge_cost_micros">="np_agent_usage_daily"."reported_cost_micros"+"np_agent_usage_daily"."estimated_cost_micros")
);
--> statement-breakpoint
CREATE TABLE "np_agent_usage_reservations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"agent_id" uuid NOT NULL,
	"run_id" uuid NOT NULL,
	"connection_id" uuid NOT NULL,
	"connection_config_snapshot_id" uuid NOT NULL,
	"model" text NOT NULL,
	"pricing_id" text NOT NULL,
	"pricing_version" integer NOT NULL,
	"pricing_fingerprint" text NOT NULL,
	"pricing_effective_at" timestamp with time zone NOT NULL,
	"idempotency_key" text NOT NULL,
	"state" text NOT NULL,
	"reserved_calls" integer NOT NULL,
	"reserved_input_tokens" integer NOT NULL,
	"reserved_output_tokens" integer NOT NULL,
	"reserved_cost_micros" bigint NOT NULL,
	"actual_input_tokens" integer,
	"actual_cached_input_tokens" integer,
	"actual_output_tokens" integer,
	"actual_cost_micros" bigint,
	"actual_usage_source" text,
	"actual_cost_source" text,
	"unpriced" boolean DEFAULT false NOT NULL,
	"budget_charge_cost_micros" bigint,
	"reserved_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"finalized_at" timestamp with time zone,
	CONSTRAINT "np_agent_usage_reservations_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_usage_reservations_call_binding_unique" UNIQUE("site_id","run_id","connection_id","id"),
	CONSTRAINT "np_agent_usage_reservations_idempotency_unique" UNIQUE("site_id","run_id","connection_id","idempotency_key"),
	CONSTRAINT "np_agent_usage_reservations_state_check" CHECK ("np_agent_usage_reservations"."state" in ('reserved','reconciled','released','expired')),
	CONSTRAINT "np_agent_usage_reservations_bounds_check" CHECK ("np_agent_usage_reservations"."reserved_calls" between 1 and 2147483647 and "np_agent_usage_reservations"."reserved_input_tokens">=0 and "np_agent_usage_reservations"."reserved_output_tokens">=0 and "np_agent_usage_reservations"."reserved_cost_micros" between 0 and 9007199254740991 and ("np_agent_usage_reservations"."actual_input_tokens" is null or "np_agent_usage_reservations"."actual_input_tokens">=0) and ("np_agent_usage_reservations"."actual_cached_input_tokens" is null or "np_agent_usage_reservations"."actual_cached_input_tokens" between 0 and "np_agent_usage_reservations"."actual_input_tokens") and ("np_agent_usage_reservations"."actual_output_tokens" is null or "np_agent_usage_reservations"."actual_output_tokens">=0) and ("np_agent_usage_reservations"."actual_cost_micros" is null or "np_agent_usage_reservations"."actual_cost_micros" between 0 and 9007199254740991) and ("np_agent_usage_reservations"."budget_charge_cost_micros" is null or "np_agent_usage_reservations"."budget_charge_cost_micros" between 0 and 9007199254740991)),
	CONSTRAINT "np_agent_usage_reservations_pricing_check" CHECK ("np_agent_usage_reservations"."pricing_version">0 and "np_agent_usage_reservations"."pricing_fingerprint" ~ '^pr1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_usage_reservations"."pricing_effective_at"<="np_agent_usage_reservations"."reserved_at" and char_length("np_agent_usage_reservations"."model") between 1 and 128 and char_length("np_agent_usage_reservations"."pricing_id") between 1 and 128 and "np_agent_usage_reservations"."idempotency_key" ~ '^[A-Za-z0-9][A-Za-z0-9._:-]{0,255}$'),
	CONSTRAINT "np_agent_usage_reservations_usage_check" CHECK (((
      "np_agent_usage_reservations"."state" in ('reserved','released') and "np_agent_usage_reservations"."actual_input_tokens" is null and "np_agent_usage_reservations"."actual_cached_input_tokens" is null and "np_agent_usage_reservations"."actual_output_tokens" is null and "np_agent_usage_reservations"."actual_cost_micros" is null and "np_agent_usage_reservations"."actual_usage_source" is null and "np_agent_usage_reservations"."actual_cost_source" is null and "np_agent_usage_reservations"."unpriced"=false and (("np_agent_usage_reservations"."state"='reserved' and "np_agent_usage_reservations"."budget_charge_cost_micros" is null) or ("np_agent_usage_reservations"."state"='released' and "np_agent_usage_reservations"."budget_charge_cost_micros"=0))
    ) or (
      "np_agent_usage_reservations"."state"='reconciled' and "np_agent_usage_reservations"."actual_input_tokens" is not null and "np_agent_usage_reservations"."actual_cached_input_tokens" is not null and "np_agent_usage_reservations"."actual_output_tokens" is not null and "np_agent_usage_reservations"."actual_cost_micros" is not null and "np_agent_usage_reservations"."actual_usage_source" in ('provider','adapter-estimate') and "np_agent_usage_reservations"."actual_cost_source" in ('provider','adapter-estimate') and "np_agent_usage_reservations"."unpriced"=false and "np_agent_usage_reservations"."budget_charge_cost_micros"="np_agent_usage_reservations"."actual_cost_micros"
    ) or (
      "np_agent_usage_reservations"."state"='expired' and "np_agent_usage_reservations"."actual_input_tokens" is null and "np_agent_usage_reservations"."actual_cached_input_tokens" is null and "np_agent_usage_reservations"."actual_output_tokens" is null and "np_agent_usage_reservations"."actual_cost_micros" is null and "np_agent_usage_reservations"."actual_usage_source"='unknown' and "np_agent_usage_reservations"."actual_cost_source"='unknown' and "np_agent_usage_reservations"."unpriced"=true and "np_agent_usage_reservations"."budget_charge_cost_micros"="np_agent_usage_reservations"."reserved_cost_micros"
    )) is true),
	CONSTRAINT "np_agent_usage_reservations_time_check" CHECK (("np_agent_usage_reservations"."expires_at">"np_agent_usage_reservations"."reserved_at" and (("np_agent_usage_reservations"."state"='reserved' and "np_agent_usage_reservations"."finalized_at" is null) or ("np_agent_usage_reservations"."state"<>'reserved' and "np_agent_usage_reservations"."finalized_at">="np_agent_usage_reservations"."reserved_at")) and ("np_agent_usage_reservations"."state"<>'expired' or "np_agent_usage_reservations"."finalized_at">="np_agent_usage_reservations"."expires_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agent_vault_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"secret_version_id" uuid NOT NULL,
	"ciphertext" "bytea" NOT NULL,
	"wrapped_data_key" "bytea" NOT NULL,
	"nonce" "bytea" NOT NULL,
	"auth_tag" "bytea" NOT NULL,
	"algorithm" text NOT NULL,
	"kek_id" text NOT NULL,
	"kek_version" text NOT NULL,
	"aad_digest" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"destroyed_at" timestamp with time zone,
	CONSTRAINT "np_agent_vault_entries_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_vault_entries_secret_unique" UNIQUE("secret_version_id"),
	CONSTRAINT "np_agent_vault_entries_bytes_check" CHECK (octet_length("np_agent_vault_entries"."ciphertext") > 0 and octet_length("np_agent_vault_entries"."wrapped_data_key") > 0 and
        octet_length("np_agent_vault_entries"."nonce") > 0 and octet_length("np_agent_vault_entries"."auth_tag") > 0)
);
--> statement-breakpoint
CREATE TABLE "np_agent_vault_operations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"connection_id" uuid NOT NULL,
	"secret_version_id" uuid NOT NULL,
	"vault_adapter" text NOT NULL,
	"vault_adapter_contract_version" integer NOT NULL,
	"vault_adapter_fingerprint" text NOT NULL,
	"kind" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"request_digest_key_id" text NOT NULL,
	"request_digest" text NOT NULL,
	"state" text NOT NULL,
	"secret_ref" text,
	"result_digest" text,
	"last_error_code" text,
	"target_key_id" text,
	"target_key_version" text,
	"attempt" integer DEFAULT 1 NOT NULL,
	"row_version" integer DEFAULT 1 NOT NULL,
	"lease_until" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"finished_at" timestamp with time zone,
	CONSTRAINT "np_agent_vault_operations_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_vault_operations_adapter_idempotency_unique" UNIQUE("vault_adapter","idempotency_key"),
	CONSTRAINT "np_agent_vault_operations_kind_check" CHECK ("np_agent_vault_operations"."kind" in ('seal', 'rewrap', 'destroy')),
	CONSTRAINT "np_agent_vault_operations_state_check" CHECK ("np_agent_vault_operations"."state" in ('queued', 'running', 'waiting_inspection', 'succeeded', 'failed')),
	CONSTRAINT "np_agent_vault_operations_versions_check" CHECK ("np_agent_vault_operations"."vault_adapter_contract_version" > 0 and "np_agent_vault_operations"."attempt" between 1 and 65535 and "np_agent_vault_operations"."row_version" > 0),
	CONSTRAINT "np_agent_vault_operations_rewrap_target_check" CHECK (("np_agent_vault_operations"."kind" = 'rewrap' and "np_agent_vault_operations"."target_key_id" is not null and "np_agent_vault_operations"."target_key_version" is not null) or
        ("np_agent_vault_operations"."kind" <> 'rewrap' and "np_agent_vault_operations"."target_key_id" is null and "np_agent_vault_operations"."target_key_version" is null)),
	CONSTRAINT "np_agent_vault_operations_state_time_check" CHECK ((
        ("np_agent_vault_operations"."state" = 'queued' and "np_agent_vault_operations"."lease_until" is null and "np_agent_vault_operations"."finished_at" is null and "np_agent_vault_operations"."result_digest" is null and "np_agent_vault_operations"."last_error_code" is null)
        or ("np_agent_vault_operations"."state" in ('running', 'waiting_inspection') and "np_agent_vault_operations"."finished_at" is null and "np_agent_vault_operations"."result_digest" is null)
        or ("np_agent_vault_operations"."state" = 'succeeded' and "np_agent_vault_operations"."finished_at" is not null and "np_agent_vault_operations"."result_digest" is not null and "np_agent_vault_operations"."last_error_code" is null)
        or ("np_agent_vault_operations"."state" = 'failed' and "np_agent_vault_operations"."finished_at" is not null and "np_agent_vault_operations"."result_digest" is not null and "np_agent_vault_operations"."last_error_code" is not null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_agent_versions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"agent_id" uuid NOT NULL,
	"version" integer NOT NULL,
	"row_version" integer DEFAULT 1 NOT NULL,
	"status" text NOT NULL,
	"model_connection_id" uuid,
	"model" text,
	"scopes" text[] NOT NULL,
	"autonomy" text NOT NULL,
	"capability_modes" jsonb NOT NULL,
	"policy_mode" text NOT NULL,
	"budget" jsonb NOT NULL,
	"settings" jsonb NOT NULL,
	"recipe_registry_body" jsonb NOT NULL,
	"recipe_registry_fingerprint" text NOT NULL,
	"config_hash" text NOT NULL,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"activated_at" timestamp with time zone,
	"retired_at" timestamp with time zone,
	CONSTRAINT "np_agent_versions_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agent_versions_agent_id_unique" UNIQUE("site_id","agent_id","id"),
	CONSTRAINT "np_agent_versions_config_unique" UNIQUE("site_id","agent_id","id","config_hash"),
	CONSTRAINT "np_agent_versions_number_unique" UNIQUE("site_id","agent_id","version"),
	CONSTRAINT "np_agent_versions_status_check" CHECK ("np_agent_versions"."status" in ('draft','active','retired')),
	CONSTRAINT "np_agent_versions_number_check" CHECK ("np_agent_versions"."version">0 and "np_agent_versions"."row_version">0),
	CONSTRAINT "np_agent_versions_modes_check" CHECK ("np_agent_versions"."autonomy" in ('observe','advise','guarded','approved') and "np_agent_versions"."policy_mode" in ('site','site_and_agent')),
	CONSTRAINT "np_agent_versions_model_check" CHECK ((("np_agent_versions"."model_connection_id" is null and "np_agent_versions"."model" is null) or ("np_agent_versions"."model_connection_id" is not null and char_length("np_agent_versions"."model") between 1 and 128)) is true),
	CONSTRAINT "np_agent_versions_scopes_check" CHECK (cardinality("np_agent_versions"."scopes") between 0 and 64 and array_position("np_agent_versions"."scopes",null) is null and ("np_agent_versions"."status"='draft' or "np_agent_versions"."scopes" @> array['site:read']::text[])),
	CONSTRAINT "np_agent_versions_contract_check" CHECK ((jsonb_typeof("np_agent_versions"."capability_modes")='array' and jsonb_array_length("np_agent_versions"."capability_modes")<=21 and jsonb_typeof("np_agent_versions"."settings")='array' and jsonb_array_length("np_agent_versions"."settings") between 1 and 8 and "np_agent_versions"."budget"->>'schemaVersion'='np.agent-budget.v1' and "np_agent_versions"."budget"->>'costCurrency'='USD' and "np_agent_versions"."recipe_registry_body"->>'schemaVersion'='np.agent-recipe-registry.v1' and "np_agent_versions"."recipe_registry_body"->>'projection'='registry' and jsonb_array_length("np_agent_versions"."recipe_registry_body"->'recipes') between 1 and 8 and octet_length("np_agent_versions"."recipe_registry_body"::text)<=8388608 and octet_length("np_agent_versions"."settings"::text)<=262144) is true),
	CONSTRAINT "np_agent_versions_hash_check" CHECK ("np_agent_versions"."config_hash" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$' and "np_agent_versions"."recipe_registry_fingerprint" ~ '^cj1:sha256:[A-Za-z0-9_-]{43}$'),
	CONSTRAINT "np_agent_versions_time_check" CHECK ((("np_agent_versions"."status"='draft' and "np_agent_versions"."activated_at" is null and "np_agent_versions"."retired_at" is null) or ("np_agent_versions"."status"='active' and "np_agent_versions"."activated_at">="np_agent_versions"."created_at" and "np_agent_versions"."retired_at" is null) or ("np_agent_versions"."status"='retired' and "np_agent_versions"."activated_at">="np_agent_versions"."created_at" and "np_agent_versions"."retired_at">="np_agent_versions"."activated_at")) is true)
);
--> statement-breakpoint
CREATE TABLE "np_agents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"site_id" text NOT NULL,
	"principal_id" uuid NOT NULL,
	"name" text NOT NULL,
	"template" text NOT NULL,
	"status" text NOT NULL,
	"active_version_id" uuid,
	"draft_version_id" uuid,
	"row_version" integer DEFAULT 1 NOT NULL,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_agents_site_id_id_unique" UNIQUE("site_id","id"),
	CONSTRAINT "np_agents_principal_unique" UNIQUE("principal_id"),
	CONSTRAINT "np_agents_principal_binding_unique" UNIQUE("site_id","id","principal_id"),
	CONSTRAINT "np_agents_status_check" CHECK ("np_agents"."status" in ('draft','active','paused','error','archived')),
	CONSTRAINT "np_agents_template_check" CHECK ("np_agents"."template" in ('publisher','moderator','operator','guardian','custom')),
	CONSTRAINT "np_agents_version_check" CHECK ("np_agents"."row_version" > 0),
	CONSTRAINT "np_agents_name_check" CHECK (char_length("np_agents"."name") between 1 and 120 and "np_agents"."name"=btrim("np_agents"."name")),
	CONSTRAINT "np_agents_lifecycle_check" CHECK ((("np_agents"."status"='draft' and "np_agents"."active_version_id" is null) or ("np_agents"."status" in ('active','paused','error') and "np_agents"."active_version_id" is not null) or "np_agents"."status"='archived') and ("np_agents"."active_version_id" is null or "np_agents"."draft_version_id" is null or "np_agents"."active_version_id"<>"np_agents"."draft_version_id") and ("np_agents"."status"<>'archived' or "np_agents"."draft_version_id" is null)),
	CONSTRAINT "np_agents_time_check" CHECK ("np_agents"."updated_at" >= "np_agents"."created_at")
);
--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_audit_event_id_np_audit_events_id_fk" FOREIGN KEY ("audit_event_id") REFERENCES "public"."np_audit_events"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_run_fk" FOREIGN KEY ("site_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_run_release_fk" FOREIGN KEY ("site_id","run_source_release_id") REFERENCES "public"."np_agent_source_releases"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_execution_invocation_fk" FOREIGN KEY ("site_id","execution_invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actions" ADD CONSTRAINT "np_agent_actions_compensates_fk" FOREIGN KEY ("site_id","compensates_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actor_restrictions" ADD CONSTRAINT "np_agent_actor_restrictions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actor_restrictions" ADD CONSTRAINT "np_agent_actor_restrictions_incident_fk" FOREIGN KEY ("site_id","incident_id") REFERENCES "public"."np_agent_incidents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actor_restrictions" ADD CONSTRAINT "np_agent_actor_restrictions_source_action_fk" FOREIGN KEY ("site_id","source_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_actor_restrictions" ADD CONSTRAINT "np_agent_actor_restrictions_removal_action_fk" FOREIGN KEY ("site_id","removal_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_challenge_issued_to_user_id_np_users_id_fk" FOREIGN KEY ("challenge_issued_to_user_id") REFERENCES "public"."np_users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_requested_by_user_id_np_users_id_fk" FOREIGN KEY ("requested_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_decided_by_user_id_np_users_id_fk" FOREIGN KEY ("decided_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_revoked_by_user_id_np_users_id_fk" FOREIGN KEY ("revoked_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_changeset_fk" FOREIGN KEY ("site_id","target_changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_action_fk" FOREIGN KEY ("site_id","target_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_requester_fk" FOREIGN KEY ("site_id","requested_by_principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_approvals" ADD CONSTRAINT "np_agent_approvals_rollback_plan_fk" FOREIGN KEY ("site_id","target_rollback_plan_id") REFERENCES "public"."np_agent_changeset_rollback_plans"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_executions" ADD CONSTRAINT "np_agent_changeset_executions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_executions" ADD CONSTRAINT "np_agent_changeset_executions_changeset_fk" FOREIGN KEY ("site_id","changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_executions" ADD CONSTRAINT "np_agent_changeset_executions_approval_fk" FOREIGN KEY ("site_id","approval_id") REFERENCES "public"."np_agent_approvals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_executions" ADD CONSTRAINT "np_agent_changeset_executions_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_executions" ADD CONSTRAINT "np_agent_changeset_executions_rollback_plan_fk" FOREIGN KEY ("site_id","rollback_plan_id") REFERENCES "public"."np_agent_changeset_rollback_plans"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_operations" ADD CONSTRAINT "np_agent_changeset_operations_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_operations" ADD CONSTRAINT "np_agent_changeset_operations_changeset_fk" FOREIGN KEY ("site_id","changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_previews" ADD CONSTRAINT "np_agent_changeset_previews_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_previews" ADD CONSTRAINT "np_agent_changeset_previews_changeset_fk" FOREIGN KEY ("site_id","changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_previews" ADD CONSTRAINT "np_agent_changeset_previews_invocation_fk" FOREIGN KEY ("site_id","admitting_invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_previews" ADD CONSTRAINT "np_agent_changeset_previews_run_fk" FOREIGN KEY ("site_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_operations" ADD CONSTRAINT "np_agent_changeset_rollback_operations_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_operations" ADD CONSTRAINT "np_agent_changeset_rollback_operations_plan_fk" FOREIGN KEY ("site_id","rollback_plan_id") REFERENCES "public"."np_agent_changeset_rollback_plans"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_operations" ADD CONSTRAINT "np_agent_changeset_rollback_operations_original_fk" FOREIGN KEY ("site_id","original_operation_id") REFERENCES "public"."np_agent_changeset_operations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_operations" ADD CONSTRAINT "np_agent_changeset_rollback_operations_changeset_fk" FOREIGN KEY ("site_id","changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_plans" ADD CONSTRAINT "np_agent_changeset_rollback_plans_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_plans" ADD CONSTRAINT "np_agent_changeset_rollback_plans_changeset_fk" FOREIGN KEY ("site_id","changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_rollback_plans" ADD CONSTRAINT "np_agent_changeset_rollback_plans_invocation_fk" FOREIGN KEY ("site_id","admitting_invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_validation_attempts" ADD CONSTRAINT "np_agent_changeset_validation_attempts_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_validation_attempts" ADD CONSTRAINT "np_agent_changeset_validation_attempts_changeset_fk" FOREIGN KEY ("site_id","changeset_id") REFERENCES "public"."np_agent_changesets"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changeset_validation_attempts" ADD CONSTRAINT "np_agent_changeset_validation_attempts_invocation_fk" FOREIGN KEY ("site_id","admitting_invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changesets" ADD CONSTRAINT "np_agent_changesets_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changesets" ADD CONSTRAINT "np_agent_changesets_created_by_user_id_np_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changesets" ADD CONSTRAINT "np_agent_changesets_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changesets" ADD CONSTRAINT "np_agent_changesets_run_fk" FOREIGN KEY ("site_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changesets" ADD CONSTRAINT "np_agent_changesets_run_release_fk" FOREIGN KEY ("site_id","run_source_release_id") REFERENCES "public"."np_agent_source_releases"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_changesets" ADD CONSTRAINT "np_agent_changesets_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_circuit_breakers" ADD CONSTRAINT "np_agent_circuit_breakers_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_auth_requests" ADD CONSTRAINT "np_agent_connection_auth_requests_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_auth_requests" ADD CONSTRAINT "np_agent_connection_auth_requests_staff_session_id_np_sessions_id_fk" FOREIGN KEY ("staff_session_id") REFERENCES "public"."np_sessions"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_auth_requests" ADD CONSTRAINT "np_agent_connection_auth_requests_connection_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_auth_requests" ADD CONSTRAINT "np_agent_connection_auth_requests_config_fk" FOREIGN KEY ("site_id","config_snapshot_id") REFERENCES "public"."np_agent_connection_config_versions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_config_versions" ADD CONSTRAINT "np_agent_connection_config_versions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_config_versions" ADD CONSTRAINT "np_agent_connection_config_versions_connection_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_operations" ADD CONSTRAINT "np_agent_connection_operations_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_operations" ADD CONSTRAINT "np_agent_connection_operations_created_by_user_id_np_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_operations" ADD CONSTRAINT "np_agent_connection_operations_connection_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_operations" ADD CONSTRAINT "np_agent_connection_operations_config_fk" FOREIGN KEY ("site_id","config_snapshot_id") REFERENCES "public"."np_agent_connection_config_versions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_operations" ADD CONSTRAINT "np_agent_connection_operations_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_operations" ADD CONSTRAINT "np_agent_connection_operations_auth_request_fk" FOREIGN KEY ("site_id","auth_request_id") REFERENCES "public"."np_agent_connection_auth_requests"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_secret_versions" ADD CONSTRAINT "np_agent_connection_secret_versions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connection_secret_versions" ADD CONSTRAINT "np_agent_connection_secret_versions_connection_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connections" ADD CONSTRAINT "np_agent_connections_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_connections" ADD CONSTRAINT "np_agent_connections_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_containments" ADD CONSTRAINT "np_agent_containments_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_containments" ADD CONSTRAINT "np_agent_containments_source_action_fk" FOREIGN KEY ("site_id","source_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_containments" ADD CONSTRAINT "np_agent_containments_restore_action_fk" FOREIGN KEY ("site_id","restore_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_containments" ADD CONSTRAINT "np_agent_containments_incident_fk" FOREIGN KEY ("site_id","incident_id") REFERENCES "public"."np_agent_incidents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_content_receipts" ADD CONSTRAINT "np_agent_content_receipts_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_content_receipts" ADD CONSTRAINT "np_agent_content_receipts_event_fk" FOREIGN KEY ("site_id","emitted_event_id") REFERENCES "public"."np_agent_events"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_reviews" ADD CONSTRAINT "np_agent_evaluation_reviews_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_reviews" ADD CONSTRAINT "np_agent_evaluation_reviews_recorded_by_user_id_np_users_id_fk" FOREIGN KEY ("recorded_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_reviews" ADD CONSTRAINT "np_agent_evaluation_reviews_audit_fk" FOREIGN KEY ("audit_event_id") REFERENCES "public"."np_audit_events"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_reviews" ADD CONSTRAINT "np_agent_evaluation_reviews_source_fk" FOREIGN KEY ("site_id","source_id") REFERENCES "public"."np_agent_evaluation_sources"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_reviews" ADD CONSTRAINT "np_agent_evaluation_reviews_previous_fk" FOREIGN KEY ("site_id","source_id","previous_revision_id") REFERENCES "public"."np_agent_evaluation_reviews"("site_id","source_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_reviews" ADD CONSTRAINT "np_agent_evaluation_reviews_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_evaluation_sources" ADD CONSTRAINT "np_agent_evaluation_sources_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_events" ADD CONSTRAINT "np_agent_events_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_events" ADD CONSTRAINT "np_agent_events_causal_run_fk" FOREIGN KEY ("site_id","causal_run_id","causal_root_run_id","causal_depth") REFERENCES "public"."np_agent_runs"("site_id","id","root_run_id","causal_depth") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_events" ADD CONSTRAINT "np_agent_events_causal_action_fk" FOREIGN KEY ("site_id","causal_run_id","causal_action_id") REFERENCES "public"."np_agent_actions"("site_id","run_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_feedback" ADD CONSTRAINT "np_agent_feedback_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_feedback" ADD CONSTRAINT "np_agent_feedback_recorded_by_user_id_np_users_id_fk" FOREIGN KEY ("recorded_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_feedback" ADD CONSTRAINT "np_agent_feedback_supersedes_fk" FOREIGN KEY ("site_id","supersedes_id") REFERENCES "public"."np_agent_feedback"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_feedback" ADD CONSTRAINT "np_agent_feedback_agent_version_fk" FOREIGN KEY ("site_id","agent_version_id") REFERENCES "public"."np_agent_versions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_feedback" ADD CONSTRAINT "np_agent_feedback_provider_call_fk" FOREIGN KEY ("site_id","provider_call_id") REFERENCES "public"."np_agent_provider_calls"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_signals" ADD CONSTRAINT "np_agent_incident_signals_incident_fk" FOREIGN KEY ("site_id","incident_id") REFERENCES "public"."np_agent_incidents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_signals" ADD CONSTRAINT "np_agent_incident_signals_signal_fk" FOREIGN KEY ("site_id","signal_id") REFERENCES "public"."np_agent_signals"("site_id","id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_incident_timeline_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_incident_timeline_incident_fk" FOREIGN KEY ("site_id","incident_id") REFERENCES "public"."np_agent_incidents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_timeline_eventId_fk" FOREIGN KEY ("site_id","event_id") REFERENCES "public"."np_agent_events"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_timeline_signalId_fk" FOREIGN KEY ("site_id","signal_id") REFERENCES "public"."np_agent_signals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_timeline_runId_fk" FOREIGN KEY ("site_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_timeline_actionId_fk" FOREIGN KEY ("site_id","action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_timeline_approvalId_fk" FOREIGN KEY ("site_id","approval_id") REFERENCES "public"."np_agent_approvals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incident_timeline" ADD CONSTRAINT "np_agent_timeline_providerCallId_fk" FOREIGN KEY ("site_id","provider_call_id") REFERENCES "public"."np_agent_provider_calls"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incidents" ADD CONSTRAINT "np_agent_incidents_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_incidents" ADD CONSTRAINT "np_agent_incidents_assigned_fk" FOREIGN KEY ("site_id","assigned_agent_id") REFERENCES "public"."np_agents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_invocations" ADD CONSTRAINT "np_agent_invocations_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_invocations" ADD CONSTRAINT "np_agent_invocations_staff_user_id_np_users_id_fk" FOREIGN KEY ("staff_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_invocations" ADD CONSTRAINT "np_agent_invocations_audit_event_id_np_audit_events_id_fk" FOREIGN KEY ("audit_event_id") REFERENCES "public"."np_audit_events"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_invocations" ADD CONSTRAINT "np_agent_invocations_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_mcp_tasks" ADD CONSTRAINT "np_agent_mcp_tasks_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_mcp_tasks" ADD CONSTRAINT "np_agent_mcp_tasks_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_mcp_tasks" ADD CONSTRAINT "np_agent_mcp_tasks_run_fk" FOREIGN KEY ("site_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_mcp_tasks" ADD CONSTRAINT "np_agent_mcp_tasks_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_notifications" ADD CONSTRAINT "np_agent_notifications_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_notifications" ADD CONSTRAINT "np_agent_notifications_connectionId_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_notifications" ADD CONSTRAINT "np_agent_notifications_connectionConfigSnapshotId_fk" FOREIGN KEY ("site_id","connection_id","connection_config_snapshot_id","connection_config_version","connection_config_hash") REFERENCES "public"."np_agent_connection_config_versions"("site_id","connection_id","id","version","config_hash") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_notifications" ADD CONSTRAINT "np_agent_notifications_incidentId_fk" FOREIGN KEY ("site_id","incident_id") REFERENCES "public"."np_agent_incidents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_notifications" ADD CONSTRAINT "np_agent_notifications_runId_fk" FOREIGN KEY ("site_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_notifications" ADD CONSTRAINT "np_agent_notifications_actionId_fk" FOREIGN KEY ("site_id","action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_clients" ADD CONSTRAINT "np_agent_oauth_clients_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_clients" ADD CONSTRAINT "np_agent_oauth_clients_created_by_user_id_np_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_codes" ADD CONSTRAINT "np_agent_oauth_codes_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_codes" ADD CONSTRAINT "np_agent_oauth_codes_staff_session_id_np_sessions_id_fk" FOREIGN KEY ("staff_session_id") REFERENCES "public"."np_sessions"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_codes" ADD CONSTRAINT "np_agent_oauth_codes_request_fk" FOREIGN KEY ("site_id","request_id") REFERENCES "public"."np_agent_oauth_requests"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_codes" ADD CONSTRAINT "np_agent_oauth_codes_grant_fk" FOREIGN KEY ("site_id","grant_id") REFERENCES "public"."np_agent_oauth_grants"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_codes" ADD CONSTRAINT "np_agent_oauth_codes_client_fk" FOREIGN KEY ("site_id","client_id") REFERENCES "public"."np_agent_oauth_clients"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_grants" ADD CONSTRAINT "np_agent_oauth_grants_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_grants" ADD CONSTRAINT "np_agent_oauth_grants_staff_user_id_np_users_id_fk" FOREIGN KEY ("staff_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_grants" ADD CONSTRAINT "np_agent_oauth_grants_client_fk" FOREIGN KEY ("site_id","client_id") REFERENCES "public"."np_agent_oauth_clients"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_grants" ADD CONSTRAINT "np_agent_oauth_grants_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_refresh_tokens" ADD CONSTRAINT "np_agent_oauth_refresh_tokens_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_refresh_tokens" ADD CONSTRAINT "np_agent_oauth_refresh_tokens_grant_fk" FOREIGN KEY ("site_id","grant_id") REFERENCES "public"."np_agent_oauth_grants"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_refresh_tokens" ADD CONSTRAINT "np_agent_oauth_refresh_tokens_parent_fk" FOREIGN KEY ("site_id","parent_token_id") REFERENCES "public"."np_agent_oauth_refresh_tokens"("site_id","token_id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_refresh_tokens" ADD CONSTRAINT "np_agent_oauth_refresh_tokens_replacement_fk" FOREIGN KEY ("site_id","replacement_token_id") REFERENCES "public"."np_agent_oauth_refresh_tokens"("site_id","token_id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_requests" ADD CONSTRAINT "np_agent_oauth_requests_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_requests" ADD CONSTRAINT "np_agent_oauth_requests_staff_user_id_np_users_id_fk" FOREIGN KEY ("staff_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_requests" ADD CONSTRAINT "np_agent_oauth_requests_staff_session_id_np_sessions_id_fk" FOREIGN KEY ("staff_session_id") REFERENCES "public"."np_sessions"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_oauth_requests" ADD CONSTRAINT "np_agent_oauth_requests_client_fk" FOREIGN KEY ("site_id","client_id") REFERENCES "public"."np_agent_oauth_clients"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_executions" ADD CONSTRAINT "np_agent_operator_executions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_executions" ADD CONSTRAINT "np_agent_operator_executions_plan_fk" FOREIGN KEY ("site_id","plan_id") REFERENCES "public"."np_agent_operator_plans"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_executions" ADD CONSTRAINT "np_agent_operator_executions_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_executions" ADD CONSTRAINT "np_agent_operator_executions_action_fk" FOREIGN KEY ("site_id","action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_executions" ADD CONSTRAINT "np_agent_operator_executions_source_run_fk" FOREIGN KEY ("site_id","source_run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_executions" ADD CONSTRAINT "np_agent_operator_executions_result_run_fk" FOREIGN KEY ("site_id","result_run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_plans" ADD CONSTRAINT "np_agent_operator_plans_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_plans" ADD CONSTRAINT "np_agent_operator_plans_audit_event_id_np_audit_events_id_fk" FOREIGN KEY ("audit_event_id") REFERENCES "public"."np_audit_events"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_plans" ADD CONSTRAINT "np_agent_operator_plans_approval_action_fk" FOREIGN KEY ("site_id","approval_action_id") REFERENCES "public"."np_agent_actions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_operator_plans" ADD CONSTRAINT "np_agent_operator_plans_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_policies" ADD CONSTRAINT "np_agent_policies_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_policies" ADD CONSTRAINT "np_agent_policies_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_policies" ADD CONSTRAINT "np_agent_policies_agent_fk" FOREIGN KEY ("site_id","agent_id") REFERENCES "public"."np_agents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_artifact_uploads" ADD CONSTRAINT "np_agent_preview_artifact_uploads_preview_fk" FOREIGN KEY ("site_id","preview_id") REFERENCES "public"."np_agent_changeset_previews"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_artifact_uploads" ADD CONSTRAINT "np_agent_preview_artifact_uploads_artifact_fk" FOREIGN KEY ("site_id","preview_id","artifact_id") REFERENCES "public"."np_agent_preview_artifacts"("site_id","preview_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_artifacts" ADD CONSTRAINT "np_agent_preview_artifacts_preview_fk" FOREIGN KEY ("site_id","preview_id","preview_contract_fingerprint") REFERENCES "public"."np_agent_changeset_previews"("site_id","id","preview_contract_fingerprint") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_render_sessions" ADD CONSTRAINT "np_agent_preview_render_sessions_preview_fk" FOREIGN KEY ("site_id","preview_id","preview_contract_fingerprint") REFERENCES "public"."np_agent_changeset_previews"("site_id","id","preview_contract_fingerprint") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_render_sessions" ADD CONSTRAINT "np_agent_preview_render_sessions_reservation_fk" FOREIGN KEY ("site_id","preview_id","id","render_attempt_id") REFERENCES "public"."np_agent_changeset_previews"("site_id","id","render_session_id","render_attempt_id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_viewer_launches" ADD CONSTRAINT "np_agent_preview_viewer_launches_preview_fk" FOREIGN KEY ("site_id","preview_id") REFERENCES "public"."np_agent_changeset_previews"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_preview_viewer_launches" ADD CONSTRAINT "np_agent_preview_viewer_launches_invocation_fk" FOREIGN KEY ("site_id","admitting_invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_principals" ADD CONSTRAINT "np_agent_principals_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_principals" ADD CONSTRAINT "np_agent_principals_authority_user_id_np_users_id_fk" FOREIGN KEY ("authority_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_principals" ADD CONSTRAINT "np_agent_principals_owner_user_id_np_users_id_fk" FOREIGN KEY ("owner_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_provider_calls" ADD CONSTRAINT "np_agent_provider_calls_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_provider_calls" ADD CONSTRAINT "np_agent_provider_calls_run_fk" FOREIGN KEY ("site_id","run_id","connection_id","connection_config_snapshot_id") REFERENCES "public"."np_agent_runs"("site_id","id","connection_id","connection_config_snapshot_id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_provider_calls" ADD CONSTRAINT "np_agent_provider_calls_retry_fk" FOREIGN KEY ("site_id","run_id","retry_of_id") REFERENCES "public"."np_agent_provider_calls"("site_id","run_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_provider_calls" ADD CONSTRAINT "np_agent_provider_calls_config_fk" FOREIGN KEY ("site_id","connection_id","connection_config_snapshot_id","connection_config_version","connection_config_hash") REFERENCES "public"."np_agent_connection_config_versions"("site_id","connection_id","id","version","config_hash") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_provider_calls" ADD CONSTRAINT "np_agent_provider_calls_secret_fk" FOREIGN KEY ("site_id","connection_id","secret_version_id","credential_version") REFERENCES "public"."np_agent_connection_secret_versions"("site_id","connection_id","id","version") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_provider_calls" ADD CONSTRAINT "np_agent_provider_calls_reservation_fk" FOREIGN KEY ("site_id","run_id","connection_id","usage_reservation_id") REFERENCES "public"."np_agent_usage_reservations"("site_id","run_id","connection_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_restriction_enforcements" ADD CONSTRAINT "np_agent_restriction_enforcements_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_agent_fk" FOREIGN KEY ("site_id","agent_id","principal_id") REFERENCES "public"."np_agents"("site_id","id","principal_id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_version_fk" FOREIGN KEY ("site_id","agent_id","agent_version_id","agent_config_hash") REFERENCES "public"."np_agent_versions"("site_id","agent_id","id","config_hash") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_trigger_fk" FOREIGN KEY ("site_id","agent_id","agent_version_id","trigger_id") REFERENCES "public"."np_agent_triggers"("site_id","agent_id","agent_version_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_connection_config_fk" FOREIGN KEY ("site_id","connection_id","connection_config_snapshot_id","connection_config_version","connection_config_hash") REFERENCES "public"."np_agent_connection_config_versions"("site_id","connection_id","id","version","config_hash") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_invocation_fk" FOREIGN KEY ("site_id","invocation_id") REFERENCES "public"."np_agent_invocations"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_root_fk" FOREIGN KEY ("site_id","root_run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runs" ADD CONSTRAINT "np_agent_runs_parent_fk" FOREIGN KEY ("site_id","parent_run_id") REFERENCES "public"."np_agent_runs"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runtime_receipts" ADD CONSTRAINT "np_agent_runtime_receipts_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runtime_receipts" ADD CONSTRAINT "np_agent_runtime_receipts_agent_fk" FOREIGN KEY ("site_id","agent_id") REFERENCES "public"."np_agents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runtime_receipts" ADD CONSTRAINT "np_agent_runtime_receipts_run_fk" FOREIGN KEY ("site_id","agent_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","agent_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runtime_receipts" ADD CONSTRAINT "np_agent_runtime_receipts_version_fk" FOREIGN KEY ("site_id","agent_id","agent_version_id") REFERENCES "public"."np_agent_versions"("site_id","agent_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runtime_receipts" ADD CONSTRAINT "np_agent_runtime_receipts_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_runtime_receipts" ADD CONSTRAINT "np_agent_runtime_receipts_event_fk" FOREIGN KEY ("site_id","emitted_event_id") REFERENCES "public"."np_agent_events"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_service_tokens" ADD CONSTRAINT "np_agent_service_tokens_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_service_tokens" ADD CONSTRAINT "np_agent_service_tokens_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_service_tokens" ADD CONSTRAINT "np_agent_service_tokens_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_service_tokens" ADD CONSTRAINT "np_agent_service_tokens_replaces_fk" FOREIGN KEY ("site_id","replaces_token_id") REFERENCES "public"."np_agent_service_tokens"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_signals" ADD CONSTRAINT "np_agent_signals_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_signals" ADD CONSTRAINT "np_agent_signals_incident_fk" FOREIGN KEY ("site_id","incident_id") REFERENCES "public"."np_agent_incidents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_site_deletion_sagas" ADD CONSTRAINT "np_agent_site_deletion_sagas_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_site_deletion_sagas" ADD CONSTRAINT "np_agent_site_deletion_sagas_requested_by_user_id_np_users_id_fk" FOREIGN KEY ("requested_by_user_id") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_source_release_edges" ADD CONSTRAINT "np_agent_source_release_edges_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_source_release_edges" ADD CONSTRAINT "np_agent_source_release_edges_release_fk" FOREIGN KEY ("site_id","source_release_id") REFERENCES "public"."np_agent_source_releases"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_source_releases" ADD CONSTRAINT "np_agent_source_releases_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_source_releases" ADD CONSTRAINT "np_agent_source_releases_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_triggers" ADD CONSTRAINT "np_agent_triggers_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_triggers" ADD CONSTRAINT "np_agent_triggers_version_fk" FOREIGN KEY ("site_id","agent_id","agent_version_id") REFERENCES "public"."np_agent_versions"("site_id","agent_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_usage_daily" ADD CONSTRAINT "np_agent_usage_daily_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_usage_daily" ADD CONSTRAINT "np_agent_usage_daily_agent_fk" FOREIGN KEY ("site_id","agent_id") REFERENCES "public"."np_agents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_usage_daily" ADD CONSTRAINT "np_agent_usage_daily_connection_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_usage_reservations" ADD CONSTRAINT "np_agent_usage_reservations_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_usage_reservations" ADD CONSTRAINT "np_agent_usage_reservations_run_fk" FOREIGN KEY ("site_id","agent_id","run_id") REFERENCES "public"."np_agent_runs"("site_id","agent_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_usage_reservations" ADD CONSTRAINT "np_agent_usage_reservations_connection_fk" FOREIGN KEY ("site_id","run_id","connection_id","connection_config_snapshot_id") REFERENCES "public"."np_agent_runs"("site_id","id","connection_id","connection_config_snapshot_id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_vault_entries" ADD CONSTRAINT "np_agent_vault_entries_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_vault_entries" ADD CONSTRAINT "np_agent_vault_entries_secret_fk" FOREIGN KEY ("site_id","secret_version_id") REFERENCES "public"."np_agent_connection_secret_versions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_vault_operations" ADD CONSTRAINT "np_agent_vault_operations_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_vault_operations" ADD CONSTRAINT "np_agent_vault_operations_connection_fk" FOREIGN KEY ("site_id","connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_vault_operations" ADD CONSTRAINT "np_agent_vault_operations_secret_fk" FOREIGN KEY ("site_id","secret_version_id") REFERENCES "public"."np_agent_connection_secret_versions"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_versions" ADD CONSTRAINT "np_agent_versions_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_versions" ADD CONSTRAINT "np_agent_versions_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_versions" ADD CONSTRAINT "np_agent_versions_agent_fk" FOREIGN KEY ("site_id","agent_id") REFERENCES "public"."np_agents"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agent_versions" ADD CONSTRAINT "np_agent_versions_connection_fk" FOREIGN KEY ("site_id","model_connection_id") REFERENCES "public"."np_agent_connections"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agents" ADD CONSTRAINT "np_agents_site_id_np_sites_id_fk" FOREIGN KEY ("site_id") REFERENCES "public"."np_sites"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agents" ADD CONSTRAINT "np_agents_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_agents" ADD CONSTRAINT "np_agents_principal_fk" FOREIGN KEY ("site_id","principal_id") REFERENCES "public"."np_agent_principals"("site_id","id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "np_agent_actions_site_state_idx" ON "np_agent_actions" USING btree ("site_id","state","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_actions_run_idx" ON "np_agent_actions" USING btree ("site_id","run_id","sequence");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_actor_restrictions_active_target_uidx" ON "np_agent_actor_restrictions" USING btree ("site_id","subject_key","scope_digest") WHERE "np_agent_actor_restrictions"."state" in ('pending','active','removing');--> statement-breakpoint
CREATE INDEX "np_agent_actor_restrictions_incident_idx" ON "np_agent_actor_restrictions" USING btree ("site_id","incident_id");--> statement-breakpoint
CREATE INDEX "np_agent_actor_restrictions_expiry_idx" ON "np_agent_actor_restrictions" USING btree ("site_id","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_approvals_live_statement_uidx" ON "np_agent_approvals" USING btree ("site_id","target_kind","target_id","plan_hash") WHERE "np_agent_approvals"."state" in ('pending','approved');--> statement-breakpoint
CREATE INDEX "np_agent_approvals_expiry_idx" ON "np_agent_approvals" USING btree ("site_id","state","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_changeset_executions_recovery_idx" ON "np_agent_changeset_executions" USING btree ("site_id","state","lease_until","id");--> statement-breakpoint
CREATE INDEX "np_agent_changeset_previews_state_idx" ON "np_agent_changeset_previews" USING btree ("site_id","state","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_changeset_rollback_plans_active_unique" ON "np_agent_changeset_rollback_plans" USING btree ("site_id","changeset_id") WHERE "np_agent_changeset_rollback_plans"."state" in ('preparing','ready','approval_pending','approved','executing');--> statement-breakpoint
CREATE INDEX "np_agent_changeset_rollback_plans_expiry_idx" ON "np_agent_changeset_rollback_plans" USING btree ("site_id","state","expires_at","id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_changeset_validation_attempts_active_unique" ON "np_agent_changeset_validation_attempts" USING btree ("site_id","changeset_id") WHERE "np_agent_changeset_validation_attempts"."state" in ('queued','validating');--> statement-breakpoint
CREATE INDEX "np_agent_changeset_validation_attempts_expiry_idx" ON "np_agent_changeset_validation_attempts" USING btree ("site_id","state","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_changesets_site_state_idx" ON "np_agent_changesets" USING btree ("site_id","state","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_changesets_principal_idx" ON "np_agent_changesets" USING btree ("site_id","principal_id","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_changesets_invocation_idx" ON "np_agent_changesets" USING btree ("site_id","invocation_id");--> statement-breakpoint
CREATE INDEX "np_agent_changesets_expiry_idx" ON "np_agent_changesets" USING btree ("site_id","state","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_circuit_breakers_state_idx" ON "np_agent_circuit_breakers" USING btree ("site_id","state","retry_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_connection_auth_requests_pending_uidx" ON "np_agent_connection_auth_requests" USING btree ("site_id","connection_id") WHERE "np_agent_connection_auth_requests"."status" = 'pending';--> statement-breakpoint
CREATE INDEX "np_agent_connection_auth_requests_expiry_idx" ON "np_agent_connection_auth_requests" USING btree ("site_id","status","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_connection_config_versions_active_uidx" ON "np_agent_connection_config_versions" USING btree ("site_id","connection_id") WHERE "np_agent_connection_config_versions"."state" = 'active';--> statement-breakpoint
CREATE INDEX "np_agent_connection_config_versions_connection_idx" ON "np_agent_connection_config_versions" USING btree ("site_id","connection_id","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_connection_operations_claim_idx" ON "np_agent_connection_operations" USING btree ("site_id","state","lease_until");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_connection_secret_versions_active_uidx" ON "np_agent_connection_secret_versions" USING btree ("site_id","connection_id") WHERE "np_agent_connection_secret_versions"."status" = 'active' and "np_agent_connection_secret_versions"."purpose" = 'connection-credential';--> statement-breakpoint
CREATE INDEX "np_agent_connection_secret_versions_connection_idx" ON "np_agent_connection_secret_versions" USING btree ("site_id","connection_id","status");--> statement-breakpoint
CREATE INDEX "np_agent_connection_secret_versions_expiry_idx" ON "np_agent_connection_secret_versions" USING btree ("site_id","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_connections_site_status_idx" ON "np_agent_connections" USING btree ("site_id","status","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_connections_active_secret_idx" ON "np_agent_connections" USING btree ("active_secret_version_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_containments_active_target_uidx" ON "np_agent_containments" USING btree ("site_id","kind","target_ref") WHERE "np_agent_containments"."state" in ('pending','active','restoring');--> statement-breakpoint
CREATE INDEX "np_agent_containments_incident_idx" ON "np_agent_containments" USING btree ("site_id","incident_id");--> statement-breakpoint
CREATE INDEX "np_agent_containments_state_idx" ON "np_agent_containments" USING btree ("site_id","state","updated_at");--> statement-breakpoint
CREATE INDEX "np_agent_content_receipts_pending_idx" ON "np_agent_content_receipts" USING btree ("site_id","next_attempt_at","created_at","id") WHERE "np_agent_content_receipts"."state" in ('pending','blocked');--> statement-breakpoint
CREATE INDEX "np_agent_content_receipts_state_idx" ON "np_agent_content_receipts" USING btree ("state","site_id");--> statement-breakpoint
CREATE INDEX "np_agent_content_receipts_event_idx" ON "np_agent_content_receipts" USING btree ("site_id","emitted_event_id");--> statement-breakpoint
CREATE INDEX "np_agent_content_receipts_history_idx" ON "np_agent_content_receipts" USING btree ("site_id","created_at","id");--> statement-breakpoint
CREATE INDEX "np_agent_content_receipts_coverage_idx" ON "np_agent_content_receipts" USING btree ("site_id","occurred_at","id") WHERE "np_agent_content_receipts"."state"='emitted';--> statement-breakpoint
CREATE INDEX "np_agent_content_receipts_document_idx" ON "np_agent_content_receipts" USING btree ("site_id",("body"->>'collection'),("body"->>'documentId'),"occurred_at","id") WHERE "np_agent_content_receipts"."state"='emitted';--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_evaluation_reviews_supersedes_unique" ON "np_agent_evaluation_reviews" USING btree ("site_id","previous_revision_id") WHERE "np_agent_evaluation_reviews"."previous_revision_id" is not null;--> statement-breakpoint
CREATE INDEX "np_agent_evaluation_reviews_case_idx" ON "np_agent_evaluation_reviews" USING btree ("site_id","source_id","case_id","case_version","version_number");--> statement-breakpoint
CREATE INDEX "np_agent_evaluation_sources_page_idx" ON "np_agent_evaluation_sources" USING btree ("site_id","id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_events_deduplication_uidx" ON "np_agent_events" USING btree ("site_id","source_kind","source_component","kind","deduplication_key") WHERE "np_agent_events"."deduplication_key" is not null;--> statement-breakpoint
CREATE INDEX "np_agent_events_recorded_idx" ON "np_agent_events" USING btree ("site_id","recorded_at");--> statement-breakpoint
CREATE INDEX "np_agent_events_kind_idx" ON "np_agent_events" USING btree ("site_id","kind","recorded_at");--> statement-breakpoint
CREATE INDEX "np_agent_events_undispatched_idx" ON "np_agent_events" USING btree ("site_id","recorded_at") WHERE "np_agent_events"."dispatched_at" is null;--> statement-breakpoint
CREATE INDEX "np_agent_events_expiry_idx" ON "np_agent_events" USING btree ("site_id","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_feedback_supersedes_uidx" ON "np_agent_feedback" USING btree ("site_id","supersedes_id") WHERE "np_agent_feedback"."supersedes_id" is not null;--> statement-breakpoint
CREATE INDEX "np_agent_feedback_target_idx" ON "np_agent_feedback" USING btree ("site_id","target_kind","target_fingerprint","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_timeline_site_source_sequence_idx" ON "np_agent_incident_timeline" USING btree ("site_id","source_id","sequence");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_incidents_active_uidx" ON "np_agent_incidents" USING btree ("site_id","category","fingerprint") WHERE "np_agent_incidents"."status" in ('open','investigating','contained','monitoring');--> statement-breakpoint
CREATE INDEX "np_agent_incidents_observed_idx" ON "np_agent_incidents" USING btree ("site_id","last_observed_at","id");--> statement-breakpoint
CREATE INDEX "np_agent_incidents_updated_idx" ON "np_agent_incidents" USING btree ("site_id","updated_at","id");--> statement-breakpoint
CREATE INDEX "np_agent_incidents_status_idx" ON "np_agent_incidents" USING btree ("site_id","status","last_observed_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_invocations_idempotency_uidx" ON "np_agent_invocations" USING btree ("site_id","actor_kind","actor_fingerprint","authorization_context_fingerprint","operation_kind","operation_id","idempotency_key") WHERE "np_agent_invocations"."idempotency_key" is not null;--> statement-breakpoint
CREATE INDEX "np_agent_invocations_site_state_idx" ON "np_agent_invocations" USING btree ("site_id","state","requested_at");--> statement-breakpoint
CREATE INDEX "np_agent_invocations_principal_idx" ON "np_agent_invocations" USING btree ("site_id","principal_id");--> statement-breakpoint
CREATE INDEX "np_agent_invocations_audit_idx" ON "np_agent_invocations" USING btree ("site_id","audit_event_id");--> statement-breakpoint
CREATE INDEX "np_agent_invocations_expiry_idx" ON "np_agent_invocations" USING btree ("site_id","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_mcp_tasks_site_status_idx" ON "np_agent_mcp_tasks" USING btree ("site_id","status","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_mcp_tasks_authorization_idx" ON "np_agent_mcp_tasks" USING btree ("site_id","principal_id","authorization_context_fingerprint","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_notifications_delivery_idx" ON "np_agent_notifications" USING btree ("site_id","state","next_attempt_at");--> statement-breakpoint
CREATE INDEX "np_agent_oauth_clients_site_status_idx" ON "np_agent_oauth_clients" USING btree ("site_id","status");--> statement-breakpoint
CREATE INDEX "np_agent_oauth_codes_expiry_idx" ON "np_agent_oauth_codes" USING btree ("site_id","status","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_oauth_grants_active_uidx" ON "np_agent_oauth_grants" USING btree ("site_id","client_id","staff_user_id","resource","scope_hash","exposure_mode") WHERE "np_agent_oauth_grants"."status" = 'active';--> statement-breakpoint
CREATE INDEX "np_agent_oauth_grants_principal_idx" ON "np_agent_oauth_grants" USING btree ("site_id","principal_id");--> statement-breakpoint
CREATE INDEX "np_agent_oauth_grants_expiry_idx" ON "np_agent_oauth_grants" USING btree ("site_id","status","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_oauth_refresh_tokens_active_leaf_uidx" ON "np_agent_oauth_refresh_tokens" USING btree ("site_id","family_id") WHERE "np_agent_oauth_refresh_tokens"."status" = 'active';--> statement-breakpoint
CREATE INDEX "np_agent_oauth_refresh_tokens_expiry_idx" ON "np_agent_oauth_refresh_tokens" USING btree ("site_id","status","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_oauth_requests_expiry_idx" ON "np_agent_oauth_requests" USING btree ("site_id","status","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_policies_site_number_uidx" ON "np_agent_policies" USING btree ("site_id","version") WHERE "np_agent_policies"."agent_id" is null;--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_policies_agent_number_uidx" ON "np_agent_policies" USING btree ("site_id","agent_id","version") WHERE "np_agent_policies"."agent_id" is not null;--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_policies_site_active_uidx" ON "np_agent_policies" USING btree ("site_id") WHERE "np_agent_policies"."agent_id" is null and "np_agent_policies"."status"='active';--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_policies_agent_active_uidx" ON "np_agent_policies" USING btree ("site_id","agent_id") WHERE "np_agent_policies"."agent_id" is not null and "np_agent_policies"."status"='active';--> statement-breakpoint
CREATE INDEX "np_agent_policies_site_status_idx" ON "np_agent_policies" USING btree ("site_id","status","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_preview_artifact_uploads_state_idx" ON "np_agent_preview_artifact_uploads" USING btree ("site_id","state","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_preview_artifacts_capture_unique" ON "np_agent_preview_artifacts" USING btree ("preview_id","kind",coalesce("route",''),coalesce("locale",''),coalesce("viewport"->>'name',''),coalesce("report_part",0));--> statement-breakpoint
CREATE INDEX "np_agent_preview_artifacts_cleanup_idx" ON "np_agent_preview_artifacts" USING btree ("site_id","object_state","metadata_prune_at");--> statement-breakpoint
CREATE INDEX "np_agent_preview_render_sessions_expiry_idx" ON "np_agent_preview_render_sessions" USING btree ("site_id","state","expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_preview_viewer_launches_active_unique" ON "np_agent_preview_viewer_launches" USING btree ("preview_id","staff_session_id") WHERE "np_agent_preview_viewer_launches"."state" in ('exchange_pending','active');--> statement-breakpoint
CREATE INDEX "np_agent_preview_viewer_launches_site_state_idx" ON "np_agent_preview_viewer_launches" USING btree ("site_id","state","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_principals_site_status_idx" ON "np_agent_principals" USING btree ("site_id","status","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_principals_authority_user_idx" ON "np_agent_principals" USING btree ("authority_user_id");--> statement-breakpoint
CREATE INDEX "np_agent_provider_calls_state_idx" ON "np_agent_provider_calls" USING btree ("site_id","state","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_restriction_enforcements_subject_idx" ON "np_agent_restriction_enforcements" USING btree ("site_id","subject_key","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_runs_site_state_idx" ON "np_agent_runs" USING btree ("site_id","state","queued_at");--> statement-breakpoint
CREATE INDEX "np_agent_runs_principal_idx" ON "np_agent_runs" USING btree ("site_id","principal_id","queued_at");--> statement-breakpoint
CREATE INDEX "np_agent_runs_deadline_idx" ON "np_agent_runs" USING btree ("site_id","deadline_at");--> statement-breakpoint
CREATE INDEX "np_agent_runs_agent_idx" ON "np_agent_runs" USING btree ("site_id","agent_id","queued_at");--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_pending_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","next_attempt_at","created_at","id") WHERE "np_agent_runtime_receipts"."state" in ('pending','blocked');--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_state_idx" ON "np_agent_runtime_receipts" USING btree ("state","site_id");--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_event_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","emitted_event_id");--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_history_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","created_at","id");--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_coverage_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","occurred_at","id") WHERE "np_agent_runtime_receipts"."state"='emitted';--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_cohort_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","agent_id","occurred_at","id") WHERE "np_agent_runtime_receipts"."state"='emitted';--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_run_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","run_id");--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_principal_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","principal_id");--> statement-breakpoint
CREATE INDEX "np_agent_runtime_receipts_version_idx" ON "np_agent_runtime_receipts" USING btree ("site_id","agent_version_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_service_tokens_active_head_uidx" ON "np_agent_service_tokens" USING btree ("site_id","rotation_family_id") WHERE "np_agent_service_tokens"."status" = 'active_head';--> statement-breakpoint
CREATE INDEX "np_agent_service_tokens_principal_idx" ON "np_agent_service_tokens" USING btree ("site_id","principal_id");--> statement-breakpoint
CREATE INDEX "np_agent_service_tokens_expiry_idx" ON "np_agent_service_tokens" USING btree ("site_id","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_signals_window_idx" ON "np_agent_signals" USING btree ("site_id","window_ended_at");--> statement-breakpoint
CREATE INDEX "np_agent_signals_fingerprint_idx" ON "np_agent_signals" USING btree ("site_id","fingerprint","window_ended_at");--> statement-breakpoint
CREATE INDEX "np_agent_signals_open_idx" ON "np_agent_signals" USING btree ("site_id","created_at") WHERE "np_agent_signals"."status"='open';--> statement-breakpoint
CREATE INDEX "np_agent_signals_expiry_idx" ON "np_agent_signals" USING btree ("site_id","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_site_deletion_sagas_state_idx" ON "np_agent_site_deletion_sagas" USING btree ("state","lease_until");--> statement-breakpoint
CREATE INDEX "np_agent_source_release_edges_owner_idx" ON "np_agent_source_release_edges" USING btree ("site_id","owner_kind","owner_id");--> statement-breakpoint
CREATE INDEX "np_agent_source_releases_source_idx" ON "np_agent_source_releases" USING btree ("source_id","site_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_source_releases_guardian_key_unique" ON "np_agent_source_releases" USING btree ("site_id",("evidence_body"->>'deliveryKeyDigest')) WHERE "np_agent_source_releases"."source_kind"='guardian-event';--> statement-breakpoint
CREATE INDEX "np_agent_source_releases_reservation_idx" ON "np_agent_source_releases" USING btree ("site_id",("evidence_body"->>'reservationId')) WHERE "np_agent_source_releases"."source_kind"='provider-call';--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_source_releases_key_unique" ON "np_agent_source_releases" USING btree ("site_id","principal_id","admission_key_digest") WHERE "np_agent_source_releases"."source_kind"='runtime-run';--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_triggers_logical_uidx" ON "np_agent_triggers" USING btree ("site_id","agent_id","agent_version_id","kind",coalesce("event_type","cron",''),"filter_hash");--> statement-breakpoint
CREATE INDEX "np_agent_triggers_due_idx" ON "np_agent_triggers" USING btree ("site_id","next_run_at") WHERE "np_agent_triggers"."enabled"=true and "np_agent_triggers"."kind"='schedule';--> statement-breakpoint
CREATE INDEX "np_agent_usage_daily_budget_idx" ON "np_agent_usage_daily" USING btree ("site_id","usage_date","agent_id");--> statement-breakpoint
CREATE INDEX "np_agent_usage_reservations_expiry_idx" ON "np_agent_usage_reservations" USING btree ("site_id","state","expires_at");--> statement-breakpoint
CREATE INDEX "np_agent_usage_reservations_budget_idx" ON "np_agent_usage_reservations" USING btree ("site_id","agent_id","reserved_at");--> statement-breakpoint
CREATE INDEX "np_agent_vault_entries_site_idx" ON "np_agent_vault_entries" USING btree ("site_id","created_at");--> statement-breakpoint
CREATE INDEX "np_agent_vault_operations_claim_idx" ON "np_agent_vault_operations" USING btree ("site_id","state","lease_until");--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_versions_active_uidx" ON "np_agent_versions" USING btree ("site_id","agent_id") WHERE "np_agent_versions"."status"='active';--> statement-breakpoint
CREATE UNIQUE INDEX "np_agent_versions_draft_uidx" ON "np_agent_versions" USING btree ("site_id","agent_id") WHERE "np_agent_versions"."status"='draft';--> statement-breakpoint
CREATE INDEX "np_agents_site_status_idx" ON "np_agents" USING btree ("site_id","status","created_at");