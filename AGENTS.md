# AGENTS.md

Analysis Tool For ColorOS: a Python CLI that downloads ColorOS ROMs, extracts images, and pulls, renames and version-tracks APKs into **one JSON database set** (`app_code.json` / `app_name.json` / `app_version.json` — no per-device-class split, unlike the HyperOS/OriginOS siblings). APK info is read via `pyaxmlparser`. End-user usage and downloads are in `README.md`.

**This repo's project-level documentation is this file alone** (HANDOFF.md and docs/ were retired — handoff/architecture docs are deprecated workflow-wide). Versioning, channels, tag rules and the release-log template are specified globally in `~/.config/opencode/VERSIONING.md` — **read it before touching any CI file**; commit format follows `~/.config/opencode/COMMITTING.md`. Directory layout and pipeline details are inferable from the code and the workflow comments.

## Environment

- Secrets are **org-level, already visible to every org repo** — this repo needs no per-repo setup: `SERVER_HOST` / `SERVER_USER` / `SERVER_SSH_KEY` / `SERVER_OPENLIST_DIR` (OpenList storage root; `ci/upload-openlist.sh` appends the distribution dir itself — never hard-code it). `SERVER_BASE_DIR` belongs to the Calorie Diary backend and is **not used here**. Optional var `SSH_PORT` (default 22).
- Runner: the org-level self-hosted `HORATIO-DEV` (Linux x64), **shared by the three Analysis-Tool repos**; its workspace persists across jobs (`Analysis.yml` relies on the checkout's `git clean` to clear residue).

## Commands

```bash
pip install -r requirements.txt
python3 main.py -h

# Sanity checks before pushing CI changes (no test suite exists)
bash -n ci/release-log.sh && bash -n ci/upload-openlist.sh
python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml
grep -rn '/www/' ci .github && echo "FAIL: server paths in source" || echo "OK"
```

Release flow in one line: push `main` → alpha to OpenList (no tag); `git tag x.y.z[-beta.N]` → beta/stable + Release. Details and rules: `~/.config/opencode/VERSIONING.md`.

## Boundaries

**Always**
- Doc-only commits use the `docs:` prefix (paths-ignore skips the build; the release log also filters them).
- Any CI change goes through `~/.config/opencode/VERSIONING.md` first; commit-rule changes follow `~/.config/opencode/COMMITTING.md`.

**Ask first**
- Renaming `build.yml` (the alpha log range queries the Actions API by that filename), changing the tag regex, the OpenList retention policy, or artifact naming.
- Bumping `VERSION` (must match the next tag verbatim).

**Never**
- Hard-code server paths in `ci/` or workflows (the `grep /www/` check above fails the review).
- Hand-edit `release.md` / `changelog.txt` / `version.json` on the server.
- Commit build output (`output/`, `*.zip`, `__pycache__/`, `venv/`).

## Known pitfalls

- **Upstream 500s**: CI pulls latest `ssut/payload-dumper-go` / `sekaiacg/erofs-utils` via the GitHub API — flaky builds are usually this, **rerun**.
- Tags must be exactly `x.y.z` / `x.y.z-beta.N`; this repo's history once used a four-segment `v2.0.3.0` format — that's gone, don't revive it.
- Withdrawn versions don't free their Build ID (rollback `beta.2` → next must be `beta.3`).
- The self-hosted runner's workspace persists across runs — stale `output/` can mislead local verification.
