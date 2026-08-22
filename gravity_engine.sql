-- Gravity Is Optional / orientation-office relational rule engine
-- SQLite 3.45+
--
-- This database is the project's source of truth. The static browser adapter
-- ships a compiled subset of these relations so GitHub Pages needs no server,
-- sign-in, API key, or remote database. Every visible policy, object mass,
-- mission, message, and allowed transition originates in this SQL model.

PRAGMA foreign_keys = ON;
PRAGMA recursive_triggers = ON;

BEGIN IMMEDIATE;

CREATE TABLE schema_revisions (
    revision_id       INTEGER PRIMARY KEY,
    applied_at        TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description       TEXT NOT NULL,
    checksum_note     TEXT NOT NULL
);

CREATE TABLE gravity_rules (
    rule_id            INTEGER PRIMARY KEY,
    slug               TEXT NOT NULL UNIQUE,
    display_name       TEXT NOT NULL,
    angle_degrees      REAL NOT NULL CHECK(angle_degrees >= 0 AND angle_degrees < 360),
    strength_percent   REAL NOT NULL CHECK(strength_percent >= 0 AND strength_percent <= 100),
    glyph              TEXT NOT NULL,
    accent_hex         TEXT NOT NULL CHECK(accent_hex GLOB '#[0-9A-Fa-f]*'),
    field_message      TEXT NOT NULL,
    policy_sql         TEXT NOT NULL,
    category           TEXT NOT NULL CHECK(category IN ('cardinal','diagonal','microgravity','experimental','weather','office')),
    stability          INTEGER NOT NULL DEFAULT 50 CHECK(stability BETWEEN 0 AND 100),
    public_rule        INTEGER NOT NULL DEFAULT 1 CHECK(public_rule IN (0,1)),
    sort_order         INTEGER NOT NULL,
    created_at         TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE object_catalog (
    object_id          INTEGER PRIMARY KEY,
    slug               TEXT NOT NULL UNIQUE,
    display_label      TEXT NOT NULL,
    object_set         INTEGER NOT NULL CHECK(object_set BETWEEN 1 AND 8),
    mass_units         REAL NOT NULL CHECK(mass_units > 0),
    width_units        INTEGER NOT NULL CHECK(width_units BETWEEN 40 AND 180),
    height_units       INTEGER NOT NULL CHECK(height_units BETWEEN 24 AND 110),
    restitution        REAL NOT NULL DEFAULT .72 CHECK(restitution BETWEEN 0 AND 1),
    drag_factor        REAL NOT NULL DEFAULT .998 CHECK(drag_factor > 0 AND drag_factor <= 1),
    accent_hex         TEXT NOT NULL,
    archival_note      TEXT NOT NULL,
    active             INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1))
);

CREATE TABLE missions (
    mission_id         INTEGER PRIMARY KEY,
    slug               TEXT NOT NULL UNIQUE,
    kicker             TEXT NOT NULL,
    title              TEXT NOT NULL,
    instructions       TEXT NOT NULL,
    metric             TEXT NOT NULL CHECK(metric IN ('docked_objects','elapsed_microgravity','sideways_weather','collisions','manual_drags','rule_changes')),
    target_value       REAL NOT NULL CHECK(target_value > 0),
    completion_message TEXT NOT NULL,
    sort_order         INTEGER NOT NULL
);

CREATE TABLE field_messages (
    message_id         INTEGER PRIMARY KEY,
    event_key          TEXT NOT NULL,
    message_text       TEXT NOT NULL,
    tone_hz            INTEGER CHECK(tone_hz BETWEEN 40 AND 1800),
    tone_shape         TEXT CHECK(tone_shape IN ('sine','triangle','square','sawtooth')),
    priority           INTEGER NOT NULL DEFAULT 50 CHECK(priority BETWEEN 0 AND 100),
    UNIQUE(event_key, message_text)
);

CREATE TABLE allowed_transitions (
    transition_id      INTEGER PRIMARY KEY,
    from_rule_id       INTEGER REFERENCES gravity_rules(rule_id) ON DELETE CASCADE,
    to_rule_id         INTEGER NOT NULL REFERENCES gravity_rules(rule_id) ON DELETE CASCADE,
    transition_name    TEXT NOT NULL,
    impulse_x          REAL NOT NULL DEFAULT 0,
    impulse_y          REAL NOT NULL DEFAULT 0,
    transition_ms      INTEGER NOT NULL CHECK(transition_ms BETWEEN 80 AND 5000),
    requires_gust      INTEGER NOT NULL DEFAULT 0 CHECK(requires_gust IN (0,1)),
    UNIQUE(from_rule_id,to_rule_id)
);

CREATE TABLE field_sessions (
    session_id         TEXT PRIMARY KEY,
    started_at         TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active_rule_id     INTEGER NOT NULL REFERENCES gravity_rules(rule_id),
    active_mission_id  INTEGER NOT NULL REFERENCES missions(mission_id),
    paused             INTEGER NOT NULL DEFAULT 0 CHECK(paused IN (0,1)),
    sound_enabled      INTEGER NOT NULL DEFAULT 1 CHECK(sound_enabled IN (0,1)),
    custom_strength    REAL CHECK(custom_strength BETWEEN 0 AND 100),
    custom_angle       REAL CHECK(custom_angle >= 0 AND custom_angle < 360),
    object_set         INTEGER NOT NULL DEFAULT 1 CHECK(object_set BETWEEN 1 AND 8)
);

CREATE TABLE object_states (
    session_id         TEXT NOT NULL REFERENCES field_sessions(session_id) ON DELETE CASCADE,
    object_id          INTEGER NOT NULL REFERENCES object_catalog(object_id),
    position_x         REAL NOT NULL,
    position_y         REAL NOT NULL,
    velocity_x         REAL NOT NULL DEFAULT 0,
    velocity_y         REAL NOT NULL DEFAULT 0,
    rotation_radians   REAL NOT NULL DEFAULT 0,
    spin_rate          REAL NOT NULL DEFAULT 0,
    docked             INTEGER NOT NULL DEFAULT 0 CHECK(docked IN (0,1)),
    last_updated_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(session_id,object_id)
);

