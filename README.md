# AuraDB Knowledge Graph – RTU Study Programmes

**Course:** Knowledge Management Systems  
**Author:** Farids Guseinovs  
**Tool:** Neo4j AuraDB Free  
**Dataset:** [ArithaRTU/KMS_Dataset](https://github.com/ArithaRTU/KMS_Dataset)

## 1. About the data

The dataset describes two RTU master programmes, **Business Informatics (DMB0)** and **Digital Humanities (HMD0)**. It has CSV files for nodes and edges:

- **Nodes:** study field, study programmes, courses, course topics and learning outcomes
- **Edges:** programme → course, programme → study field, course → topic, course → learning outcome

Topics include contact and independent hours. Learning outcomes have a `scope` (programme or course) and an `owner_id`, which I used to link programme-level outcomes to their programme.

## 2. Schema

```
(:StudyField)<-[:BELONGS_TO]-(:Program)-[:INCLUDES {credits, section}]->(:Course)-[:COVERS]->(:Topic)
(:Program)-[:HAS_OUTCOME]->(:LearningOutcome)<-[:HAS_OUTCOME]-(:Course)
```

| Node | Key | Main properties |
|---|---|---|
| Program | id | title, level, credits, languages, study_mode |
| Course | id | title, credits, languages, abstract, prerequisites |
| Topic | id | title, ordinal, contact_hours, independent_hours |
| LearningOutcome | id | text, scope, ordinal |
| StudyField | id | name |

I added a uniqueness constraint on `id` for each label so that the imports with `MERGE` don't create duplicates.

![Schema](images/schema.png)

## 3. Import

I imported everything with `LOAD CSV` straight from the GitHub raw files. The full script is in [`import.cypher`](import.cypher).

**Result:**

![Node counts](images/node_counts.png)
![Relationship counts](images/relationship_counts.png)

The graph has 1,110 nodes and 1,113 relationships. One thing I noticed: `program+course.csv` has 89 rows, but only **79 INCLUDES** relationships were created. That's because 10 rows are duplicates (the same course is listed twice for the same programme), and `MERGE` keeps only one.

## 4. Queries

All queries are also in [`queries.cypher`](queries.cypher).

### Q1 – Which courses are shared by both programmes?
```cypher
MATCH (:Program {id:'DMB0'})-[:INCLUDES]->(c:Course)<-[:INCLUDES]-(:Program {id:'HMD0'})
RETURN c.id AS course, c.title AS title, c.credits AS credits ORDER BY title;
```
![Q1](images/q1_shared_courses.png)

**Result:** 4 courses are in both programmes: Communication and Presentation Skills, Knowledge Management Systems, Portfolio Management Technologies and e-Business Solutions. So the two programmes overlap mostly on management and soft-skill courses, not on technical ones.

### Q2 – Which courses have the most topics?
```cypher
MATCH (c:Course)-[:COVERS]->(t:Topic)
RETURN c.title AS course, count(t) AS topics, sum(t.contact_hours) AS contact_hours
ORDER BY topics DESC LIMIT 10;
```
![Q2](images/q2_topics_hours.png)

**Result:** Introduction to Knowledge Society Technology has the most topics (20). Digital Textuality has 19 topics but the most contact hours (64). More topics doesn't always mean more hours, e.g. Audio and Video Data Processing has 19 topics but only 26 contact hours.

### Q3 – How are Business Informatics credits split by section?
```cypher
MATCH (:Program {id:'DMB0'})-[i:INCLUDES]->(c:Course)
RETURN i.section AS section, count(c) AS courses, sum(i.credits) AS total_credits
ORDER BY total_credits DESC;
```
![Q3](images/q3_credits_by_section.png)

**Result:** Compulsory courses give 57 ECTS and the Master thesis (Final Examination) gives 30 ECTS, which matches the programme description. The other sections add up to more than the programme needs, because they are choice pools and students only pick some of them.

### Q4 – Which courses teach about data?
```cypher
MATCH (c:Course)-[:COVERS]->(t:Topic)
WHERE toLower(t.title) CONTAINS 'data'
RETURN c.title AS course, count(t) AS data_topics, collect(t.title)[..2] AS examples
ORDER BY data_topics DESC LIMIT 10;
```
![Q4](images/q4_data_topics.png)

**Result:** Python Programming Language, Introduction to Big Data Analytics and Introduction to Knowledge Society Technology each have 6 topics about data. This kind of keyword search across topics is useful if a student wants to find every course on a certain subject.

### Q5 – Full path of one course
```cypher
MATCH path = (:Program)-[:INCLUDES]->(:Course {id:'DE0745'})-[:COVERS|HAS_OUTCOME]->()
RETURN path;
```
![Q5](images/q5_course_paths.png)

**Result:** This shows the course Advanced Data Technologies with its programme (Business Informatics), its topics (database systems, temporal databases, data retrieval) and its learning outcomes, all in one query.

## 5. Conclusion

The curriculum data fits a graph really well, because it's all about connections: programmes contain courses, courses cover topics and give learning outcomes, and some courses are shared. In a relational database, questions like "which courses are in both programmes" or "show everything linked to this course" need several joins. In Cypher they are short pattern matches. I also found a small data-quality issue (duplicate programme-course rows) while checking the import.
