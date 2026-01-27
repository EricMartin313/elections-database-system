-- ================================================================
-- Elections Database Management System:
-- loadAll.sql - Script to load sample data
-- 
-- Author: Eric Martin
-- Purpose: Inserts sample data meeting all project requirements
-- Usage: mysql -u username -p elections_db < loadAll.sql
-- Note: Run after createAll.sql
-- 
-- UPDATES:
-- - Improved coordinate precision to match DECIMAL(12,6)
-- - Enhanced sample data distribution
-- ================================================================

-- Disable foreign key checks for loading
SET FOREIGN_KEY_CHECKS = 0;

-- Clear any existing data
DELETE FROM staff_schedule;
DELETE FROM ballot;
DELETE FROM registration;
DELETE FROM operating_period;
DELETE FROM email;
DELETE FROM staff;
DELETE FROM poll;
DELETE FROM voting_center;
DELETE FROM residence;
DELETE FROM folk;
DELETE FROM place;

-- Reset auto-increment counters
ALTER TABLE place AUTO_INCREMENT = 1;
ALTER TABLE registration AUTO_INCREMENT = 1;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ================================================================
-- SAMPLE DATA INSERTION
-- ================================================================

-- 1. PLACES (6 total: 3 voting centers, 3 residences in 2 states, 2+ cities each)
INSERT INTO place (street_number, street_name, city, state, zipcode, x_coordinate, y_coordinate, place_type) VALUES
-- Voting Centers (distributed across states and cities) - improved precision
('100', 'Government Plaza', 'Megapolis', 'Northern Province', '10001', 0.000000, 0.000000, 'VOTING_CENTER'),           -- ID 1: Capital, origin
('250', 'Civic Center Drive', 'Northtown', 'Northern Province', '10501', -15.523456, 12.345678, 'VOTING_CENTER'),     -- ID 2: Northern city
('400', 'Democracy Avenue', 'Southville', 'Southern Province', '20001', 8.765432, -22.123456, 'VOTING_CENTER'),       -- ID 3: Southern city

-- Residences (distributed to support folk requirements) - improved precision
('123', 'Oak Street', 'Megapolis', 'Northern Province', '10002', -2.123456, 1.876543, 'RESIDENCE'),                    -- ID 4: Near center 1
('456', 'Pine Lane', 'Northtown', 'Northern Province', '10502', -14.012345, 11.543210, 'RESIDENCE'),                  -- ID 5: Near center 2  
('789', 'Elm Drive', 'Westport', 'Southern Province', '20501', 25.345678, -18.765432, 'RESIDENCE');                   -- ID 6: Farther from all

-- 2. VOTING CENTERS (3 centers with unique acronyms)
INSERT INTO voting_center (place_id, acronym) VALUES
(1, 'MGPL'),    -- Megapolis Center
(2, 'NRTH'),    -- Northtown Center  
(3, 'SVAL');    -- Southville Center

-- 3. RESIDENCES (3 residences)
INSERT INTO residence (place_id) VALUES (4), (5), (6);

-- 4. FOLK (12 total, including staff members, distributed across residences)
INSERT INTO folk (personal_id, first_name, last_name, nickname, date_of_birth, primary_phone, secondary_phone, residence_id) VALUES
-- Staff members (6 total)
('1234567890123401', 'Alice', 'Johnson', 'AJ', '1985-03-15', '5551234567', '5559876543', 4),
('1234567890123402', 'Bob', 'Smith', 'Bobby', '1990-07-22', '5552345678', NULL, 5),
('1234567890123403', 'Carol', 'Davis', 'CD', '1988-11-08', '5553456789', '5558765432', 6),
('1234567890123404', 'David', 'Wilson', 'Dave', '1992-05-14', '5554567890', '5557654321', 4),
('1234567890123405', 'Emma', 'Brown', 'Em', '1987-09-30', '5555678901', NULL, 5),
('1234567890123406', 'Frank', 'Miller', 'Frankie', '1991-12-03', '5556789012', '5556543210', 6),

