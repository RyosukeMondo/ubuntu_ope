#!/usr/bin/env python3

import json
import subprocess
import os
import sys

# Get all repositories
result = subprocess.run(['gh', 'repo', 'list', 'RyosukeMondo', '--limit', '1000', '--json', 'nameWithOwner'],
                       capture_output=True, text=True)

repos = json.loads(result.stdout)

cloned_count = 0
skipped_count = 0
failed_count = 0

for repo in repos:
    name_with_owner = repo['nameWithOwner']
    repo_name = name_with_owner.split('/')[-1]

    if os.path.isdir(repo_name):
        print(f"Skipping {repo_name} (already exists)")
        sys.stdout.flush()
        skipped_count += 1
    else:
        print(f"Cloning {repo_name}...", end=' ')
        sys.stdout.flush()
        result = subprocess.run(['gh', 'repo', 'clone', name_with_owner, repo_name])
        if result.returncode == 0:
            print("✓")
            sys.stdout.flush()
            cloned_count += 1
        else:
            print("✗")
            sys.stdout.flush()
            failed_count += 1

print(f"\nSummary:")
print(f"  Cloned: {cloned_count}")
print(f"  Skipped: {skipped_count}")
print(f"  Failed: {failed_count}")
