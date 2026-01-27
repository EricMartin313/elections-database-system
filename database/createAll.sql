-- ================================================================
-- Elections Database Management System:
-- createAll.sql
--
-- Author: Eric Martin
-- Purpose: Creates tables, constraints, indexes, and functions
-- Usage: mysql -u username -p elections_db < createAll.sql
-- ================================================================

-- Set character set and storage engine defaults
SET NAMES utf8mb4;
SET default_storage_engine = InnoDB;

-- ================================================================
-- TABLE CREATION (in dependency order)
-- ================================================================

-- 1. PLACE TABLE (no dependencies)
CREATE TABLE place (
    place_id INT AUTO_INCREMENT PRIMARY KEY,
    street_number VARCHAR(10) NOT NULL,
    street_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zipcode CHAR(5) NOT NULL,
    -- Precision coordinates for accurate geographic calculations
    x_coordinate DECIMAL(12,6) NOT NULL,
    y_coordinate DECIMAL(12,6) NOT NULL,
    place_type ENUM('RESIDENCE', 'VOTING_CENTER') NOT NULL,
    
    -- Unique constraints
    UNIQUE KEY uk_place_address (street_number, street_name, city, state, zipcode),
    UNIQUE KEY uk_place_coordinates (x_coordinate, y_coordinate),
    
    -- Check constraints
    CONSTRAINT chk_coordinates CHECK (x_coordinate BETWEEN -1000 AND 1000 AND y_coordinate BETWEEN -1000 AND 1000)
);