CREATE TABLE interaction_log (
    interaction_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id         TEXT NOT NULL REFERENCES field_sessions(session_id) ON DELETE CASCADE,
    occurred_at        TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type         TEXT NOT NULL CHECK(event_type IN ('rule_change','strength_change','gust','freeze','unfreeze','drag','dock','collision','mission_change','reset','shuffle','sound_change')),
    object_id          INTEGER REFERENCES object_catalog(object_id),
    rule_id            INTEGER REFERENCES gravity_rules(rule_id),
    value_numeric      REAL,
    value_text         TEXT
);

CREATE TABLE mission_progress (
    session_id         TEXT NOT NULL REFERENCES field_sessions(session_id) ON DELETE CASCADE,
    mission_id         INTEGER NOT NULL REFERENCES missions(mission_id),
    current_value      REAL NOT NULL DEFAULT 0 CHECK(current_value >= 0),
    completed          INTEGER NOT NULL DEFAULT 0 CHECK(completed IN (0,1)),
    completed_at       TEXT,
    PRIMARY KEY(session_id,mission_id)
);

CREATE TABLE field_presets (
    preset_id          INTEGER PRIMARY KEY,
    preset_name        TEXT NOT NULL UNIQUE,
    rule_id            INTEGER NOT NULL REFERENCES gravity_rules(rule_id),
    mission_id         INTEGER NOT NULL REFERENCES missions(mission_id),
    object_set         INTEGER NOT NULL,
    starting_message   TEXT NOT NULL,
    featured           INTEGER NOT NULL DEFAULT 0 CHECK(featured IN (0,1))
);

INSERT INTO schema_revisions(revision_id,description,checksum_note) VALUES
(1,'Initial orientation-office schema','tables/rules/matter/missions'),
(2,'Added event ledger and completion projections','interaction-log/progress'),
(3,'Expanded public policy cabinet','six featured policies plus archival alternatives');

INSERT INTO gravity_rules(rule_id,slug,display_name,angle_degrees,strength_percent,glyph,accent_hex,field_message,policy_sql,category,stability,public_rule,sort_order) VALUES
(1,'standard-down','Standard Down / Unpopular',90,62,'↓','#d9ff45','THE FLOOR HAS BEEN NOTIFIED.','SELECT vector FROM gravity_rules WHERE slug = ''standard-down'';','cardinal',94,1,1),
(2,'ceiling-day','Ceiling Appreciation Day',270,58,'↑','#ff6257','THE CEILING HAS ACCEPTED NEW RESPONSIBILITIES.','UPDATE orientation SET angle = 270 WHERE room = ''office'';','cardinal',72,1,2),
(3,'eastward-office','Everything Files East',0,74,'←','#62c8ff','ALL PAPERWORK NOW FALLS TOWARD YESTERDAY.','SELECT apply_vector(0,74,''eastward-office'');','cardinal',81,1,3),
(4,'diagonal-lunch','Diagonal Lunch Break',135,52,'↘','#b8a1ff','LUNCH WILL ARRIVE AT A FORTY-FIVE DEGREE ANGLE.','CALL rotate_reality(135,''until further notice'');','diagonal',63,1,4),
(5,'soft-left','A Gentle Lean Left',180,31,'→','#ffd0a8','THE ROOM IS LEANING, BUT POLITELY.','SELECT * FROM vectors WHERE force < .35 ORDER BY doubt;','cardinal',88,1,5),
(6,'microgravity','Zero-G Filing Hour',90,0,'0G','#8ce2c4','DOWN HAS LEFT AN OUT-OF-OFFICE REPLY.','DELETE FROM gravity WHERE certainty = ''unnecessary'';','microgravity',34,1,6),
(7,'northwest-doubt','Northwest With Reservations',315,44,'↖','#f7a8d2','EVERYTHING IS FALLING TOWARD A QUESTION IN THE CORNER.','UPDATE vector SET angle=315,confidence=.44;','diagonal',58,0,7),
(8,'southwest-snack','Southwest Snack Migration',45,67,'↙','#f4c85b','ALL CRUMBS HAVE CHOSEN THE SAME HOLIDAY DESTINATION.','SELECT migrate(''crumbs'',45,67);','diagonal',77,0,8),
(9,'northeast-mail','Northeast Internal Mail',225,71,'↗','#83d3e8','THE OUTBOX IS NOW ABOVE AND SLIGHTLY TO THE RIGHT.','UPDATE mailroom SET gravity_angle=225;','diagonal',69,0,9),
(10,'right-wall-weekend','Weekend On The Right Wall',180,83,'→','#ff8a70','SATURDAY HAS ATTACHED ITSELF TO THE EASTERN WALL.','SELECT pin_day(''Saturday'',''east'');','office',76,0,10),
(11,'weak-floor','Floor, But Uncommitted',90,18,'↓','#d7eaa0','THE FLOOR WOULD PREFER NOT TO MAKE PROMISES.','UPDATE gravity_rules SET strength_percent=18 WHERE slug=''weak-floor'';','experimental',42,0,11),
(12,'strong-ceiling','Ceiling With Authority',270,96,'↑','#d45555','PLEASE SECURE ALL OPINIONS AND LOOSE PAPER.','UPDATE gravity_rules SET strength_percent=96 WHERE slug=''strong-ceiling'';','experimental',91,0,12),
(13,'almost-east','Mostly East, Emotionally South',7,49,'←','#68c6de','THE VECTOR IS TECHNICALLY EAST BUT FEELS COMPLICATED.','SELECT resolve_vector(7,49,''emotionally south'');','experimental',53,0,13),
(14,'almost-west','West After Reconsideration',188,46,'→','#a987d5','THE ROOM CHANGED ITS MIND EIGHT DEGREES AGO.','SELECT reconsider(180,8);','experimental',61,0,14),
(15,'rain-sideways','Official Sideways Weather',0,72,'←','#58b9ec','RAIN HAS BEEN INSTRUCTED TO AVOID THE GROUND.','UPDATE weather SET fall_angle=0 WHERE kind=''rain'';','weather',84,0,15),
(16,'rain-upward','Unlicensed Upward Rain',270,55,'↑','#4da6dc','THE FORECAST IS RETURNING TO THE CLOUDS.','UPDATE weather SET fall_angle=270 WHERE license IS NULL;','weather',47,0,16),
(17,'paperwork-vortex','Municipal Paperwork Vortex',33,86,'↙','#e76c65','FORMS 11-B THROUGH 14-F ARE CIRCLING RECEPTION.','SELECT vortex(''paperwork'',33,86);','office',38,0,17),
(18,'coffee-list','Coffee Falls Toward The List',122,64,'↘','#ad754e','THE MUG HAS IDENTIFIED ITS ADMINISTRATIVE PURPOSE.','SELECT attract(''coffee'',''unfinished list'');','office',79,0,18),
(19,'lunch-orbit','Lunch Enters Stable Orbit',90,9,'0G','#e3aa62','SANDWICH TRAJECTORY IS ACCEPTABLE.','UPDATE lunch SET orbit=''stable'',crumbs=''pending'';','office',66,0,19),
(20,'calendar-collapse','Calendar Collapse',90,91,'↓','#ef765b','EVERY APPOINTMENT HAS FALLEN INTO THIS AFTERNOON.','SELECT collapse_calendar(CURRENT_DATE);','office',73,0,20),
(21,'monday-buoyancy','Monday Becomes Buoyant',270,23,'↑','#8ebae8','MONDAY IS RISING SLOWLY AND WITHOUT EXPLANATION.','UPDATE weekdays SET density=.23 WHERE name=''Monday'';','office',57,0,21),
(22,'friday-heavy','Friday Gains Unexpected Mass',90,88,'↓','#8f6bd8','THE WEEKEND IS NOW HARDER TO LIFT.','UPDATE weekdays SET mass=mass*1.88 WHERE name=''Friday'';','office',82,0,22),
(23,'desk-tide','Desk Tide / Incoming',162,51,'↘','#67d2b6','SMALL OBJECTS ARE GATHERING NEAR THE THIRD DRAWER.','SELECT tidal_pull(''desk'',3,.51);','experimental',64,0,23),
(24,'window-attraction','Window-Side Attraction',0,39,'←','#78c9f0','EVERYTHING WOULD LIKE TO SEE OUTSIDE.','SELECT attract_all(''window'',.39);','office',75,0,24),
(25,'door-repulsion','Doorway Repulsion',180,69,'→','#fb776c','THE EXIT HAS BECOME TEMPORARILY UNPOPULAR.','SELECT repel_all(''door'',.69);','office',68,0,25),
(26,'quiet-corner','Quiet Corner Singularity',315,77,'↖','#8e87e4','ALL UNFINISHED THOUGHTS ARE COLLECTING NORTHWEST.','SELECT singularity(''quiet corner'',.77);','experimental',44,0,26),
(27,'noon-inversion','Noon Inversion',270,62,'↑','#f2d864','UP AND DOWN WILL EXCHANGE SHIFTS AT TWELVE.','SELECT invert_at(''12:00'');','experimental',71,0,27),
(28,'five-pm-release','Five O’Clock Release',270,37,'↑','#eb8e77','EVERYTHING NOT BOLTED DOWN MAY GO HOME.','DELETE FROM restraint WHERE clock >= ''17:00'';','office',59,0,28),
(29,'gentle-southwest','Gentle Southwest Suggestion',45,22,'↙','#bedb8d','THE FIELD HAS MADE A QUIET RECOMMENDATION.','SELECT suggest_vector(45,.22);','diagonal',92,0,29),
(30,'urgent-northeast','Urgent Northeast Escalation',225,93,'↗','#ef5e70','ALL MATTER HAS BEEN MARKED HIGH PRIORITY.','UPDATE matter SET priority=''urgent'',angle=225;','diagonal',86,0,30),
(31,'uncertain-zero','Microgravity With Doubts',90,3,'0G','#a8dfcf','A TRACE AMOUNT OF DOWN REMAINS IN THE SYSTEM.','SELECT residual_gravity(.03);','microgravity',29,0,31),
(32,'perfect-zero','Perfectly Filed Nothing',0,0,'0G','#ded7f2','NO VECTOR FOUND. THIS IS NOT AN ERROR.','SELECT NULL AS down WHERE FALSE;','microgravity',100,0,32);

