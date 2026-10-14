"""Run every R, Python and JavaScript regression suite; preserve full local logs.

No production input is read or uploaded. Database integration is a separate,
explicit validation command using a disposable synthetic database.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--logs', type=Path, default=ROOT / '.artifact-temp' / 'validation' / sys.platform)
    parser.add_argument('--rscript', default=os.environ.get('RSCRIPT', shutil.which('Rscript')))
    args = parser.parse_args()
    if not args.rscript and os.name == 'nt':
        candidate = Path('C:/Program Files/R/R-4.3.1/bin/Rscript.exe')
        if candidate.exists():
            args.rscript = str(candidate)
    if not args.rscript or not shutil.which('node'):
        parser.error('Rscript and node must be installed; use --rscript to select R.')
    args.logs = args.logs.resolve()
    args.logs.mkdir(parents=True, exist_ok=True)
    scratch = args.logs / 'temp'
    scratch.mkdir(exist_ok=True)
    env = os.environ.copy()
    for key in ('TMPDIR', 'TEMP', 'TMP'):
        env[key] = str(scratch)
    env['LANG'] = env['LC_ALL'] = 'English_United States.utf8' if os.name == 'nt' else 'C.UTF-8'
    env['RSCRIPT'] = args.rscript
    env['PATH'] = str(Path(args.rscript).parent) + os.pathsep + env.get('PATH', '')
    if os.name == 'nt':
        libs = Path('C:/Users/User/AppData/Local/R/win-library/4.3')
        if libs.exists():
            env.setdefault('R_LIBS_USER', str(libs))
    commands = [('R', [args.rscript, 'scripts/run_tests.R'])]
    commands.extend((p.stem, [sys.executable, str(p)]) for p in sorted((ROOT / 'tests').glob('test-*.py')))
    commands.append(('JavaScript', ['node', '--test'] + [str(p) for p in sorted((ROOT / 'tests').glob('test-*.js'))]))
    outcomes = []
    for name, command in commands:
        started = time.monotonic()
        log = args.logs / (name + '.log')
        print(f'Running {name}', flush=True)
        with log.open('w', encoding='utf-8') as output:
            result = subprocess.run(command, cwd=ROOT, env=env, stdout=output, stderr=subprocess.STDOUT, check=False)
        outcome = dict(suite=name, exit_code=result.returncode, seconds=round(time.monotonic() - started, 2), log=str(log))
        outcomes.append(outcome)
        print(f'{name}: {"PASS" if result.returncode == 0 else "FAIL"} ({outcome["seconds"]}s)', flush=True)
        (args.logs / 'results.json').write_text(json.dumps(outcomes, indent=2) + '\n', encoding='utf-8')
    failed = [item['suite'] for item in outcomes if item['exit_code']]
    print(f'{len(outcomes) - len(failed)}/{len(outcomes)} suites passed.' + (' Failed: ' + ', '.join(failed) if failed else ''))
    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
