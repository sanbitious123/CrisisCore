"""Fires N dispatch requests at once against the real database and prints the verdict.
Usage: python tests/concurrency_test.py [N] [api_url]     (backend must be running; run db/reset_demo.sql first)"""
import json, sys, urllib.request
n = int(sys.argv[1]) if len(sys.argv) > 1 else 100
api = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8000"
r = json.load(urllib.request.urlopen(urllib.request.Request(f"{api}/proof/concurrency?requests={n}", method="POST"), timeout=300))
print(json.dumps(r, indent=2))
print("\nPASSED" if r["passed"] else "\nFAILED")
