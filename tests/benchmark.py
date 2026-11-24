"""Scheduler benchmark: FCFS vs Priority vs Priority+Aging. Usage: python tests/benchmark.py [api_url]"""
import json, sys, urllib.request
api = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000"
r = json.load(urllib.request.urlopen(urllib.request.Request(f"{api}/proof/benchmark", method="POST"), timeout=120))
print(f"{r['runs']} random workloads, {r['jobs']} requests each, {r['units']} units")
print(f"{'policy':10} {'critical avg wait':>18} {'low p95 wait':>14} {'low avg wait':>14}")
for p, m in r["policies"].items():
    print(f"{p:10} {m['crit_avg']:>18} {m['low_p95']:>14} {m['low_avg']:>14}")