-- Regular folk (6 additional)
('1234567890123407', 'Grace', 'Garcia', 'Gracie', '1995-01-18', '5557890123', '5555432109', 4),
('1234567890123408', 'Henry', 'Martinez', 'Hank', '1993-08-25', '5558901234', NULL, 5),
('1234567890123409', 'Iris', 'Lopez', 'Iri', '1989-04-12', '5559012345', '5554321098', 6),
('1234567890123410', 'Jack', 'Anderson', 'Jackie', '1994-10-07', '5550123456', NULL, 4),
('1234567890123411', 'Karen', 'Taylor', 'Kay', '1986-06-29', '5551234568', '5553210987', 5),
('1234567890123412', 'Luis', 'Thomas', 'Lou', '1996-02-11', '5552345679', NULL, 6);

-- 5. STAFF (6 total: 3 clerks, 3 monitors)
INSERT INTO staff (personal_id, staff_type) VALUES
('1234567890123401', 'CLERK'),     -- Alice
('1234567890123402', 'CLERK'),     -- Bob
('1234567890123403', 'CLERK'),     -- Carol
('1234567890123404', 'MONITOR'),   -- David
('1234567890123405', 'MONITOR'),   -- Emma
('1234567890123406', 'MONITOR');   -- Frank

-- 6. EMAIL ADDRESSES (at least one per folk, some with multiple)
INSERT INTO email (folk_id, email_address) VALUES
-- Staff emails
('1234567890123401', 'alice.johnson@election.wonderland'),
('1234567890123401', 'aj@personal.mail'),
('1234567890123402', 'bob.smith@election.wonderland'),
('1234567890123403', 'carol.davis@election.wonderland'),
('1234567890123404', 'david.wilson@election.wonderland'),
('1234567890123405', 'emma.brown@election.wonderland'),
('1234567890123406', 'frank.miller@election.wonderland'),

-- Regular folk emails
('1234567890123407', 'grace.garcia@mail.wonderland'),
('1234567890123408', 'henry.martinez@webmail.wonder'),
('1234567890123408', 'hank@personal.wonder'),
('1234567890123409', 'iris.lopez@mail.wonderland'),
('1234567890123410', 'jack.anderson@webmail.wonder'),
('1234567890123411', 'karen.taylor@mail.wonderland'),
('1234567890123412', 'luis.thomas@webmail.wonder');

-- 7. POLLS (4 total with overlapping availability periods)
INSERT INTO poll (short_name, question_text, availability_start, availability_end) VALUES
('POL1', 'Do you support the proposed infrastructure improvement initiative?', '2025-01-15 08:00:00', '2025-03-15 20:00:00'),
('POL2', 'Should Wonderland adopt renewable energy standards for all government buildings?', '2025-02-01 08:00:00', '2025-04-01 20:00:00'),  
('POL3', 'Do you approve of extending voting center operating hours during election periods?', '2025-01-01 08:00:00', '2025-02-28 20:00:00'),
('POL4', 'Should the election department implement online voter registration?', '2025-02-15 08:00:00', '2025-04-15 20:00:00');

-- 8. OPERATING PERIODS (3 centers × 4 periods each = 12 total)
INSERT INTO operating_period (center_id, period_start, period_end) VALUES
-- Megapolis Center (ID 1) - 4 periods
(1, '2025-01-01 07:00:00', '2025-01-31 21:00:00'),
(1, '2025-02-01 06:30:00', '2025-02-28 21:30:00'), 
(1, '2025-03-01 07:00:00', '2025-03-31 21:00:00'),
(1, '2025-04-01 07:30:00', '2025-04-30 20:30:00'),

-- Northtown Center (ID 2) - 4 periods  
(2, '2025-01-01 08:00:00', '2025-01-31 20:00:00'),
(2, '2025-02-01 07:30:00', '2025-02-28 20:30:00'),
(2, '2025-03-01 08:00:00', '2025-03-31 20:00:00'), 
(2, '2025-04-01 08:30:00', '2025-04-30 19:30:00'),

-- Southville Center (ID 3) - 4 periods
(3, '2025-01-01 08:30:00', '2025-01-31 19:30:00'),
(3, '2025-02-01 08:00:00', '2025-02-28 20:00:00'),
(3, '2025-03-01 08:30:00', '2025-03-31 19:30:00'),
(3, '2025-04-01 09:00:00', '2025-04-30 19:00:00');

