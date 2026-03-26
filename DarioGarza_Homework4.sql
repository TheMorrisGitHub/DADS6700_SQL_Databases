-- Homework 4, module 11.
-- Chapter 9, Problems and Exercises 9.10E Recursive Query.

WITH entire-pre-req-courses(coursenr, coursename, level)
AS
(SELECT coursenr, pre-req-coursenr, 1
FROM PRE-REQUISITE
)

UNION All

(SELECT pre.coursenr, pre.coursename,  e.level+1
FROM entire-pre-req-courses as e, PRE-REQUISTE as pre
WHERE pre.coursename = "Principles of Database Management")



SELECT * FROM entire-pre-req-courses
