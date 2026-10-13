# AGENTS.md

Analysis Tool For ColorOS: a Python CLI that downloads ColorOS ROMs, extracts images, and pulls, renames and version-tracks APKs into **one JSON database set** (`app_code.json` / `app_name.json` / `app_version.json` — no per-device-class split, unlike the HyperOS/OriginOS siblings). APK info is read via `pyaxmlparser`. End-user usage and downloads are in `README.md`.

Distribution: 8 platform zips built by CI, shipped to the self-hosted OpenList (three channels: 内测版 alpha / 公测版 beta / 正式版 stable) plus GitHub Releases for beta/stable only.

## Commands

```bash
pip install -r requirements.txt   # pyaxmlparser — the only Python dep
python3 main.py -h                # all flags; the usual flow is -d → -p → -i → -f → …

# Local sanity checks before pushing CI changes (no test suite exists)
bash -n ci/release-log.sh && bash -n ci/upload-openlist.sh
python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml
grep -rn '/www/' ci .github && echo "FAIL: server paths in source" || echo "OK"
```

Runtime tools the scripts shell out to: `aria2c`, `7z`, plus `payload-dumper-go` / `extract.erofs` — bundled inside the distributed zips' `tools/`, **not** vendored in the repo.

## Release / CI

- **Versioning, channels, tag rules and the release-log template are specified in `~/.config/opencode/VERSIONING.md` — read it before touching any CI file** (build.yml encodes its rules, e.g. "Build ID = `github.run_number` = version_code, monotonic, never reused"). Commit format follows `~/.config/opencode/COMMITTING.md`.
- Flow in short: push `main` → alpha build → OpenList `alpha/` (single version, no tag, no Release); `git tag x.y.z-beta.N` → beta + prerelease Release; `git tag x.y.z` → stable + Release. Tags must be exactly `x.y.z` or `x.y.z-beta.N` — the workflow rejects anything else.
- `ci/release-log.sh <range>` generates two files: `release.md` (Markdown, OpenList README / Release notes) and `changelog.txt` (plain text for `version.json`). It filters out `docs/chore/ci/test/style/build` commit types — **doc-only commits must use the `docs:` prefix** or they pollute the update log (and `*.md`/`docs/**` pushes skip the build entirely via paths-ignore).
- Artifact names are a public contract: `<repo>-<VERSION>-<BUILD_ID>-<platform>-<arch>.zip`, identical in `output/`, Release assets and OpenList; never rename history.
- `Analysis.yml` is the on-demand ROM-analysis workflow (workflow_dispatch: device type, ROM link, optional DB upload) — unrelated to releases.
- Secrets are **org-level, already visible to every org repo** — no per-repo setup: `SERVER_HOST` / `SERVER_USER` / `SERVER_SSH_KEY` / `SERVER_OPENLIST_DIR` (`ci/upload-openlist.sh` appends the distribution dir itself — never hard-code it). `SERVER_BASE_DIR` belongs to the Calorie Diary backend and is **not used here**. Optional var `SSH_PORT` (default 22). The runner is the org-level self-hosted `HORATIO-DEV` (Linux x64), **shared by the three Analysis-Tool repos**.

## Boundaries

**Always**
- Doc-only commits use the `docs:` prefix (paths-ignore skips the build; the release log also filters them).
- Keep `ci/release-log.sh` / `ci/upload-openlist.sh` runnable standalone (`bash -n` clean) and free of hard-coded server paths.

**Ask first**
- Renaming `build.yml` (the alpha log range queries the Actions API by that filename), changing the tag regex, the OpenList retention policy, or artifact naming.
- Bumping `VERSION` (it must match the next release tag verbatim).

**Never**
- Hand-edit `release.md` / `changelog.txt` / `version.json` on the server — CI regenerates and uploads them.
- Add `v` prefixes or extra segments to tags.
- Commit build output (`output/`, `*.zip`, `__pycache__/`, `venv/`).

## Known pitfalls

- **Upstream 500s**: CI pulls latest releases of `ssut/payload-dumper-go` and `sekaiacg/erofs-utils` via the GitHub API — when it flakes, the build goes red for no fault of this repo. **Just rerun.**
- Tags must be exactly `x.y.z` / `x.y.z-beta.N`; this repo's history once used a four-segment `v2.0.3.0` format — that's gone, don't revive it.
- **Withdrawn versions don't free their Build ID**: after rolling back `beta.2`, the next beta must be `beta.3`.
- **The self-hosted runner's workspace persists across runs** — stale `output/` from a previous run can confuse local verification; check before trusting artifacts.