INSERT INTO object_catalog(object_id,slug,display_label,object_set,mass_units,width_units,height_units,restitution,drag_factor,accent_hex,archival_note) VALUES
(1,'lost-key','LOST KEY',1,1.2,112,60,.74,.998,'#d9ff45','Found beneath a floor that no longer points down.'),
(2,'monday','MONDAY',1,2.4,112,60,.66,.997,'#ff6257','Heavier before noon and unexpectedly buoyant after five.'),
(3,'small-moon','SMALL MOON',1,3.2,112,60,.61,.996,'#62c8ff','Property of the municipal night office; return after orbit.'),
(4,'paper-clip','PAPER CLIP',1,.7,112,60,.81,.999,'#b8a1ff','Known to attach itself to unrelated trajectories.'),
(5,'one-idea','ONE IDEA',1,1.5,112,60,.77,.998,'#ffd0a8','Incomplete, bright at the edges, not yet peer reviewed.'),
(6,'lunch','LUNCH',1,2.1,112,60,.63,.997,'#8ce2c4','Scheduled for 12:30; currently orbiting reception.'),
(7,'unsent-note','UNSENT NOTE',2,.8,112,60,.83,.999,'#ff6257','Addressed to nobody and therefore everyone.'),
(8,'spare-hour','SPARE HOUR',2,1.7,112,60,.72,.998,'#62c8ff','Recovered between 2:14 and 3:14 on an unknown Tuesday.'),
(9,'tiny-planet','TINY PLANET',2,3.6,112,60,.58,.995,'#d9ff45','Local weather: mostly desk lamp with scattered eraser dust.'),
(10,'office-plant','OFFICE PLANT',2,2.8,112,60,.59,.996,'#8ce2c4','Leans toward attention instead of light.'),
(11,'maybe','MAYBE',2,1.1,112,60,.79,.999,'#b8a1ff','Mass fluctuates when observed directly.'),
(12,'receipt','RECEIPT',2,.6,112,60,.86,.999,'#ffd0a8','Proof of a purchase nobody remembers making.'),
(13,'blue-tuesday','BLUE TUESDAY',3,2.2,112,60,.68,.997,'#62c8ff','Not the weekday itself; only its atmospheric pressure.'),
(14,'door-four','DOOR 04',3,3.1,112,60,.6,.996,'#d9ff45','Opens into the same room at a more interesting angle.'),
(15,'quiet-noise','QUIET NOISE',3,1.3,112,60,.78,.998,'#b8a1ff','Audible only while moving away.'),
(16,'future-sock','FUTURE SOCK',3,.9,112,60,.82,.999,'#ff6257','Its matching pair has not happened yet.'),
(17,'half-map','HALF A MAP',3,1.8,112,60,.7,.998,'#ffd0a8','The missing half insists this is the correct side.'),
(18,'last-email','LAST EMAIL',3,2.5,112,60,.65,.997,'#8ce2c4','Marked urgent by somebody who has already logged off.'),
(19,'borrowed-shadow','BORROWED SHADOW',4,1.4,118,58,.76,.998,'#806de0','Please return before the original object notices.'),
(20,'soft-deadline','SOFT DEADLINE',4,2.7,118,58,.62,.996,'#ff897e','Becomes rigid approximately twelve minutes before impact.'),
(21,'wrong-floor','WRONG FLOOR',4,4.2,118,58,.51,.994,'#d9ff45','Removed from Elevator B during routine orientation.'),
(22,'little-weather','LITTLE WEATHER',4,1.6,118,58,.73,.998,'#62c8ff','One pocket-sized front with uncertain precipitation.'),
(23,'archived-wave','ARCHIVED WAVE',4,2.0,118,58,.69,.997,'#8ce2c4','Previously part of an ocean; paperwork complete.'),
(24,'doorbell-memory','DOORBELL MEMORY',4,1.0,118,58,.8,.999,'#ffd0a8','Rings only after everyone has gone.'),
(25,'folded-distance','FOLDED DISTANCE',5,2.9,116,62,.61,.996,'#b8a1ff','Measures three blocks while closed and seven while open.'),
(26,'spare-horizon','SPARE HORIZON',5,3.4,116,62,.57,.995,'#ff6257','Useful when the usual horizon is being serviced.'),
(27,'tiny-applause','TINY APPLAUSE',5,.7,116,62,.85,.999,'#d9ff45','One audience member, recorded from very far away.'),
(28,'second-morning','SECOND MORNING',5,2.3,116,62,.67,.997,'#62c8ff','Issued after the first morning failed inspection.'),
(29,'loose-coordinate','LOOSE COORDINATE',5,1.2,116,62,.79,.998,'#8ce2c4','May point to a place or simply a very confident number.'),
(30,'careful-comet','CAREFUL COMET',5,3.8,116,62,.55,.994,'#ffd0a8','Travels slowly near breakable ideas.'),
(31,'forgotten-password','FORGOTTEN PASSWORD',6,1.9,120,56,.71,.997,'#ff6257','Contains one capital letter and no remaining certainty.'),
(32,'temporary-north','TEMPORARY NORTH',6,2.6,120,56,.64,.996,'#62c8ff','Valid until the compass remembers its previous commitment.'),
(33,'minor-miracle','MINOR MIRACLE',6,1.4,120,56,.76,.998,'#d9ff45','Approved for indoor use under ordinary lighting.'),
(34,'paper-eclipse','PAPER ECLIPSE',6,.8,120,56,.84,.999,'#b8a1ff','Briefly blocks the desk lamp and several responsibilities.'),
(35,'borrowed-gravity','BORROWED GRAVITY',6,3.3,120,56,.58,.995,'#8ce2c4','Return with the same direction and approximately the same force.'),
(36,'warm-static','WARM STATIC',6,1.1,120,56,.8,.998,'#ffd0a8','Collected from a radio between stations and summers.'),
(37,'leftover-sunset','LEFTOVER SUNSET',7,2.1,114,60,.68,.997,'#ff897e','Refrigerate after opening; colors may separate.'),
(38,'unfinished-stair','UNFINISHED STAIR',7,4.0,114,60,.53,.994,'#d9ff45','Leads upward regardless of the current definition of upward.'),
(39,'small-permission','SMALL PERMISSION',7,.9,114,60,.82,.999,'#62c8ff','Enough to begin, not enough to become sensible.'),
(40,'misplaced-pause','MISPLACED PAUSE',7,1.5,114,60,.74,.998,'#b8a1ff','Recovered from the middle of an interrupted sentence.'),
(41,'portable-corner','PORTABLE CORNER',7,3.0,114,60,.6,.996,'#8ce2c4','Allows any room to have one additional place to think.'),
(42,'almost-answer','ALMOST ANSWER',7,1.3,114,60,.78,.998,'#ffd0a8','Fits most questions if viewed from a sufficient angle.'),
(43,'night-receipt','NIGHT RECEIPT',8,.7,110,58,.85,.999,'#806de0','Itemized proof that darkness was delivered as requested.'),
(44,'spare-window','SPARE WINDOW',8,3.5,110,58,.56,.995,'#62c8ff','View sold separately; latch remembers another building.'),
(45,'minute-forty','MINUTE 40',8,1.0,110,58,.81,.999,'#d9ff45','Removed from an hour that was running slightly long.'),
(46,'quiet-ladder','QUIET LADDER',8,3.7,110,58,.54,.994,'#8ce2c4','Makes no promise about which direction it climbs.'),
(47,'weather-button','WEATHER BUTTON',8,1.6,110,58,.73,.998,'#ff6257','Do not press during already interesting conditions.'),
(48,'untitled-object','UNTITLED OBJECT',8,2.2,110,58,.67,.997,'#ffd0a8','The naming committee has been gently falling since April.');

