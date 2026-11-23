#!/usr/bin/env python3
"""Execute the `run:` steps of a GitHub Actions workflow file, in order, locally.

Framework CI uses this to test the adopter CI template
(templates/ci/github-actions/flutter-gates.yml) against the eval base app —
the YAML adopters copy is the thing under test, not a hand-maintained replica
of its commands.

  run-workflow-steps.py WORKFLOW --job JOB --cwd DIR [--var NAME=VALUE]...

`uses:` steps are skipped (the caller sets up the toolchain). A step env value
containing `${{ ... }}` is taken from --var NAME=VALUE when given, else from the
expression's `|| 'default'` fallback, else empty. Exit: first failing step's
code, 0 when every step passed, 2 on usage errors.

Framework-development tool only: never installed into adopter repositories.
"""
import argparse
import os
import re
import subprocess
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("run-workflow-steps: PyYAML required (pip install pyyaml)")

FALLBACK = re.compile(r"\|\|\s*'([^']*)'")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("workflow")
    ap.add_argument("--job", required=True)
    ap.add_argument("--cwd", required=True)
    ap.add_argument("--var", action="append", default=[])
    args = ap.parse_args()

    overrides = {}
    for v in args.var:
        if "=" not in v:
            print(f"run-workflow-steps: --var expects NAME=VALUE, got {v!r}", file=sys.stderr)
            return 2
        k, val = v.split("=", 1)
        overrides[k] = val

    with open(args.workflow, encoding="utf-8") as f:
        wf = yaml.safe_load(f)
    try:
        steps = wf["jobs"][args.job]["steps"]
    except (KeyError, TypeError):
        print(f"run-workflow-steps: job {args.job!r} not found", file=sys.stderr)
        return 2

    ran = 0
    for step in steps:
        name = step.get("name") or step.get("uses") or "(unnamed)"
        if "run" not in step:
            print(f"--- skip  {name} (uses:)")
            continue
        env = dict(os.environ)
        for k, val in (step.get("env") or {}).items():
            val = str(val)
            if "${{" in val:
                if k in overrides:
                    val = overrides[k]
                else:
                    m = FALLBACK.search(val)
                    val = m.group(1) if m else ""
            env[k] = val
        print(f"--- run   {name}", flush=True)
        rc = subprocess.run(["bash", "-eo", "pipefail", "-c", step["run"]], cwd=args.cwd, env=env).returncode
        ran += 1
        if rc != 0:
            print(f"--- FAIL  {name} (exit {rc})", flush=True)
            return rc
    if ran == 0:
        print("run-workflow-steps: no run: steps executed — refusing to report a pass", file=sys.stderr)
        return 1
    print(f"--- all {ran} run: steps passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
