# CrisisCore v2 API routes (added in backend/v2.py)

| Method | Route | What it does |
|---|---|---|
| POST | /alerts/ingest | Body: source, hazard, place, latitude, longitude, hazard_score (0-10), people_exposed, access_score (0-10), auto_dispatch. Scores the alert in the DB, creates the task, dispatches the nearest free unit. Same hazard+place within 30 min returns status "duplicate". |
| GET | /alerts | Latest 50 alerts with score, band, task state and assigned unit |
| GET | /alerts/{id} | Score breakdown, all decisions (including operator overrides), playbook, rule config |
| GET | /tasks/board | Running and waiting tasks with unit and waiting minutes |
| POST | /tasks/{id}/dispatch | Dispatch one waiting task (nearest free unit, row lock, Banker check) |
| POST | /tasks/{id}/complete | Finish mission, free the unit, give it to the next waiting task (query: auto=true) |
| POST | /tasks/{id}/override | Body: priority (1-10), operator, reason (required). Logged. |
| GET | /overview | Units free/total per type, task counts, alert count |
| GET | /resources/full | All units with coordinates and current task |
| GET | /playbook | Hazard to task type and unit type |
| GET/PUT | /config, /config/{param}?value= | Severity weights, cut-offs, aging settings |
| GET | /deadlock/cycles | Cycles of any length in the wait-for graph |
| POST | /deadlock/recover-any | Preempt the lowest-priority task in the first cycle |
| POST | /proof/concurrency?requests=100 | N simultaneous dispatches on real units, then checks double bookings |
| POST | /proof/benchmark | FCFS vs Priority vs Priority+aging simulation (30 workloads) |
| GET | /proof/crash | Result of tests/crash_test.py (tests/results/crash.json) |

Original 12 routes are unchanged (see docs/api_routes.md).
