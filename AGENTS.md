# AGENTS.md

Analysis Tool For ColorOS: a Python CLI that downloads ColorOS ROMs, extracts images, and pulls, renames and version-tracks APKs into **one JSON database set** (`app_code.json` / `app_name.json` / `app_version.json` — no per-device-class split, unlike the HyperOS/OriginOS siblings). APK info is read via `pyaxmlparser`. End-user usage and downloads are in `README.md`.

**This repo is Chinese-documented and self-contained — the detail lives here, not in this file:**

| File | Content |
|---|---|
| `HANDOFF.md` | Environment, secrets, release flow, key decisions, pitfalls, acceptance checklist — **read on takeover** |
| `docs/VERSIONING.md` | Version numbers / three channels / trigger rules / OpenList / full workflow — **the single source of truth; read before touching CI** |
| `docs/COMMITTING.md` | Commit spec — a byte-identical twin of VERSIONING §30; **editing one means editing the other** |
| `docs/ARCHITECTURE.md` | Directory layout and the two pipelines |

This AGENTS.md is only the English orientation layer; when it and the Chinese docs disagree, the Chinese docs win — fix this file.

## Commands

```bash
pip install -r requirements.txt
python3 main.py -h

# Sanity checks before pushing CI changes (from HANDOFF §7; no test suite exists)
bash -n ci/release-log.sh && bash -n ci/upload-openlist.sh
python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml
grep -rn '/www/' ci .github && echo "FAIL: server paths in source" || echo "OK"
```

Release flow in one line: push `main` → alpha to OpenList (no tag); `git tag x.y.z[-beta.N]` → beta/stable + Release. Details and rules: `docs/VERSIONING.md` (which mirrors `~/.config/opencode/VERSIONING.md`).

## Boundaries

**Always**
- Doc-only commits use the `docs:` prefix (paths-ignore skips the build; the release log also filters them).
- Any CI change goes through `docs/VERSIONING.md` first and keeps `docs/COMMITTING.md` in sync when it touches commit rules.

**Ask first**
- Renaming `build.yml` (the alpha log range queries the Actions API by that filename), changing the tag regex, the OpenList retention policy, or artifact naming.
- Bumping `VERSION` (must match the next tag verbatim).

**Never**
- Hard-code server paths in `ci/` or workflows (the `grep /www/` check above fails the review).
- Hand-edit `release.md` / `changelog.txt` / `version.json` on the server.
- Commit build output (`output/`, `*.zip`, `__pycache__/`, `venv/`).

## Known pitfalls (full list in HANDOFF §6)

- **Upstream 500s**: CI pulls latest `ssut/payload-dumper-go` / `sekaiacg/erofs-utils` via the GitHub API — flaky builds are usually this, **rerun**.
- Tags must be exactly `x.y.z` / `x.y.z-beta.N`; this repo's history once used a four-segment `v2.0.3.0` format — that's gone, don't revive it.
- Withdrawn versions don't free their Build ID (rollback `beta.2` → next must be `beta.3`).
- The self-hosted runner's workspace persists across runs — stale `output/` can mislead local verification.
