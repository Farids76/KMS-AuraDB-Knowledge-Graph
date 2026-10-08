// ===== Constraints =====
CREATE CONSTRAINT IF NOT EXISTS FOR (p:Program) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (c:Course) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (t:Topic) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (o:LearningOutcome) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (f:StudyField) REQUIRE f.id IS UNIQUE;

// ===== Nodes =====
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_study_fields.csv' AS r
MERGE (f:StudyField {id: r.study_field_id}) SET f.name = r.name;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_study_programs.csv' AS r
MERGE (p:Program {id: r.program_id})
SET p.title = r.title, p.level = r.level_and_type, p.credits = toFloat(r.credit_points),
    p.languages = r.languages, p.study_mode = r.study_mode;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_study_courses.csv' AS r
MERGE (c:Course {id: r.course_id})
SET c.title = r.title, c.credits = toFloat(r.credit_points), c.languages = r.languages,
    c.abstract = r.abstract, c.prerequisites = r.prerequisites;

// Topics + Course-[:COVERS]->Topic
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_course_topics.csv' AS r
MERGE (t:Topic {id: r.topic_id})
SET t.title = r.title, t.ordinal = toInteger(r.ordinal),
    t.contact_hours = toInteger(r.intramural_contact_hours),
    t.independent_hours = toInteger(r.intramural_independent_hours)
WITH t, r MATCH (c:Course {id: r.course_id}) MERGE (c)-[:COVERS]->(t);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_learning_outcomes.csv' AS r
MERGE (o:LearningOutcome {id: r.outcome_id})
SET o.text = r.text, o.scope = r.scope, o.ordinal = toInteger(r.ordinal);

// ===== Relationships =====
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/program%2Bcourse.csv' AS r
MATCH (p:Program {id: r.program_id}), (c:Course {id: r.course_id})
MERGE (p)-[i:INCLUDES]->(c) SET i.credits = toFloat(r.credit_points), i.section = r.section_name;

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/program%2Bstudy_field.csv' AS r
MATCH (p:Program {id: r.program_id}), (f:StudyField {id: r.study_field_id})
MERGE (p)-[:BELONGS_TO]->(f);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/edges/course%2Blearning_outcome.csv' AS r
MATCH (c:Course {id: r.course_id}), (o:LearningOutcome {id: r.outcome_id})
MERGE (c)-[:HAS_OUTCOME]->(o);

// Programme-level outcomes (linked through owner_id)
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ArithaRTU/KMS_Dataset/main/nodes/nodes_learning_outcomes.csv' AS r
WITH r WHERE r.scope = 'programme'
MATCH (p:Program {id: r.owner_id}), (o:LearningOutcome {id: r.outcome_id})
MERGE (p)-[:HAS_OUTCOME]->(o);

// ===== Check =====
MATCH (n) RETURN labels(n)[0] AS type, count(*) AS count ORDER BY type;
MATCH ()-[r]->() RETURN type(r) AS relationship, count(*) AS count;
