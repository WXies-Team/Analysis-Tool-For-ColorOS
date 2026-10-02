# HANDOFF — Analysis Tool For ColorOS 交接文档

> 规范以 `docs/VERSIONING.md` 为唯一事实源；本文件只记**环境、流程、坑**，不重复规范条文。

## 1. 项目速览

- **是什么**：从 ColorOS ROM 提取/重命名/更新 APK 的 Python 脚本集，维护三份 JSON 数据库。
- **语言/栈**：Python 3 + androguard；CI 全在 self-hosted runner 上跑（7z、aria2 靠 runner 预装）。
- **产物**：每平台一个 zip（8 个平台组合），解压即用，无安装器。
- **分发**：OpenList 三通道 + GitHub Release（仅 beta/stable）。

## 2. 文档地图

| 文件 | 内容 |
| ---- | ---- |
| `docs/VERSIONING.md` | 版本号 / 三通道 / 触发规则 / 日志模板 / OpenList / 完整 workflow（**改 CI 前必读**） |
| `docs/COMMITTING.md` | Commit 规范（与 VERSIONING §30 是**逐字相同的两份副本**，改一处必须同步另一处） |
| `docs/ARCHITECTURE.md` | 目录结构与两条流水线 |
| `README.md` | 使用说明与下载入口 |

## 3. 环境与密钥

**Secrets（组织级，ALL 仓库可见，本仓无需再配）**：
`SERVER_HOST` `SERVER_USER` `SERVER_SSH_KEY` `SERVER_OPENLIST_DIR`

- `SERVER_OPENLIST_DIR` = OpenList 存储根（`.../OpenList/storage`），
  分发目录 `Analysis-Tool-For-ColorOS` 由 `ci/upload-openlist.sh` 在脚本内拼接 —— **源码里不存路径**；
- `SERVER_BASE_DIR` 是热量日记后端部署根，**本仓不用**。

**Vars**：无必需项（`SSH_PORT` 可选，默认 22）。

**Runner**：组织级 self-hosted `HORATIO-DEV`（Linux x64），三个 Analysis-Tool 仓库共用，
工作区跨任务保留（`Analysis.yml` 依赖 checkout 的 `git clean` 清残留）。

**外部依赖（会突然 500）**：`ssut/payload-dumper-go`、`sekaiacg/erofs-utils` —— 由
`robinraju/release-downloader` 拉 latest，GitHub API 抖动时 Build 会红，**重跑即可**，不是本仓代码问题。

## 4. 发版流程

| 想做什么 | 怎么做 |
| -------- | ------ |
| 日常迭代（alpha） | push 到 `main` 即自动构建，产物进 OpenList `alpha/`（只留 1 版），**不打 tag、不建 Release** |
| 发公测（beta） | `git tag 2.2.0-beta.1 && git push origin 2.2.0-beta.1` → 自动构建 + 预发布 Release |
| 发正式（stable） | `git tag 2.2.0 && git push origin 2.2.0` → 自动构建 + 正式 Release |
| 手动重跑 | Actions → `Build` → `Run workflow`（Build ID 复用同一 run_number） |
| 撤回已发版本 | 删 Release → 删 tag → Actions → `rollback-openlist`（channel/target_version/drop_version） |
| 只跑 ROM 分析 | Actions → `Analysis Tool For ColorOS`（在当前分支运行） |

发版前自查：`VERSION` 是否为想要的 `MAJOR.MINOR.PATCH` → 打的 tag 是否与目标版本**逐字一致** →
Run log 里 `release.md` 分组是否合理 → OpenList 三通道目录与 `version.json` 是否更新。

## 5. 关键决策（为什么是这样）

1. **Build ID = `github.run_number`**，与 `version_code` 同值，全局单调递增、永不复用（§5）；
2. **alpha 不建 Release、不打 tag**，OpenList alpha 通道是它唯一出口（§9）；
3. **`docs/**`、`*.md` 被 paths-ignore**：纯文档 push 不占 runner，日志区间不受影响 —— 所以文档提交必须用 `docs:` 前缀；
4. **日志双文件**：`release.md`（带版本大标题，给 OpenList/GitHub 渲染）+ `changelog.txt`（纯文本，进 `version.json`）；
5. **保留 1/2/3 + 归档**：超期版本物理删除，Release notes **不加任何失效提示**（废弃标记机制已移除，§27.7）；
6. **产物名即对外契约**：`<名字>-<版本>-<平台>-<arch>.zip` 三处（output/、Release asset、OpenList）必须逐字一致，历史不改名。

## 6. 已知坑

1. **外部依赖 500**：见 §3，重跑即可；
2. **本仓历史 tag 曾是 `v2.0.3.0` 四段格式**：已在本轮规范化为 `x.y.z`；新 tag 必须走 `x.y.z` / `x.y.z-beta.N`，否则 `Determine channel and version` 直接失败；
3. **workflow 文件名不能随手改**：`Build.yml` 被 `Generate release log` 的 Actions API 路径引用（alpha 日志区间靠它），改名必须同步 §28/§29；
4. **同一 `version_name` 换 Build ID**：撤回不释放 Build ID，撤回 `beta.2` 后下次必须发 `beta.3`；
5. **self-hosted 工作区跨 run 保留**：本地跑脚本验证时注意 `output/` 可能有上次残留。

## 7. 快速验收清单

```bash
bash -n ci/release-log.sh && bash -n ci/upload-openlist.sh   # 脚本语法
python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml
grep -rn '/www/' ci .github && echo "FAIL: 源码里仍有服务器路径" || echo "OK: 无明文路径"
```

CI 侧：
1. push 一次 → alpha 构建成功，OpenList `alpha/` 只有 1 版、`version.json` 的 `version_name` 带 `-alpha.N`；
2. 打 `x.y.z-beta.N` → Release 为**预发布**，notes 是中文分组模板；
3. 打 `x.y.z` → 正式 Release，`stable/` 归档后共 3 版（当前 1 + 归档 2）；
4. `gh release list` 标题格式均为 `x.y.z[-beta.N]`，无 `v` 前缀。