INSERT INTO missions(mission_id,slug,kicker,title,instructions,metric,target_value,completion_message,sort_order) VALUES
(1,'dock','ASSIGNMENT 01 / MISPLACED MATTER','Deliver six things to the docking bay.','Change the direction of gravity until every object crosses the striped bay. There is no correct down—only useful momentum.','docked_objects',6,'COMPLETE / PHYSICS IMPRESSED',1),
(2,'orbit','ASSIGNMENT 02 / ADMINISTRATIVE ORBIT','Keep the office in microgravity for twelve seconds.','Reduce the field below twenty-three percent. The filing system would like one complete uninterrupted orbit.','elapsed_microgravity',12,'COMPLETE / ORBIT FILED',2),
(3,'rain','ASSIGNMENT 03 / SIDEWAYS WEATHER','Make the rain fall completely sideways.','Point gravity due east and maintain the contradiction until the weather office gives up.','sideways_weather',100,'COMPLETE / FORECAST DENIED',3),
(4,'collision-study','ASSIGNMENT 04 / IMPACT PAPERWORK','Record twenty polite collisions.','Allow matter to meet the boundaries often enough to complete Form 8-G.','collisions',20,'COMPLETE / IMPACTS NOTARIZED',4),
(5,'manual-review','ASSIGNMENT 05 / HANDS-ON REALITY','Manually relocate every object once.','Drag each item through the field so it knows a person is paying attention.','manual_drags',6,'COMPLETE / MATTER REASSURED',5),
(6,'policy-tour','ASSIGNMENT 06 / POLICY TOUR','Activate all six public rules.','Give every approved alternative to down a brief and fair hearing.','rule_changes',6,'COMPLETE / COMMITTEE ADJOURNED',6);

