#!/usr/bin/env python3
"""
file_manifest.py

Scans the project directory and generates a file manifest (fileIndex.luau) listing all .luau modules under src/.
Run this script to update the manifest whenever files change.
"""
import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(PROJECT_ROOT, 'src')
OUTPUT_FILE = os.path.join(PROJECT_ROOT, 'fileIndex.luau')

luau_files = []
for root, dirs, files in os.walk(SRC_DIR):
    for file in files:
        if file.endswith('.luau'):
            rel_path = os.path.relpath(os.path.join(root, file), PROJECT_ROOT)
            luau_files.append(rel_path.replace('\\', '/'))

with open(OUTPUT_FILE, 'w') as f:
    f.write('-- Auto-generated file manifest\n')
    f.write('return {\n')
    for path in sorted(luau_files):
        f.write(f'    "{path}",\n')
    f.write('}\n')

print(f"fileIndex.luau updated with {len(luau_files)} files.")
