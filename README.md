# CrisisCore

Alert-driven emergency resource coordination. Team Eclipse (T233), Graphic Era (Deemed to be University), Dehradun. Mentor: Ms. Anamika Sharma.

An alert (sensor feed, agency feed, control room) is scored by the database, becomes a prioritized task, and the nearest free unit is dispatched with row locks so no unit is ever double-booked. Completing a mission frees the unit and gives it to the next waiting task. Deadlocks are detected and recovered.

**Stack:** MySQL 8.4 InnoDB, Python FastAPI, single-file HTML/JS dashboard.

## What we fixed after Phase-II feedback
- Any hazard: new hazard is one row in `Hazard_Playbook`, no code change
- How incidents are reported: alert intake from three sources into one `Alert` table
- Who decides severity: rule table `Priority_Config`, audit trail in `Alert_Decision`, operator override needs a reason

## Run
See `docs/RUNBOOK_v2.md`. Short version:
```
mysql -u root -p crisiscore < db/migration_v2.sql
mysql -u root -p crisiscore < db/reset_demo.sql
cd backend && uvicorn main:app --reload
```
Open `frontend/crisiscore.html`.

## Proof Lab
- `python tests/concurrency_test.py 100` many simultaneous dispatches, checks double bookings
- `python tests/benchmark.py` FCFS vs Priority vs Priority+aging (simulation)
- `python tests/crash_test.py prepare` then restart MySQL, then `python tests/crash_test.py verify`

## Folders
`db/` schema, migration, demo data | `backend/` FastAPI | `frontend/` dashboard | `tests/` Proof Lab scripts | `docs/` run book, API routes

## Limitations
Sensor/agency feeds are simulated, people and access values are demo assumptions, benchmark is a policy simulation, single MySQL node, no login.

## Team
Saniyalochan (lead, backend), Chaitanya Chamoli (database), Aarish Siddiqui and Pranav Mengi (frontend, tests, docs).
