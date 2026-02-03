-- ================================================================
-- Elections Database Management System:
-- queryAll.sql - Sample SQL queries
-- 
-- Author: Eric Martin
-- Purpose: Implements all required queries and reports
-- Usage: mysql -u username -p elections_db < queryAll.sql
-- Note: Uses MySQL scripting variables for parameterized queries
-- ================================================================

-- ================================================================
-- Voter Information Query
-- ================================================================
SELECT 'Retrieve comprehensive voter contact information' AS Query_Description;

SELECT 
    CONCAT(f.first_name, ' ', f.last_name) AS full_name,
    pl.city,
    e.email_address
FROM folk f
JOIN residence r ON f.residence_id = r.place_id
JOIN place pl ON r.place_id = pl.place_id
LEFT JOIN email e ON f.personal_id = e.folk_id
ORDER BY f.last_name, f.first_name, e.email_address;

-- ================================================================
-- Population Demographics by City
-- ================================================================
SELECT 'Retrieve population demographics organized by city and state' AS Query_Description;

SELECT 
    pl.city,
    pl.state,
    COUNT(f.personal_id) AS num_residents
FROM place pl
JOIN residence r ON pl.place_id = r.place_id
JOIN folk f ON r.place_id = f.residence_id
GROUP BY pl.city, pl.state
HAVING COUNT(f.personal_id) > 0
ORDER BY num_residents DESC, pl.city;

-- ================================================================
-- Voting Center Registration Summary
-- ================================================================
SELECT 'List each center with number of registered folks by zipcode' AS Query_Description;

SELECT 
    vc.acronym AS center_acronym,
    pl.city,
    pl.state,
    pl.zipcode,
    COUNT(DISTINCT reg.folk_id) AS registered_folks_count
FROM voting_center vc
JOIN place pl ON vc.place_id = pl.place_id
LEFT JOIN registration reg ON vc.place_id = reg.center_id AND reg.is_valid = TRUE
GROUP BY vc.place_id, vc.acronym, pl.city, pl.state, pl.zipcode
ORDER BY pl.zipcode ASC;

-- ================================================================
-- Center Registration Lookup
-- ================================================================
SELECT 'Find distinct identifiers and names of folks registered at given center in time period' AS Query_Description;

-- @center_acronym and @start_date, @end_date are scripting variables
SET @center_acronym = 'MGPL';
SET @start_date = '2025-01-01';
SET @end_date = '2025-01-31';

SELECT DISTINCT
    f.personal_id,
    CONCAT(f.first_name, ' ', f.last_name) AS full_name
FROM folk f
JOIN registration reg ON f.personal_id = reg.folk_id
JOIN voting_center vc ON reg.center_id = vc.place_id
WHERE vc.acronym = @center_acronym
  AND reg.voting_date BETWEEN @start_date AND @end_date
  AND reg.is_valid = TRUE
ORDER BY f.last_name, f.first_name;

-- ================================================================
-- Geographic Registration Analysis
-- ================================================================
SELECT 'Find registrations within 3 miles from Megapolis center, excluding given list' AS Query_Description;

-- @target_month and @exclusion_list are scripting variables  
SET @target_month = '2025-02';
SET @exclusion_list = 'NRTH,SVAL';  -- comma-separated list

SELECT 
    COUNT(DISTINCT reg.registration_id) AS unique_registrations_count
FROM registration reg
JOIN voting_center vc ON reg.center_id = vc.place_id
JOIN place pl_vc ON vc.place_id = pl_vc.place_id
JOIN place pl_megapolis ON pl_megapolis.city = 'Megapolis' AND pl_megapolis.place_type = 'VOTING_CENTER'
WHERE DATE_FORMAT(reg.voting_date, '%Y-%m') = @target_month
  AND reg.is_valid = TRUE
  AND SQRT(POW(pl_vc.x_coordinate - pl_megapolis.x_coordinate, 2) + 
           POW(pl_vc.y_coordinate - pl_megapolis.y_coordinate, 2)) <= 3
  AND FIND_IN_SET(vc.acronym, @exclusion_list) = 0;

-- ================================================================
-- Center Population Analytics
-- ================================================================
SELECT 'Most popular voting center(s) in given city for time period' AS Query_Description;

