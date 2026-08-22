-- Gravity Is Optional / policy analytics, anomaly detection, and archival audit layer
-- This module can be loaded after gravity_engine.sql. It keeps the relational model
-- responsible for cross-language conformance instead of treating SQL as seed data.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS policy_measurements (
    measurement_id     INTEGER PRIMARY KEY,
    session_id         TEXT NOT NULL REFERENCES field_sessions(session_id) ON DELETE CASCADE,
    rule_id            INTEGER NOT NULL REFERENCES gravity_rules(rule_id),
    observed_at        TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    measured_angle     REAL NOT NULL CHECK(measured_angle >= 0 AND measured_angle < 360),
    measured_strength  REAL NOT NULL CHECK(measured_strength BETWEEN 0 AND 100),
    object_count       INTEGER NOT NULL CHECK(object_count >= 0),
    kinetic_total      REAL NOT NULL CHECK(kinetic_total >= 0),
    collision_count    INTEGER NOT NULL DEFAULT 0 CHECK(collision_count >= 0),
    observer_note      TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS transition_audits (
    audit_id            INTEGER PRIMARY KEY,
    session_id          TEXT NOT NULL REFERENCES field_sessions(session_id) ON DELETE CASCADE,
    from_rule_id        INTEGER REFERENCES gravity_rules(rule_id),
    to_rule_id          INTEGER NOT NULL REFERENCES gravity_rules(rule_id),
    requested_at        TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at        TEXT,
    elapsed_ms          INTEGER CHECK(elapsed_ms >= 0),
    maximum_impulse     REAL CHECK(maximum_impulse >= 0),
    displaced_objects   INTEGER NOT NULL DEFAULT 0 CHECK(displaced_objects >= 0),
    approved            INTEGER NOT NULL DEFAULT 0 CHECK(approved IN (0,1)),
    rejection_reason    TEXT
);

CREATE TABLE IF NOT EXISTS polyglot_conformance (
    conformance_id      INTEGER PRIMARY KEY,
    language_name       TEXT NOT NULL,
    module_path         TEXT NOT NULL UNIQUE,
    responsibility      TEXT NOT NULL,
    reference_case      TEXT NOT NULL,
    expected_json       TEXT NOT NULL CHECK(json_valid(expected_json)),
    last_result_json    TEXT CHECK(last_result_json IS NULL OR json_valid(last_result_json)),
    passed              INTEGER CHECK(passed IN (0,1)),
    checked_at          TEXT
);

INSERT OR REPLACE INTO polyglot_conformance
    (conformance_id,language_name,module_path,responsibility,reference_case,expected_json)
VALUES
    (1,'C','polyglot/vector_field.c','scalar field integration','ordinary-down-step','{"x":0,"y":10,"epsilon":0.001}'),
    (2,'PHP','polyglot/policy_export.php','policy manifest export','stable-sort','{"first":"ordinary_down","schema":1}'),
    (3,'PowerShell','polyglot/Test-GravitySchema.ps1','schema validation','complete-database','{"passed":true,"checks":6}'),
    (4,'Solidity','polyglot/GravityPolicy.sol','policy approval ledger','file-and-approve','{"approved":true,"angle":90}'),
    (5,'Cuda','polyglot/gravity_kernel.cu','parallel object integration','one-block-step','{"bodies":6,"errors":0}'),
    (6,'Fortran','polyglot/orbital_solver.f90','orbital energy solver','unit-orbit','{"energy":0.5,"epsilon":0.000001}'),
    (7,'Ada','polyglot/gravity_vectors.adb','range-safe policy validation','invalid-angle','{"valid":false}'),
    (8,'COBOL','polyglot/GRAVITY-REPORT.cob','policy office report','experimental-policy','{"status":"APPROVED: EXPERIMENTAL"}'),
    (9,'Prolog','polyglot/gravity_rules.pl','transition inference','ordinary-to-micro','{"reachable":true}'),
    (10,'D','polyglot/collision_audit.d','collision impulse audit','equal-mass-collision','{"notable":true}'),
    (11,'Groovy','polyglot/GravityMission.groovy','mission definition DSL','dock-six','{"target":6}'),
    (12,'Objective-C','polyglot/GOIOrientationBridge.m','orientation bridge','left-vector','{"x":-10,"y":0,"epsilon":0.001}'),
    (13,'Pascal','polyglot/gravity_policy.pas','portable policy validation','valid-down','{"valid":true}');

CREATE INDEX IF NOT EXISTS idx_measurement_session_time ON policy_measurements(session_id,observed_at);
CREATE INDEX IF NOT EXISTS idx_measurement_rule ON policy_measurements(rule_id,measured_strength);
CREATE INDEX IF NOT EXISTS idx_transition_session ON transition_audits(session_id,requested_at);
CREATE INDEX IF NOT EXISTS idx_transition_rules ON transition_audits(from_rule_id,to_rule_id);
CREATE INDEX IF NOT EXISTS idx_conformance_language ON polyglot_conformance(language_name,passed);

CREATE VIEW IF NOT EXISTS policy_accuracy AS
SELECT
    r.rule_id,
    r.slug,
    r.display_name,
    count(m.measurement_id) AS sample_count,
    round(avg(abs(m.measured_angle-r.angle_degrees)),3) AS mean_angle_error,
    round(avg(abs(m.measured_strength-r.strength_percent)),3) AS mean_strength_error,
    round(avg(m.kinetic_total),3) AS mean_kinetic_total,
    sum(m.collision_count) AS collisions_observed,
    CASE
        WHEN count(m.measurement_id)=0 THEN 'unobserved'
        WHEN avg(abs(m.measured_angle-r.angle_degrees))<2 AND avg(abs(m.measured_strength-r.strength_percent))<3 THEN 'accurate'
        WHEN avg(abs(m.measured_angle-r.angle_degrees))<8 THEN 'approximately gravity'
        ELSE 'administratively sideways'
    END AS accuracy_status
FROM gravity_rules r
LEFT JOIN policy_measurements m ON m.rule_id=r.rule_id
GROUP BY r.rule_id;

CREATE VIEW IF NOT EXISTS transition_reliability AS
SELECT
    source.slug AS from_policy,
    target.slug AS to_policy,
    count(a.audit_id) AS attempts,
    sum(CASE WHEN a.approved=1 AND a.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed,
    round(100.0*sum(CASE WHEN a.approved=1 AND a.completed_at IS NOT NULL THEN 1 ELSE 0 END)/nullif(count(a.audit_id),0),1) AS completion_percent,
    round(avg(a.elapsed_ms),1) AS mean_elapsed_ms,
    max(a.maximum_impulse) AS largest_impulse,
    sum(a.displaced_objects) AS displaced_objects
FROM transition_audits a
LEFT JOIN gravity_rules source ON source.rule_id=a.from_rule_id
JOIN gravity_rules target ON target.rule_id=a.to_rule_id
GROUP BY a.from_rule_id,a.to_rule_id;

CREATE VIEW IF NOT EXISTS polyglot_status AS
SELECT
    language_name,
    module_path,
    responsibility,
    CASE
        WHEN passed=1 THEN 'conforming'
        WHEN passed=0 THEN 'disagrees with gravity'
        ELSE 'awaiting inspection'
    END AS status,
    checked_at,
    json_extract(expected_json,'$') AS expected,
    json_extract(last_result_json,'$') AS observed
FROM polyglot_conformance
ORDER BY language_name;

CREATE VIEW IF NOT EXISTS session_field_report AS
WITH current_measurement AS (
    SELECT m.*,row_number() OVER(PARTITION BY m.session_id ORDER BY m.observed_at DESC,m.measurement_id DESC) AS sequence
    FROM policy_measurements m
), event_totals AS (
    SELECT session_id,count(*) AS event_count,count(DISTINCT event_type) AS event_kinds
    FROM interaction_log GROUP BY session_id
)
SELECT
    s.session_id,
    r.slug AS active_policy,
    mission.slug AS active_mission,
    s.paused,
    s.object_set,
    coalesce(m.measured_angle,r.angle_degrees) AS effective_angle,
    coalesce(m.measured_strength,s.custom_strength,r.strength_percent) AS effective_strength,
    coalesce(m.object_count,0) AS objects_observed,
    coalesce(m.kinetic_total,0) AS kinetic_total,
    coalesce(e.event_count,0) AS events_recorded,
    coalesce(e.event_kinds,0) AS distinct_event_kinds,
    CASE WHEN p.completed=1 THEN 'complete' ELSE 'in progress' END AS mission_status
FROM field_sessions s
JOIN gravity_rules r ON r.rule_id=s.active_rule_id
JOIN missions mission ON mission.mission_id=s.active_mission_id
LEFT JOIN current_measurement m ON m.session_id=s.session_id AND m.sequence=1
LEFT JOIN event_totals e ON e.session_id=s.session_id
LEFT JOIN mission_progress p ON p.session_id=s.session_id AND p.mission_id=s.active_mission_id;

CREATE TRIGGER IF NOT EXISTS audit_transition_before_insert
BEFORE INSERT ON transition_audits
BEGIN
    SELECT CASE
        WHEN NEW.from_rule_id IS NOT NULL AND NOT EXISTS(
            SELECT 1 FROM allowed_transitions
            WHERE from_rule_id=NEW.from_rule_id AND to_rule_id=NEW.to_rule_id
        ) THEN RAISE(ABORT,'transition is not approved by the gravity office')
    END;
END;

CREATE TRIGGER IF NOT EXISTS audit_transition_after_complete
AFTER UPDATE OF completed_at ON transition_audits
WHEN OLD.completed_at IS NULL AND NEW.completed_at IS NOT NULL
BEGIN
    INSERT INTO interaction_log(session_id,event_type,rule_id,value_numeric,value_text)
    VALUES(NEW.session_id,'rule_change',NEW.to_rule_id,NEW.maximum_impulse,json_object('audit_id',NEW.audit_id,'elapsed_ms',NEW.elapsed_ms,'displaced_objects',NEW.displaced_objects));
END;

CREATE TRIGGER IF NOT EXISTS measurement_angle_guard
BEFORE INSERT ON policy_measurements
WHEN abs(NEW.measured_angle-(SELECT angle_degrees FROM gravity_rules WHERE rule_id=NEW.rule_id))>45
BEGIN
    SELECT RAISE(ABORT,'measurement disagrees with filed direction by more than forty-five degrees');
END;

CREATE TRIGGER IF NOT EXISTS conformance_result_guard
BEFORE UPDATE OF last_result_json,passed ON polyglot_conformance
WHEN NEW.last_result_json IS NULL OR json_valid(NEW.last_result_json)=0
BEGIN
    SELECT RAISE(ABORT,'polyglot result must be valid JSON');
END;

CREATE VIEW IF NOT EXISTS gravity_anomalies AS
SELECT 'unstable_public_policy' AS anomaly,r.slug AS subject,r.stability AS magnitude
FROM gravity_rules r WHERE r.public_rule=1 AND r.stability<35
UNION ALL
SELECT 'unusually_forceful_transition',cast(a.audit_id AS TEXT),round(a.maximum_impulse,2)
FROM transition_audits a WHERE a.maximum_impulse>25
UNION ALL
SELECT 'collision_weather',m.session_id,sum(m.collision_count)
FROM policy_measurements m GROUP BY m.session_id HAVING sum(m.collision_count)>20
UNION ALL
SELECT 'polyglot_disagreement',language_name,0
FROM polyglot_conformance WHERE passed=0;

CREATE VIEW IF NOT EXISTS audit_integrity_report AS
SELECT
    (SELECT count(*)=13 FROM polyglot_conformance) AS all_language_modules_registered,
    (SELECT count(DISTINCT language_name)=13 FROM polyglot_conformance) AS language_names_unique,
    (SELECT count(*)=0 FROM polyglot_conformance WHERE json_valid(expected_json)=0) AS expectations_are_json,
    (SELECT count(*)=0 FROM policy_measurements WHERE measured_angle<0 OR measured_angle>=360) AS angles_in_range,
    (SELECT count(*)=0 FROM policy_measurements WHERE measured_strength<0 OR measured_strength>100) AS strengths_in_range,
    (SELECT count(*)=0 FROM transition_audits WHERE approved=0 AND completed_at IS NOT NULL) AS rejected_transitions_incomplete,
    (SELECT count(*)>=8 FROM gravity_rules) AS gravity_policy_catalog_present,
    (SELECT count(*)>=6 FROM object_catalog) AS object_catalog_present,
    (SELECT count(*)>=3 FROM missions) AS mission_catalog_present,
    (SELECT count(*)>=1 FROM allowed_transitions) AS transition_graph_present;
