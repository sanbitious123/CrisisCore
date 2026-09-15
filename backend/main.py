from fastapi import FastAPI, HTTPException
import mysql.connector

app = FastAPI()
from fastapi.middleware.cors import CORSMiddleware

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
        password="Berry@12345",
        database="crisiscore"
    )


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