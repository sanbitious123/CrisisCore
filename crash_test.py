"""Crash test: kill MySQL in the middle of a dispatch, then prove InnoDB kept committed work and dropped uncommitted work.

Step 1   python tests/crash_test.py prepare [--kill-cmd "taskkill /F /IM mysqld.exe"]
         (run the terminal as Administrator if you use --kill-cmd; or kill mysqld yourself when it asks)
Step 2   start MySQL again (e.g.  net start MySQL84   or from Services)
Step 3   python tests/crash_test.py verify
"""
import json, os, subprocess, sys, time
import mysql.connector

PASSWORD = os.environ.get("DB_PASSWORD", "Berry@12345")
HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "results")
STATE = os.path.join(RES, "crash_state.json")


def connect():
    return mysql.connector.connect(host="localhost", user="root", password=PASSWORD, database="crisiscore")


def ingest(cur, label):
    a = cur.callproc("sp_ingest_alert", ("proof", "flood", f"[CRASH TEST] {label}", 30.3165, 78.0322, 8, 50000, 3, 0, 0, 0, "", ""))
    return a[9]


def prepare():
    os.makedirs(RES, exist_ok=True)
    kill_cmd = sys.argv[sys.argv.index("--kill-cmd") + 1] if "--kill-cmd" in sys.argv else None
    c = connect(); cur = c.cursor(buffered=True)
    task_a, task_b = ingest(cur, "A committed"), ingest(cur, "B uncommitted")
    c.commit()
    a = cur.callproc("sp_dispatch_task", (task_a, "", 0)); c.commit()
    unit_a = a[2]
    if not unit_a:
        sys.exit("No free rescue team. Run db/reset_demo.sql first.")
    print(f"[1] Task {task_a} dispatched and COMMITTED on unit {unit_a}")
    cur.execute("SELECT resource_id FROM Resource WHERE resource_type='rescue_team' AND status='available' ORDER BY resource_id LIMIT 1")
    row = cur.fetchone()
    if not row:
        sys.exit("Need a second free rescue team.")
    unit_b = row[0]
    c.start_transaction()                                   # dispatch of task B, never committed
    cur.execute("INSERT INTO Resource_Allocation (task_id, resource_id) VALUES (%s,%s)", (task_b, unit_b))
    cur.execute("UPDATE Resource SET status='allocated' WHERE resource_id=%s", (unit_b,))
    cur.execute("UPDATE Task SET state='running', started_at=NOW() WHERE task_id=%s", (task_b,))
    print(f"[2] Task {task_b} dispatch to unit {unit_b} written but NOT committed (transaction is open)")
    json.dump({"task_a": task_a, "unit_a": unit_a, "task_b": task_b, "unit_b": unit_b,
               "killed_at": time.strftime("%H:%M:%S")}, open(STATE, "w"))
    if kill_cmd:
        print(f"[3] Killing MySQL now: {kill_cmd}")
        subprocess.run(kill_cmd, shell=True)
    else:
        print("[3] KILL mysqld NOW (Task Manager -> mysqld.exe -> End task). Waiting...")
    t0 = time.time()
    while time.time() - t0 < 120:
        try:
            cur.execute("SELECT 1"); cur.fetchall(); time.sleep(0.5)
        except Exception:
            print("[4] Connection lost: MySQL is down. Start it again, then run:  python tests/crash_test.py verify")
            return
    print("MySQL was not killed within 2 minutes. Test aborted (open transaction will roll back when this script exits).")


def verify():
    st = json.load(open(STATE))
    c = None
    for _ in range(120):
        try:
            c = connect(); break
        except Exception:
            time.sleep(1)
    if not c:
        sys.exit("MySQL is not reachable. Start it first.")
    cur = c.cursor(dictionary=True)
    q = lambda sql, p=(): (cur.execute(sql, p), cur.fetchall())[1]
    ta = q("SELECT state FROM Task WHERE task_id=%s", (st["task_a"],))[0]["state"]
    tb = q("SELECT state FROM Task WHERE task_id=%s", (st["task_b"],))[0]["state"]
    a_alloc = q("SELECT COUNT(*) n FROM Resource_Allocation WHERE task_id=%s AND released_at IS NULL", (st["task_a"],))[0]["n"]
    b_alloc = q("SELECT COUNT(*) n FROM Resource_Allocation WHERE task_id=%s", (st["task_b"],))[0]["n"]
    unit_b = q("SELECT status FROM Resource WHERE resource_id=%s", (st["unit_b"],))[0]["status"]
    double = q("SELECT COUNT(*) n FROM (SELECT resource_id FROM Resource_Allocation WHERE released_at IS NULL GROUP BY resource_id HAVING COUNT(*)>1) x")[0]["n"]
    log = q("SELECT COUNT(*) n FROM Transaction_Log WHERE action_type='ALLOCATE' AND details LIKE %s", (f"Task {st['task_a']} %",))[0]["n"]
    res = {"killed_at": st["killed_at"], "verified_at": time.strftime("%H:%M:%S"),
           "committed_task_state": ta, "committed_allocation_rows": a_alloc, "committed_log_rows": log,
           "uncommitted_task_state": tb, "uncommitted_allocation_rows": b_alloc, "uncommitted_unit_status": unit_b,
           "double_bookings": double}
    res["passed"] = (ta == "running" and a_alloc == 1 and tb == "new" and b_alloc == 0 and unit_b == "available" and double == 0)
    json.dump(res, open(os.path.join(RES, "crash.json"), "w"), indent=2)
    print(json.dumps(res, indent=2))
    print("\nPASSED: committed work survived, uncommitted work vanished." if res["passed"] else "\nFAILED: look at the values above.")
    # clean up test tasks
    cur.callproc("sp_complete_task", (st["task_a"], 0, "", 0))
    cur.execute("UPDATE Task SET state='cancelled' WHERE task_id=%s AND state='new'", (st["task_b"],))
    c.commit()


if __name__ == "__main__":
    {"prepare": prepare, "verify": verify}.get(sys.argv[1] if len(sys.argv) > 1 else "", lambda: print(__doc__))()
