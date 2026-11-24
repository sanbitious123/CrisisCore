# CrisisCore v2: run steps (do in this order)

1. Copy files into your repo: db/migration_v2.sql, db/reset_demo.sql, backend/v2.py, backend/main.py (only 2 lines added), tests/*.py, frontend/crisiscore.html
2. Backup first:  mysqldump -u root -p crisiscore > backup_before_v2.sql
3. Migration:     mysql -u root -p crisiscore < db/migration_v2.sql      (must show no error)
4. Clean demo:    mysql -u root -p crisiscore < db/reset_demo.sql        (prints 4 resource types)
5. Backend:       cd backend && uvicorn main:app --reload               (needs: pip install pydantic)
6. Open frontend/crisiscore.html in Chrome. Top right should say "Live backend".
7. Test in this order: Alerts -> send 3 alerts -> Dispatch -> Complete a mission -> Proof Lab (1, 2) -> crash test (3).
8. Before the presentation: re-run step 4 so everything starts clean.

If a step errors, send me the exact error text.

## What changed
- Alerts (sensor / agency / control room) -> one Alert table -> sp_ingest_alert scores it from Priority_Config -> task + unit.
- Hazard_Playbook: flood, landslide, forest fire, collapse, medical. New hazard = 1 row.
- sp_dispatch_task: nearest free unit, row locks with SKIP LOCKED, Banker check.
- sp_complete_task: frees the unit and auto-gives it to the next waiting task.
- Operator override needs a reason and is logged (Alert_Decision + Transaction_Log).
- v_task_queue has aging (waiting tasks gain priority).
- sp_recover_deadlock bug fixed (it used to mark all past units of the victim as free). Any-length cycle detection.
- Old routes, old dashboard (frontend/index.html), demo_deadlock.sql still work.