-- @city_name, @start_period, @end_period are scripting variables
SET @city_name = 'Megapolis';
SET @start_period = '2025-01-01';
SET @end_period = '2025-01-31';

SELECT 
    vc.acronym,
    pl.city,
    COUNT(reg.registration_id) AS total_registrations
FROM voting_center vc
JOIN place pl ON vc.place_id = pl.place_id
JOIN registration reg ON vc.place_id = reg.center_id
WHERE pl.city = @city_name
  AND reg.voting_date BETWEEN @start_period AND @end_period
  AND reg.is_valid = TRUE
GROUP BY vc.place_id, vc.acronym, pl.city
HAVING COUNT(reg.registration_id) = (
    SELECT MAX(reg_count) 
    FROM (
        SELECT COUNT(r.registration_id) AS reg_count
        FROM voting_center vc2
        JOIN place pl2 ON vc2.place_id = pl2.place_id  
        JOIN registration r ON vc2.place_id = r.center_id
        WHERE pl2.city = @city_name
          AND r.voting_date BETWEEN @start_period AND @end_period
          AND r.is_valid = TRUE
        GROUP BY vc2.place_id
    ) AS subquery
)
ORDER BY vc.acronym;

-- ================================================================
-- Universal Registration Report
-- ================================================================
SELECT 'Find folks with valid registrations at every voting center in given state' AS Query_Description;

-- @state_name is scripting variable
SET @state_name = 'Northern Province';

SELECT DISTINCT
    f.personal_id,
    CONCAT(f.first_name, ' ', f.last_name) AS full_name
FROM folk f
WHERE NOT EXISTS (
    -- Find voting centers in the state where this folk is NOT registered
    SELECT vc.place_id
    FROM voting_center vc
    JOIN place pl ON vc.place_id = pl.place_id
    WHERE pl.state = @state_name
    AND NOT EXISTS (
        SELECT 1
        FROM registration reg
        WHERE reg.folk_id = f.personal_id
          AND reg.center_id = vc.place_id
          AND reg.is_valid = TRUE
    )
)
-- Ensure the folk has at least one registration in the state
AND EXISTS (
    SELECT 1
    FROM registration reg
    JOIN voting_center vc ON reg.center_id = vc.place_id
    JOIN place pl ON vc.place_id = pl.place_id
    WHERE reg.folk_id = f.personal_id
      AND pl.state = @state_name
      AND reg.is_valid = TRUE
)
ORDER BY f.last_name, f.first_name;

-- ================================================================
-- Find folks registered at centers farther than closest center to their residence
-- ================================================================
SELECT 'Non-optimal Register' AS Query_Description;

SELECT DISTINCT
    f.personal_id,
    CONCAT(f.first_name, ' ', f.last_name) AS full_name,
    reg_vc.acronym AS registered_center,
    ROUND(SQRT(POW(reg_pl.x_coordinate - res_pl.x_coordinate, 2) + 
               POW(reg_pl.y_coordinate - res_pl.y_coordinate, 2)), 3) AS registered_distance,
    closest.closest_acronym,
    closest.closest_distance
FROM folk f
JOIN residence res ON f.residence_id = res.place_id
JOIN place res_pl ON res.place_id = res_pl.place_id
JOIN registration reg ON f.personal_id = reg.folk_id
JOIN voting_center reg_vc ON reg.center_id = reg_vc.place_id  
JOIN place reg_pl ON reg_vc.place_id = reg_pl.place_id
JOIN (
    -- Subquery to find closest center and distance for each folk
    SELECT 
        f2.personal_id,
        vc2.acronym AS closest_acronym,
        ROUND(MIN(SQRT(POW(pl2.x_coordinate - res_pl2.x_coordinate, 2) + 
                       POW(pl2.y_coordinate - res_pl2.y_coordinate, 2))), 3) AS closest_distance
    FROM folk f2
    JOIN residence res2 ON f2.residence_id = res2.place_id
    JOIN place res_pl2 ON res2.place_id = res_pl2.place_id
    JOIN voting_center vc2
    JOIN place pl2 ON vc2.place_id = pl2.place_id
    JOIN operating_period op2 ON vc2.place_id = op2.center_id
    JOIN registration reg2 ON f2.personal_id = reg2.folk_id
    WHERE reg2.voting_date >= DATE(op2.period_start)
      AND reg2.voting_date <= DATE(op2.period_end)
    GROUP BY f2.personal_id
    HAVING MIN(SQRT(POW(pl2.x_coordinate - res_pl2.x_coordinate, 2) + 
                    POW(pl2.y_coordinate - res_pl2.y_coordinate, 2))) = 
           SQRT(POW(pl2.x_coordinate - res_pl2.x_coordinate, 2) + 
                POW(pl2.y_coordinate - res_pl2.y_coordinate, 2))
) closest ON f.personal_id = closest.personal_id
WHERE reg.is_valid = TRUE
  AND SQRT(POW(reg_pl.x_coordinate - res_pl.x_coordinate, 2) + 
           POW(reg_pl.y_coordinate - res_pl.y_coordinate, 2)) > closest.closest_distance