INSERT INTO field_messages(message_id,event_key,message_text,tone_hz,tone_shape,priority) VALUES
(1,'boot','THE FLOOR HAS BEEN NOTIFIED.',220,'triangle',90),
(2,'boot','ORIENTATION OFFICE OPEN / EXPECT MINOR FALLING.',180,'triangle',75),
(3,'rule_change','ORIENTATION UPDATED / PLEASE ADJUST EXPECTATIONS.',310,'triangle',80),
(4,'rule_change','DOWN HAS BEEN REASSIGNED WITHOUT A MEETING.',280,'square',72),
(5,'rule_change','THE COMPASS HAS FILED A FORMAL OBJECTION.',245,'triangle',68),
(6,'gust','A SMALL BUT DETERMINED GUST HAS BEEN RELEASED.',160,'sawtooth',88),
(7,'gust','LOOSE PAPERWORK IS ENJOYING THE INTERRUPTION.',140,'square',64),
(8,'gust','AIR CIRCULATION EXCEEDS THE ORIGINAL BRIEF.',190,'sawtooth',70),
(9,'freeze','PHYSICS PAUSED / TAKE YOUR TIME.',120,'square',90),
(10,'unfreeze','PHYSICS HAS RELUCTANTLY RESUMED.',320,'triangle',90),
(11,'shuffle','THE LOST-AND-FOUND HAS ISSUED SIX NEW PROBLEMS.',260,'triangle',86),
(12,'shuffle','PREVIOUS MATTER RETURNED TO AN UNDISCLOSED SHELF.',210,'square',65),
(13,'dock','OBJECT ACCEPTED BY THE DOCKING BAY.',440,'triangle',92),
(14,'dock','MATTER FILED SUCCESSFULLY / PROBABLY.',520,'triangle',76),
(15,'dock','THE BAY HAS MADE ROOM FOR ONE MORE IMPOSSIBILITY.',390,'sine',73),
(16,'collision','BOUNDARY CONTACT / NO APOLOGY REQUIRED.',130,'square',40),
(17,'collision','THE WALL REMAINS WHERE IT WAS LAST SEEN.',115,'square',35),
(18,'collision','IMPACT RECORDED AS CONSTRUCTIVE FEEDBACK.',150,'triangle',38),
(19,'drag','MANUAL OVERRIDE / HUMAN GRAVITY DETECTED.',230,'triangle',55),
(20,'reset','OBJECTS RETURNED TO THEIR APPROXIMATE BEGINNING.',180,'sawtooth',78),
(21,'microgravity','DOWN HAS LEFT AN OUT-OF-OFFICE REPLY.',300,'sine',85),
(22,'microgravity','FLOATING IS NOW A VALID ADMINISTRATIVE STATE.',360,'sine',75),
(23,'mission_complete','COMPLETE / PHYSICS IMPRESSED.',660,'triangle',100),
(24,'mission_complete','THE UNIVERSE HAS STAMPED YOUR FORM.',720,'triangle',96),
(25,'sound_off','AUDIO FIELD CLOSED / SILENCE REMAINS OPTIONAL.',NULL,NULL,65),
(26,'sound_on','AUDIO FIELD RESTORED / TEST CHORD APPROVED.',440,'triangle',65),
(27,'sideways','THE WEATHER OFFICE IS PRETENDING NOT TO NOTICE.',330,'sine',78),
(28,'orbit','FILING SYSTEM ENTERING A SLOW ADMINISTRATIVE ORBIT.',280,'sine',80),
(29,'high_force','FIELD STRENGTH MAY WRINKLE THE CALENDAR.',95,'sawtooth',72),
(30,'low_force','GRAVITY IS PRESENT IN AN ADVISORY CAPACITY ONLY.',390,'sine',72),
(31,'idle','NOTHING IS FALLING URGENTLY.',NULL,NULL,25),
(32,'idle','THE ROOM IS THINKING ABOUT DIRECTION.',NULL,NULL,25),
(33,'idle','ALL OBJECTS ACCOUNTED FOR, MORE OR LESS.',NULL,NULL,25),
(34,'idle','PLEASE DO NOT FEED THE VECTOR.',NULL,NULL,25),
(35,'idle','THE FLOOR WOULD LIKE A SECOND OPINION.',NULL,NULL,25),
(36,'idle','CURRENT CONDITIONS: BEAUTIFULLY INCONCLUSIVE.',NULL,NULL,25);

INSERT INTO allowed_transitions(from_rule_id,to_rule_id,transition_name,impulse_x,impulse_y,transition_ms,requires_gust)
SELECT a.rule_id,b.rule_id,
       'REORIENT ' || upper(a.slug) || ' TO ' || upper(b.slug),
       round(cos(b.angle_degrees * 0.0174532925199433) * b.strength_percent / 100,4),
       round(sin(b.angle_degrees * 0.0174532925199433) * b.strength_percent / 100,4),
       240 + abs(a.angle_degrees-b.angle_degrees) * 4,
       CASE WHEN abs(a.angle_degrees-b.angle_degrees) > 179 THEN 1 ELSE 0 END
FROM gravity_rules a
CROSS JOIN gravity_rules b
WHERE a.rule_id <= 6 AND b.rule_id <= 6 AND a.rule_id <> b.rule_id;

