# 架构说明 — Analysis Tool For ColorOS

Python 脚本集：从 ROM 包里提取、重命名并更新 APK，维护一份「包名 → 应用名 / 版本号 / versionCode」
数据库（`app_name.json` / `app_code.json` / `app_version.json`）。

## 1. 目录结构

```text
Analysis-Tool-For-ColorOS/
├── main.py                 # 入口与 argparse：-d 下载 / -p 取 payload / -i 取镜像 / -f 解 EROFS
│                           #   -n 重命名 / -u 更新版本 / -m 更新包名 / -a 删包 / -c 清理 / -o 取信息
├── config.py               # 路径、下载、解包等常量与目录初始化
├── defs.py                 # 具体实现（下载 / 解包 / 重命名 / 数据库读写）
├── requirements.txt        # 运行依赖（androguard 等）
├── VERSION                 # 当前目标版本（MAJOR.MINOR.PATCH），alpha 版本名的基底
├── exclude_apk.txt         # 不参与重命名/更新的包名单
├── app_name.json           # 应用名主库（包名 → 应用名）
├── app_code.json           # 包名库
├── app_version.json        # 版本号 / versionCode 库
├── ci/
│   ├── release-log.sh      # Release Log 双文件生成（release.md + changelog.txt，Conventional Commits 分类）
│   └── upload-openlist.sh  # 产物/README/version.json 上传 OpenList + 版本归档清理
└── .github/workflows/
    ├── Build.yml           # 发版：push/tag → 版本计算 → 日志 → 8 平台打包 → OpenList → Release
    ├── Analysis.yml        # 手动 ROM 分析（workflow_dispatch），在当前分支上跑
    └── rollback-openlist.yml # 撤回已发布版本（OpenList 通道指针回滚）
```

## 2. 两条流水线

### Build.yml（push / tag / 手动，见 `docs/VERSIONING.md` §17）

```text
Determine channel and version      # push→alpha（VERSION+run_number）/ tag→beta|stable
Generate release log               # 按通道算日志区间 → ci/release-log.sh → release.md + changelog.txt
Process + Download dependencies    # 组装 8 个平台目录，逐平台注入 payload-dumper-go / erofs-utils
7z 打包 → output/<名字>-<版本>-<平台>-<arch>.zip
Deploy to OpenList                 # ci/upload-openlist.sh（三通道全传，含 alpha）
Release（仅 beta/stable）          # files=./output/*，notes=release.md
```

顺序不可换：**先 Deploy（含归档清理）再 Create Release**（§29 不变量 5）。

### Analysis.yml（workflow_dispatch）

输入 ROM 链接 / 是否回传数据库 → 下载解 ROM → 解 payload、取 img、解 EROFS → 删排除包 →
跑 `main.py -u -m -n` 更新版本、更新包名并重命名 → 可选 `chore: ... [skip ci]` 回传数据库到 `main`。

## 3. 产物与分发

- 产物：每平台一个 zip（命名规范见 `docs/VERSIONING.md` §25），包内自带 `tools/` 依赖，解压即用；
- OpenList：`https://storage.horatio.cn/Analysis-Tool-For-ColorOS/{alpha,beta,stable}/`
  （存储根是 Actions Secret `SERVER_OPENLIST_DIR`，分发目录名由 `ci/upload-openlist.sh` 拼接，
  源码里不出现任何 `/www/...` 字面路径）；
- GitHub Release：仅 beta / stable，notes 由 `ci/release-log.sh` 生成；
- 保留策略：alpha 1 / beta 2 / stable 3，旧版本移入「以前的版本/」后按数量清理（§27.5）。

## 4. 环境

- Runner：组织级 self-hosted（`HORATIO-DEV`，Linux x64），三个 Analysis-Tool 仓库共用；
- Secrets：组织级 `SERVER_HOST` / `SERVER_USER` / `SERVER_SSH_KEY` / `SERVER_OPENLIST_DIR`（ALL 可见）；
- Vars：无必需项，`SSH_PORT` 可选（默认 22）。
