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
-- Dumping data for table `emergency`
--

LOCK TABLES `emergency` WRITE;
/*!40000 ALTER TABLE `emergency` DISABLE KEYS */;
INSERT INTO `emergency` VALUES (1,'Test-Flood','flood','high','active','2026-09-06 01:30:32');
/*!40000 ALTER TABLE `emergency` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `incident`
--

LOCK TABLES `incident` WRITE;
/*!40000 ALTER TABLE `incident` DISABLE KEYS */;
INSERT INTO `incident` VALUES (1,1,'Test Location',NULL,NULL,10,'2026-09-06 01:31:48'),(2,1,'Dehradun',30.316500,78.032200,0,'2026-10-06 09:07:25');
/*!40000 ALTER TABLE `incident` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `resource`
--

LOCK TABLES `resource` WRITE;
/*!40000 ALTER TABLE `resource` DISABLE KEYS */;
INSERT INTO `resource` VALUES (1,'ambulance','Ambulance-01','allocated',NULL),(2,'ambulance','Ambulance-02','allocated',NULL),(3,'rescue_team','Team-Alpha','allocated',NULL),(4,'rescue_team','Team-Beta','allocated',NULL);
/*!40000 ALTER TABLE `resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `resource_allocation`
--

LOCK TABLES `resource_allocation` WRITE;
/*!40000 ALTER TABLE `resource_allocation` DISABLE KEYS */;
INSERT INTO `resource_allocation` VALUES (1,1,1,'2026-09-06 01:35:25','2026-09-06 11:37:34'),(2,2,1,'2026-09-06 11:37:44','2026-09-06 11:43:15'),(3,1,1,'2026-09-06 11:43:19',NULL),(4,3,2,'2026-09-16 01:24:45',NULL),(5,5,3,'2026-09-25 16:51:54',NULL),(6,6,4,'2026-09-25 16:51:59','2026-10-05 14:21:47'),(7,6,4,'2026-10-06 08:59:30',NULL);
/*!40000 ALTER TABLE `resource_allocation` ENABLE KEYS */;
UNLOCK TABLES;
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
-- Dumping data for table `resource_type_pool`
--

LOCK TABLES `resource_type_pool` WRITE;
/*!40000 ALTER TABLE `resource_type_pool` DISABLE KEYS */;
INSERT INTO `resource_type_pool` VALUES ('ambulance',3),('rescue_team',2);
/*!40000 ALTER TABLE `resource_type_pool` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `task`
--

LOCK TABLES `task` WRITE;
/*!40000 ALTER TABLE `task` DISABLE KEYS */;
INSERT INTO `task` VALUES (1,1,'Ambulance Dispatch',8,'running','2026-09-06 01:32:53','2026-09-06 11:43:19',NULL),(2,1,'Ambulance Dispatch',5,'running','2026-09-06 01:33:09','2026-09-06 11:37:44',NULL),(3,1,'rescue_team_deploy',9,'running','2026-09-16 01:13:26','2026-09-16 01:24:45',NULL),(4,1,'rescue_team_deploy',9,'new','2026-09-16 01:16:06',NULL,NULL),(5,1,'rescue_operation_A',7,'running','2026-09-25 16:25:39','2026-09-25 16:51:54',NULL),(6,1,'rescue_operation_B',6,'running','2026-09-25 16:25:41','2026-10-06 08:59:30',NULL),(7,2,'Fire',8,'new','2026-10-06 09:07:25',NULL,NULL);
/*!40000 ALTER TABLE `task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `task_max_claim`
--

LOCK TABLES `task_max_claim` WRITE;
/*!40000 ALTER TABLE `task_max_claim` DISABLE KEYS */;
INSERT INTO `task_max_claim` VALUES (1,'ambulance',1),(2,'ambulance',5);
/*!40000 ALTER TABLE `task_max_claim` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `task_waiting`
--

LOCK TABLES `task_waiting` WRITE;
/*!40000 ALTER TABLE `task_waiting` DISABLE KEYS */;
INSERT INTO `task_waiting` VALUES (1,5,4,'2026-09-25 16:52:07');
/*!40000 ALTER TABLE `task_waiting` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `transaction_log`
--

LOCK TABLES `transaction_log` WRITE;
/*!40000 ALTER TABLE `transaction_log` DISABLE KEYS */;
INSERT INTO `transaction_log` VALUES (1,'ALLOCATE','Resource_Allocation',3,'2026-09-06 11:43:19','Task 1 allocated Resource 1'),(2,'ALLOCATE','Resource_Allocation',4,'2026-09-16 01:24:45','Task 3 allocated Resource 2'),(3,'ALLOCATE','Resource_Allocation',5,'2026-09-25 16:51:54','Task 5 allocated Resource 3'),(4,'ALLOCATE','Resource_Allocation',6,'2026-09-25 16:51:59','Task 6 allocated Resource 4'),(5,'DEADLOCK_RECOVERY','Task',6,'2026-10-05 14:21:47','Task 6 preempted to resolve deadlock cycle with Task 5'),(6,'ALLOCATE','Resource_Allocation',7,'2026-10-06 08:59:30','Task 6 allocated Resource 4');
/*!40000 ALTER TABLE `transaction_log` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-18 22:42:05