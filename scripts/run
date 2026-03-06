#!/usr/bin/env python3
# run.py - build and run a simulation test with Verilator
#
# Usage: scripts/run.py [options] <testname>
# Example: scripts/run.py test_cpu_bringup
#          scripts/run.py --trace test_cpu_bringup_basic
#
# The script will:
#   1. Find <testname>.svh (new style) or <testname>.sv (legacy) under tb/
#   2. For .svh tests: read tb/cpu/bringup/template/bringup_wrapper.sv.tmpl,
#      substitute %%TESTNAME%%, and write a generated top module to rundir/
#   3. Resolve the source filelist (.f): per-test if present, else hdl/cpu/top/cpu.f
#   4. Expand path variables in the filelist
#   5. Compile with Verilator into rundir/<testname>/work/
#   6. Run the simulation (outputs, waveform.vcd land in rundir/<testname>/)

import argparse
import os
import re
import subprocess
import sys

# ---------------------------------------------------------------------------
# Locate repo root (one level up from this script)
# ---------------------------------------------------------------------------
script_dir = os.path.dirname(os.path.abspath(__file__))
repo_root  = os.path.dirname(script_dir)

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
parser = argparse.ArgumentParser(usage='%(prog)s [--trace] <testname>')
parser.add_argument('--trace', action='store_true')
parser.add_argument('testname')
args = parser.parse_args()
testname = args.testname

# ---------------------------------------------------------------------------
# Find the testbench file under tb/ (.svh new style, .sv legacy)
# ---------------------------------------------------------------------------
tb_file    = None
test_style = None

for dirpath, dirnames, filenames in os.walk(os.path.join(repo_root, 'tb')):
    if tb_file:
        break
    for fname in filenames:
        if fname == f'{testname}.svh':
            tb_file    = os.path.join(dirpath, fname)
            test_style = 'svh'
            break
        elif fname == f'{testname}.sv' and tb_file is None:
            tb_file    = os.path.join(dirpath, fname)
            test_style = 'sv'

if tb_file is None:
    sys.exit(f"ERROR: could not find '{testname}.svh' or '{testname}.sv' under {repo_root}/tb")

print(f"testbench : {tb_file}  ({test_style})")

# ---------------------------------------------------------------------------
# Prepare output directories (needed before generating wrapper)
# ---------------------------------------------------------------------------
run_dir  = os.path.join(repo_root, 'rundir', testname)
work_dir = run_dir + '/work' + ('_trace' if args.trace else '')
os.makedirs(work_dir, exist_ok=True)

# ---------------------------------------------------------------------------
# For .svh tests: generate the thin module wrapper from the template.
# For .sv tests:  use the file as-is (legacy path).
# ---------------------------------------------------------------------------
if test_style == 'svh':
    tests_dir   = os.path.dirname(tb_file)                # .../tb/cpu/bringup/tests
    bringup_dir = os.path.dirname(tests_dir)              # .../tb/cpu/bringup
    env_dir     = os.path.join(bringup_dir, 'env')
    tmpl_file   = os.path.join(bringup_dir, 'template', 'bringup_wrapper.sv.tmpl')

    if not os.path.isdir(env_dir):
        sys.exit(f"ERROR: env dir not found: {env_dir}")
    if not os.path.isfile(tmpl_file):
        sys.exit(f"ERROR: wrapper template not found: {tmpl_file}")

    wrapper = os.path.join(run_dir, f'{testname}.sv')
    with open(tmpl_file, 'r') as f:
        content = f.read()
    content = content.replace('%%TESTNAME%%', testname)
    with open(wrapper, 'w') as f:
        f.write(content)
    print(f"generated : {wrapper}")

    verilator_top = wrapper
    include_dirs  = [env_dir, tests_dir]
else:
    tb_dir        = os.path.dirname(tb_file)
    verilator_top = tb_file
    include_dirs  = [tb_dir]

# ---------------------------------------------------------------------------
# Resolve the filelist (.f)
# Convention: a <testname>.f next to the testbench takes priority;
#             otherwise fall back to hdl/cpu/top/cpu.f
# ---------------------------------------------------------------------------
tb_dir_for_f = os.path.dirname(tb_file)
per_test_f   = os.path.join(tb_dir_for_f, f'{testname}.f')
default_f    = os.path.join(repo_root, 'hdl', 'cpu', 'top', 'cpu.f')

if os.path.isfile(per_test_f):
    src_f = per_test_f
    print(f"filelist  : {src_f}  (per-test)")
elif os.path.isfile(default_f):
    src_f = default_f
    print(f"filelist  : {src_f}  (default)")
else:
    sys.exit(
        f"ERROR: no filelist found for '{testname}'.\n"
        f"  Looked for: {per_test_f}\n"
        f"  Fallback  : {default_f}"
    )

# ---------------------------------------------------------------------------
# Expand path variables in the filelist and write to run_dir
# ---------------------------------------------------------------------------
vars_ = {
    'CPU_DIR'       : os.path.join(repo_root, 'hdl', 'cpu'),
    'COMMON_DIR'    : os.path.join(repo_root, 'hdl', 'common'),
    'CHIPLEVEL_DIR' : os.path.join(repo_root, 'hdl', 'chiplevel'),
}

def expand_vars(line):
    def replace(m):
        key = m.group(1)
        if key in vars_:
            return vars_[key]
        sys.exit(f"Unknown variable ${key} in filelist")
    return re.sub(r'\$\{(\w+)\}', replace, line)

expanded_f = os.path.join(run_dir, 'expanded.f')
with open(src_f, 'r') as fin, open(expanded_f, 'w') as fout:
    for line in fin:
        fout.write(expand_vars(line))

print(f"expanded  : {expanded_f}")

# ---------------------------------------------------------------------------
# Compile with Verilator
# ---------------------------------------------------------------------------
compile_cmd = [
    'verilator',
    '--binary', '--sv', '-Wall', '--timing',
    '-Wno-TIMESCALEMOD',
] + (['--trace'] if args.trace else []) + [
    '--top-module', testname,
    '--Mdir',       work_dir,
] + [f'-I{d}' for d in include_dirs] + [
    '-f',           expanded_f,
    verilator_top,
]

print('\n--- compile ---')
print(' '.join(compile_cmd), '\n')
result = subprocess.run(compile_cmd)
if result.returncode != 0:
    sys.exit(f"Verilator compilation failed (exit {result.returncode})")

# ---------------------------------------------------------------------------
# Run the simulation from run_dir so waveform.vcd lands there
# ---------------------------------------------------------------------------
sim_bin = os.path.join(work_dir, f'V{testname}')
if not os.access(sim_bin, os.X_OK):
    sys.exit(f"ERROR: compiled binary not found: {sim_bin}")

print('\n--- simulate ---')
print(f"cwd: {run_dir}")
print(f"{sim_bin}\n")

result = subprocess.run([sim_bin], cwd=run_dir)
if result.returncode != 0:
    sys.exit(f"Simulation exited with non-zero status ({result.returncode})")

print(f"\nOutputs in {run_dir}")
