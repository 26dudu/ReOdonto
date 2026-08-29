import os
import sys
from app import app

print("=== REGISTERED ROUTES ===")
for rule in app.url_map.iter_rules():
    methods = ','.join(sorted(rule.methods - {'HEAD', 'OPTIONS'}))
    print(f"{rule.rule:50} {methods:20}")