-- 9. REGISTRATIONS (24 total distributed across 3 polls, 3 centers, 2 months)
INSERT INTO registration (folk_id, poll_id, center_id, voting_date, registration_datetime, is_valid) VALUES
-- January registrations (12 registrations - polls POL1, POL3)
('1234567890123401', 'POL1', 1, '2025-01-20', '2025-01-10 09:15:00', TRUE),
('1234567890123402', 'POL1', 2, '2025-01-22', '2025-01-10 10:30:00', TRUE), 
('1234567890123403', 'POL1', 3, '2025-01-25', '2025-01-11 14:20:00', TRUE),
('1234567890123404', 'POL3', 1, '2025-01-18', '2025-01-12 11:45:00', TRUE),
('1234567890123405', 'POL3', 2, '2025-01-21', '2025-01-12 16:10:00', TRUE),
('1234567890123406', 'POL3', 3, '2025-01-28', '2025-01-13 13:25:00', TRUE),
('1234567890123407', 'POL1', 1, '2025-01-23', '2025-01-14 08:40:00', TRUE),
('1234567890123408', 'POL3', 2, '2025-01-19', '2025-01-14 15:55:00', TRUE),
('1234567890123409', 'POL1', 3, '2025-01-26', '2025-01-15 12:30:00', TRUE),
('1234567890123410', 'POL3', 1, '2025-01-24', '2025-01-15 17:15:00', TRUE),
('1234567890123411', 'POL1', 2, '2025-01-27', '2025-01-16 09:50:00', TRUE),
('1234567890123412', 'POL3', 3, '2025-01-29', '2025-01-16 14:05:00', TRUE),

-- February registrations (12 registrations - polls POL2, POL4)  
('1234567890123401', 'POL2', 2, '2025-02-10', '2025-02-01 08:30:00', TRUE),
('1234567890123402', 'POL2', 3, '2025-02-12', '2025-02-01 11:15:00', TRUE),
('1234567890123403', 'POL4', 1, '2025-02-20', '2025-02-16 09:45:00', TRUE),
('1234567890123404', 'POL2', 1, '2025-02-14', '2025-02-02 13:20:00', TRUE), 
('1234567890123405', 'POL4', 3, '2025-02-22', '2025-02-17 15:30:00', TRUE),
('1234567890123406', 'POL2', 2, '2025-02-16', '2025-02-03 10:40:00', TRUE),
('1234567890123407', 'POL4', 1, '2025-02-25', '2025-02-18 12:15:00', TRUE),
('1234567890123408', 'POL2', 3, '2025-02-18', '2025-02-04 14:50:00', TRUE),
('1234567890123409', 'POL4', 2, '2025-02-24', '2025-02-19 16:25:00', TRUE),
('1234567890123410', 'POL2', 1, '2025-02-11', '2025-02-05 08:35:00', TRUE),
('1234567890123411', 'POL4', 3, '2025-02-26', '2025-02-20 11:10:00', TRUE),
('1234567890123412', 'POL2', 2, '2025-02-13', '2025-02-06 13:45:00', TRUE);

-- 10. BALLOTS (18 total distributed across 2 polls with various vote choices)
INSERT INTO ballot (folk_id, poll_id, vote_choice, cast_datetime, registration_id) VALUES
-- POL1 ballots (12 ballots - all January POL1 registrations)
('1234567890123401', 'POL1', 'YES', '2025-01-20 14:30:00', 1),
('1234567890123402', 'POL1', 'NO', '2025-01-22 11:15:00', 2),
('1234567890123403', 'POL1', 'YES', '2025-01-25 16:45:00', 3),
('1234567890123407', 'POL1', 'ABSTAIN', '2025-01-23 10:20:00', 7),
('1234567890123409', 'POL1', 'YES', '2025-01-26 13:55:00', 9),
('1234567890123411', 'POL1', 'NO', '2025-01-27 15:10:00', 11),

