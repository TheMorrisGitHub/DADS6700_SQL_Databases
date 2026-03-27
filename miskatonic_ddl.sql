-- ============================================================
-- Miskatonic University: Resource Management
-- DADS6700 - Milestone 2 | Dario Garza
-- MySQL 
-- ============================================================

-- ============================================================
-- 1. PERSONS  (superclass of Student and Professor)
-- ============================================================
CREATE TABLE persons (
    id          VARCHAR(36)  NOT NULL,          -- UUID
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    age         INT          NOT NULL CHECK (age > 0),
    email       VARCHAR(255) NOT NULL UNIQUE,
    address     VARCHAR(500),
    account_id  VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

-- ============================================================
-- 2. STUDENTS  (ISA OVERLAP with Person; disjoint with Professor)
-- ============================================================
CREATE TABLE students (
    id                VARCHAR(36)  NOT NULL,
    person_id         VARCHAR(36)  NOT NULL UNIQUE,   -- 1-to-1 with persons
    modality          ENUM('ON_SITE', 'REMOTE') NOT NULL,
    status            VARCHAR(50)  NOT NULL DEFAULT 'ACTIVE',
    career_course     VARCHAR(255),
    enrollment_status ENUM('ENROLLED', 'PENDING', 'WITHDRAWN') NOT NULL DEFAULT 'PENDING',
    PRIMARY KEY (id),
    -- FK: person_id -> persons(id)
    INDEX idx_students_person (person_id)
);

-- ============================================================
-- 3. ON-SITE STUDENTS  (subtype of Student)
-- ============================================================
CREATE TABLE on_site_students (
    id              VARCHAR(36)  NOT NULL,
    student_id      VARCHAR(36)  NOT NULL UNIQUE,   -- 1-to-1 with students
    campus_card_id  VARCHAR(100) NOT NULL UNIQUE,
    parking_pass    TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    INDEX idx_onsite_student (student_id)
);

-- ============================================================
-- 4. REMOTE STUDENTS  (subtype of Student)
-- ============================================================
CREATE TABLE remote_students (
    id                    VARCHAR(36)  NOT NULL,
    student_id            VARCHAR(36)  NOT NULL UNIQUE,
    timezone              VARCHAR(100) NOT NULL,
    virtual_access_token  VARCHAR(500) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_remote_student (student_id)
);

-- ============================================================
-- 5. PROFESSORS
-- ============================================================
CREATE TABLE professors (
    id            VARCHAR(36)  NOT NULL,
    person_id     VARCHAR(36)  NOT NULL UNIQUE,
    department_id VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_professors_person (person_id)
);

-- ============================================================
-- 6. BUILDINGS
-- ============================================================
CREATE TABLE buildings (
    id           VARCHAR(36)  NOT NULL,
    building_id  VARCHAR(100) NOT NULL UNIQUE,   -- human-readable code e.g. "BLDG-A"
    name         VARCHAR(255) NOT NULL,
    address      VARCHAR(500) NOT NULL,
    total_floors INT          NOT NULL DEFAULT 1 CHECK (total_floors > 0),
    PRIMARY KEY (id)
);

-- ============================================================
-- 7. LOCATIONS  (superclass of Classroom and CommonArea)
-- ============================================================
CREATE TABLE locations (
    id            VARCHAR(36)  NOT NULL,
    location_id   VARCHAR(100) NOT NULL UNIQUE,   -- human-readable code
    location_name VARCHAR(255) NOT NULL,
    location_type ENUM('CLASSROOM', 'COMMON_AREA') NOT NULL,
    max_capacity  INT          NOT NULL CHECK (max_capacity > 0),
    floor_number  INT          NOT NULL DEFAULT 1,
    building_id   VARCHAR(36)  NOT NULL,           -- FK -> buildings(id)
    PRIMARY KEY (id),
    INDEX idx_locations_building (building_id)
);

-- ============================================================
-- 8. CLASSROOMS  (subtype of Location)
-- ============================================================
CREATE TABLE classrooms (
    id           VARCHAR(36)  NOT NULL,
    location_id  VARCHAR(36)  NOT NULL UNIQUE,    -- FK -> locations(id)
    room_id      VARCHAR(100) NOT NULL UNIQUE,
    syllabus_id  VARCHAR(100),
    class_term   VARCHAR(50),
    has_projector TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    INDEX idx_classrooms_location (location_id)
);

-- ============================================================
-- 9. COMMON AREAS  (subtype of Location)
-- ============================================================
CREATE TABLE common_areas (
    id           VARCHAR(36)  NOT NULL,
    location_id  VARCHAR(36)  NOT NULL UNIQUE,    -- FK -> locations(id)
    area_id      VARCHAR(100) NOT NULL UNIQUE,
    area_type    ENUM('GYM', 'LIBRARY', 'CAFETERIA', 'LAB', 'MEETING_ROOM',
                       'CONFERENCE_ROOM', 'PARKING', 'COFFEE_AREA', 'OTHER') NOT NULL,
    reserve_hour VARCHAR(10),                      -- e.g. "08:00"
    reserve_date DATE,
    PRIMARY KEY (id),
    INDEX idx_common_areas_location (location_id)
);

-- ============================================================
-- 10. COURSES  (assigned to a Classroom, taught by a Professor)
-- ============================================================
CREATE TABLE courses (
    id           VARCHAR(36)  NOT NULL,
    professor_id VARCHAR(36)  NOT NULL,            -- FK -> professors(id)
    classroom_id VARCHAR(36)  NOT NULL,            -- FK -> classrooms(id)
    course_name  VARCHAR(255) NOT NULL,
    syllabus_id  VARCHAR(100),
    class_term   VARCHAR(50)  NOT NULL,
    is_remote    TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    INDEX idx_courses_professor (professor_id),
    INDEX idx_courses_classroom (classroom_id)
);

-- ============================================================
-- 11. ENROLLMENTS  (association class: Student <-> Course)
-- ============================================================
CREATE TABLE enrollments (
    id          VARCHAR(36)  NOT NULL,
    student_id  VARCHAR(36)  NOT NULL,             -- FK -> students(id)
    course_id   VARCHAR(36)  NOT NULL,             -- FK -> courses(id)
    enroll_date DATE         NOT NULL,
    status      ENUM('ACCEPTED', 'PENDING', 'DENIED', 'WITHDRAWN') NOT NULL DEFAULT 'PENDING',
    PRIMARY KEY (id),
    UNIQUE KEY uq_enrollment (student_id, course_id),
    INDEX idx_enrollments_student (student_id),
    INDEX idx_enrollments_course (course_id)
);

-- ============================================================
-- 12. RESERVATIONS  (Person reserves a Location)
-- ============================================================
CREATE TABLE reservations (
    id          VARCHAR(36)  NOT NULL,
    person_id   VARCHAR(36)  NOT NULL,             -- FK -> persons(id)
    location_id VARCHAR(36)  NOT NULL,             -- FK -> locations(id)
    status      ENUM('PENDING', 'CONFIRMED', 'CANCELLED', 'NO_SHOW') NOT NULL DEFAULT 'PENDING',
    start_time  DATETIME     NOT NULL,
    end_time    DATETIME     NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_reservations_person (person_id),
    INDEX idx_reservations_location (location_id),
    -- Soft constraint: end > start (CHECK support varies by MySQL version)
    CONSTRAINT chk_reservation_times CHECK (end_time > start_time)
);

-- ============================================================
-- 13. DENY CAPACITY LOGS  (weak entity: triggered by Reservation + Location)
-- ============================================================
CREATE TABLE deny_capacity_logs (
    id              VARCHAR(36)  NOT NULL,
    location_id     VARCHAR(36)  NOT NULL,         -- FK -> locations(id)
    reservation_id  VARCHAR(36),                   -- FK -> reservations(id); nullable if walk-in
    date            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    denied_count    INT          NOT NULL DEFAULT 1,
    log_id          VARCHAR(100) NOT NULL,
    hour_schedule   VARCHAR(20),                   -- e.g. "14:00-15:00"
    deny_reason     VARCHAR(500),
    PRIMARY KEY (id),
    INDEX idx_deny_location (location_id),
    INDEX idx_deny_reservation (reservation_id)
);

-- ============================================================
-- SAMPLE DATA  (minimum viable seed for testing and queries)
-- ============================================================

-- Buildings
INSERT INTO buildings (id, building_id, name, address, total_floors) VALUES
    ('b1', 'BLDG-A', 'Arkham Hall',     '123 Miskatonic Ave, Arkham MA', 5),
    ('b2', 'BLDG-B', 'Dunwich Science', '125 Miskatonic Ave, Arkham MA', 3),
    ('b3', 'BLDG-C', 'Innsmouth Annex', '127 Miskatonic Ave, Arkham MA', 4);

-- Locations
INSERT INTO locations (id, location_id, location_name, location_type, max_capacity, floor_number, building_id) VALUES
    ('l1',  'LOC-101', 'Room 101',         'CLASSROOM',   30, 1, 'b1'),
    ('l2',  'LOC-102', 'Room 102',         'CLASSROOM',   25, 1, 'b1'),
    ('l3',  'LOC-201', 'Lab Room A',       'CLASSROOM',   20, 2, 'b1'),
    ('l4',  'LOC-GYM', 'Main Gym',         'COMMON_AREA', 80, 1, 'b2'),
    ('l5',  'LOC-LIB', 'Library',          'COMMON_AREA',150, 2, 'b2'),
    ('l6',  'LOC-CAF', 'Cafeteria',        'COMMON_AREA',200, 1, 'b3'),
    ('l7',  'LOC-MTG', 'Meeting Room 1',   'COMMON_AREA', 15, 3, 'b3'),
    ('l8',  'LOC-103', 'Room 103',         'CLASSROOM',   35, 1, 'b2'),
    ('l9',  'LOC-PRK', 'Parking Lot A',    'COMMON_AREA',100, 0, 'b3'),
    ('l10', 'LOC-COF', 'Coffee Corner',    'COMMON_AREA', 30, 1, 'b1');

-- Classrooms
INSERT INTO classrooms (id, location_id, room_id, syllabus_id, class_term, has_projector) VALUES
    ('cr1', 'l1', 'RM-101', 'SYL-DADS',  'Fall 2025',   1),
    ('cr2', 'l2', 'RM-102', 'SYL-CS101', 'Fall 2025',   1),
    ('cr3', 'l3', 'RM-LAB', 'SYL-PHY',   'Fall 2025',   0),
    ('cr4', 'l8', 'RM-103', 'SYL-MATH',  'Spring 2026', 1);

-- Common Areas
INSERT INTO common_areas (id, location_id, area_id, area_type, reserve_hour, reserve_date) VALUES
    ('ca1', 'l4',  'AREA-GYM', 'GYM',          '06:00', '2025-09-01'),
    ('ca2', 'l5',  'AREA-LIB', 'LIBRARY',       '08:00', '2025-09-01'),
    ('ca3', 'l6',  'AREA-CAF', 'CAFETERIA',     '07:00', '2025-09-01'),
    ('ca4', 'l7',  'AREA-MTG', 'MEETING_ROOM',  '09:00', '2025-09-01'),
    ('ca5', 'l9',  'AREA-PRK', 'PARKING',       '07:00', '2025-09-01'),
    ('ca6', 'l10', 'AREA-COF', 'COFFEE_AREA',   '07:30', '2025-09-01');

-- Persons
INSERT INTO persons (id, first_name, last_name, age, email, address, account_id) VALUES
    ('p1',  'Howard', 'Lovecraft',  45, 'h.lovecraft@misk.edu',  '10 Providence St', 'ACC-001'),
    ('p2',  'Abdul',  'Alhazred',   38, 'a.alhazred@misk.edu',   '22 Arkham Rd',     'ACC-002'),
    ('p3',  'Armitage','Henry',     55, 'a.henry@misk.edu',      '5 Faculty Row',    'ACC-003'),
    ('p4',  'Wilbur', 'Whateley',   22, 'w.whateley@misk.edu',   '99 Dunwich Ln',    'ACC-004'),
    ('p5',  'Cthulhu','Fhtagn',     19, 'c.fhtagn@misk.edu',     'R\'lyeh',          'ACC-005'),
    ('p6',  'Nyarla', 'Hotep',      21, 'n.hotep@misk.edu',      'Dreamlands',       'ACC-006'),
    ('p7',  'Randolph','Carter',    30, 'r.carter@misk.edu',     '7 Silver Key Ave', 'ACC-007'),
    ('p8',  'Dagon',  'Deep',       20, 'd.deep@misk.edu',       'Innsmouth Bay',    'ACC-008'),
    ('p9',  'Missy',  'Elton',      25, 'm.elton@misk.edu',      '14 Remote Way',    'ACC-009'),
    ('p10', 'Zara',   'Quinn',      27, 'z.quinn@misk.edu',      '55 Online Blvd',   'ACC-010'),
    ('p11', 'James',  'Danforth',   50, 'j.danforth@misk.edu',   '3 Prof Lane',      'ACC-011'),
    ('p12', 'Obed',   'Marsh',      48, 'o.marsh@misk.edu',      '88 Harbor Dr',     'ACC-012');

-- Professors
INSERT INTO professors (id, person_id, department_id) VALUES
    ('pr1', 'p1',  'DEPT-ANTH'),
    ('pr2', 'p3',  'DEPT-CS'),
    ('pr3', 'p11', 'DEPT-MATH'),
    ('pr4', 'p12', 'DEPT-PHY');

-- Students
INSERT INTO students (id, person_id, modality, status, career_course, enrollment_status) VALUES
    ('s1', 'p2',  'ON_SITE', 'ACTIVE', 'Computer Science', 'ENROLLED'),
    ('s2', 'p4',  'ON_SITE', 'ACTIVE', 'Data Analytics',   'ENROLLED'),
    ('s3', 'p5',  'REMOTE',  'ACTIVE', 'Physics',          'ENROLLED'),
    ('s4', 'p6',  'REMOTE',  'ACTIVE', 'Anthropology',     'ENROLLED'),
    ('s5', 'p7',  'ON_SITE', 'ACTIVE', 'Mathematics',      'ENROLLED'),
    ('s6', 'p8',  'ON_SITE', 'ACTIVE', 'Data Analytics',   'ENROLLED'),
    ('s7', 'p9',  'REMOTE',  'ACTIVE', 'Computer Science', 'ENROLLED'),
    ('s8', 'p10', 'REMOTE',  'ACTIVE', 'Mathematics',      'PENDING');

-- On-Site Students
INSERT INTO on_site_students (id, student_id, campus_card_id, parking_pass) VALUES
    ('os1', 's1', 'CARD-001', 1),
    ('os2', 's2', 'CARD-002', 0),
    ('os3', 's5', 'CARD-005', 1),
    ('os4', 's6', 'CARD-006', 0);

-- Remote Students
INSERT INTO remote_students (id, student_id, timezone, virtual_access_token) VALUES
    ('rs1', 's3', 'UTC-5', 'TOKEN-CTHULHU-2025'),
    ('rs2', 's4', 'UTC+2', 'TOKEN-NYARLA-2025'),
    ('rs3', 's7', 'UTC-8', 'TOKEN-MISSY-2025'),
    ('rs4', 's8', 'UTC+1', 'TOKEN-ZARA-2025');

-- Courses
INSERT INTO courses (id, professor_id, classroom_id, course_name, syllabus_id, class_term, is_remote) VALUES
    ('c1', 'pr1', 'cr1', 'Introduction to Anthropology', 'SYL-ANTH101', 'Fall 2025',   0),
    ('c2', 'pr2', 'cr2', 'Databases & Data Management',  'SYL-DADS6700','Fall 2025',   0),
    ('c3', 'pr3', 'cr4', 'Applied Mathematics',          'SYL-MATH301', 'Spring 2026', 0),
    ('c4', 'pr4', 'cr3', 'Physics Lab',                  'SYL-PHY201',  'Fall 2025',   0),
    ('c5', 'pr2', 'cr1', 'NoSQL & Modern Databases',     'SYL-DADS6800','Spring 2026', 1);

-- Enrollments
INSERT INTO enrollments (id, student_id, course_id, enroll_date, status) VALUES
    ('e1',  's1', 'c1', '2025-08-20', 'ACCEPTED'),
    ('e2',  's2', 'c2', '2025-08-20', 'ACCEPTED'),
    ('e3',  's3', 'c5', '2025-08-21', 'ACCEPTED'),   -- remote student, remote course ✓
    ('e4',  's4', 'c5', '2025-08-21', 'ACCEPTED'),
    ('e5',  's5', 'c3', '2025-12-15', 'ACCEPTED'),
    ('e6',  's6', 'c4', '2025-08-22', 'ACCEPTED'),
    ('e7',  's7', 'c5', '2025-08-23', 'ACCEPTED'),
    ('e8',  's8', 'c3', '2025-12-15', 'PENDING'),
    ('e9',  's1', 'c2', '2025-08-25', 'ACCEPTED'),
    ('e10', 's2', 'c4', '2025-08-25', 'DENIED');

-- Reservations
INSERT INTO reservations (id, person_id, location_id, status, start_time, end_time) VALUES
    ('r1',  'p2',  'l5',  'CONFIRMED',  '2025-09-10 09:00:00', '2025-09-10 11:00:00'),
    ('r2',  'p4',  'l4',  'CONFIRMED',  '2025-09-10 07:00:00', '2025-09-10 08:00:00'),
    ('r3',  'p5',  'l5',  'CONFIRMED',  '2025-09-10 10:00:00', '2025-09-10 12:00:00'),
    ('r4',  'p6',  'l7',  'CONFIRMED',  '2025-09-11 14:00:00', '2025-09-11 15:00:00'),
    ('r5',  'p7',  'l6',  'CONFIRMED',  '2025-09-11 12:00:00', '2025-09-11 13:00:00'),
    ('r6',  'p8',  'l4',  'CONFIRMED',  '2025-09-12 07:00:00', '2025-09-12 08:00:00'),
    ('r7',  'p9',  'l5',  'PENDING',    '2025-09-12 15:00:00', '2025-09-12 17:00:00'),
    ('r8',  'p10', 'l10', 'CANCELLED',  '2025-09-13 08:00:00', '2025-09-13 09:00:00'),
    ('r9',  'p2',  'l6',  'NO_SHOW',    '2025-09-14 12:00:00', '2025-09-14 13:00:00'),
    ('r10', 'p5',  'l9',  'CONFIRMED',  '2025-09-15 07:00:00', '2025-09-15 18:00:00'),
    ('r11', 'p1',  'l7',  'CONFIRMED',  '2025-09-16 10:00:00', '2025-09-16 11:00:00'),
    ('r12', 'p3',  'l5',  'CONFIRMED',  '2025-09-17 13:00:00', '2025-09-17 15:00:00');

-- Deny Capacity Logs
INSERT INTO deny_capacity_logs (id, location_id, reservation_id, date, denied_count, log_id, hour_schedule, deny_reason) VALUES
    ('d1', 'l4',  'r6',  '2025-09-12 07:05:00', 3, 'LOG-001', '07:00-08:00', 'Max capacity reached at gym'),
    ('d2', 'l5',  'r7',  '2025-09-12 15:02:00', 1, 'LOG-002', '15:00-17:00', 'Library at full capacity'),
    ('d3', 'l6',  NULL,  '2025-09-11 12:30:00', 8, 'LOG-003', '12:00-13:00', 'Cafeteria overflow during lunch peak'),
    ('d4', 'l4',  NULL,  '2025-09-10 07:15:00', 5, 'LOG-004', '07:00-08:00', 'Morning gym rush'),
    ('d5', 'l10', 'r8',  '2025-09-13 08:10:00', 2, 'LOG-005', '08:00-09:00', 'Coffee corner at capacity');

-- ============================================================
-- ANALYTICAL QUERIES
-- ============================================================

-- Q1: Occupancy rate per location (% of capacity used via reservations)
-- SELECT
--     l.location_name,
--     l.location_type,
--     l.max_capacity,
--     COUNT(r.id)                                  AS total_reservations,
--     ROUND(COUNT(r.id) / l.max_capacity * 100, 2) AS occupancy_pct
-- FROM locations l
-- LEFT JOIN reservations r ON r.location_id = l.id AND r.status = 'CONFIRMED'
-- GROUP BY l.id, l.location_name, l.location_type, l.max_capacity
-- ORDER BY occupancy_pct DESC;

-- Q2: Students denied due to max capacity per location
-- SELECT
--     l.location_name,
--     SUM(d.denied_count) AS total_denied,
--     COUNT(d.id)         AS deny_events
-- FROM deny_capacity_logs d
-- JOIN locations l ON l.id = d.location_id
-- GROUP BY l.id, l.location_name
-- ORDER BY total_denied DESC;

-- Q3: Remote students enrolled in on-site (physical) courses — constraint check
-- SELECT p.first_name, p.last_name, s.modality, c.course_name, e.status
-- FROM enrollments e
-- JOIN students s  ON s.id = e.student_id
-- JOIN persons p   ON p.id = s.person_id
-- JOIN courses c   ON c.id = e.course_id
-- WHERE s.modality = 'REMOTE' AND c.is_remote = 0;

-- Q4: Professor teaching load
-- SELECT p.first_name, p.last_name, pr.department_id, COUNT(c.id) AS courses_taught
-- FROM professors pr
-- JOIN persons p  ON p.id = pr.person_id
-- LEFT JOIN courses c ON c.professor_id = pr.id
-- GROUP BY pr.id, p.first_name, p.last_name, pr.department_id
-- ORDER BY courses_taught DESC;

-- Q5: Peak deny hours across all locations
-- SELECT hour_schedule, SUM(denied_count) AS total_denied
-- FROM deny_capacity_logs
-- GROUP BY hour_schedule
-- ORDER BY total_denied DESC;