INSERT INTO field_presets(preset_id,preset_name,rule_id,mission_id,object_set,starting_message,featured) VALUES
(1,'THE POLITE BEGINNING',1,1,1,'THE FLOOR HAS BEEN NOTIFIED.',1),
(2,'CEILING COMMITTEE',2,1,2,'THE CEILING HAS ACCEPTED NEW RESPONSIBILITIES.',1),
(3,'SIDEWAYS FORECAST',15,3,3,'RAIN HAS BEEN INSTRUCTED TO AVOID THE GROUND.',1),
(4,'ADMINISTRATIVE ORBIT',6,2,4,'DOWN HAS LEFT AN OUT-OF-OFFICE REPLY.',1),
(5,'FRIDAY COLLAPSE',22,4,5,'THE WEEKEND IS NOW HARDER TO LIFT.',0),
(6,'QUIET CORNER',26,5,6,'ALL UNFINISHED THOUGHTS ARE COLLECTING NORTHWEST.',0),
(7,'WINDOW HOLIDAY',24,6,7,'EVERYTHING WOULD LIKE TO SEE OUTSIDE.',0),
(8,'NO VECTOR FOUND',32,2,8,'NO VECTOR FOUND. THIS IS NOT AN ERROR.',0);

CREATE INDEX gravity_rules_public_order ON gravity_rules(public_rule,sort_order);
CREATE INDEX object_catalog_set_order ON object_catalog(object_set,object_id);
CREATE INDEX field_messages_event_priority ON field_messages(event_key,priority DESC);
CREATE INDEX interaction_log_session_time ON interaction_log(session_id,occurred_at);
CREATE INDEX object_states_docked ON object_states(session_id,docked);

CREATE VIEW public_rule_cabinet AS
SELECT rule_id,slug,display_name,angle_degrees,strength_percent,glyph,accent_hex,
       field_message,policy_sql,stability,sort_order,
       CASE
         WHEN strength_percent = 0 THEN 'NO ACTIVE VECTOR'
         WHEN angle_degrees = 0 THEN 'DUE EAST'
         WHEN angle_degrees = 45 THEN 'SOUTHWEST'
         WHEN angle_degrees = 90 THEN 'STANDARD SOUTH'
         WHEN angle_degrees = 135 THEN 'SOUTHEAST'
         WHEN angle_degrees = 180 THEN 'DUE WEST'
         WHEN angle_degrees = 225 THEN 'NORTHEAST'
         WHEN angle_degrees = 270 THEN 'CEILING / NORTH'
         WHEN angle_degrees = 315 THEN 'NORTHWEST'
         ELSE 'CUSTOM / UNVERIFIED'
       END AS orientation_label
FROM gravity_rules
WHERE public_rule = 1
ORDER BY sort_order;

CREATE VIEW active_object_sets AS
SELECT object_set,
       count(*) AS object_count,
       round(sum(mass_units),2) AS total_mass,
       round(avg(mass_units),2) AS average_mass,
       min(display_label) AS first_archival_label,
       group_concat(display_label,' / ') AS manifest
FROM object_catalog
WHERE active = 1
GROUP BY object_set
HAVING count(*) = 6;

CREATE VIEW current_field_state AS
SELECT s.session_id,s.started_at,s.paused,s.sound_enabled,s.object_set,
       r.slug AS rule_slug,r.display_name AS rule_name,
       coalesce(s.custom_angle,r.angle_degrees) AS effective_angle,
       coalesce(s.custom_strength,r.strength_percent) AS effective_strength,
       m.slug AS mission_slug,m.title AS mission_title,
       coalesce(p.current_value,0) AS mission_value,
       coalesce(p.completed,0) AS mission_completed,
       sum(CASE WHEN o.docked=1 THEN 1 ELSE 0 END) AS docked_objects,
       count(o.object_id) AS active_objects
FROM field_sessions s
JOIN gravity_rules r ON r.rule_id=s.active_rule_id
JOIN missions m ON m.mission_id=s.active_mission_id
LEFT JOIN mission_progress p ON p.session_id=s.session_id AND p.mission_id=s.active_mission_id
LEFT JOIN object_states o ON o.session_id=s.session_id
GROUP BY s.session_id;

CREATE VIEW session_telemetry AS
SELECT l.session_id,
       count(*) AS total_events,
       sum(l.event_type='collision') AS collisions,
       sum(l.event_type='drag') AS manual_drags,
       sum(l.event_type='dock') AS docking_events,
       sum(l.event_type='rule_change') AS rule_changes,
       sum(l.event_type='gust') AS gusts,
       min(l.occurred_at) AS first_event_at,
       max(l.occurred_at) AS latest_event_at
FROM interaction_log l
GROUP BY l.session_id;

CREATE VIEW mission_board AS
SELECT m.mission_id,m.slug,m.kicker,m.title,m.instructions,m.metric,m.target_value,
       p.session_id,coalesce(p.current_value,0) AS current_value,
       min(100,round(coalesce(p.current_value,0)*100.0/m.target_value,1)) AS completion_percent,
       coalesce(p.completed,0) AS completed,
       CASE WHEN coalesce(p.completed,0)=1 THEN m.completion_message ELSE 'INCOMPLETE / PROMISING' END AS status_label
FROM missions m
LEFT JOIN mission_progress p ON p.mission_id=m.mission_id;

CREATE VIEW browser_rule_export AS
SELECT json_group_array(json_object(
    'id',rule_id,
    'slug',slug,
    'name',display_name,
    'angle',angle_degrees,
    'strength',strength_percent,
    'glyph',glyph,
    'color',accent_hex,
    'message',field_message,
    'sql',policy_sql
)) AS rules_json
FROM public_rule_cabinet;

CREATE VIEW browser_object_export AS
SELECT object_set,json_group_array(json_object(
    'label',display_label,
    'mass',mass_units,
    'width',width_units,
    'height',height_units,
    'color',accent_hex,
    'note',archival_note
)) AS objects_json
FROM object_catalog
WHERE active=1
GROUP BY object_set;

CREATE TRIGGER field_session_seed_progress
AFTER INSERT ON field_sessions
BEGIN
    INSERT INTO mission_progress(session_id,mission_id,current_value,completed)
    SELECT NEW.session_id,mission_id,0,0 FROM missions;
END;

CREATE TRIGGER field_session_seed_objects
AFTER INSERT ON field_sessions
BEGIN
    INSERT INTO object_states(session_id,object_id,position_x,position_y,velocity_x,velocity_y)
    SELECT NEW.session_id,object_id,
           80 + ((row_number() OVER (ORDER BY object_id)-1) % 3) * 145,
           125 + cast((row_number() OVER (ORDER BY object_id)-1) / 3 AS INTEGER) * 125,
           0,0
    FROM object_catalog
    WHERE object_set=NEW.object_set AND active=1;
END;