ORDER BY f.last_name, f.first_name, reg_vc.acronym;

-- ================================================================
-- SQL Function - Get closest voting center to folk's residence
-- ================================================================
SELECT 'Get closest voting center' AS Query_Description;

-- @folk_id and @target_date are scripting variables
SET @folk_id = '1234567890123407';
SET @target_date = '2025-02-15';

SELECT 
    @folk_id AS folk_id,
    @target_date AS target_date,
    get_closest_voting_center(@folk_id, @target_date) AS closest_center_acronym;

-- Test with multiple folks and dates
SELECT 
    f.personal_id,
    CONCAT(f.first_name, ' ', f.last_name) AS full_name,
    '2025-02-15' AS test_date,
    get_closest_voting_center(f.personal_id, '2025-02-15') AS closest_center
FROM folk f
ORDER BY f.last_name, f.first_name;

-- ================================================================
-- Voting pattern Analysis
-- ================================================================
SELECT 'Cross-tabulation of voting centers vs poll answers' AS Query_Description;

-- @poll_id is scripting variable
SET @poll_id = 'POL1';

SELECT 
    vc.acronym AS voting_center,
    SUM(CASE WHEN b.vote_choice = 'YES' THEN 1 ELSE 0 END) AS YES_votes,
    SUM(CASE WHEN b.vote_choice = 'NO' THEN 1 ELSE 0 END) AS NO_votes,
    SUM(CASE WHEN b.vote_choice = 'ABSTAIN' THEN 1 ELSE 0 END) AS ABSTAIN_votes,
    COUNT(b.folk_id) AS total_ballots
FROM voting_center vc
LEFT JOIN registration reg ON vc.place_id = reg.center_id AND reg.poll_id = @poll_id
LEFT JOIN ballot b ON reg.folk_id = b.folk_id AND reg.poll_id = b.poll_id
GROUP BY vc.place_id, vc.acronym
ORDER BY vc.acronym;

-- Alternative cross-tab for POL2 to show different distribution
SET @poll_id = 'POL2';

SELECT 
    vc.acronym AS voting_center,
    SUM(CASE WHEN b.vote_choice = 'YES' THEN 1 ELSE 0 END) AS YES_votes,
    SUM(CASE WHEN b.vote_choice = 'NO' THEN 1 ELSE 0 END) AS NO_votes,
    SUM(CASE WHEN b.vote_choice = 'ABSTAIN' THEN 1 ELSE 0 END) AS ABSTAIN_votes,
    COUNT(b.folk_id) AS total_ballots
FROM voting_center vc
LEFT JOIN registration reg ON vc.place_id = reg.center_id AND reg.poll_id = @poll_id
LEFT JOIN ballot b ON reg.folk_id = b.folk_id AND reg.poll_id = b.poll_id
GROUP BY vc.place_id, vc.acronym
ORDER BY vc.acronym;

-- ================================================================
-- VERIFICATION AND SUMMARY QUERIES
-- ================================================================

SELECT 'Summary: All queries completed successfully' AS Final_Status;

-- Show current database state
SELECT 'Current Database State Summary' AS Summary;
SELECT 'Folk' AS entity, COUNT(*) AS count FROM folk
UNION ALL SELECT 'Registrations', COUNT(*) FROM registration
UNION ALL SELECT 'Ballots', COUNT(*) FROM ballot
UNION ALL SELECT 'Voting Centers', COUNT(*) FROM voting_center
UNION ALL SELECT 'Polls', COUNT(*) FROM poll;
