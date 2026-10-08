// Q1 - Courses shared by both programmes
MATCH (:Program {id:'DMB0'})-[:INCLUDES]->(c:Course)<-[:INCLUDES]-(:Program {id:'HMD0'})
RETURN c.id AS course, c.title AS title, c.credits AS credits ORDER BY title;

// Q2 - Courses with the most topics and contact hours
MATCH (c:Course)-[:COVERS]->(t:Topic)
RETURN c.title AS course, count(t) AS topics, sum(t.contact_hours) AS contact_hours
ORDER BY topics DESC LIMIT 10;

// Q3 - Business Informatics: courses and credits per section
MATCH (:Program {id:'DMB0'})-[i:INCLUDES]->(c:Course)
RETURN i.section AS section, count(c) AS courses, sum(i.credits) AS total_credits
ORDER BY total_credits DESC;

// Q4 - Courses that teach about data
MATCH (c:Course)-[:COVERS]->(t:Topic)
WHERE toLower(t.title) CONTAINS 'data'
RETURN c.title AS course, count(t) AS data_topics, collect(t.title)[..2] AS examples
ORDER BY data_topics DESC LIMIT 10;

// Q5 - Full path of one course (programme -> course -> topics / outcomes)
MATCH path = (:Program)-[:INCLUDES]->(:Course {id:'DE0745'})-[:COVERS|HAS_OUTCOME]->()
RETURN path;