CREATE TRIGGER log_rule_change
AFTER UPDATE OF active_rule_id ON field_sessions
WHEN OLD.active_rule_id <> NEW.active_rule_id
BEGIN
    INSERT INTO interaction_log(session_id,event_type,rule_id,value_text)
    VALUES(NEW.session_id,'rule_change',NEW.active_rule_id,'Policy changed through the orientation desk');
    UPDATE mission_progress
       SET current_value=current_value+1,
           completed=CASE WHEN current_value+1 >= (SELECT target_value FROM missions WHERE mission_id=6) THEN 1 ELSE completed END,
           completed_at=CASE WHEN current_value+1 >= (SELECT target_value FROM missions WHERE mission_id=6) THEN CURRENT_TIMESTAMP ELSE completed_at END
     WHERE session_id=NEW.session_id AND mission_id=6;
END;

CREATE TRIGGER log_pause_change
AFTER UPDATE OF paused ON field_sessions
WHEN OLD.paused <> NEW.paused
BEGIN
    INSERT INTO interaction_log(session_id,event_type,value_numeric,value_text)
    VALUES(NEW.session_id,CASE WHEN NEW.paused=1 THEN 'freeze' ELSE 'unfreeze' END,NEW.paused,'Field pause state changed');
END;

CREATE TRIGGER log_sound_change
AFTER UPDATE OF sound_enabled ON field_sessions
WHEN OLD.sound_enabled <> NEW.sound_enabled
BEGIN
    INSERT INTO interaction_log(session_id,event_type,value_numeric,value_text)
    VALUES(NEW.session_id,'sound_change',NEW.sound_enabled,'Local audio preference changed');
END;

CREATE TRIGGER object_docked_progress
AFTER UPDATE OF docked ON object_states
WHEN OLD.docked=0 AND NEW.docked=1
BEGIN
    INSERT INTO interaction_log(session_id,event_type,object_id,value_numeric,value_text)
    VALUES(NEW.session_id,'dock',NEW.object_id,1,'Object accepted by docking bay');
    UPDATE mission_progress
       SET current_value=(SELECT count(*) FROM object_states WHERE session_id=NEW.session_id AND docked=1),
           completed=CASE WHEN (SELECT count(*) FROM object_states WHERE session_id=NEW.session_id AND docked=1)>=6 THEN 1 ELSE 0 END,
           completed_at=CASE WHEN (SELECT count(*) FROM object_states WHERE session_id=NEW.session_id AND docked=1)>=6 THEN CURRENT_TIMESTAMP ELSE NULL END
     WHERE session_id=NEW.session_id AND mission_id=1;
END;

CREATE TRIGGER prevent_completed_object_escape
BEFORE UPDATE OF docked ON object_states
WHEN OLD.docked=1 AND NEW.docked=0
BEGIN
    SELECT RAISE(ABORT,'Docked matter requires Form 11-B before release');
END;

CREATE TRIGGER complete_progress_timestamp
AFTER UPDATE OF completed ON mission_progress
WHEN OLD.completed=0 AND NEW.completed=1 AND NEW.completed_at IS NULL
BEGIN
    UPDATE mission_progress SET completed_at=CURRENT_TIMESTAMP
    WHERE session_id=NEW.session_id AND mission_id=NEW.mission_id;
END;

-- Recursive orientation rose: used by build tooling to verify all eight user
-- directions exist, are unique, and return to the first point after one turn.
CREATE VIEW orientation_rose AS
WITH RECURSIVE points(step,angle,glyph,label) AS (
    SELECT 0,0.0,'←','EASTWARD FIELD'
    UNION ALL
    SELECT step+1,(angle+45.0)%360,
           CASE step+1 WHEN 1 THEN '↙' WHEN 2 THEN '↓' WHEN 3 THEN '↘'
                       WHEN 4 THEN '→' WHEN 5 THEN '↗' WHEN 6 THEN '↑'
                       WHEN 7 THEN '↖' ELSE '←' END,
           'ORIENTATION ' || printf('%03d',(step+1)*45)
    FROM points WHERE step<7
)
SELECT * FROM points ORDER BY step;

-- Integrity report consumed by CI. A valid build returns one row, all ones.
CREATE VIEW build_integrity_report AS
SELECT
  (SELECT count(*)=6 FROM public_rule_cabinet) AS six_public_rules,
  (SELECT count(*)=8 FROM orientation_rose) AS eight_directions,
  (SELECT min(object_count)=6 AND max(object_count)=6 FROM active_object_sets) AS six_per_object_set,
  (SELECT count(*)>=3 FROM missions) AS mission_minimum_met,
  (SELECT count(*)>=24 FROM field_messages) AS message_minimum_met,
  (SELECT count(*)=30 FROM allowed_transitions) AS public_transitions_complete,
  (SELECT json_valid(rules_json) FROM browser_rule_export) AS browser_json_valid;

CREATE TABLE orientation_test_cases (
    test_id             INTEGER PRIMARY KEY,
    test_name           TEXT NOT NULL UNIQUE,
    setup_sql           TEXT NOT NULL,
    expected_condition  TEXT NOT NULL,
    human_readable_note TEXT NOT NULL,
    test_group           TEXT NOT NULL CHECK(test_group IN ('rules','matter','missions','events','exports','accessibility'))
);

