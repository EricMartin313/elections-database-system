-- ================================================================
-- Elections Database Management System:
-- transaction.sql - ACID-Compliant Ballot Casting Implementation
-- 
-- Author: Eric Martin
-- Purpose: Implements secure ballot casting with transaction isolation
-- Usage: mysql -u username -p elections_db < transaction.sql
-- ================================================================

-- ================================================================
-- TRANSACTION ISOLATION: REPEATABLE READ
-- ================================================================
/*
Uses REPEATABLE READ isolation level for optimal balance of:
- Data consistency - prevents phantom reads during ballot validation
- System concurrency - allows multiple simultaneous ballot casting
- ACID compliance - ensures registration data remains stable throughout transaction

This isolation level prevents duplicate ballots while maintaining high throughput
for concurrent voting operations across multiple centers.
*/

-- ================================================================
-- TRANSACTIONAL BALLOT CASTING PROCEDURE
-- ================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS cast_ballot_transaction //

CREATE PROCEDURE cast_ballot_transaction(
    IN p_folk_id CHAR(16),
    IN p_poll_id CHAR(4),
    IN p_vote_choice ENUM('YES', 'NO', 'ABSTAIN'),
    IN p_expected_center_id INT,
    IN p_voting_date DATE,
    OUT p_result_code INT,
    OUT p_result_message VARCHAR(255)
)
BEGIN
    -- Variable declarations
    DECLARE v_registration_id INT DEFAULT NULL;
    DECLARE v_registration_count INT DEFAULT 0;
    DECLARE v_existing_ballot_count INT DEFAULT 0;
    DECLARE v_poll_available_start DATETIME;
    DECLARE v_poll_available_end DATETIME;
    DECLARE v_current_datetime DATETIME DEFAULT NOW();
    DECLARE v_center_operating INT DEFAULT 0;
    
    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result_code = -1;
        SET p_result_message = 'Transaction failed due to database error';
    END;
    
    -- Set isolation level for this transaction
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    -- Start transaction
    START TRANSACTION;
    
    -- ================================================================
    -- VALIDATION PHASE 1: Check for existing ballot (prevent duplicates)
    -- ================================================================
    SELECT COUNT(*) INTO v_existing_ballot_count
    FROM ballot
    WHERE folk_id = p_folk_id AND poll_id = p_poll_id;
    
    IF v_existing_ballot_count > 0 THEN
        ROLLBACK;
        SET p_result_code = 1;
        SET p_result_message = 'Ballot already cast for this poll by this voter';
        LEAVE main_proc;
    END IF;
    
    -- ================================================================
    -- VALIDATION PHASE 2: Check poll availability
    -- ================================================================
    SELECT availability_start, availability_end 
    INTO v_poll_available_start, v_poll_available_end
    FROM poll
    WHERE short_name = p_poll_id;
    
    IF v_poll_available_start IS NULL THEN
        ROLLBACK;
        SET p_result_code = 2;
        SET p_result_message = 'Poll does not exist';
        LEAVE main_proc;
    END IF;
    
    IF v_current_datetime < v_poll_available_start OR v_current_datetime > v_poll_available_end THEN
        ROLLBACK;
        SET p_result_code = 3;
        SET p_result_message = 'Poll is not currently available for voting';
        LEAVE main_proc;
    END IF;
    
    -- ================================================================
    -- VALIDATION PHASE 3: Find valid registration
    -- ================================================================
    SELECT registration_id, COUNT(*) 
    INTO v_registration_id, v_registration_count
    FROM registration
    WHERE folk_id = p_folk_id 
      AND poll_id = p_poll_id
      AND center_id = p_expected_center_id
      AND voting_date = p_voting_date
      AND is_valid = TRUE
    GROUP BY registration_id;
    
    IF v_registration_count = 0 THEN
        ROLLBACK;
        SET p_result_code = 4;
        SET p_result_message = 'No valid registration found for this voter, poll, center, and date';
        LEAVE main_proc;
    END IF;
    
    IF v_registration_count > 1 THEN
        ROLLBACK;
        SET p_result_code = 5;
        SET p_result_message = 'Multiple registrations found - data integrity issue';
        LEAVE main_proc;
    END IF;
    
    -- ================================================================
    -- VALIDATION PHASE 4: Check voting center operating hours
    -- ================================================================
    SELECT COUNT(*) INTO v_center_operating
    FROM operating_period op
    WHERE op.center_id = p_expected_center_id
      AND p_voting_date >= DATE(op.period_start)
      AND p_voting_date <= DATE(op.period_end)
      AND v_current_datetime >= op.period_start
      AND v_current_datetime <= op.period_end;
    
    IF v_center_operating = 0 THEN
        ROLLBACK;
        SET p_result_code = 6;
        SET p_result_message = 'Voting center is not currently operating';
        LEAVE main_proc;
    END IF;
    
    -- ================================================================
    -- BALLOT CASTING: All validations passed
    -- ================================================================
    INSERT INTO ballot (folk_id, poll_id, vote_choice, cast_datetime, registration_id)
    VALUES (p_folk_id, p_poll_id, p_vote_choice, v_current_datetime, v_registration_id);
    
    -- ================================================================
    -- SUCCESS: Commit transaction
    -- ================================================================
    COMMIT;
    SET p_result_code = 0;
    SET p_result_message = CONCAT('Ballot successfully cast for poll ', p_poll_id, ' with vote: ', p_vote_choice);
    
