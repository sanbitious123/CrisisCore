
USE crisiscore;

SELECT resource_id, name, status
FROM Resource
WHERE resource_id = 1;

START TRANSACTION;

UPDATE Resource
SET name = CONCAT(name, '_UNCOMMITTED')
WHERE resource_id = 1;

SELECT resource_id, name
FROM Resource
WHERE resource_id = 1;

START TRANSACTION;

UPDATE Resource
SET name = CONCAT(name, '_COMMITTED')
WHERE resource_id = 1;

COMMIT;

SELECT resource_id, name, status
FROM Resource
WHERE resource_id = 1;

UPDATE Resource
SET name = REPLACE(name, '_COMMITTED', '')
WHERE resource_id = 1;

SELECT resource_id, name, status
FROM Resource
WHERE resource_id = 1;

SELECT *
FROM Transaction_Log
ORDER BY 1 DESC
LIMIT 10;