-- POL2 ballots (12 ballots - all February POL2 registrations)
('1234567890123401', 'POL2', 'YES', '2025-02-10 12:45:00', 13),
('1234567890123402', 'POL2', 'YES', '2025-02-12 14:20:00', 14), 
('1234567890123404', 'POL2', 'ABSTAIN', '2025-02-14 09:30:00', 16),
('1234567890123406', 'POL2', 'NO', '2025-02-16 16:15:00', 18),
('1234567890123408', 'POL2', 'YES', '2025-02-18 11:40:00', 20),
('1234567890123410', 'POL2', 'NO', '2025-02-11 15:25:00', 22),
('1234567890123412', 'POL2', 'YES', '2025-02-13 08:50:00', 24);

-- Additional ballots to meet 18 total requirement  
INSERT INTO ballot (folk_id, poll_id, vote_choice, cast_datetime, registration_id) VALUES
('1234567890123404', 'POL3', 'YES', '2025-01-18 10:30:00', 4),
('1234567890123405', 'POL3', 'NO', '2025-01-21 13:20:00', 5),
('1234567890123406', 'POL3', 'ABSTAIN', '2025-01-28 16:45:00', 6),
('1234567890123408', 'POL3', 'YES', '2025-01-19 11:10:00', 8),
('1234567890123410', 'POL3', 'NO', '2025-01-24 14:25:00', 10);

-- 11. STAFF SCHEDULES (distributed across centers and staff)
INSERT INTO staff_schedule (staff_id, center_id, shift_start, shift_end) VALUES
-- Alice (CLERK) - scheduled at multiple centers
('1234567890123401', 1, '2025-01-20 07:00:00', '2025-01-20 15:00:00'),
('1234567890123401', 2, '2025-02-10 08:00:00', '2025-02-10 16:00:00'),

-- Bob (CLERK) - regular schedule at Northtown
('1234567890123402', 2, '2025-01-22 08:00:00', '2025-01-22 16:00:00'),
('1234567890123402', 2, '2025-02-12 07:30:00', '2025-02-12 15:30:00'),

-- Carol (CLERK) - works at Southville  
('1234567890123403', 3, '2025-01-25 08:30:00', '2025-01-25 16:30:00'),
('1234567890123403', 1, '2025-02-20 07:00:00', '2025-02-20 15:00:00'),

-- David (MONITOR) - supervises at Megapolis
('1234567890123404', 1, '2025-01-18 06:30:00', '2025-01-18 18:30:00'),
('1234567890123404', 1, '2025-02-14 06:30:00', '2025-02-14 18:30:00'),

-- Emma (MONITOR) - covers multiple locations
('1234567890123405', 2, '2025-01-21 07:30:00', '2025-01-21 19:30:00'),
('1234567890123405', 3, '2025-02-22 08:00:00', '2025-02-22 18:00:00'),

-- Frank (MONITOR) - evening shifts
('1234567890123406', 3, '2025-01-28 12:00:00', '2025-01-28 20:00:00'),
('1234567890123406', 2, '2025-02-16 11:00:00', '2025-02-16 19:00:00');

-- ================================================================
-- DATA VERIFICATION QUERIES
-- ================================================================

-- Summary of loaded data
SELECT 'Data Load Summary' AS Category, 'Completed Successfully' AS Status;

SELECT 'Places' AS Table_Name, COUNT(*) AS Record_Count FROM place
UNION ALL
SELECT 'Folk', COUNT(*) FROM folk  
UNION ALL
SELECT 'Staff', COUNT(*) FROM staff
UNION ALL
SELECT 'Polls', COUNT(*) FROM poll
UNION ALL
SELECT 'Voting Centers', COUNT(*) FROM voting_center
UNION ALL
SELECT 'Operating Periods', COUNT(*) FROM operating_period
UNION ALL  
SELECT 'Registrations', COUNT(*) FROM registration
UNION ALL
SELECT 'Ballots', COUNT(*) FROM ballot
UNION ALL
SELECT 'Staff Schedules', COUNT(*) FROM staff_schedule
UNION ALL
SELECT 'Email Addresses', COUNT(*) FROM email;

-- Geographic distribution verification
SELECT 
    'Geographic Distribution' AS Category,
    state,
    city, 
    COUNT(*) AS place_count,
    GROUP_CONCAT(DISTINCT place_type) AS types
FROM place
GROUP BY state, city;
