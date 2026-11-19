# AGENTS.md — Analysis Tool For ColorOS

Python CLI that downloads ColorOS ROMs, extracts images and version-tracks APKs into one JSON set (`app_code.json`, `app_name.json`, `app_version.json` — no per-device-class split). CI builds 8 platform zips to self-hosted OpenList (alpha/beta/stable) plus GitHub Releases for beta/stable; push `main` → alpha, tag `x.y.z` / `x.y.z-beta.N` → stable/beta.

## Commands

| Purpose | Command |
| --- | --- |
| Install (only Python dep) | `pip install -r requirements.txt` (`pyaxmlparser==0.3.31`) |
| Usage / all flags | `python3 main.py -h` (flow `-d` → `-p` → `-i` → `-f` → …) |
| Release notes (beta/stable) | `bash ci/check-release-notes.sh` (needs `release-notes.md`, `CHANNEL` env required) |
| Release script syntax | `bash -n ci/release-log.sh && bash -n ci/upload-openlist.sh` |
| Workflow YAML parse | `python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml` |
| No server paths in source | `grep -rn '/www/' ci .github && echo FAIL \|\| echo OK` |

No test suite; these are the only local checks. Local run needs Python 3.x + `aria2c` + 7zip; distributed zips bundle `payload-dumper-go` and `extract.erofs` in `tools/` (CI fetches them from the GitHub API — upstream 500s → rerun). The self-hosted runner's workspace persists, so check stale `output/` before trusting artifacts.

## Context loading

| Task | Read |
| --- | --- |
| Release rules / templates | `~/.config/opencode/docs/VERSIONING.md`, `RELEASE-PIPELINE.md`, `COMMITTING.md`, `release-notes-style.md` |
| Shared across the three Analysis tools | `~/.config/opencode/docs/SISTER-REPOS.md` |
| CI / deploy behavior | `.github/workflows/build.yml`, `ci/upload-openlist.sh`, `ci/release-log.sh`, `ci/check-release-notes.sh` |
| End-user usage | `README.md` |

## Boundaries

### Always
- Use the `docs:` prefix for doc-only commits (`paths-ignore` skips the build; release-log filters docs/chore/ci/test/style/build/refactor/revert).
- Beta/stable: write `release-notes.md` per `docs/release-notes-style.md` before tagging — first non-empty line is the one-sentence "why update" highlight; no raw commit prefixes or filler (CI gate `ci/check-release-notes.sh`).
- Keep `ci/release-log.sh` and `ci/upload-openlist.sh` standalone: `bash -n` clean and free of hard-coded server paths (`OPENLIST_STORAGE_DIR` comes from secret `SERVER_OPENLIST_DIR`; the script appends the distribution dir).

### Ask first
- Renaming `build.yml` (alpha log range queries the Actions API by that filename); changing the tag regex, OpenList retention or artifact naming.
- Bumping `VERSION` — it must match the next release tag verbatim.

### Never
- Hand-edit `release.md`, `changelog.txt` or `version.json` on the server — CI regenerates and uploads them; never add `v` prefixes or extra tag segments.
- Commit build output (`output/`, `*.zip`, `__pycache__/`, `venv/`) or extracted ROM dirs.

General rules: `~/.config/opencode/AGENTS.md`.
