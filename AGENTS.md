# AGENTS.md — Analysis Tool For ColorOS

Python CLI that downloads ColorOS ROMs, extracts images and version-tracks APKs into JSON sets, released with a **self-built pipeline**: push to `main` → beta (VERSION file X.Y.Z + server BUILD → four-segment `X.Y.Z.N`, no GitHub Release); human tag `X.Y.Z.0` → stable (GitHub Release latest). Two channels only (beta / stable; no alpha). No marker commits, no hand-written release notes.

## Commands

| Purpose | Command |
| --- | --- |
| Install (only Python dep) | `pip install -r requirements.txt` (`pyaxmlparser==0.3.31`) |
| Usage / all flags | `python3 main.py -h` (flow `-d` → `-p` → `-i` → `-f` → …) |
| Version dry-run (no publish) | `bash ci/determine-version.sh beta ColorApkExtractor VERSION ""` (reads server BUILD; prints version_name/code) |
| Changelog dry-run (no publish) | `bash ci/gen-changelog.sh "" /tmp/changelog.txt ""` (full history; pass a prev commit SHA for incremental) |
| Script syntax | `bash -n ci/*.sh` (all ci shell scripts) |
| Workflow YAML parse | `python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml` |
| No server paths in source | `grep -rn '/www/' ci .github && echo FAIL \|\| echo OK` |

No test suite; these are the only local checks. Local run needs Python 3.x + `aria2c` + 7zip; distributed zips bundle `payload-dumper-go` and `extract.erofs` in `tools/` (CI fetches them via `gh release download` — upstream 500s → rerun). The self-hosted runner's workspace persists, so check stale `output/` before trusting artifacts.

## Release model (self-built, two channels)

Hand-controlled `VERSION` file (X.Y.Z) + auto BUILD on the server. Push `main` → beta `X.Y.Z.N` (BUILD 1–99, no GitHub Release); human-pushed tag `X.Y.Z.0` → stable (GitHub Release latest). versionCode = MAJOR×1e6 + MINOR×1e4 + PATCH×100 + BUILD (never GITHUB_RUN_NUMBER). `ci/determine-version.sh` computes the version and reads the previous release's commit from the server over the network (OpenList API); `ci/gen-changelog.sh` builds an incremental changelog from that commit (`git log <prev>..HEAD`, full history for the first release); `ci/pack-all.sh` packs 8 platforms; `ci/upload-openlist.sh` uploads artifacts + signed `version.json` (ECDSA P-256). The tag is ONLY a stable-build trigger — it never influences version or changelog. Changelog headings are Chinese with emoji (`✨ 新增` / `🐛 修复` / `⚡ 改进`). See `~/.config/opencode/docs/versioning.md` and `release-pipeline.md`.

## Context loading

| Task | Read |
| --- | --- |
| Release rules / templates | `~/.config/opencode/docs/versioning.md`, `release-pipeline.md`, `committing.md` |
| Shared across the three Analysis tools | `~/.config/opencode/docs/sister-repos.md` |
| CI / deploy behavior | `.github/workflows/release.yml`, `ci/pack-all.sh`, `ci/upload-openlist.sh` |
| End-user usage | `README.md` |

## Boundaries

### Always
- Use the `docs:` prefix for doc-only commits (`paths-ignore` skips the release; changelog hides docs/chore/ci/test/style/build/refactor/revert).
- Keep `ci/pack-all.sh`'s platform table in sync with upstream asset names; `gh release download` patterns were verified against live assets.
- Keep `ci/upload-openlist.sh` standalone: `bash -n` clean and free of hard-coded server paths (`OPENLIST_STORAGE_DIR` comes from secret `SERVER_OPENLIST_DIR`).

### Ask first
- Changing the platform table, artifact naming, OpenList retention, or `.github/workflows/release.yml`.
- Bumping a dependency pin in `ci/pack-all.sh` (erofs macOS tag is pinned because newer builds dropped `extract.erofs`).
- Beta/Stable tags.

### Never
- Hand-edit `CHANGELOG.md`, `changelog.txt` or `version.json` on the server — CI regenerates and uploads them.
- Commit build output (`output/`, `*.zip`, `__pycache__/`, `venv/`) or extracted ROM dirs.
- Reintroduce semantic-release, `release.config.mjs`, marker commits, `release-notes.md`, or `ci/release-*.sh` scripts.
- Treat the two channels as branches — there is no `beta` branch; channels are version states.

General rules: `~/.config/opencode/AGENTS.md`.
