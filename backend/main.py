from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import mysql.connector

DB_PASSWORD = "Berry@12345"

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password=DB_PASSWORD,
        database="crisiscore"
    )


# Which resource type each incident type needs
NEEDS = {
    "fire": "rescue_team",
    "flood": "rescue_team",
    "building collapse": "rescue_team",
    "road accident": "ambulance",
    "medical emergency": "ambulance",
}


@app.get("/")
def root():
    return {"message": "CrisisCore backend is running"}


@app.get("/tasks/queue")
def get_task_queue():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM v_task_queue")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


@app.post("/allocate")
def allocate_resource(task_id: int, resource_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.callproc("sp_allocate_resource", [task_id, resource_id])

    result = None
    for res in cursor.stored_results():
        result = res.fetchall()

    conn.commit()
    cursor.close()
    conn.close()

    if not result:
        raise HTTPException(status_code=500, detail="No result returned from procedure")

    return {"result": result[0]["result"]}


@app.get("/banker-check")
def banker_check(task_id: int, resource_type: str):
    conn = get_connection()
    cursor = conn.cursor()

    args = cursor.callproc("sp_run_banker_check", (task_id, resource_type, 0))
    is_safe = args[2]

    cursor.close()
    conn.close()

    return {"task_id": task_id, "resource_type": resource_type, "safe": bool(is_safe)}


@app.get("/resources")
def get_resources():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT resource_id, resource_type, name, status FROM Resource")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


@app.get("/resources/{resource_id}/detail")
def resource_detail(resource_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Resource WHERE resource_id=%s", (resource_id,))
    resource = cursor.fetchone()
    cursor.execute("""
        SELECT allocation_id, task_id, acquired_at, released_at
        FROM Resource_Allocation
        WHERE resource_id=%s
        ORDER BY acquired_at DESC LIMIT 1
    """, (resource_id,))
    allocation = cursor.fetchone()
    cursor.close()
    conn.close()
    return {"resource": resource, "latest_allocation": allocation}


@app.post("/deadlock/recover")
def recover_deadlock():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.callproc("sp_recover_deadlock")

    result = None
    for res in cursor.stored_results():
        result = res.fetchall()

    conn.commit()
    cursor.close()
    conn.close()

    if not result:
        raise HTTPException(status_code=500, detail="No result returned")

    return {"result": result[0]["result"]}


@app.get("/deadlock/graph")
def deadlock_graph():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT tw1.task_id AS from_task, ra.task_id AS to_task, tw1.resource_id
        FROM Task_Waiting tw1
        JOIN Resource_Allocation ra
          ON ra.resource_id = tw1.resource_id AND ra.released_at IS NULL
        WHERE tw1.task_id <> ra.task_id
    """)
    edges = cursor.fetchall()
    cursor.close()
    conn.close()
    return edges


@app.get("/logs")
def get_logs():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Transaction_Log ORDER BY logged_at DESC, log_id DESC LIMIT 30")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


@app.get("/banker/matrix")
def banker_matrix(resource_type: str):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT total_instances FROM Resource_Type_Pool WHERE resource_type=%s",
        (resource_type,)
    )
    pool = cursor.fetchone()
    total = pool["total_instances"] if pool else 0

    cursor.execute("""
        SELECT tmc.task_id, tmc.max_claim,
               (SELECT COUNT(*) FROM Resource_Allocation ra
                JOIN Resource r ON r.resource_id = ra.resource_id
                WHERE ra.task_id = tmc.task_id
                  AND r.resource_type = %s
                  AND ra.released_at IS NULL) AS allocated
        FROM Task_Max_Claim tmc
        WHERE tmc.resource_type = %s
    """, (resource_type, resource_type))
    rows = cursor.fetchall()

    cursor.execute("""
        SELECT COUNT(*) AS cnt
        FROM Resource_Allocation ra
        JOIN Resource r ON r.resource_id = ra.resource_id
        WHERE r.resource_type = %s AND ra.released_at IS NULL
    """, (resource_type,))
    allocated_total = cursor.fetchone()["cnt"]
    available = total - allocated_total

    cursor.close()
    conn.close()

    for r in rows:
        r["need"] = r["max_claim"] - r["allocated"]

    return {"total": total, "available": available, "rows": rows}


@app.post("/incidents/report")
def report_incident(location: str, incident_type: str, severity: str, victims: int = 0,
                    latitude: float = None, longitude: float = None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "INSERT INTO Incident (emergency_id, location, latitude, longitude, victims_count) "
        "VALUES (%s, %s, %s, %s, %s)",
        (1, location, latitude, longitude, victims)
    )
    incident_id = cursor.lastrowid

    priority = {"critical": 10, "high": 8, "medium": 5, "low": 2}.get(severity.lower(), 5)

    cursor.execute(
        "INSERT INTO Task (incident_id, task_type, priority) VALUES (%s, %s, %s)",
        (incident_id, incident_type, priority)
    )
    task_id = cursor.lastrowid

    rtype = NEEDS.get(incident_type.lower(), "ambulance")
    cursor.execute(
        "INSERT INTO Task_Max_Claim (task_id, resource_type, max_claim) VALUES (%s, %s, 1)",
        (task_id, rtype)
    )

    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Incident reported", "incident_id": incident_id, "task_id": task_id}


@app.get("/incidents")
def get_incidents():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT i.incident_id, i.location, i.latitude, i.longitude, i.victims_count, i.reported_at,
               t.task_id, t.task_type, t.priority, t.state, r.name AS assigned_unit
        FROM Incident i
        LEFT JOIN Task t ON t.incident_id = i.incident_id
        LEFT JOIN Resource_Allocation ra ON ra.task_id = t.task_id AND ra.released_at IS NULL
        LEFT JOIN Resource r ON r.resource_id = ra.resource_id
        ORDER BY i.reported_at DESC
        LIMIT 30
    """)
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result