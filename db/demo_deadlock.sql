
USE crisiscore;

CALL sp_allocate_resource(6, 4);

INSERT INTO Task_Waiting (task_id, resource_id)
VALUES (6, 3);

CALL sp_detect_deadlock();

SELECT *
FROM Transaction_Log
ORDER BY 1 DESC
LIMIT 10;