-- 2. VOTING_CENTER TABLE (depends on Place)
CREATE TABLE voting_center (
    place_id INT PRIMARY KEY,
    acronym CHAR(4) NOT NULL,
    
    -- Constraints
    UNIQUE KEY uk_vc_acronym (acronym),
    CONSTRAINT fk_vc_place FOREIGN KEY (place_id) REFERENCES place(place_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Check that acronym is alphanumeric
    CONSTRAINT chk_vc_acronym CHECK (acronym REGEXP '^[A-Z0-9]{4}$')
);

-- 3. RESIDENCE TABLE (depends on Place)
CREATE TABLE residence (
    place_id INT PRIMARY KEY,
    
    CONSTRAINT fk_res_place FOREIGN KEY (place_id) REFERENCES place(place_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. FOLK TABLE (depends on Residence)
CREATE TABLE folk (
    personal_id CHAR(16) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    nickname VARCHAR(50),
    date_of_birth DATE NOT NULL,
    primary_phone CHAR(10) NOT NULL,
    secondary_phone CHAR(10),
    residence_id INT NOT NULL,
    
    -- Foreign key constraints
    CONSTRAINT fk_folk_residence FOREIGN KEY (residence_id) REFERENCES residence(place_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_personal_id CHECK (personal_id REGEXP '^[0-9]{16}$'),
    CONSTRAINT chk_primary_phone CHECK (primary_phone REGEXP '^[0-9]{10}$'),
    CONSTRAINT chk_secondary_phone CHECK (secondary_phone IS NULL OR secondary_phone REGEXP '^[0-9]{10}$'),
    CONSTRAINT chk_birth_date CHECK (date_of_birth <= CURDATE())
);

-- 5. STAFF TABLE (depends on Folk)
CREATE TABLE staff (
    personal_id CHAR(16) PRIMARY KEY,
    staff_type ENUM('CLERK', 'MONITOR') NOT NULL,
    
    CONSTRAINT fk_staff_folk FOREIGN KEY (personal_id) REFERENCES folk(personal_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 6. EMAIL TABLE (depends on Folk)
CREATE TABLE email (
    folk_id CHAR(16) NOT NULL,
    email_address VARCHAR(255) NOT NULL,
    
    PRIMARY KEY (folk_id, email_address),
    CONSTRAINT fk_email_folk FOREIGN KEY (folk_id) REFERENCES folk(personal_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Check email format
    CONSTRAINT chk_email_format CHECK (email_address REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
);

-- 7. POLL TABLE (no dependencies)
CREATE TABLE poll (
    short_name CHAR(4) PRIMARY KEY,
    question_text TEXT NOT NULL,
    availability_start DATETIME NOT NULL,
    availability_end DATETIME NOT NULL,
    
    -- Check constraints
    CONSTRAINT chk_poll_short_name CHECK (short_name REGEXP '^[A-Z0-9]{4}$'),
    CONSTRAINT chk_poll_dates CHECK (availability_start < availability_end)
);

-- 8. OPERATING_PERIOD TABLE (depends on VotingCenter)
CREATE TABLE operating_period (
    center_id INT NOT NULL,
    period_start DATETIME NOT NULL,
    period_end DATETIME NOT NULL,
    
    PRIMARY KEY (center_id, period_start),
    CONSTRAINT fk_op_center FOREIGN KEY (center_id) REFERENCES voting_center(place_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_op_dates CHECK (period_start < period_end)
);

-- 9. REGISTRATION TABLE (depends on Folk, Poll, VotingCenter)
CREATE TABLE registration (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    folk_id CHAR(16) NOT NULL,
    poll_id CHAR(4) NOT NULL,
    center_id INT NOT NULL,
    voting_date DATE NOT NULL,
    registration_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Foreign key constraints
    CONSTRAINT fk_reg_folk FOREIGN KEY (folk_id) REFERENCES folk(personal_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reg_poll FOREIGN KEY (poll_id) REFERENCES poll(short_name) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reg_center FOREIGN KEY (center_id) REFERENCES voting_center(place_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Unique constraint - one registration per folk-poll-center-date combination
    UNIQUE KEY uk_registration (folk_id, poll_id, center_id, voting_date),
    
    -- Check constraints
    CONSTRAINT chk_reg_voting_date CHECK (voting_date >= DATE(registration_datetime))
);

-- 10. BALLOT TABLE (depends on Folk, Poll, Registration)
CREATE TABLE ballot (
    folk_id CHAR(16) NOT NULL,
    poll_id CHAR(4) NOT NULL,
    vote_choice ENUM('YES', 'NO', 'ABSTAIN') NOT NULL,
    cast_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registration_id INT NOT NULL,
    
    PRIMARY KEY (folk_id, poll_id),
    
    -- Explicit unique constraint for folk per poll ballot (though PRIMARY KEY already ensures this)
    UNIQUE KEY uk_ballot_folk_poll (folk_id, poll_id),
    
    -- Foreign key constraints for ballot registration validation
    CONSTRAINT fk_ballot_folk FOREIGN KEY (folk_id) REFERENCES folk(personal_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ballot_poll FOREIGN KEY (poll_id) REFERENCES poll(short_name) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ballot_registration FOREIGN KEY (registration_id) REFERENCES registration(registration_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 11. STAFF_SCHEDULE TABLE (depends on Staff, VotingCenter)
CREATE TABLE staff_schedule (
    staff_id CHAR(16) NOT NULL,
    center_id INT NOT NULL,
    shift_start DATETIME NOT NULL,
    shift_end DATETIME NOT NULL,
    
    PRIMARY KEY (staff_id, center_id, shift_start),
    
    -- Foreign key constraints
    CONSTRAINT fk_schedule_staff FOREIGN KEY (staff_id) REFERENCES staff(personal_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_schedule_center FOREIGN KEY (center_id) REFERENCES voting_center(place_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_shift_times CHECK (shift_start < shift_end)
);

-- ================================================================
-- INDEX CREATION (for query optimization)
-- ================================================================

-- Geographic indexes for distance calculations
CREATE INDEX idx_place_coordinates ON place(x_coordinate, y_coordinate);
CREATE INDEX idx_place_city_state ON place(city, state);

-- Temporal indexes for date/time queries
CREATE INDEX idx_registration_date ON registration(voting_date);
CREATE INDEX idx_ballot_datetime ON ballot(cast_datetime);
CREATE INDEX idx_operating_period_dates ON operating_period(period_start, period_end);

-- Foreign key indexes (some may be auto-created by MySQL)
CREATE INDEX idx_folk_residence ON folk(residence_id);
CREATE INDEX idx_registration_poll ON registration(poll_id);
CREATE INDEX idx_registration_center ON registration(center_id);
CREATE INDEX idx_ballot_registration ON ballot(registration_id);

-- ================================================================
-- CUSTOM FUNCTIONS
-- ================================================================

DELIMITER //

-- Function to get the closest voting center to a folk's residence
-- that is operating on a given date
CREATE FUNCTION get_closest_voting_center(
    folk_personal_id CHAR(16),
    target_date DATE
)
RETURNS CHAR(4)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE result_acronym CHAR(4) DEFAULT NULL;
    
    SELECT vc.acronym INTO result_acronym
    FROM voting_center vc
    JOIN place p_vc ON vc.place_id = p_vc.place_id
    JOIN operating_period op ON vc.place_id = op.center_id
    JOIN folk f ON f.personal_id = folk_personal_id
    JOIN residence r ON f.residence_id = r.place_id
    JOIN place p_res ON r.place_id = p_res.place_id
    WHERE target_date >= DATE(op.period_start) 
      AND target_date <= DATE(op.period_end)
    ORDER BY 
        SQRT(POW(p_vc.x_coordinate - p_res.x_coordinate, 2) + 
             POW(p_vc.y_coordinate - p_res.y_coordinate, 2)),
        vc.acronym  -- tie breaker
    LIMIT 1;
    
    RETURN result_acronym;
END //

DELIMITER ;

-- ================================================================
-- TRIGGERS FOR BUSINESS RULE ENFORCEMENT
-- ================================================================

DELIMITER //

-- Trigger to validate registration dates against operating periods
CREATE TRIGGER validate_registration_before_insert
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN
    DECLARE period_count INT DEFAULT 0;
    
    -- Check if the voting date falls within any operating period of the center
    SELECT COUNT(*) INTO period_count
    FROM operating_period op
    WHERE op.center_id = NEW.center_id
      AND NEW.voting_date >= DATE(op.period_start)
      AND NEW.voting_date <= DATE(op.period_end);
    
    -- If no valid operating period found, mark as invalid
    IF period_count = 0 THEN
        SET NEW.is_valid = FALSE;
    END IF;
END //

-- Enhanced trigger for ballot registration validation
CREATE TRIGGER validate_ballot_before_insert
BEFORE INSERT ON ballot
FOR EACH ROW
BEGIN
    DECLARE reg_count INT DEFAULT 0;
    DECLARE reg_folk_id CHAR(16);
    DECLARE reg_poll_id CHAR(4);
    
    -- Check if valid registration exists and matches folk/poll
    SELECT COUNT(*), MAX(r.folk_id), MAX(r.poll_id) INTO reg_count, reg_folk_id, reg_poll_id
    FROM registration r
    WHERE r.registration_id = NEW.registration_id
      AND r.folk_id = NEW.folk_id
      AND r.poll_id = NEW.poll_id
      AND r.is_valid = TRUE;
    
    -- If no valid registration found, raise error
    IF reg_count = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot cast ballot without valid registration';
    END IF;
    
    -- Additional check for mismatched folk/poll IDs
    IF reg_folk_id != NEW.folk_id OR reg_poll_id != NEW.poll_id THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ballot folk/poll IDs must match registration';
    END IF;
END //

-- Trigger to prevent operating period modifications when registrations exist
CREATE TRIGGER prevent_operating_period_update
BEFORE UPDATE ON operating_period
FOR EACH ROW
BEGIN
    DECLARE reg_count INT DEFAULT 0;
    
    -- Check if any registrations exist for this center during the current period
    SELECT COUNT(*) INTO reg_count
    FROM registration r
    WHERE r.center_id = OLD.center_id
      AND r.voting_date >= DATE(OLD.period_start)
      AND r.voting_date <= DATE(OLD.period_end);
    
    -- If registrations exist, prevent modification
    IF reg_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot modify operating period when registrations exist for this time period';
    END IF;
END //

CREATE TRIGGER prevent_operating_period_delete
BEFORE DELETE ON operating_period
FOR EACH ROW
BEGIN
    DECLARE reg_count INT DEFAULT 0;
    
    -- Check if any registrations exist for this center during this period
    SELECT COUNT(*) INTO reg_count
    FROM registration r
    WHERE r.center_id = OLD.center_id
      AND r.voting_date >= DATE(OLD.period_start)
      AND r.voting_date <= DATE(OLD.period_end);
    
    -- If registrations exist, prevent deletion
    IF reg_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete operating period when registrations exist for this time period';
    END IF;
END //

-- Trigger to prevent poll modifications when ballots exist
CREATE TRIGGER prevent_poll_modification
BEFORE UPDATE ON poll
FOR EACH ROW
BEGIN
    DECLARE ballot_count INT DEFAULT 0;
    
    -- Check if any ballots exist for this poll
    SELECT COUNT(*) INTO ballot_count
    FROM ballot b
    WHERE b.poll_id = OLD.short_name;
    
    -- If ballots exist, prevent modification
    IF ballot_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot modify poll when ballots have been cast';
    END IF;
END //

CREATE TRIGGER prevent_poll_delete
BEFORE DELETE ON poll
FOR EACH ROW
BEGIN
    DECLARE ballot_count INT DEFAULT 0;
    
    -- Check if any ballots exist for this poll
    SELECT COUNT(*) INTO ballot_count
    FROM ballot b
    WHERE b.poll_id = OLD.short_name;
    
    -- If ballots exist, prevent deletion
    IF ballot_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete poll when ballots have been cast';
    END IF;
END //

DELIMITER ;

-- ================================================================
-- VIEWS FOR COMMON QUERIES
-- ================================================================

-- View for active polls
CREATE VIEW active_polls AS
SELECT 
    short_name,
    question_text,
    availability_start,
    availability_end
FROM poll
WHERE CURRENT_TIMESTAMP BETWEEN availability_start AND availability_end;

-- View for current registrations
CREATE VIEW current_registrations AS
SELECT 
    r.registration_id,
    f.first_name,
    f.last_name,
    p.short_name as poll_name,
    vc.acronym as center_acronym,
    r.voting_date,
    r.is_valid
FROM registration r
JOIN folk f ON r.folk_id = f.personal_id
JOIN poll p ON r.poll_id = p.short_name
JOIN voting_center vc ON r.center_id = vc.place_id
WHERE r.is_valid = TRUE;

-- View for voting center summary
CREATE VIEW voting_center_summary AS
SELECT 
    vc.acronym,
    pl.city,
    pl.state,
    pl.x_coordinate,
    pl.y_coordinate,
    COUNT(DISTINCT r.folk_id) as registered_voters,
    COUNT(DISTINCT b.folk_id) as ballots_cast
FROM voting_center vc
JOIN place pl ON vc.place_id = pl.place_id
LEFT JOIN registration r ON vc.place_id = r.center_id AND r.is_valid = TRUE
LEFT JOIN ballot b ON r.registration_id = b.registration_id
GROUP BY vc.place_id, vc.acronym, pl.city, pl.state, pl.x_coordinate, pl.y_coordinate;

-- ================================================================
-- COMPLETION MESSAGE
-- ================================================================

SELECT 'Database schema created successfully!' as Status,
       'All fixes applied: enhanced foreign keys, validation triggers, improved precision, unique constraints' as Details;