INSERT INTO orientation_test_cases(test_id,test_name,setup_sql,expected_condition,human_readable_note,test_group) VALUES
(1,'public cabinet contains exactly six rules','SELECT count(*) FROM public_rule_cabinet;','result = 6','The interface intentionally presents six memorable policies rather than exposing the full archival rule table.','rules'),
(2,'standard down points south','SELECT angle_degrees FROM gravity_rules WHERE slug=''standard-down'';','result = 90','Canvas coordinates increase downward, so ninety degrees is the conventional floor-facing vector.','rules'),
(3,'ceiling day reverses standard down','SELECT angle_degrees FROM gravity_rules WHERE slug=''ceiling-day'';','result = 270','The ceiling policy must produce the exact opposite vector without altering the stored object masses.','rules'),
(4,'microgravity has zero strength','SELECT strength_percent FROM gravity_rules WHERE slug=''microgravity'';','result = 0','Microgravity remains a named rule with an angle for display but applies no acceleration to matter.','rules'),
(5,'all public accents are hexadecimal','SELECT count(*) FROM public_rule_cabinet WHERE accent_hex NOT GLOB ''#[0-9A-Fa-f]*'';','result = 0','Every public policy needs a deterministic card color for the compiled static interface.','rules'),
(6,'orientation rose has eight points','SELECT count(*) FROM orientation_rose;','result = 8','The controller exposes all eight controller-style directions at forty-five-degree intervals.','rules'),
(7,'every active object set has six objects','SELECT min(object_count),max(object_count) FROM active_object_sets;','both results = 6','New-object shuffle must never produce an incomplete assignment or overflow the six-slot dock.','matter'),
(8,'all matter has positive mass','SELECT count(*) FROM object_catalog WHERE mass_units<=0;','result = 0','Even absurd office matter must retain positive inertial mass; only the field may become weightless.','matter'),
(9,'all matter fits the canvas label system','SELECT count(*) FROM object_catalog WHERE width_units>180 OR height_units>110;','result = 0','Compiled object cards remain readable and draggable inside narrow mobile physics windows.','matter'),
(10,'object notes are never blank','SELECT count(*) FROM object_catalog WHERE trim(archival_note)='''';','result = 0','Every found object carries a tiny narrative reason to exist beyond being a physics rectangle.','matter'),
(11,'dock mission target matches dock capacity','SELECT target_value FROM missions WHERE slug=''dock'';','result = 6','The assignment language, docking readout, and relational completion trigger must agree.','missions'),
(12,'orbit mission lasts twelve seconds','SELECT target_value FROM missions WHERE slug=''orbit'';','result = 12','The field should feel sustained but remain short enough to encourage replay and experimentation.','missions'),
(13,'sideways weather uses percentage completion','SELECT metric,target_value FROM missions WHERE slug=''rain'';','metric = sideways_weather and target = 100','Rain progress is accumulated while the gravity vector remains exactly horizontal.','missions'),
(14,'completion labels exist for every mission','SELECT count(*) FROM missions WHERE trim(completion_message)='''';','result = 0','A successful assignment must visibly acknowledge completion rather than silently filling a bar.','missions'),
(15,'rule transitions exclude self loops','SELECT count(*) FROM allowed_transitions WHERE from_rule_id=to_rule_id;','result = 0','Reapplying the same policy is handled as a no-op and should not create artificial progress.','events'),
(16,'public transitions form complete directed graph','SELECT count(*) FROM allowed_transitions;','result = 30','Six public rules require six times five directed transitions so every policy can follow every other.','events'),
(17,'reverse transitions requiring gust are marked','SELECT count(*) FROM allowed_transitions WHERE abs(impulse_x)+abs(impulse_y)>0 AND transition_ms>900;','result greater than 0','Large orientation reversals deliberately receive longer animation windows and optional impulse cues.','events'),
(18,'event tones remain within audible range','SELECT count(*) FROM field_messages WHERE tone_hz IS NOT NULL AND tone_hz NOT BETWEEN 40 AND 1800;','result = 0','Synthesized feedback avoids inaudible frequencies and harsh ultrasonic mistakes.','events'),
(19,'silent messages do not claim tone shapes','SELECT count(*) FROM field_messages WHERE tone_hz IS NULL AND tone_shape IS NOT NULL;','result = 0','Text-only idle notices stay silent and should not instantiate unnecessary audio nodes.','events'),
(20,'rule export is valid JSON','SELECT json_valid(rules_json) FROM browser_rule_export;','result = 1','The static adapter can consume public policy data without repairing malformed output.','exports'),
(21,'every object export is valid JSON','SELECT count(*) FROM browser_object_export WHERE json_valid(objects_json)=0;','result = 0','Each six-object manifest must compile independently for deterministic shuffling.','exports'),
(22,'export exposes human labels','SELECT count(*) FROM browser_rule_export WHERE rules_json NOT LIKE ''%name%'';','result = 0','Browser data keeps display names rather than leaking only database identifiers into the interface.','exports'),
(23,'glyphs are present for public rules','SELECT count(*) FROM public_rule_cabinet WHERE trim(glyph)='''';','result = 0','Direction buttons and rule cards always have a text equivalent that remains understandable without color.','accessibility'),
(24,'field messages explain state changes','SELECT count(*) FROM public_rule_cabinet WHERE length(field_message)<18;','result = 0','The live field message must describe the active policy rather than relying on animation alone.','accessibility'),
(25,'mission instructions are complete sentences','SELECT count(*) FROM missions WHERE instructions NOT LIKE ''%.'';','result = 0','Instructions should remain readable in isolation for keyboard and assistive-technology users.','accessibility'),
(26,'public rule names are unique','SELECT count(display_name)-count(DISTINCT display_name) FROM public_rule_cabinet;','result = 0','Every cabinet option has a distinct accessible name and a distinct narrative premise.','accessibility'),
(27,'object labels are unique','SELECT count(display_label)-count(DISTINCT display_label) FROM object_catalog;','result = 0','The docking readout and screen reader descriptions can identify every object unambiguously.','accessibility'),
(28,'featured presets are available','SELECT count(*) FROM field_presets WHERE featured=1;','result at least 4','Maintainers can open representative scenarios without manually assembling rule, mission, and object relations.','exports'),
(29,'integrity view returns one healthy row','SELECT * FROM build_integrity_report;','every column = 1','Continuous integration uses the same relational assertions documented throughout this test catalog.','exports'),
(30,'demo transaction leaves no session','SELECT count(*) FROM field_sessions WHERE session_id=''DEMO-ORIENTATION-SESSION'';','result = 0 after rollback','Repository validation demonstrates the full trigger chain without shipping persistent sample state.','events');

COMMIT;

-- Example transaction used by maintainers when testing the relational engine.
-- It is intentionally rolled back so the repository remains deterministic.
BEGIN;
INSERT INTO field_sessions(session_id,active_rule_id,active_mission_id,object_set)
VALUES('DEMO-ORIENTATION-SESSION',1,1,1);
UPDATE field_sessions SET active_rule_id=2 WHERE session_id='DEMO-ORIENTATION-SESSION';
UPDATE object_states SET docked=1 WHERE session_id='DEMO-ORIENTATION-SESSION' AND object_id=1;
SELECT * FROM current_field_state WHERE session_id='DEMO-ORIENTATION-SESSION';
SELECT * FROM mission_board WHERE session_id='DEMO-ORIENTATION-SESSION';
SELECT * FROM session_telemetry WHERE session_id='DEMO-ORIENTATION-SESSION';
SELECT * FROM build_integrity_report;
ROLLBACK;
