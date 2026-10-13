-- MySQL dump 10.13  Distrib 8.4.11, for Win64 (x86_64)
--
-- Host: localhost    Database: crisiscore
-- ------------------------------------------------------
-- Server version	8.4.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `emergency`
--

DROP TABLE IF EXISTS `emergency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `emergency` (
  `emergency_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `severity` varchar(20) NOT NULL,
  `status` varchar(20) DEFAULT 'active',
  `started_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`emergency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `incident`
--

DROP TABLE IF EXISTS `incident`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incident` (
  `incident_id` int NOT NULL AUTO_INCREMENT,
  `emergency_id` int NOT NULL,
  `location` varchar(150) NOT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `LONGITUDE` decimal(9,6) DEFAULT NULL,
  `victims_count` int DEFAULT '0',
  `reported_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`incident_id`),
  KEY `emergency_id` (`emergency_id`),
  CONSTRAINT `incident_ibfk_1` FOREIGN KEY (`emergency_id`) REFERENCES `emergency` (`emergency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resource`
--

DROP TABLE IF EXISTS `resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource` (
  `resource_id` int NOT NULL AUTO_INCREMENT,
  `resource_type` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `status` varchar(20) DEFAULT 'available',
  `location` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`resource_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resource_allocation`
--

DROP TABLE IF EXISTS `resource_allocation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_allocation` (
  `allocation_id` int NOT NULL AUTO_INCREMENT,
  `task_id` int NOT NULL,
  `resource_id` int NOT NULL,
  `acquired_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `released_at` datetime DEFAULT NULL,
  PRIMARY KEY (`allocation_id`),
  KEY `task_id` (`task_id`),
  KEY `resource_id` (`resource_id`),
  CONSTRAINT `resource_allocation_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`),
  CONSTRAINT `resource_allocation_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`resource_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_prevent_double_allocation` BEFORE INSERT ON `resource_allocation` FOR EACH ROW BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count
    FROM Resource_Allocation
    WHERE resource_id = NEW.resource_id AND released_at IS NULL;

    IF existing_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This resource is already allocated to another active task.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_log_allocation` AFTER INSERT ON `resource_allocation` FOR EACH ROW BEGIN
    INSERT INTO Transaction_Log (action_type, table_name, record_id, details)
    VALUES ('ALLOCATE', 'Resource_Allocation', NEW.allocation_id,
            CONCAT('Task ', NEW.task_id, ' allocated Resource ', NEW.resource_id));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `resource_type_pool`
--

DROP TABLE IF EXISTS `resource_type_pool`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_type_pool` (
  `resource_type` varchar(50) NOT NULL,
  `total_instances` int NOT NULL,
  PRIMARY KEY (`resource_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task`
--

DROP TABLE IF EXISTS `task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task` (
  `task_id` int NOT NULL AUTO_INCREMENT,
  `incident_id` int NOT NULL,
  `task_type` varchar(50) NOT NULL,
  `priority` int NOT NULL,
  `state` varchar(20) DEFAULT 'new',
  `arrival_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  KEY `incident_id` (`incident_id`),
  CONSTRAINT `task_ibfk_1` FOREIGN KEY (`incident_id`) REFERENCES `incident` (`incident_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_max_claim`
--

DROP TABLE IF EXISTS `task_max_claim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_max_claim` (
  `task_id` int NOT NULL,
  `resource_type` varchar(50) NOT NULL,
  `max_claim` int NOT NULL,
  PRIMARY KEY (`task_id`,`resource_type`),
  CONSTRAINT `task_max_claim_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_waiting`
--

DROP TABLE IF EXISTS `task_waiting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_waiting` (
  `wait_id` int NOT NULL AUTO_INCREMENT,
  `task_id` int NOT NULL,
  `resource_id` int NOT NULL,
  `waiting_since` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`wait_id`),
  KEY `task_id` (`task_id`),
  KEY `resource_id` (`resource_id`),
  CONSTRAINT `task_waiting_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`),
  CONSTRAINT `task_waiting_ibfk_2` FOREIGN KEY (`resource_id`) REFERENCES `resource` (`resource_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `transaction_log`
--

DROP TABLE IF EXISTS `transaction_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_log` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `action_type` varchar(50) NOT NULL,
  `table_name` varchar(50) NOT NULL,
  `record_id` int NOT NULL,
  `logged_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `details` text,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `v_task_queue`
--

DROP TABLE IF EXISTS `v_task_queue`;
/*!50001 DROP VIEW IF EXISTS `v_task_queue`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_task_queue` AS SELECT 
 1 AS `task_id`,
 1 AS `incident_id`,
 1 AS `task_type`,
 1 AS `priority`,
 1 AS `state`,
 1 AS `arrival_time`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping routines for database 'crisiscore'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_allocate_resource` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_allocate_resource`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_detect_deadlock` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_detect_deadlock`()
BEGIN
    SELECT 
        tw1.task_id AS task_a,
        tw1.resource_id AS a_waits_for_resource,
        ra1.task_id AS task_b,
        tw2.resource_id AS b_waits_for_resource,
        ra2.task_id AS back_to_task_a
    FROM Task_Waiting tw1
    JOIN Resource_Allocation ra1 
        ON ra1.resource_id = tw1.resource_id AND ra1.released_at IS NULL
    JOIN Task_Waiting tw2 
        ON tw2.task_id = ra1.task_id
    JOIN Resource_Allocation ra2 
        ON ra2.resource_id = tw2.resource_id AND ra2.released_at IS NULL AND ra2.task_id = tw1.task_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_recover_deadlock` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_recover_deadlock`()
BEGIN
    DECLARE v_task_a INT;
    DECLARE v_task_b INT;
    DECLARE v_resource_to_release INT;
    DECLARE v_priority_a INT;
    DECLARE v_priority_b INT;
    DECLARE v_victim_task INT;

    -- Pehla detected cycle utha lo
    SELECT task_a, task_b, b_waits_for_resource
    INTO v_task_a, v_task_b, v_resource_to_release
    FROM (
        SELECT 
            tw1.task_id AS task_a,
            ra1.task_id AS task_b,
            tw2.resource_id AS b_waits_for_resource
        FROM Task_Waiting tw1
        JOIN Resource_Allocation ra1 
            ON ra1.resource_id = tw1.resource_id AND ra1.released_at IS NULL
        JOIN Task_Waiting tw2 
            ON tw2.task_id = ra1.task_id
        JOIN Resource_Allocation ra2 
            ON ra2.resource_id = tw2.resource_id AND ra2.released_at IS NULL AND ra2.task_id = tw1.task_id
        LIMIT 1
    ) AS cycle;

    -- Dono tasks ki priority nikaalo
    SELECT priority INTO v_priority_a FROM Task WHERE task_id = v_task_a;
    SELECT priority INTO v_priority_b FROM Task WHERE task_id = v_task_b;

    -- Jo lowest priority ka hai, wahi victim banega
    IF v_priority_a <= v_priority_b THEN
        SET v_victim_task = v_task_a;
    ELSE
        SET v_victim_task = v_task_b;
    END IF;

    START TRANSACTION;

    -- Victim task ka jo bhi resource allocated tha, wo release karo
    UPDATE Resource_Allocation
    SET released_at = NOW()
    WHERE task_id = v_victim_task AND released_at IS NULL;

    UPDATE Resource r
    JOIN Resource_Allocation ra ON ra.resource_id = r.resource_id
    SET r.status = 'available'
    WHERE ra.task_id = v_victim_task AND ra.released_at IS NOT NULL;

    -- Victim task ko wapas 'new' state mein daalo, taaki dobara try ho
    UPDATE Task SET state = 'new', started_at = NULL WHERE task_id = v_victim_task;

    -- Victim task ki waiting entry hata do (kyunki usko preempt kar diya)
    DELETE FROM Task_Waiting WHERE task_id = v_victim_task;

    -- Log karo ki recovery hui
    INSERT INTO Transaction_Log (action_type, table_name, record_id, details)
    VALUES ('DEADLOCK_RECOVERY', 'Task', v_victim_task,
            CONCAT('Task ', v_victim_task, ' preempted to resolve deadlock cycle with Task ',
                   IF(v_victim_task = v_task_a, v_task_b, v_task_a)));

    COMMIT;

    SELECT CONCAT('Deadlock resolved: Task ', v_victim_task, ' preempted') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_run_banker_check` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_run_banker_check`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_task_queue`
--

/*!50001 DROP VIEW IF EXISTS `v_task_queue`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_task_queue` AS select `task`.`task_id` AS `task_id`,`task`.`incident_id` AS `incident_id`,`task`.`task_type` AS `task_type`,`task`.`priority` AS `priority`,`task`.`state` AS `state`,`task`.`arrival_time` AS `arrival_time` from `task` where (`task`.`state` in ('new','ready')) order by `task`.`priority` desc,`task`.`arrival_time` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-13 23:22:46