END //

DELIMITER ;

-- ================================================================
-- SAMPLE USAGE WITH SCRIPTING VARIABLES
-- ================================================================

-- @folk_id, @poll_id, @vote_choice, @center_id, @voting_date
SET @folk_id = '1234567890123407';
SET @poll_id = 'POL4';
SET @vote_choice = 'YES';
SET @center_id = 1;
SET @voting_date = '2025-02-25';

-- Call the transactional procedure
CALL cast_ballot_transaction(
    @folk_id, 
    @poll_id, 
    @vote_choice, 
    @center_id, 
    @voting_date,
    @result_code, 
    @result_message
);

-- Display results
SELECT 
    @folk_id AS folk_id,
    @poll_id AS poll_id,
    @vote_choice AS vote_choice,
    @result_code AS result_code,
    @result_message AS result_message;

-- ================================================================
-- ADDITIONAL TEST CASES
-- ================================================================

-- Test Case 1: Successful ballot casting
SELECT 'Test Case 1: Valid ballot casting' AS test_description;
CALL cast_ballot_transaction(
    '1234567890123403', 'POL4', 'NO', 1, '2025-02-20',
    @result_code, @result_message
);
SELECT @result_code AS result_code, @result_message AS result_message;

-- Test Case 2: Attempt duplicate ballot (should fail)
SELECT 'Test Case 2: Duplicate ballot attempt' AS test_description;
CALL cast_ballot_transaction(
    '1234567890123401', 'POL1', 'NO', 1, '2025-01-20',
    @result_code, @result_message
);
SELECT @result_code AS result_code, @result_message AS result_message;

-- Test Case 3: Invalid registration (should fail)
SELECT 'Test Case 3: No valid registration' AS test_description;
CALL cast_ballot_transaction(
    '1234567890123412', 'POL1', 'YES', 1, '2025-01-15',
    @result_code, @result_message
);
SELECT @result_code AS result_code, @result_message AS result_message;

-- Test Case 4: Poll not available (should fail if tested outside poll availability)
SELECT 'Test Case 4: Poll availability check' AS test_description;

-- ================================================================
-- CONCURRENT TESTING EXAMPLE
-- ================================================================

/*
--To test concurrent operations, run the following in multiple database connections:

--CONNECTION 1:
CALL cast_ballot_transaction('1234567890123405', 'POL4', 'YES', 3, '2025-02-22', @r1, @m1);

--CONNECTION 2 (simultaneously):
CALL cast_ballot_transaction('1234567890123411', 'POL4', 'NO', 3, '2025-02-26', @r2, @m2);

--Both should succeed as they don't interfere with each other's data.

--CONNECTION 3 (attempting duplicate):
CALL cast_ballot_transaction('1234567890123405', 'POL4', 'NO', 3, '2025-02-22', @r3, @m3);

--This should fail with duplicate ballot error.
*/

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Show all successful ballot castings
SELECT 'Recent successful ballot castings' AS description;
SELECT 
    b.folk_id,
    CONCAT(f.first_name, ' ', f.last_name) AS voter_name,
    b.poll_id,
    b.vote_choice,
    b.cast_datetime,
    vc.acronym AS center
FROM ballot b
JOIN folk f ON b.folk_id = f.personal_id
JOIN registration r ON b.registration_id = r.registration_id
JOIN voting_center vc ON r.center_id = vc.place_id
ORDER BY b.cast_datetime DESC;

-- Show registration vs ballot summary
SELECT 'Registration vs Ballot Summary' AS description;
SELECT 
    COUNT(DISTINCT r.registration_id) AS total_valid_registrations,
    COUNT(DISTINCT b.folk_id) AS unique_voters,
    COUNT(b.folk_id) AS total_ballots_cast,
    ROUND(COUNT(b.folk_id) / COUNT(DISTINCT r.registration_id) * 100, 2) AS turnout_percentage
FROM registration r
LEFT JOIN ballot b ON r.folk_id = b.folk_id AND r.poll_id = b.poll_id
WHERE r.is_valid = TRUE;
