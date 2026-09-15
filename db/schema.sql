

CREATE DATABASE IF NOT EXISTS crisiscore;
USE crisiscore;

-- Core tables
CREATE TABLE Emergency (
    emergency_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Incident (
    incident_id INT AUTO_INCREMENT PRIMARY KEY,
    emergency_id INT NOT NULL,
    location VARCHAR(150) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    victims_count INT DEFAULT 0,
    reported_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (emergency_id) REFERENCES Emergency(emergency_id)
);

CREATE TABLE Task (
    task_id INT AUTO_INCREMENT PRIMARY KEY,
    incident_id INT NOT NULL,
    task_type VARCHAR(50) NOT NULL,
    priority INT NOT NULL,
    state VARCHAR(20) DEFAULT 'new',
    arrival_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    completed_at DATETIME,
    FOREIGN KEY (incident_id) REFERENCES Incident(incident_id)
);

CREATE TABLE Resource (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_type VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'available',
    location VARCHAR(150)
);

CREATE TABLE Resource_Allocation (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    resource_id INT NOT NULL,
    acquired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    released_at DATETIME NULL,
    FOREIGN KEY (task_id) REFERENCES Task(task_id),
    FOREIGN KEY (resource_id) REFERENCES Resource(resource_id)
);

-- Banker's Algorithm support tables
CREATE TABLE Resource_Type_Pool (
    resource_type VARCHAR(50) PRIMARY KEY,
    total_instances INT NOT NULL
);

CREATE TABLE Task_Max_Claim (
    task_id INT NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    max_claim INT NOT NULL,
    PRIMARY KEY (task_id, resource_type),
    FOREIGN KEY (task_id) REFERENCES Task(task_id)
);

-- Write-ahead-style logging
CREATE TABLE Transaction_Log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- Priority-ordered scheduling view
CREATE VIEW v_task_queue AS
SELECT task_id, incident_id, task_type, priority, state, arrival_time
FROM Task
WHERE state IN ('new', 'ready')
ORDER BY priority DESC, arrival_time ASC;

-- Trigger: prevent double-booking a resource
DELIMITER //
CREATE TRIGGER trg_prevent_double_allocation
BEFORE INSERT ON Resource_Allocation
FOR EACH ROW
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count
    FROM Resource_Allocation
    WHERE resource_id = NEW.resource_id AND released_at IS NULL;

    IF existing_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This resource is already allocated to another active task.';
    END IF;
END //
DELIMITER ;

-- Trigger: automatically log every allocation
DELIMITER //
CREATE TRIGGER trg_log_allocation
AFTER INSERT ON Resource_Allocation
FOR EACH ROW
BEGIN
    INSERT INTO Transaction_Log (action_type, table_name, record_id, details)
    VALUES ('ALLOCATE', 'Resource_Allocation', NEW.allocation_id,
            CONCAT('Task ', NEW.task_id, ' allocated Resource ', NEW.resource_id));
END //
DELIMITER ;

-- Stored procedure: safe, locked resource allocation
DELIMITER //
CREATE PROCEDURE sp_allocate_resource(
    IN p_task_id INT,
    IN p_resource_id INT
)
BEGIN
    DECLARE resource_status VARCHAR(20);

    START TRANSACTION;

    SELECT status INTO resource_status
    FROM Resource
    WHERE resource_id = p_resource_id
    FOR UPDATE;

    IF resource_status = 'available' THEN
        INSERT INTO Resource_Allocation (task_id, resource_id)
        VALUES (p_task_id, p_resource_id);

        UPDATE Resource
        SET status = 'allocated'
        WHERE resource_id = p_resource_id;

        UPDATE Task
        SET state = 'running', started_at = NOW()
        WHERE task_id = p_task_id;

        COMMIT;
        SELECT 'Allocation successful' AS result;
    ELSE
        ROLLBACK;
        SELECT 'Allocation failed: resource not available' AS result;
    END IF;
END //
DELIMITER ;

-- Stored procedure: Banker's Algorithm safety check
DELIMITER //
CREATE PROCEDURE sp_run_banker_check(
    IN p_task_id INT,
    IN p_resource_type VARCHAR(50),
    OUT p_is_safe BOOLEAN
)
BEGIN
    DECLARE v_total INT;
    DECLARE v_allocated INT;
    DECLARE v_max_claim INT;
    DECLARE v_available INT;
    DECLARE v_need INT;

    SELECT total_instances INTO v_total
    FROM Resource_Type_Pool
    WHERE resource_type = p_resource_type;

    SELECT COUNT(*) INTO v_allocated
    FROM Resource_Allocation ra
    JOIN Resource r ON r.resource_id = ra.resource_id
    WHERE r.resource_type = p_resource_type AND ra.released_at IS NULL;

    SET v_available = v_total - v_allocated;

    SELECT max_claim INTO v_max_claim
    FROM Task_Max_Claim
    WHERE task_id = p_task_id AND resource_type = p_resource_type;

    SET v_need = v_max_claim;

    IF v_need <= v_available THEN
        SET p_is_safe = TRUE;
    ELSE
        SET p_is_safe = FALSE;
    END IF;
END //
DELIMITER ;