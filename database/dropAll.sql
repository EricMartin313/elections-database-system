-- ================================================================
-- Elections Database Management System:
-- dropAll.sql - Script to drop all database objects
-- 
-- Author: Eric Martin
-- Purpose: Clean removal of all project-specific database objects
-- Usage: mysql -u username -p elections_db < dropAll.sql
-- ================================================================

-- Disable foreign key checks to allow dropping tables in any order
SET FOREIGN_KEY_CHECKS = 0;

-- Drop custom functions first
DROP FUNCTION IF EXISTS get_closest_voting_center;

-- Drop all tables (order doesn't matter with FK checks disabled)
DROP TABLE IF EXISTS staff_schedule;
DROP TABLE IF EXISTS ballot;
DROP TABLE IF EXISTS registration;
DROP TABLE IF EXISTS operating_period;
DROP TABLE IF EXISTS email;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS poll;
DROP TABLE IF EXISTS voting_center;
DROP TABLE IF EXISTS residence;
DROP TABLE IF EXISTS folk;
DROP TABLE IF EXISTS place;

-- Drop any views that might exist
DROP VIEW IF EXISTS active_polls;
DROP VIEW IF EXISTS current_registrations;
DROP VIEW IF EXISTS voting_center_summary;

-- Drop any procedures that might exist
DROP PROCEDURE IF EXISTS register_voter;
DROP PROCEDURE IF EXISTS cast_ballot;

-- Drop any triggers that might exist
DROP TRIGGER IF EXISTS validate_registration;
DROP TRIGGER IF EXISTS validate_ballot;
DROP TRIGGER IF EXISTS check_operating_period;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Display completion message
SELECT 'All database objects dropped successfully' AS Status;