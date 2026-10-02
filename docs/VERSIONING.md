# 软件版本号与 CI/CD 发布规范

## 1. 目的

本规范用于统一软件的版本号、构建号、Git Tag、CI/CD 构建及发布流程，确保不同版本之间具有明确、唯一且可追溯的关系。

软件版本由以下两个核心字段组成：

- **Version Name**：用于描述软件版本，面向用户和开发人员。
- **Version Code**：用于唯一标识具体构建，面向系统和发布平台。

其中：

```text
Version Name = 软件版本语义
Version Code = 全局构建标识
Build ID     = CI 构建标识
```

本规范中，**Build ID 与 Version Code 使用同一个全局递增编号**。

例如：

```text
Version Name: 1.2.0-alpha.102
Version Code: 102
Build ID:     102
```

---

# 2. Channel

项目仅允许以下三个 Channel：

| Channel  | 含义       | 触发方式   | 自动 Build | 自动 Release | Git Tag |
| -------- | ---------- | ---------- | ---------: | -----------: | ------: |
| `alpha`  | 开发测试版 | Push       |         ✅ |           ❌ |      ❌ |
| `beta`   | 测试发布版 | Beta Tag   |         ✅ |           ✅ |      ✅ |
| `stable` | 正式发布版 | Stable Tag |         ✅ |           ✅ |      ✅ |

禁止使用其他 Channel，包括但不限于：

```text
dev
rc
nightly
canary
preview
snapshot
```

其中：

- `dev` 的概念统一由 `alpha` 承担。
- 不使用 `rc`。
- Alpha、Beta、Stable 构成唯一版本生命周期。

```text
alpha → beta → stable
```

---

# 3. Version Name

Version Name 用于表达软件版本语义。

## 3.1 Alpha

Alpha 格式：

```text
MAJOR.MINOR.PATCH-alpha.BUILD_ID
```

例如：

```text
1.2.0-alpha.100
1.2.0-alpha.101
1.2.0-alpha.102
```

其中：

- `MAJOR.MINOR.PATCH` 表示当前开发目标版本。
- `alpha` 表示 Alpha Channel。
- `BUILD_ID` 表示本次构建的全局 Build ID。
- Alpha 后缀**不再使用独立的 Alpha 序号**。
- Alpha 后缀直接使用 Version Code / Build ID。

因此：

```text
Version Name:
1.2.0-alpha.102

Version Code:
102

Build ID:
102
```

三者中的构建编号保持一致。

生成示例（workflow 内，完整实现见 §28 `Determine channel and version` 步骤）：

```bash
BUILD_ID=${{ github.run_number }}          # 全局单调递增的唯一来源
BASE=$(tr -d '[:space:]' < VERSION)        # 读目标版本，如 1.2.0
VERSION="$BASE-alpha.$BUILD_ID"            # → 1.2.0-alpha.102
```

---

## 3.2 Beta

Beta 格式：

```text
MAJOR.MINOR.PATCH-beta.N
```

例如：

```text
1.2.0-beta.1
1.2.0-beta.2
1.2.0-beta.3
```

其中：

- `MAJOR.MINOR.PATCH` 表示目标正式版本。
- `beta` 表示 Beta Channel。
- `N` 表示该目标版本下的 Beta 发布序号。
- `N` 从 `1` 开始。
- 同一个目标版本下，Beta 序号不得重复。

---

## 3.3 Stable

Stable 为正式版本，不包含 Channel 后缀。

格式：

```text
MAJOR.MINOR.PATCH
```

例如：

```text
1.0.0
1.0.1
1.1.0
1.2.0
2.0.0
```

---

# 4. MAJOR / MINOR / PATCH

## 4.1 MAJOR

发生重大变化或不兼容变更时递增。

例如：

```text
1.5.0 → 2.0.0
```

适用情况包括：

- 重大架构变更
- 不兼容 API 修改
- 不兼容配置修改
- 数据格式发生重大变化
- 大规模重构导致旧版本无法直接兼容

---

## 4.2 MINOR

增加向后兼容的新功能时递增。

例如：

```text
1.2.0 → 1.3.0
```

适用情况包括：

- 新增功能
- 新增模块
- 新增设置
- 新增平台支持
- 较大的功能改进

---

## 4.3 PATCH

进行 Bug 修复、小型优化和维护更新时递增。

例如：

```text
1.2.0 → 1.2.1
```

适用情况包括：

- Bug 修复
- 安全修复
- 性能优化
- UI 修复
- 小型兼容性修复

---

# 5. Version Code / Build ID

Version Code 是项目生命周期内的全局构建编号。

Build ID 与 Version Code 使用同一个编号。

```text
Build ID == Version Code
```

例如：

```text
Build ID:     100
Version Code: 100
```

---

## 5.1 基本规则

Version Code / Build ID 必须满足：

1. 必须为正整数。
2. 全局单调递增。
3. 不得重复。
4. 已使用的编号永久保留。
5. 不因 Channel 变化而重置。
6. 不因 MAJOR、MINOR、PATCH 变化而重置。
7. 不因 Alpha、Beta 序号变化而重置。
8. 同一个 Version Name 重新构建时，也必须获得新的 Build ID。
9. Alpha Version Name 中的 `BUILD_ID` 必须与本次 Build ID / Version Code 完全一致。

---

## 5.2 示例

```text
1.2.0-alpha.100 → Build ID 100 → Version Code 100
1.2.0-alpha.101 → Build ID 101 → Version Code 101
1.2.0-alpha.102 → Build ID 102 → Version Code 102
1.2.0-beta.1    → Build ID 103 → Version Code 103
1.2.0-beta.2    → Build ID 104 → Version Code 104
1.2.0            → Build ID 105 → Version Code 105
1.2.1            → Build ID 106 → Version Code 106
1.3.0            → Build ID 107 → Version Code 107
```

---

## 5.3 同一 Version Name 重新构建

如果同一个 Version Name 重新构建，必须产生新的 Build ID。

例如：

```text
1.2.0-alpha.102 → Build ID 102
1.2.0-alpha.103 → Build ID 103
```

Alpha 的 Version Name 会因为 Build ID 改变而改变。

对于 Beta / Stable：

```text
1.2.0-beta.1 → Build ID 103
1.2.0-beta.1 → Build ID 104
```

如果 Beta / Stable 发生重新构建，Version Name 可以保持不变，但 Build ID / Version Code 必须使用新的编号。

---

# 6. Alpha 版本生成规则

Alpha 是开发阶段的自动构建版本。

Alpha 的版本后缀直接使用 Build ID。

## 6.1 Alpha 格式

```text
MAJOR.MINOR.PATCH-alpha.BUILD_ID
```

例如：

```text
1.2.0-alpha.100
1.2.0-alpha.101
1.2.0-alpha.102
```

---

## 6.2 Alpha 不存在独立序号

项目不维护：

```text
alpha.1
alpha.2
alpha.3
```

这样的独立 Alpha 计数器。

Alpha 后缀直接来自 Build ID：

```text
alpha.BUILD_ID
```

例如：

```text
Build ID 200
→ 1.2.0-alpha.200
```

Build ID 201：

```text
→ 1.2.0-alpha.201
```

因此不需要额外维护：

```text
Alpha Counter
```

---

## 6.3 每次 Push 自动生成 Alpha

每次向规定分支执行 Push 后，CI 自动生成一个新的 Alpha Build。

例如：

```text
git push
```

第一次：

```text
Build ID:
100

Version:
1.2.0-alpha.100
```

第二次：

```text
Build ID:
101

Version:
1.2.0-alpha.101
```

第三次：

```text
Build ID:
102

Version:
1.2.0-alpha.102
```

---

## 6.4 新目标版本

当开发目标从：

```text
1.2.0
```

变为：

```text
1.3.0
```

Alpha 后缀**不会重新从 1 开始**，而是继续使用全局 Build ID。

例如：

```text
1.2.0-alpha.100
1.2.0-alpha.101
1.2.0-alpha.102
        ↓
1.2.0-beta.1
        ↓
1.2.0
        ↓
1.3.0-alpha.106
1.3.0-alpha.107
1.3.0-alpha.108
```

这是因为 Alpha 后缀就是全局 Build ID。

---

# 7. Alpha CI/CD

每次 Push 后自动触发 Alpha 构建。

> **完整可复刻实现**：触发条件、权限、版本计算、日志区间、构建、OpenList 分发、
> Release 的**完整 workflow 见 §28**；配套脚本见 §26.4（日志生成）、
> §27.8（OpenList 上传）。

流程：

```text
Push
 ↓
CI
 ↓
确定当前目标版本 MAJOR.MINOR.PATCH
 ↓
生成新的 Build ID
 ↓
Version Code = Build ID
 ↓
Version Name = MAJOR.MINOR.PATCH-alpha.BUILD_ID
 ↓
生成 Release Log
 ↓
Build
 ↓
Test
 ↓
保存 Artifact
```

例如：

```text
Push
 ↓
Build ID = 102
 ↓
Version Code = 102
 ↓
Version Name = 1.2.0-alpha.102
 ↓
Build / Test
 ↓
Artifact
```

---

# 8. Alpha 强制禁止 Git Tag

**Alpha 严禁创建 Git Tag。**

这是强制规则。

例如：

```text
Version Name:
1.2.0-alpha.102
```

可以存在于：

- CI
- Artifact
- Build Metadata
- Release Log

但是 Git 仓库中不得存在：

```text
1.2.0-alpha.102
```

对应的 Git Tag。

因此：

```text
Alpha Version
    ≠
Git Tag
```

---

## 8.1 Alpha 禁止通过 Tag 触发

禁止：

```text
git tag 1.2.0-alpha.102
git push origin 1.2.0-alpha.102
```

Alpha 唯一正常触发方式：

```text
git push
```

即：

```text
Push → Alpha Build
```

---

# 9. Alpha 不创建 Release

Alpha 构建完成后：

- 不创建 GitHub Release。
- 不创建正式 Release。
- 不发布到正式发行渠道。
- 不进入 Beta Release。
- 不进入 Stable Release。

Alpha 构建产物仅保存于：

```text
GitHub Actions / CI Artifact
```

例如：

```text
GitHub Actions

Alpha Build
├── Version: 1.2.0-alpha.102
├── Build ID: 102
├── Version Code: 102
├── Commit: xxxxxxx
├── Release Log
└── Artifact
```

---

# 10. Alpha Release Log

每一次 Alpha Build 都必须生成 Release Log。

Release Log 可以根据 Git Commit 自动生成。

推荐 Commit 格式：

```text
feat: 新增下载队列
fix: 修复下载失败问题
perf: 优化下载速度
refactor: 重构任务管理
docs: 更新文档
```

示例：

```text
1.2.0-alpha.102

新增
- 新增下载队列功能

变更
- 优化任务管理

修复
- 修复下载失败问题
```

Alpha Release Log 至少必须能够通过以下方式之一追溯：

- GitHub Actions Job
- CI Build Log
- CI Artifact

Alpha 虽然不创建 Release，但必须保留对应的变更记录。

## 10.1 Alpha 日志范围

Alpha Release Log **只包含本次构建与上一次成功 Alpha 构建之间的提交**：

```text
上一次成功 Alpha 构建的 Commit .. 当前 Commit
```

- Alpha 禁止创建 Git Tag，区间起点由 CI 通过 GitHub Actions API 取本构建工作流上一次成功运行的 Commit（完整实现见 §28 `Generate release log` 步骤）。
- 仓库尚无任何成功构建（首次）时，范围为全部提交。
- 同一 Commit 重新构建（rerun）时，跳过同 Commit 的历史运行，沿用与其一致的区间。
- 每个 Alpha 的 Release Log 互不重复：某次提交只会出现在其后的第一个 Alpha 日志中。

---

# 11. Beta 发布规范

Beta 是面向测试用户的发布版本。

Beta 必须通过 Git Tag 触发。

## 11.1 Beta Version

格式：

```text
MAJOR.MINOR.PATCH-beta.N
```

例如：

```text
1.2.0-beta.1
1.2.0-beta.2
```

---

## 11.2 Beta Tag

Beta Tag 必须与 Version Name 完全一致。

例如：

```text
Version Name:
1.2.0-beta.1

Git Tag:
1.2.0-beta.1
```

执行：

```text
git tag 1.2.0-beta.1
git push origin 1.2.0-beta.1
```

CI 自动触发 Beta 发布。

---

## 11.3 Beta CI 流程

```text
Beta Tag
 ↓
CI Trigger
 ↓
验证 Git Tag
 ↓
验证 Version Name
 ↓
分配新的 Build ID
 ↓
Version Code = Build ID
 ↓
生成 Release Log
 ↓
Build
 ↓
Test
 ↓
创建 Release
 ↓
发布 Beta
```

## 11.4 撤回 Beta

已发布的 Beta 需要撤回时，按此顺序执行（**完整 workflow、恢复顺序与验收清单见 §27.9**）：

1. 删 GitHub Release：`gh release delete <版本> --yes`
2. 删 Git Tag：`git tag -d <版本> && git push origin :refs/tags/<版本>`
3. Actions 跑 `rollback-openlist`，把 OpenList 的通道指针与版本目录回滚
   （含从「以前的版本」归档恢复带 zip 的 CI 原件）

撤回**不释放**已消耗的 Build ID，因此 **下一个 Beta 必须换新序号**
（撤回 `beta.2` 后下次发 `beta.3`），避免同一 `version_name` 对应不同 Build ID。

---

# 12. Beta Release Log

每一个 Beta 版本都必须存在 Release Log。

Beta Release Log 可以由 CI 根据 Git Commit 自动生成，并附加到 Beta Release。

## 12.1 Beta 日志范围

Beta Release Log **只包含上一个 Beta Tag 到当前 Beta Tag 之间的提交**：

```text
上一个 Beta Tag .. 当前 Beta Tag
```

- 不存在更早的 Beta Tag（首个 Beta）时，回退到最近的一个任意 Tag（通常为上一个 Stable）。
- 仓库尚无任何 Tag 时，范围为全部提交。
- 区间计算的完整实现见 §28 `Generate release log` 步骤（`beta` 分支）。

示例：

```text
1.2.0-beta.2

新增
- 新增下载队列

变更
- 优化任务管理

修复
- 修复下载失败问题
- 修复任务状态异常问题

Known Issues
- XXX
```

---

# 13. Stable 发布规范

Stable 是正式发布版本。

Stable 不包含 Channel 后缀。

格式：

```text
MAJOR.MINOR.PATCH
```

例如：

```text
1.2.0
```

Stable 必须通过 Git Tag 触发。

---

# 14. Stable Tag

Stable Tag 必须与 Version Name 完全一致。

例如：

```text
Version Name:
1.2.0

Git Tag:
1.2.0
```

执行：

```text
git tag 1.2.0
git push origin 1.2.0
```

CI 自动触发 Stable 发布。

---

## 14.1 Stable CI 流程

```text
Stable Tag
 ↓
CI Trigger
 ↓
验证 Git Tag
 ↓
验证 Version Name
 ↓
分配新的 Build ID
 ↓
Version Code = Build ID
 ↓
生成 Release Log
 ↓
Build
 ↓
Test
 ↓
创建 Release
 ↓
发布 Stable
```

---

# 15. Stable Release Log

每一个 Stable 版本都必须存在正式 Release Log。

Stable Release Log 应面向最终用户进行整理。

## 15.1 Stable 日志范围

Stable Release Log **只包含上一个 Stable Tag 到当前 Stable Tag 之间的提交**：

```text
上一个 Stable Tag .. 当前 Stable Tag
```

- 不存在更早的 Stable Tag（首个 Stable）时，回退到最近的一个任意 Tag（通常为上一个 Beta）。
- 仓库尚无任何 Tag 时，范围为全部提交。
- 区间计算的完整实现见 §28 `Generate release log` 步骤（`stable` 分支）。

示例：

```text
1.2.0

新增
- 新增下载队列
- 新增任务管理

优化
- 优化下载性能
- 优化用户界面

修复
- 修复下载失败问题
- 修复任务状态异常问题

Known Issues
- XXX
```

Stable Release Log 作为正式 Release 的发布说明。

---

# 16. Git Tag 规范

Git Tag **只允许用于 Beta 和 Stable**。

```text
Alpha  → 禁止 Tag
Beta   → 必须 Tag
Stable → 必须 Tag
```

---

## 16.1 Beta Tag

必须满足：

```text
Git Tag == Version Name
```

例如：

```text
Version Name:
1.2.0-beta.1

Git Tag:
1.2.0-beta.1
```

---

## 16.2 Stable Tag

必须满足：

```text
Git Tag == Version Name
```

例如：

```text
Version Name:
1.2.0

Git Tag:
1.2.0
```

---

## 16.3 禁止额外前缀或后缀

禁止：

```text
v1.2.0
release-1.2.0
stable-1.2.0
beta-1.2.0
```

正确：

```text
1.2.0
1.2.0-beta.1
```

---

# 17. CI/CD 触发规则

最终 CI/CD 采用以下规则：

| Git 事件   | Channel | Version Name           | Build ID | 自动 Build | 自动 Release | Git Tag |
| ---------- | ------- | ---------------------- | -------: | ---------: | -----------: | ------: |
| Push       | Alpha   | `x.y.z-alpha.BUILD_ID` |     新增 |         ✅ |           ❌ |      ❌ |
| Beta Tag   | Beta    | `x.y.z-beta.N`         |     新增 |         ✅ |           ✅ |      ✅ |
| Stable Tag | Stable  | `x.y.z`                |     新增 |         ✅ |           ✅ |      ✅ |

**路径过滤（仅影响 Push 行）**：`build.yml` 对分支 push 设了 `paths-ignore`——
`docs/**` 与全部 `*.md` 不触发构建，省掉纯文档改动的全量测试+打包。

- **Tag 行不受影响**：GitHub 明确 *Path filters are not evaluated for pushes of tags*，
  Beta/Stable Tag 永远触发，上表 ✅ 不打折。
- **混合 push**：只要有一个改动文件不在忽略列表内就照常触发；diff 超 1000 commit
  或生成超时则强制触发。
- **对日志无影响**：被跳过的 commit 留在「上次成功构建..HEAD」区间内，由
  `ci/release-log.sh` 按类型过滤（`docs|chore|ci|test|style|build` 不入日志）——
  因此文档类改动必须用 `docs:` 前缀提交，用 `feat:`/`fix:` 会被写进更新日志。
- `ci/**` 与 `.github/**` **刻意不忽略**：CI 脚本与 workflow 本身只有在本次 push 里
  才会被用到并验证，跳过等于改了不测。

---

# 18. 完整版本生命周期

假设当前 Stable：

```text
1.1.0
Build ID 150
```

开始开发 `1.2.0`。

第一次 Push：

```text
1.2.0-alpha.151
Build ID 151
Version Code 151
```

第二次 Push：

```text
1.2.0-alpha.152
Build ID 152
Version Code 152
```

第三次 Push：

```text
1.2.0-alpha.153
Build ID 153
Version Code 153
```

此时：

```text
Git Tag:
无
```

进入 Beta：

```text
Git Tag:
1.2.0-beta.1
```

CI 生成：

```text
Version:
1.2.0-beta.1

Build ID:
154

Version Code:
154
```

继续 Beta：

```text
Git Tag:
1.2.0-beta.2
```

CI 生成：

```text
Version:
1.2.0-beta.2

Build ID:
155

Version Code:
155
```

最终 Stable：

```text
Git Tag:
1.2.0
```

CI 生成：

```text
Version:
1.2.0

Build ID:
156

Version Code:
156
```

---

# 19. 完整示例

```text
1.2.0-alpha.200   Build ID 200   ← Push，Action only
1.2.0-alpha.201   Build ID 201   ← Push，Action only
1.2.0-alpha.202   Build ID 202   ← Push，Action only
1.2.0-alpha.203   Build ID 203   ← Push，Action only
        ↓
Git Tag: 1.2.0-beta.1
        ↓
1.2.0-beta.1      Build ID 204   ← 自动 Beta Release
        ↓
Git Tag: 1.2.0-beta.2
        ↓
1.2.0-beta.2      Build ID 205   ← 自动 Beta Release
        ↓
Git Tag: 1.2.0
        ↓
1.2.0              Build ID 206   ← 自动 Stable Release
        ↓
开发下一版本
        ↓
1.3.0-alpha.207   Build ID 207   ← Push，Action only
1.3.0-alpha.208   Build ID 208   ← Push，Action only
```

注意：

```text
1.2.0-alpha.203
        ↓
1.3.0-alpha.207
```

Alpha 后缀始终跟随全局 Build ID，不重新从 `1` 开始。

---

# 20. Version Name 与 Version Code 对照

### Alpha

```text
Version Name:
1.2.0-alpha.202

Version Code:
202

Build ID:
202
```

### Beta

```text
Version Name:
1.2.0-beta.1

Version Code:
204

Build ID:
204
```

### Stable

```text
Version Name:
1.2.0

Version Code:
206

Build ID:
206
```

因此：

```text
Alpha:
Version Name 后缀 = Build ID = Version Code
```

而 Beta / Stable：

```text
Version Name
    ≠
Version Code

Version Code 仍然是全局 Build ID。
```

---

# 21. 强制规则

以下规则为项目强制规范：

1. 项目仅允许 `alpha`、`beta`、`stable` 三个 Channel。
2. 不允许使用 `dev`、`rc`、`nightly`、`canary`、`preview`、`snapshot` 等其他 Channel。
3. 所有开发阶段构建统一使用 `alpha`。
4. Alpha 每次 Push 自动触发 CI Build；纯文档（`docs/**`、`*.md`）经 `paths-ignore` 跳过。
   路径过滤只作用于分支 push，**Tag 不受路径过滤影响**（见 §17），Beta/Stable Tag 必然触发。
5. Alpha Version Name 格式必须为 `MAJOR.MINOR.PATCH-alpha.BUILD_ID`。
6. Alpha 后缀必须直接使用本次 Build ID。
7. Alpha 不维护独立的 Alpha 序号。
8. Alpha 的 Build ID 与 Version Code 必须一致。
9. Build ID / Version Code 必须全局单调递增。
10. Build ID / Version Code 永远不得重复。
11. 已使用的 Build ID / Version Code 永久不得重新使用。
12. Alpha 严禁创建 Git Tag。
13. Alpha 严禁通过 Git Tag 触发 CI。
14. Alpha 不创建 GitHub Release。
15. Alpha 不发布到正式发行渠道。
16. Alpha 构建产物只发布到 OpenList 的 alpha 通道——不进 GitHub Release，也不上传 Action Artifact。
17. Alpha 每次构建必须生成 Release Log。
18. Beta 必须通过 Beta Git Tag 触发 CI。
19. Beta Tag 必须与 Version Name 完全一致。
20. Beta Tag 触发后必须自动 Build 并创建 Beta Release。
21. Beta 每次发布必须生成 Release Log。
22. Stable 必须通过 Stable Git Tag 触发 CI。
23. Stable Tag 必须与 Version Name 完全一致。
24. Stable Tag 触发后必须自动 Build 并创建 Stable Release。
25. Stable 每次发布必须生成 Release Log。
26. Git Tag 不得增加 `v`、`release-`、`stable-`、`beta-` 等额外前缀或后缀。
27. Git Tag 只允许存在于 Beta 和 Stable。
28. 版本生命周期统一为：

```text
alpha → beta → stable
```

---

# 22. 最终 CI/CD 模型

```text
                         Developer Push
                               │
                               ▼
                      ┌─────────────────┐
                      │      Alpha      │
                      │   Auto Build    │
                      └────────┬────────┘
                               │
                               ▼
                         Generate Build ID
                               │
                               ▼
                    x.y.z-alpha.BUILD_ID
                               │
                               ▼
                    Action / CI Artifact
                         + Release Log
                               │
                               │
                    ❌ Git Tag
                    ❌ GitHub Release
                               │
                               ▼
                         开发完成
                               │
                               ▼
                  Git Tag: 1.2.0-beta.1
                               │
                               ▼
                      ┌─────────────────┐
                      │      Beta       │
                      │   Auto Build    │
                      └────────┬────────┘
                               │
                               ▼
                         Beta Release
                         + Release Log
                               │
                               │
                  Git Tag: 1.2.0-beta.2
                               │
                               ▼
                         Beta Release
                               │
                               ▼
                         测试完成
                               │
                               ▼
                     Git Tag: 1.2.0
                               │
                               ▼
                      ┌─────────────────┐
                      │     Stable      │
                      │   Auto Build    │
                      └────────┬────────┘
                               │
                               ▼
                       Stable Release
                       + Release Log
```

---

# 23. 最终定义

## Alpha

```text
Push
 ↓
MAJOR.MINOR.PATCH-alpha.BUILD_ID
 ↓
Build
 ↓
Release Log
 ↓
Artifact
```

Alpha：

```text
Git Tag      = ❌
GitHub Release = ❌
Build ID     = Version Code
```

---

## Beta

```text
Git Tag
 ↓
MAJOR.MINOR.PATCH-beta.N
 ↓
Build
 ↓
Release Log
 ↓
Beta Release
```

Beta：

```text
Git Tag == Version Name
Build ID = Version Code
```

---

## Stable

```text
Git Tag
 ↓
MAJOR.MINOR.PATCH
 ↓
Build
 ↓
Release Log
 ↓
Stable Release
```

Stable：

```text
Git Tag == Version Name
Build ID = Version Code
```

---

# 24. 最终规则总览

```text
┌─────────┬──────────────────────────────┬──────────────┬───────────────┐
│ Channel │ Version Name                │ Trigger      │ Release       │
├─────────┼──────────────────────────────┼──────────────┼───────────────┤
│ Alpha   │ x.y.z-alpha.BUILD_ID        │ Git Push     │ ❌             │
│ Beta    │ x.y.z-beta.N                │ Git Tag      │ ✅             │
│ Stable  │ x.y.z                        │ Git Tag      │ ✅             │
└─────────┴──────────────────────────────┴──────────────┴───────────────┘
```

Git Tag：

```text
Alpha  → ❌ 禁止
Beta   → ✅ 必须，Tag == Version Name
Stable → ✅ 必须，Tag == Version Name
```

Build ID / Version Code：

```text
全局唯一
全局递增
永不重复
```

Alpha：

```text
alpha.BUILD_ID
```

因此最终版本体系为：

```text
1.2.0-alpha.100
1.2.0-alpha.101
1.2.0-alpha.102
        ↓
1.2.0-beta.1
1.2.0-beta.2
        ↓
1.2.0
```

最终生命周期：

```text
alpha → beta → stable
```

---

# 25. 构建产物命名规范

所有 CI/CD 生成的构建产物必须使用统一的文件名格式。

构建产物名称必须能够识别：

- 软件名称
- Version Name
- Build ID
- Platform
- CPU Architecture

本项目的产物是**按平台打包的压缩包**：每个平台一个 zip，包内自带 `tools/`
依赖（`payload-dumper-go` / `extract.erofs`）与全部脚本，解压即用，
没有安装器、也没有签名/渠道变体。

---

## 25.1 基本格式

```text
<软件名>-<Version Name>-<Build ID>-<Platform>-<arch>.zip
```

| 段           | 说明             | 取值示例                        |
| ------------ | ---------------- | ------------------------------- |
| 软件名       | 固定前缀         | `Analysis-Tool-For-ColorOS`     |
| Version Name | 由通道决定（§3） | `2.2.0-alpha.17` / `2.2.0-beta.1` / `2.1.0` |
| Build ID     | `github.run_number`，与 `version_code` 同值（§5） | `22` |
| Platform     | 见 §25.2         | `Linux`                         |
| arch         | 见 §25.3         | `x86_64`                        |

示例：`Analysis-Tool-For-ColorOS-2.1.0-22-Linux-x86_64.zip`

### Alpha / Beta / Stable

三通道的文件名格式**完全一致**，只有 Version Name 段随通道变化：

| 通道   | 示例                                              |
| ------ | ------------------------------------------------- |
| Alpha  | `Analysis-Tool-For-ColorOS-2.2.0-alpha.17-17-Linux-x86_64.zip` |
| Beta   | `Analysis-Tool-For-ColorOS-2.2.0-beta.1-18-Linux-x86_64.zip`   |
| Stable | `Analysis-Tool-For-ColorOS-2.1.0-22-Linux-x86_64.zip`          |

---

## 25.2 Platform 命名规范

首字母大写的操作系统名，与 `runtime identifier` 风格对齐但保留常见写法：

| Platform | 目标环境                          |
| -------- | --------------------------------- |
| `Windows` | Windows x86_64（Cygwin 工具链）  |
| `Linux`   | Linux x86_64 / arm64             |
| `Darwin`  | macOS x86_64 / arm64             |
| `Android` | Android 终端（termux 类环境）    |
| `WSL`     | Windows Subsystem for Linux      |

- 不得写成 `win`、`macos`、`linux-gnu` 等缩写或变体；
- Platform 段与 `7z` 打包目录名、Release asset 名、OpenList 产物名三处必须逐字一致。

---

## 25.3 Architecture 命名规范

| arch       | 说明                |
| ---------- | ------------------- |
| `x86_64`   | 64 位 Intel/AMD     |
| `arm64`    | 64 位 ARM           |

- 只允许 `x86_64` / `arm64`，禁止 `amd64`、`aarch64`、`x64`、`armv8` 等同义写法；
- 本项目**没有 32 位产物**，出现 `x86` / `armv7` 即为配置错误。

---

## 25.4 无 Build Type 段

原规范里 Alpha 的 Debug/Release 双产物在本项目不适用：

- 产物是 Python 脚本打包，**不存在 debug/release 编译差异**；
- 因此 Alpha 不额外追加 `debug` / `release` 后缀，三通道产物名除 Version Name 外逐字相同；
- **Build ID 必须进文件名**（与热量日记 §25.1 一致）：`github.run_number` 全局单调递增，
  写进文件名后，同一个 Version Name 重新构建也不会互相覆盖，`version.json` 与 Release Log
  里的 `build_id` 也能一眼对上产物。

---

## 25.5 文件扩展名

| 类型           | 扩展名  |
| -------------- | ------- |
| 平台压缩包     | `.zip`  |

只允许 `.zip`；不产出 `.tar.gz`、`.7z`（打包过程内部会用 tar/7z，但产物统一转 zip）。

---

## 25.6 Artifact 示例

本次 Version Name 为 `2.1.0` 时，一次构建产出 8 个产物：

```text
Analysis-Tool-For-ColorOS-2.1.0-22-Windows-x86_64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-Linux-arm64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-Linux-x86_64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-Darwin-arm64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-Darwin-x86_64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-Android-arm64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-Android-x86_64.zip
Analysis-Tool-For-ColorOS-2.1.0-22-WSL-x86_64.zip
```

同一文件名出现在三处，必须逐字一致：

1. `output/` 下的文件（`build.yml` 的 `Move dependencies-*` 产出）；
2. GitHub Release asset（`Create GitHub Release` 步骤 `ls output/<名字>-"$VERSION"-"$BUILD_ID"-*.zip`）；
3. OpenList 版本目录（`ci/upload-openlist.sh` 按 `Analysis-Tool-For-ColorOS-<version>-*.zip` 匹配上传）。

---

## 25.7 Artifact 强制规则

1. 产物名必须严格符合 §25.1 格式，缺段、多段、大小写不符即视为错误；
2. 一次构建的全部产物 Version Name 段必须**完全相同**；
3. `Platform` / `arch` 组合必须来自 §25.2 / §25.3 的白名单，且不得重复；
4. 同一仓库的历史产物不得被重新命名覆盖（已发布的文件名即对外契约）；
5. Alpha 产物只进 Action Artifact 与 OpenList alpha 通道，**不进 GitHub Release**（§9）。

---

## 25.8 最终 Artifact 命名规则

```text
Analysis-Tool-For-ColorOS-<Version Name>-<Platform>-<arch>.zip
```

`<Version Name>` 按通道取：

```text
Alpha
└── <MAJOR.MINOR.PATCH>-alpha.<BUILD_ID>

Beta
└── <MAJOR.MINOR.PATCH>-beta.<N>

Stable
└── <MAJOR.MINOR.PATCH>
```
---

# 26. Release Log 模板与生成实现

Release Log 由 `ci/release-log.sh` 一次生成两份文件，分别服务 OpenList / GitHub Release 与 `version.json` 的 changelog。
build.yml 的 `Generate release log` 步骤按 §10.1 / §12.1 / §15.1 计算好日志区间后调用该脚本。

## 26.1 双文件设计

| 文件           | 格式     | 消费方                                  | 说明                                       |
| -------------- | -------- | --------------------------------------- | ------------------------------------------ |
| `release.md`   | Markdown | OpenList 各级 README、GitHub Release    | 含 `# 版本` 大标题，页面上版本醒目          |
| `changelog.txt` | 纯文本  | `version.json` 的 `changelog`（网页/工具读取） | 不含版本头与任何标记                    |

设计原因：

- 版本号已由 `version_name`（解析自 `version.json`）单独展示，若日志再以版本号开头会重复显示；
- OpenList 的 README 页面需要版本号作为大标题，因此 Markdown 版保留版本头；
- 纯文本版直接进 `changelog` 字段展示，不含 `#`、`>`、emoji 等会露出的语法标记。

## 26.2 release.md 模板（Markdown）

```markdown
# Analysis Tool For ColorOS 2.2.0-alpha.17

> 2026-09-28 · Build 115 · 内测版
>
> 📥 [前往 OpenList 下载内测版](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/alpha/)

### ✨ 新增
- 按 channel 分段生成更新日志范围

### 🐛 修复
- 修复更新弹窗进度显示异常
```

- 分组标题中文化（Keep a Changelog 分类的中文对应），Stable 与非 Stable 统一：
  **新增 / 变更 / 优化 / 修复 / 其他**，采用 GitHub 自动 Release Notes 风格的 emoji 前缀；
- 元信息行：ISO 日期 · Build ID · 通道中文名（内测版 / 公测版 / 正式版）；
- **下载链接**：设置了 `OPENLIST_BASE_URL` 时自动注入，指向**通道根目录**
  （保留策略只清理版本子目录，通道根入口长期有效）；Release notes **不再追加任何
  失效提示**（废弃标记机制已移除，见 §27.7）。

## 26.3 changelog.txt 模板（纯文本）

```text
新增
- 按 channel 分段生成更新日志范围

修复
- 修复更新弹窗进度显示异常
```

无标题、无版本号、无任何 Markdown 标记，展示时直接露出原文也不显语法。

## 26.4 生成实现（示例文件：`ci/release-log.sh`）

```bash
#!/usr/bin/env bash
# 生成 Release Log（Conventional Commits 分类），日志区间由调用方计算后传入。
# 用法: ci/release-log.sh <range>     例: ci/release-log.sh 372b302..HEAD  /  ci/release-log.sh HEAD
# 环境: VERSION / BUILD_ID / CHANNEL 必填；PRODUCT_NAME / OPENLIST_BASE_URL 可选
#       （OPENLIST_BASE_URL 设置后在 Markdown 头注入 OpenList 下载链接）
#
# 一次生成两份文件（见 docs/VERSIONING.md §26）：
#   release.md    Markdown，供 OpenList README 与 GitHub Release notes 渲染（含版本标题与下载链接）
#   changelog.txt 纯文本，供 version.json 的 changelog 字段
#
# 过滤规则：docs/chore/ci/test/style/build 不入日志；完全相同的消息只保留一条。
set -euo pipefail

RANGE=${1:?用法: ci/release-log.sh <range>}
: "${VERSION:?VERSION is required}"
: "${BUILD_ID:?BUILD_ID is required}"
: "${CHANNEL:?CHANNEL is required}"
PRODUCT_NAME=${PRODUCT_NAME:-Analysis Tool For ColorOS}
OPENLIST_BASE_URL=${OPENLIST_BASE_URL:-}

case "$CHANNEL" in
  alpha)  CHANNEL_LABEL="内测版" ;;
  beta)   CHANNEL_LABEL="公测版" ;;
  stable) CHANNEL_LABEL="正式版" ;;
  *)      CHANNEL_LABEL="$CHANNEL" ;;
esac

git log --pretty=format:'%s' "$RANGE" | awk \
  -v VERSION="$VERSION" \
  -v BUILD_ID="$BUILD_ID" \
  -v CHANNEL="$CHANNEL" \
  -v CHANNEL_LABEL="$CHANNEL_LABEL" \
  -v PRODUCT="$PRODUCT_NAME" \
  -v OPENLIST="$OPENLIST_BASE_URL" \
  -v DATE="$(date -u +%F)" '
  /^feat(\([^)]*\))?:/ { s = $0; sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s); if (s in seen) next; seen[s] = 1; a[++na] = s; next }
  /^fix(\([^)]*\))?:/  { s = $0; sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s); if (s in seen) next; seen[s] = 1; f[++nf] = s; next }
  {
    s = $0
    if ($0 ~ /^[A-Za-z]+(\([^)]*\))?:/) sub(/^[A-Za-z]+(\([^)]*\))?:[ \t]*/, "", s)
    # 非用户可见变更（文档/杂务/CI/测试/样式/构建）不入日志
    if ($0 ~ /^(docs|chore|ci|test|style|build)(\([^)]*\))?:/) { next }
    # 完全相同的消息只保留一条
    if (s in seen) { next }
    seen[s] = 1
    if (CHANNEL == "stable") { p[++np] = s }
    else if ($0 ~ /^[A-Za-z]+(\([^)]*\))?:/) { c[++nc] = s }
    else { o[++no] = s }
  }
  END {
    MD = "release.md"; TXT = "changelog.txt"
    # Markdown 头：OpenList / GitHub 渲染用（版本大标题 + 元信息 + 可选下载链接）
    print "# " PRODUCT " " VERSION > MD
    print "" > MD
    print "> " DATE " · Build " BUILD_ID " · " CHANNEL_LABEL > MD
    if (OPENLIST != "") {
      print ">" > MD
      print "> 📥 [前往 OpenList 下载" CHANNEL_LABEL "](" OPENLIST "/" CHANNEL "/)" > MD
    }
    print "" > MD
    # 纯文本无头：版本号已在别处展示，这里不再重复
    # 分组标题中文化（Keep a Changelog 分类的中文对应），Stable 与非 Stable 统一
    empty = 1
    if (na) {
      empty = 0
      print "### ✨ 新增" > MD; print "新增" > TXT
      for (i = 1; i <= na; i++) { print "- " a[i] > MD; print "- " a[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (nc) {
      empty = 0
      print "### 🔄 变更" > MD; print "变更" > TXT
      for (i = 1; i <= nc; i++) { print "- " c[i] > MD; print "- " c[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (np) {
      empty = 0
      print "### ⚡ 优化" > MD; print "优化" > TXT
      for (i = 1; i <= np; i++) { print "- " p[i] > MD; print "- " p[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (nf) {
      empty = 0
      print "### 🐛 修复" > MD; print "修复" > TXT
      for (i = 1; i <= nf; i++) { print "- " f[i] > MD; print "- " f[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (no) {
      empty = 0
      print "### 🧰 其他" > MD; print "其他" > TXT
      for (i = 1; i <= no; i++) { print "- " o[i] > MD; print "- " o[i] > TXT }
      print "" > MD; print "" > TXT
    }
    if (empty) {
      # 无用户可见变更时按同格式输出兜底条目（业界惯例 Bug fixes and improvements），
      # 避免日志出现开发向措辞
      print "### 🐛 修复" > MD; print "修复" > TXT
      print "- 修复了一些已知问题" > MD
      print "- 修复了一些已知问题" > TXT
      print "" > MD; print "" > TXT
    }
  }
'
```

分类规则（与 Conventional Commits 对应，提交格式与**条目写作要求**见 §30；
**分组标题在日志中显示为中文**；`feat`/`fix` 的描述须面向用户，这是日志可读性的源头）：

| Commit 前缀           | 非 Stable 分组 | Stable 分组 |
| --------------------- | -------------- | ----------- |
| `feat:`               | 新增           | 新增        |
| `fix:`                | 修复           | 修复        |
| 其他常规类型前缀       | 变更           | 优化        |
| 无类型前缀的裸文本     | 其他           | 优化        |
| `docs:` `chore:` `ci:` `test:` `style:` `build:` | 不入日志 | 不入日志 |

当区间内**没有**任何用户可见变更（全是被过滤的类型或空区间）时，两份文件按同格式输出兜底条目，
不输出「本次无用户可见变更」这类开发向措辞（日志面向最终用户，参照业界惯例
“Bug fixes and improvements”）：

```text
修复
- 修复了一些已知问题
```

（`release.md` 对应 `### 🐛 修复` 分组。）

---

# 27. OpenList 发布与 version.json

App 的分发与在线更新依赖自建 OpenList（`storage.horatio.cn`）。
`ci/upload-openlist.sh` 在每次 build.yml 构建成功后全自动执行，无需手动上传。

## 27.1 目录结构

```text
OpenList/storage/Analysis-Tool-For-ColorOS/
├── README.md                 # 下载中心首页卡片（脚本维护）
├── alpha/
│   ├── README.md             # = 最新 alpha 的 release.md
│   ├── version.json          # 检查更新 / 网页读取的元数据
│   ├── 2.2.0-alpha.17/       # 当前版本目录（zip + README.md + version.json）
│   └── 以前的版本/            # 旧版本归档（alpha 仅保留最新 1 版，无归档）
├── beta/                     # 保留最新 2 版
└── stable/                   # 保留最新 3 版
```

## 27.2 每次构建同步的文件

| 目标                                        | 来源            | 作用                              |
| ------------------------------------------- | --------------- | --------------------------------- |
| `<版本目录>/README.md`、`<通道>/README.md`  | `release.md`    | OpenList 页面自动渲染的更新说明   |
| `<通道>/version.json`、`<版本目录>/version.json` | CI 生成     | 检查更新 / 网页读取                |
| `<版本目录>/*.zip`                          | 构建产物        | 平台压缩包下载                    |
| `Analysis-Tool-For-ColorOS/README.md`                    | 脚本内置模板    | 下载中心首页三通道卡片            |

## 27.3 version.json 字段

| 字段            | 说明                                                        |
| --------------- | ----------------------------------------------------------- |
| `channel`       | `alpha` / `beta` / `stable`                                 |
| `version_name`  | 完整版本名，如 `2.2.0-alpha.17`（页面与更新提示展示）       |
| `version_code`  | 全局构建号，等于 `build_id`（见 §5）                        |
| `build_id`      | 全局构建号                                                  |
| `file_name`     | 默认下载产物文件名（Linux x86_64）                           |
| `download_url`  | 产物直链                                                    |
| `changelog`     | `changelog.txt` 全文（纯文本，不含版本号，见 §26.1）        |
| `updated_at`    | UTC 时间戳                                                  |

## 27.4 拉取方式

`version.json` 有两条等价取法，网页、脚本、未来的更新检查都适用：

1. **签名直链（推荐）**：`POST https://storage.horatio.cn/api/fs/get`，body 为
   `{"path":"/Analysis-Tool-For-ColorOS/<channel>/version.json"}`，取返回的 `raw_url` 后 GET；
2. **静态直链兜底**：`https://storage.horatio.cn/Analysis-Tool-For-ColorOS/<channel>/version.json`
   （OpenList 的 SPA 会把未知路径返回成 HTML——读到 `<` 开头即视为失败，不要当 JSON 解析）。

**注意：不要在 OpenList 后台把 `version.json` 加入隐藏文件**，否则 `fs_get` 返回 403，
调用方会收到「存储服务权限拒绝」。如需隐藏配置，请使用全局设置里的隐藏文件项，勿点选该文件。

下载产物时同理：先把 `download_url` 换算为签名 `raw_url`（网页直链未签名会返回 HTML），
下载完成后校验前 4 字节 `50 4B 03 04`（ZIP 魔数），拦掉被重定向成网页的坏包。

版本比较与通道策略——**通道独立**：只拉取目标通道的 `version.json`，
用 `version_code`（= 全局 Build ID，§5 保证跨通道可比）做新旧判断；
不做跨通道自动升级，切换通道由使用者显式选择。

## 27.5 保留与归档策略

由 `ci/upload-openlist.sh` 自动执行：新版本上传后，同通道旧版本目录移入 `以前的版本/`，
再按保留数清理。

| 通道   | 保留数量      |
| ------ | ------------- |
| alpha  | 最新 1 版     |
| beta   | 最新 2 版     |
| stable | 最新 3 版     |

## 27.6 手动触发与覆盖关系

- 重建当前版本：GitHub Actions → `build` → `Run workflow`（workflow_dispatch）；
- 直接在 OpenList 网页修改的 `README.md` / `version.json` 会在下一次 CI 构建时被覆盖，
  如需长期改动请修改 `ci/release-log.sh` / `ci/upload-openlist.sh` 后提交。

## 27.7 废弃标记（已移除）

**不再向 Release notes 追加任何失效提示**（原 `⚠️ 已超出保留策略…` 与 `📥 请前往下载中心…`
两段随 `ci/mark-stale-releases.sh` 一并移除，存量标记已清理）：
Release 页面只保留版本说明本身，失效链接自然 404，**下载中心 / 通道根入口是唯一引导**。
OpenList 的 1/2/3 版本清理规则本身不变（见 §27.8）。

## 27.8 完整上传脚本：`ci/upload-openlist.sh`

每次构建全自动执行：上传 zip → 同步 README（`release.md`）→ 生成并上传 `version.json`
（changelog 优先取 `changelog.txt`）→ 维护下载中心首页卡片 → 归档清理旧版本。

路径配置**不在仓库里**：必需 env `OPENLIST_STORAGE_DIR` 由 Actions Secret
`SERVER_OPENLIST_DIR` 注入，值是 OpenList 存储根（到 `/storage` 为止），
分发目录 `Analysis-Tool-For-ColorOS` 与遗留垃圾目录 `storage` 都由脚本在根下拼接；
未注入时脚本第一行校验即失败，不回退到任何兜底路径。

```bash
#!/usr/bin/env bash
# 严格遵循 docs/VERSIONING.md 规范
# 将构建产物与更新日志上传至服务器 OpenList 目录，并按通道策略自动归档与清理旧版本。
# 通道保留策略：
#   alpha  : 保留最新 1 版
#   beta   : 保留最新 2 版
#   stable : 保留最新 3 版
set -euo pipefail

: "${SERVER_HOST:?SERVER_HOST is required}" \
  "${SERVER_USER:?SERVER_USER is required}" \
  "${SERVER_SSH_KEY:?SERVER_SSH_KEY is required}" \
  "${CHANNEL:?CHANNEL is required}" \
  "${VERSION:?VERSION is required}" \
  "${BUILD_ID:?BUILD_ID is required}" \
  "${OPENLIST_STORAGE_DIR:?OPENLIST_STORAGE_DIR is required}"

SSH_PORT=${SSH_PORT:-22}
# OPENLIST_STORAGE_DIR 是 OpenList 存储根（Actions secret SERVER_OPENLIST_DIR），
# 本项目的分发目录 Analysis-Tool-For-ColorOS 与遗留垃圾目录 storage 都挂在它下面。
BASE_STORAGE="$OPENLIST_STORAGE_DIR/Analysis-Tool-For-ColorOS"
TARGET_DIR="$BASE_STORAGE/$CHANNEL"
VERSION_DIR="$TARGET_DIR/$VERSION"

# 构建产物：Analysis-Tool-For-ColorOS-<version>-<Platform>-<arch>.zip
ARTIFACT_PREFIX=${ARTIFACT_PREFIX:-Analysis-Tool-For-ColorOS}
ARTIFACT_DIR=${ARTIFACT_DIR:-.}
# version.json 里作为默认下载的那个产物（Linux x86_64 覆盖面最大）
PRIMARY_ARTIFACT=${PRIMARY_ARTIFACT:-Linux-x86_64}

case "$CHANNEL" in
  alpha)  KEEP_VERSIONS=1 ;;
  beta)   KEEP_VERSIONS=2 ;;
  stable) KEEP_VERSIONS=3 ;;
  *)      KEEP_VERSIONS=3 ;;
esac

SSH_OPTS=(-i "$RUNNER_TEMP/openlist_key" -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes)
run_ssh() { ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_HOST" "bash -c $(printf '%q' "$1")"; }
run_scp() { scp -i "$RUNNER_TEMP/openlist_key" -P "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "$@"; }

cleanup_key() { rm -f "$RUNNER_TEMP/openlist_key"; }
cleanup_key
trap cleanup_key EXIT

install -m 600 /dev/null "$RUNNER_TEMP/openlist_key"
printf '%s\n' "$SERVER_SSH_KEY" > "$RUNNER_TEMP/openlist_key"

echo "== [OpenList] 准备版本目录: $VERSION_DIR =="
run_ssh "mkdir -p '$VERSION_DIR'"
run_ssh "if [ -d '$OPENLIST_STORAGE_DIR/storage' ]; then rm -rf '$OPENLIST_STORAGE_DIR/storage'; fi" || true

# 1. 上传构建产物至版本号文件夹
echo "== [OpenList] 上传构建产物至 $VERSION_DIR =="
# 版本目录由 CI 独占：先清掉该目录下已有的 zip（历史命名、重传残留），
# 保证目录内容与本次产物逐字一致——否则改名/重跑会出现新旧两套文件。
run_ssh "rm -f '$VERSION_DIR'/*.zip"
mapfile -t ARTIFACTS < <(ls "$ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION"-*.zip 2>/dev/null || true)
if [ "${#ARTIFACTS[@]}" -eq 0 ]; then
  echo "::error::未找到待上传的产物: $ARTIFACT_DIR/$ARTIFACT_PREFIX-$VERSION-*.zip"
  exit 1
fi
run_scp "${ARTIFACTS[@]}" "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/"

# 2. 将 release.md 同步为该版本目录及通道目录的 README.md，供 OpenList 自动渲染
if [ -f release.md ]; then
  echo "== [OpenList] 同步 release.md 为 README.md =="
  run_scp release.md "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/README.md"
  run_scp release.md "$SERVER_USER@$SERVER_HOST:$TARGET_DIR/README.md"
fi

# 2.5 生成并上传 version.json 元数据（供网页 / 检查更新直接拉取）
echo "== [OpenList] 生成 version.json =="
VERSION_JSON_TMP="$RUNNER_TEMP/version.json"
FILE_NAME="$ARTIFACT_PREFIX-$VERSION-$BUILD_ID-$PRIMARY_ARTIFACT.zip"
DOWNLOAD_URL="https://storage.horatio.cn/Analysis-Tool-For-ColorOS/$CHANNEL/$VERSION/$FILE_NAME"

# changelog 优先取纯文本 changelog.txt（避免与日志开头重复）；
# 缺失时回退 release.md 全文，再回退默认文案
CHANGELOG_ESCAPED="\"$VERSION 更新\""
if [ -f changelog.txt ]; then
  CHANGELOG_ESCAPED=$(cat changelog.txt | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$VERSION 更新\"")
elif [ -f release.md ]; then
  CHANGELOG_ESCAPED=$(cat release.md | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$VERSION 更新\"")
fi

cat << EOF > "$VERSION_JSON_TMP"
{
  "channel": "$CHANNEL",
  "version_name": "$VERSION",
  "version_code": $BUILD_ID,
  "build_id": $BUILD_ID,
  "file_name": "$FILE_NAME",
  "download_url": "$DOWNLOAD_URL",
  "changelog": $CHANGELOG_ESCAPED,
  "updated_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF

run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$TARGET_DIR/version.json"
run_scp "$VERSION_JSON_TMP" "$SERVER_USER@$SERVER_HOST:$VERSION_DIR/version.json"
rm -f "$VERSION_JSON_TMP"

# 3. 维护项目根目录的版本选择美化卡片 README.md，供 OpenList 自动渲染
echo "== [OpenList] 维护 Analysis-Tool-For-ColorOS 根目录版本选择卡片 README.md =="
run_ssh "mkdir -p '$BASE_STORAGE/alpha' '$BASE_STORAGE/beta' '$BASE_STORAGE/stable'"
INDEX_README_TMP="$RUNNER_TEMP/hyperos_index_readme.md"
cat << 'EOF' > "$INDEX_README_TMP"
<div style="max-width: 780px; margin: 0 auto; padding: 4px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
<div style="text-align: center; margin: 16px 0 20px 0;">
<div style="font-size: 22px; font-weight: 700; margin-bottom: 6px;">🔧 Analysis Tool For ColorOS 下载中心</div>
<div style="font-size: 13px; opacity: 0.75;">根据使用需求选择对应版本通道 · 各通道独立保留与更新</div>
</div>
<div style="display: flex; flex-direction: column; gap: 14px;">
<a href="/Analysis-Tool-For-ColorOS/stable/" style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; border: 1px solid rgba(125,125,125,0.22); background: rgba(125,125,125,0.05); text-decoration: none; color: inherit; box-sizing: border-box;">
<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;">
<div style="display: flex; align-items: center; gap: 8px;">
<span style="font-size: 16px; font-weight: 600;">📁 正式版 (Stable)</span>
<span style="font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(34,197,94,0.18); color: #16a34a; font-weight: 600;">推荐日常</span>
</div>
<div style="font-size: 13px; opacity: 0.75; line-height: 1.4;">经过充分验证的稳定版本，功能完善且经过多轮测试 · 保留最新 3 版</div>
</div>
<div style="font-size: 13px; font-weight: 600; color: #16a34a; white-space: nowrap; margin-left: 16px; flex-shrink: 0;">进入通道 →</div>
</a>
<a href="/Analysis-Tool-For-ColorOS/beta/" style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; border: 1px solid rgba(125,125,125,0.22); background: rgba(125,125,125,0.05); text-decoration: none; color: inherit; box-sizing: border-box;">
<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;">
<div style="display: flex; align-items: center; gap: 8px;">
<span style="font-size: 16px; font-weight: 600;">📁 公测版 (Beta)</span>
<span style="font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(234,88,12,0.18); color: #ea580c; font-weight: 600;">先行尝鲜</span>
</div>
<div style="font-size: 13px; opacity: 0.75; line-height: 1.4;">包含已进入公测候选的新特性与界面交互，欢迎体验与反馈 · 保留最新 2 版</div>
</div>
<div style="font-size: 13px; font-weight: 600; color: #ea580c; white-space: nowrap; margin-left: 16px; flex-shrink: 0;">进入通道 →</div>
</a>
<a href="/Analysis-Tool-For-ColorOS/alpha/" style="display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 14px; border: 1px solid rgba(125,125,125,0.22); background: rgba(125,125,125,0.05); text-decoration: none; color: inherit; box-sizing: border-box;">
<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;">
<div style="display: flex; align-items: center; gap: 8px;">
<span style="font-size: 16px; font-weight: 600;">📁 内测版 (Alpha)</span>
<span style="font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(147,51,234,0.18); color: #9333ea; font-weight: 600;">每日构建</span>
</div>
<div style="font-size: 13px; opacity: 0.75; line-height: 1.4;">主分支自动化 CI 每次构建，提供全平台压缩包 · 仅保留最新 1 版</div>
</div>
<div style="font-size: 13px; font-weight: 600; color: #9333ea; white-space: nowrap; margin-left: 16px; flex-shrink: 0;">进入通道 →</div>
</a>
</div>
</div>
EOF

run_scp "$INDEX_README_TMP" "$SERVER_USER@$SERVER_HOST:$BASE_STORAGE/README.md"
rm -f "$INDEX_README_TMP"

# 4. 归档与清理旧版本：将同通道下的历史版本移入「以前的版本」，并按 1/2/3 策略保留
echo "== [OpenList] 归档旧版本至 以前的版本/ 并清理 (通道: $CHANNEL, 总保留数: $KEEP_VERSIONS) =="
ARCHIVE_SCRIPT=$(cat << 'EOF'
TARGET_DIR="$1"
CURRENT_VERSION="$2"
KEEP_VERSIONS="$3"
ARCHIVE_DIR="$TARGET_DIR/以前的版本"

# 清理同级目录下遗留的旧散落文件（若有）
rm -f "$TARGET_DIR"/Analysis-Tool-For-*.zip "$TARGET_DIR"/Analysis-Tool-For-*.txt 2>/dev/null || true

# 将当前通道根目录下非当前版本的版本号文件夹移入「以前的版本」
for dir in "$TARGET_DIR"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ "$name" != "$CURRENT_VERSION" ] && [ "$name" != "以前的版本" ]; then
    echo "归档旧版本目录: $name -> 以前的版本/$name"
    mkdir -p "$ARCHIVE_DIR"
    rm -rf "$ARCHIVE_DIR/$name"
    mv "$dir" "$ARCHIVE_DIR/"
  fi
done

# 计算「以前的版本」中允许保留的旧版本数量
MAX_ARCHIVED=$((KEEP_VERSIONS - 1))

if [ "$MAX_ARCHIVED" -le 0 ]; then
  # Alpha（仅保留最新 1 版）：无需归档旧版，清理「以前的版本」目录
  if [ -d "$ARCHIVE_DIR" ]; then
    echo "通道 $TARGET_DIR 仅保留最新 1 版，清理整个 以前的版本 目录"
    rm -rf "$ARCHIVE_DIR"
  fi
else
  # Beta（保留 2 版）、Stable（保留 3 版）：保留最新归档，超出部分清理
  if [ -d "$ARCHIVE_DIR" ]; then
    mapfile -t OLD_DIRS < <(ls -1td "$ARCHIVE_DIR"/*/ 2>/dev/null || true)
    COUNT="${#OLD_DIRS[@]}"
    echo "当前「以前的版本」中已有旧版本数: $COUNT，允许归档数: $MAX_ARCHIVED"
    if [ "$COUNT" -gt "$MAX_ARCHIVED" ]; then
      for ((i=MAX_ARCHIVED; i<COUNT; i++)); do
        echo "清理超出保留期限的旧版本: ${OLD_DIRS[i]}"
        rm -rf "${OLD_DIRS[i]}"
      done
    fi
  fi
fi
EOF
)
run_ssh "bash -s -- '$TARGET_DIR' '$VERSION' '$KEEP_VERSIONS'" <<< "$ARCHIVE_SCRIPT"

echo "== [OpenList] 同步、归档与清理全部完成 =="
```

---

---

## 27.9 撤回已发布版本：`rollback-openlist.yml`（完整 workflow）

已发布的 Beta/Stable 需要撤回时使用。**不能**手改服务器：OpenList 存储在另一台机器，
SSH 凭据只存在于 Actions secrets，因此回滚必须经由本 workflow 执行。

**改动本 workflow 后必须同步本节代码**（与 §27.8 / §28 同为「文档即唯一完整实现」）。

### 27.9.1 写法与参数

Actions → `rollback-openlist` → Run workflow：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `channel` | 是 | 要撤回的通道：`beta` / `stable` / `alpha` |
| `target_version` | 是 | 要恢复的目标版本目录名（如 `2.2.0-beta.1`）——直接指名，不再依赖仓库内快照 |
| `drop_version` | 否 | 要删除的版本目录名（如 `2.2.0-beta.2`）；留空则不删 |

> **回滚快照机制已移除**：仓库不再保存任何一次性 `version.json` / Release 日志副本。
> 恢复完全依赖 OpenList 归档（CI 原件含 zip）；归档与通道根都没有该版本时明确报错。

完整操作顺序：

```text
1. gh release delete <版本> --yes            # 撤 GitHub Release
2. git tag -d <版本> && git push origin :refs/tags/<版本>
3. Actions 跑 rollback-openlist（channel / target_version / drop_version）
4. 验收（见 27.9.3）
```

### 27.9.2 恢复顺序（关键，决定成败）

版本目录只有两个可能的来源，优先级从高到低：

1. **`<通道>/以前的版本/<版本>/` 存在 → 整目录 `mv` 回通道根。**
   归档里是 `upload-openlist.sh` 当初上传的 CI 原件，**含全部 zip**，优先级最高。
2. 通道根已有该版本目录且**含 `.zip`** → 跳过，不重建。
3. 两者皆无 → 报错终止（**没有快照可兜底**，仓库不再保存 `version.json` 副本）。

通道级的 `<通道>/version.json` 与 `<通道>/README.md` **一律从恢复后的版本目录 `cp`**，
保证指针与原件逐字一致，也保证 `download_url` 指向的安装包真实存在。

删除 `drop_version` 时，通道根与「以前的版本」**两处一并删**，避免留下重复目录。

> **踩过的坑**：第一版实现用 `mkdir -p` 新建通道根的版本目录、只灌入快照的 md/json。
> 而目标版本早在发布时就被归档进「以前的版本/」，于是通道根多出一个**没有产物的空壳**，
> `download_url` 404（下载会失败），同时归档里还留着一份原件——同一版本双份。
> 现按上述顺序恢复，本地四场景 dry-run 全通过。

### 27.9.3 验收清单

```bash
# 1) 通道根只有一个版本目录，且「以前的版本」里没有同名残留
curl -s -H 'Content-Type: application/json' \
     -d '{"path":"/Analysis-Tool-For-ColorOS/<通道>"}' https://storage.horatio.cn/api/fs/list

# 2) 通道指针指向目标版本（取 raw_url 后核对 version_name / build_id 是否为 CI 原件）
curl -s -H 'Content-Type: application/json' \
     -d '{"path":"/Analysis-Tool-For-ColorOS/<通道>/version.json"}' https://storage.horatio.cn/api/fs/get

# 3) download_url 的 zip 能取到，前 4 字节是 50 4B 03 04（PK..）
```

同时确认 GitHub Release 与 Git Tag 已删除、撤回的 `version_name` 不被下一次发布复用
（Build ID 单调递增，撤回不释放已消耗的 ID；**下一个 Beta 请用新序号**，如撤回 `beta.2`
后下次发 `beta.3`）。

### 27.9.4 完整 workflow

```yaml
name: rollback-openlist

# 撤回已发布的版本：把 OpenList 某通道的指针（version.json / README.md）回滚到指定版本，
# 并删除被撤回的版本目录。OpenList 存储在另一台机器、SSH 凭据只存在于 Actions secrets，
# 因此回滚只能经由本 workflow 执行。
#
# 版本目录的恢复顺序（关键，避免撤回后下载 404）：
#   1. 「以前的版本/<SNAP>」存在 → 整目录 mv 回通道根（CI 原件含产物，优先级最高）。
#   2. 通道根已有该版本且含产物 → 跳过，不重建。
#   3. 两者皆无 → 无法恢复，明确报错。
#   4. 通道级 version.json / README.md **始终从恢复后的版本目录拷贝**，
#      保证指针与原件逐字一致、download_url 指向的产物真实存在。
#   5. 删除被撤回版本时，通道根与「以前的版本」两处一并删，避免残留重复目录。
#
# 用法：workflow_dispatch
#   target_version 要恢复的目标版本目录名（如 2.1.0，必填）
#   channel        通道（beta / stable / alpha）
#   drop_version   要删除的版本目录名；留空则不删

on:
  workflow_dispatch:
    inputs:
      channel:
        description: '通道'
        required: true
        default: 'beta'
      target_version:
        description: '要恢复的目标版本目录名（如 2.1.0）'
        required: true
      drop_version:
        description: '要删除的版本目录名（留空不删）'
        required: false
        default: ''

permissions:
  contents: read

concurrency:
  group: rollback-${{ github.ref }}

jobs:
  rollback:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v7

      - name: 推送到 OpenList
        env:
          SERVER_HOST: ${{ secrets.SERVER_HOST }}
          SERVER_USER: ${{ secrets.SERVER_USER }}
          SERVER_SSH_KEY: ${{ secrets.SERVER_SSH_KEY }}
          SSH_PORT: ${{ vars.SSH_PORT || '22' }}
          # 路径收敛进 secret，不留在源码里；缺失时下方校验直接失败。
          OPENLIST_STORAGE_DIR: ${{ secrets.SERVER_OPENLIST_DIR }}
          CHANNEL: ${{ inputs.channel }}
          TARGET_VERSION: ${{ inputs.target_version }}
          DROP_VERSION: ${{ inputs.drop_version }}
        run: |
          set -euo pipefail
          : "${OPENLIST_STORAGE_DIR:?OPENLIST_STORAGE_DIR is required}"
          BASE_STORAGE="$OPENLIST_STORAGE_DIR/Analysis-Tool-For-ColorOS"
          TARGET_DIR="$BASE_STORAGE/$CHANNEL"
          ARCHIVE_DIR="$TARGET_DIR/以前的版本"
          KEY="$RUNNER_TEMP/openlist_key"
          install -m 600 /dev/null "$KEY"
          printf '%s\n' "$SERVER_SSH_KEY" > "$KEY"
          trap 'rm -f "$KEY"' EXIT
          SSH_OPTS=(-i "$KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes)
          run_ssh() { ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_HOST" "bash -c $(printf '%q' "$1")"; }
          run_scp() { scp -i "$KEY" -P "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "$@"; }

          SNAP_VERSION="$TARGET_VERSION"
          [ -n "$SNAP_VERSION" ] || { echo "::error::缺少 target_version"; exit 1; }

          echo "== [Rollback] 目标版本: $SNAP_VERSION / 通道: $CHANNEL =="

          # 1) 恢复版本目录：归档原件优先（含产物）
          cat <<'EOS' > "$RUNNER_TEMP/restore.sh"
          set -euo pipefail
          TARGET_DIR="$1"; ARCHIVE_DIR="$2"; SNAP="$3"
          SNAPDIR="$TARGET_DIR/$SNAP"
          ARCHIVED="$ARCHIVE_DIR/$SNAP"
          if [ -d "$ARCHIVED" ]; then
            echo "[restore] 从归档恢复: 以前的版本/$SNAP -> $SNAP"
            rm -rf "$SNAPDIR"
            mv "$ARCHIVED" "$SNAPDIR"
          elif [ -f "$SNAPDIR/version.json" ] && [ -n "$(ls -A "$SNAPDIR"/*.zip 2>/dev/null)" ]; then
            echo "[restore] 通道根已有完整版本目录，跳过"
          else
            echo "::error::归档与通道根都没有 $SNAP，无法回滚"; exit 1
          fi
          # 2) 通道指针一律以恢复后的版本目录为准（原件优先）
          test -f "$SNAPDIR/version.json" || { echo "::error::恢复后的版本目录缺 version.json"; exit 1; }
          test -f "$SNAPDIR/README.md"   || { echo "::error::恢复后的版本目录缺 README.md"; exit 1; }
          cp "$SNAPDIR/version.json" "$TARGET_DIR/version.json"
          cp "$SNAPDIR/README.md"   "$TARGET_DIR/README.md"
          # 3) 清理归档里可能残留的同名目录，杜绝同一版本双份
          rm -rf "$ARCHIVED"
          echo "[restore] 完成"
          EOS
          run_ssh "bash -s -- '$TARGET_DIR' '$ARCHIVE_DIR' '$SNAP_VERSION'" < "$RUNNER_TEMP/restore.sh"

          # 4) 删除被撤回版本：通道根与归档两处一起
          if [ -n "$DROP_VERSION" ] && [ "$DROP_VERSION" != "$SNAP_VERSION" ]; then
            echo "== [Rollback] 删除版本目录: $DROP_VERSION（通道根 + 归档） =="
            run_ssh "rm -rf '$TARGET_DIR/$DROP_VERSION' '$ARCHIVE_DIR/$DROP_VERSION'"
          fi
          echo "== [Rollback] 完成 =="
```
---

# 28. 完整 Workflow 示例（build.yml 全文）

触发、版本计算、日志区间与生成、测试构建、OpenList 分发、GitHub Release 的**唯一完整实现**。
移植到其他项目时按 §29 的清单替换常量即可。

```yaml
name: build

# 路径过滤只对分支 push 生效，**不评估 tag push**（GitHub 官方：Path filters are not
# evaluated for pushes of tags），所以 Beta/Stable Tag 一定触发，强制规则 18/20 不受影响。
# 混合 push 只要有一个文件不在忽略列表内就照常触发；diff 生成超限/超 1000 commit 时也会强制跑。
on:
  push:
    branches: [main]
    tags: ['*']
    paths-ignore:
      # 纯文档：不产出任何字节差异，白跑一次全量测试+打包只占 runner。
      # 这些 commit 会留在「上次成功构建..HEAD」区间里，但 release-log.sh
      # 本来就过滤 docs|chore|ci|test|style|build 类型，日志不受影响——
      # 因此文档类改动请一律用 `docs:` 前缀提交，否则会被写进更新日志。
      - 'docs/**'
      - '*.md'
      - '**/*.md'
      # workflow 自身/CI 配置改动不影响构建产物（Dependabot 升级 actions 等不触发）
      - '.github/**'
  workflow_dispatch:

permissions:
  contents: write
  actions: read   # alpha 日志区间需查询本工作流历史成功 run（§10.1）

concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0

      # 统一计算 Channel / Version Name / Build ID（Version Code = Build ID），
      # 直接写入 GITHUB_ENV 供本 job 全部后续步骤使用（无需独立 job，省一次全历史 clone）
      - name: Determine channel and version
        run: |
          set -euo pipefail
          BUILD_ID=${{ github.run_number }}
          if [[ "$GITHUB_REF" == refs/tags/* ]]; then
            TAG=${GITHUB_REF#refs/tags/}
            if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-beta\.[0-9]+)?$ ]]; then
              echo "非法 tag: $TAG，只允许 x.y.z 或 x.y.z-beta.N（禁止 v 前缀等额外前后缀）"
              exit 1
            fi
            if [[ "$TAG" == *-beta.* ]]; then CHANNEL=beta; else CHANNEL=stable; fi
            VERSION="$TAG"
          else
            CHANNEL=alpha
            BASE=$(tr -d '[:space:]' < VERSION)
            if [[ ! "$BASE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
              echo "VERSION 文件格式错误: '$BASE'，应为 MAJOR.MINOR.PATCH"
              exit 1
            fi
            VERSION="$BASE-alpha.$BUILD_ID"
          fi
          {
            echo "CHANNEL=$CHANNEL"
            echo "VERSION=$VERSION"
            echo "BUILD_ID=$BUILD_ID"
            echo "VERSION_CODE=$BUILD_ID"
          } >> "$GITHUB_ENV"
          echo "Channel: $CHANNEL / Version Name: $VERSION / Build ID = Version Code: $BUILD_ID"

      # 日志范围按 channel 分段（§10.1/§12.1/§15.1）：
      #   alpha  → 上一次成功构建的 commit .. 当前（alpha 不打 tag，经 Actions API 取上个成功 run）
      #   beta   → 上一个 Beta Tag .. 当前 Tag（无更早 Beta 则回退最近任意 Tag）
      #   stable → 上一个 Stable Tag .. 当前 Tag（同上回退）
      # 生成双文件（模板与示例见 §26）：
      #   release.md   → OpenList README / GitHub Release notes（Markdown）
      #   changelog.txt → version.json（纯文本无版本头）
      - name: Generate release log
        env:
          GH_TOKEN: ${{ github.token }}
          OPENLIST_BASE_URL: https://storage.horatio.cn/Analysis-Tool-For-ColorOS
        run: |
          set -euo pipefail
          if [ "$CHANNEL" = "alpha" ]; then
            PREV=$(gh api "repos/${GITHUB_REPOSITORY}/actions/workflows/build.yml/runs?branch=${GITHUB_REF_NAME}&status=success&per_page=20" \
              --jq ".workflow_runs | map(select(.id != ${GITHUB_RUN_ID} and .head_sha != \"${GITHUB_SHA}\")) | .[0].head_sha // empty" || true)
          else
            if [ "$CHANNEL" = "beta" ]; then
              PATTERN='^[0-9]+\.[0-9]+\.[0-9]+-beta\.[0-9]+$'
            else
              PATTERN='^[0-9]+\.[0-9]+\.[0-9]+$'
            fi
            PREV=$(git tag --sort=-creatordate --merged HEAD | grep -Fxv "$VERSION" | grep -E "$PATTERN" | head -n 1 || true)
            if [ -z "$PREV" ]; then
              PREV=$(git tag --sort=-creatordate --merged HEAD | grep -Fxv "$VERSION" | head -n 1 || true)
            fi
          fi
          if [ -n "$PREV" ]; then RANGE="$PREV..HEAD"; else RANGE="HEAD"; fi
          bash ci/release-log.sh "$RANGE"
          echo "===== release.md ====="
          cat release.md
          echo "===== changelog.txt ====="
          cat changelog.txt

      - name: Checkout code into separate directory
        uses: actions/checkout@v7
        with:
          path: 'repo'

      - name: Process
        run: |
          mkdir -p ./output
          mkdir -p "./Analysis-Tool-For-ColorOS-Windows-x86_64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-Linux-arm64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-Linux-x86_64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-Darwin-arm64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-Darwin-x86_64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-Android-arm64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-Android-x86_64/tools"
          mkdir -p "./Analysis-Tool-For-ColorOS-WSL-x86_64/tools"

          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Windows-x86_64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Linux-arm64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Linux-x86_64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Darwin-arm64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Darwin-x86_64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Android-arm64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-Android-x86_64/"
          cp -r ./repo/* "./Analysis-Tool-For-ColorOS-WSL-x86_64/"

      - name: Download dependencies-Linux-x86_64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_linux_amd64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Linux_x86_64*.zip"

      - name: Move dependencies-Linux-x86_64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-Linux-x86_64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Linux-x86_64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Linux-x86_64.zip" "./Analysis-Tool-For-ColorOS-Linux-x86_64/*"
          mv Analysis-Tool-For-ColorOS-Linux-x86_64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Linux-x86_64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download dependencies-Linux-arm64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_linux_arm64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Linux_aarch64*.zip"

      - name: Move dependencies-Linux-arm64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-Linux-arm64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Linux-arm64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Linux-arm64.zip" "./Analysis-Tool-For-ColorOS-Linux-arm64/*"
          mv Analysis-Tool-For-ColorOS-Linux-arm64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Linux-arm64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download dependencies-Windows-x86_64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_windows_amd64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Cygwin_x86_64*.zip"

      - name: Move dependencies-Windows-x86_64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "cygwin1.dll" -d "./Analysis-Tool-For-ColorOS-Windows-x86_64/tools"
                unzip -j "$file" "extract.erofs.exe" -d "./Analysis-Tool-For-ColorOS-Windows-x86_64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Windows-x86_64/tools" -f "$file" "payload-dumper-go.exe"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Windows-x86_64.zip" "./Analysis-Tool-For-ColorOS-Windows-x86_64/*"
          mv Analysis-Tool-For-ColorOS-Windows-x86_64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Windows-x86_64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download payload-dumper-go-Darwin-x86_64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_darwin_amd64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Darwin_x86_64*.zip"

      - name: Move dependencies-Darwin-x86_64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-Darwin-x86_64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Darwin-x86_64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Darwin-x86_64.zip" "./Analysis-Tool-For-ColorOS-Darwin-x86_64/*"
          mv Analysis-Tool-For-ColorOS-Darwin-x86_64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Darwin-x86_64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download payload-dumper-go-Darwin-arm64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_darwin_arm64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Darwin_aarch64*.zip"

      - name: Move dependencies-Darwin-arm64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-Darwin-arm64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Darwin-arm64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Darwin-arm64.zip" "./Analysis-Tool-For-ColorOS-Darwin-arm64/*"
          mv Analysis-Tool-For-ColorOS-Darwin-arm64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Darwin-arm64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download payload-dumper-go-Android-arm64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_linux_arm64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Android_arm64*.zip"

      - name: Move dependencies-Android-arm64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-Android-arm64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Android-arm64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Android-arm64.zip" "./Analysis-Tool-For-ColorOS-Android-arm64/*"
          mv Analysis-Tool-For-ColorOS-Android-arm64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Android-arm64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download payload-dumper-go-Android-x86_64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_linux_amd64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*Android_x86_64*.zip"

      - name: Move dependencies-Android-x86_64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-Android-x86_64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-Android-x86_64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-Android-x86_64.zip" "./Analysis-Tool-For-ColorOS-Android-x86_64/*"
          mv Analysis-Tool-For-ColorOS-Android-x86_64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-Android-x86_64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      - name: Download payload-dumper-go-WSL-x86_64
        uses: robinraju/release-downloader@v1.13
        with:
          repository: "ssut/payload-dumper-go"
          latest: true
          fileName: "payload-dumper-go_*_linux_amd64.tar.gz"
      - uses: robinraju/release-downloader@v1.13
        with:
          repository: "sekaiacg/erofs-utils"
          latest: true
          fileName: "erofs-utils-*WSL_x86_64*.zip"

      - name: Move dependencies-WSL-x86_64
        run: |
          for file in *; do
            case "$file" in
              *.zip)
                unzip -j "$file" "extract.erofs" -d "./Analysis-Tool-For-ColorOS-WSL-x86_64/tools"
                ;;
              *.tar.gz)
                tar -xzv -C "./Analysis-Tool-For-ColorOS-WSL-x86_64/tools" -f "$file" "payload-dumper-go"
                ;;
            esac
          done

          7z a "./Analysis-Tool-For-ColorOS-WSL-x86_64.zip" "./Analysis-Tool-For-ColorOS-WSL-x86_64/*"
          mv Analysis-Tool-For-ColorOS-WSL-x86_64.zip "output/Analysis-Tool-For-ColorOS-${{ env.VERSION }}-${{ env.BUILD_ID }}-WSL-x86_64.zip"
          rm -f ./*.zip
          rm -f ./*.tar.gz

      # 上传至 OpenList 存储目录并按通道执行旧版本清理策略（脚本全文见 §27.8）
      - name: Deploy to OpenList
        env:
          SERVER_HOST: ${{ secrets.SERVER_HOST }}
          SERVER_USER: ${{ secrets.SERVER_USER }}
          SERVER_SSH_KEY: ${{ secrets.SERVER_SSH_KEY }}
          SSH_PORT: ${{ vars.SSH_PORT || '22' }}
          OPENLIST_STORAGE_DIR: ${{ secrets.SERVER_OPENLIST_DIR }}
          ARTIFACT_DIR: output
        run: bash ci/upload-openlist.sh

      # Beta/Stable：Tag 触发时附带发布 GitHub Release（notes = release.md，Markdown）
      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail
          ARGS=(create "$VERSION" --title "$VERSION" --notes-file release.md)
          if [ "$CHANNEL" = "beta" ]; then ARGS+=(--prerelease); fi
          mapfile -t FILES < <(ls output/Analysis-Tool-For-ColorOS-"$VERSION"-"$BUILD_ID"-*.zip)
          gh release "${ARGS[@]}" "${FILES[@]}"
```

---

# 29. 移植清单（在其他项目复刻本规范）

本文件已内嵌全部脚本与 workflow；新项目按下面清单替换常量后即可得到**行为完全一致**的
Release Log 与 OpenList 分发流程。行为规范（三通道、1/2/3 保留、双文件日志、
日志区间规则）**不要改**，只改与项目身份相关的值。

| 替换点                        | 示例值（本文档）                                          | 出现位置 |
| ----------------------------- | --------------------------------------------------------- | -------- |
| 产品/目录名                   | `Analysis-Tool-For-ColorOS`                               | §27.8 上传脚本（zip 前缀、存储目录、下载中心 HTML）、§28（产物名、OPENLIST_BASE_URL） |
| 日志标题中的产品名            | `Analysis Tool For ColorOS`                               | `ci/release-log.sh` 的 `PRODUCT_NAME`（§26.4） |
| 分发域名                      | `https://storage.horatio.cn`                              | §27.8 `DOWNLOAD_URL`、§28 `OPENLIST_BASE_URL` |
| OpenList 服务器存储根目录     | `/www/project/OpenList/storage`（secret `SERVER_OPENLIST_DIR`，脚本内拼 `/Analysis-Tool-For-ColorOS`） | §27.8 `BASE_STORAGE`、§28 `OPENLIST_STORAGE_DIR` |
| 通道中文名                    | 内测版 / 公测版 / 正式版                                  | §26.4 `case "$CHANNEL"` |
| 产物 Platform / arch 白名单   | `Windows` `Linux` `Darwin` `Android` `WSL` × `x86_64` `arm64` | §25.2、§25.3、§28 `Move dependencies-*` |
| 工具链依赖                    | `ssut/payload-dumper-go`、`sekaiacg/erofs-utils`          | §28 `Download dependencies-*`（外部仓库，改名会 404） |
| 构建产物源路径                | `output/Analysis-Tool-For-ColorOS-<version>-*.zip`        | §28 `Move dependencies-*`、§27.8 `ARTIFACT_DIR` |
| **workflow 文件名**           | `build.yml`                                               | §28 `Generate release log` 里 Actions API 路径 `actions/workflows/build.yml/runs`（改名必须同步，否则 alpha 区间取不到） |
| 下载中心首页卡片 HTML 文案    | ColorOS 分析工具下载中心三通道卡片                        | §27.8 内嵌 `INDEX_README_TMP` |
| GitHub Secrets / Vars 名称    | `SERVER_HOST` `SERVER_USER` `SERVER_SSH_KEY` `SERVER_OPENLIST_DIR`（org 级）、可选 `SSH_PORT` | §27.8、§28（名称可保持，值在仓库/org 配置） |
| 保留策略数量                  | alpha 1 / beta 2 / stable 3                               | §27.5、§27.8 `KEEP_VERSIONS` |
| `VERSION` 文件                | `2.2.0` 格式的 MAJOR.MINOR.PATCH                          | §28 `Determine` 步骤 |

**必须保持不变的行为**（改了就不是本规范）：

1. 三通道与 `alpha → beta → stable` 生命周期；`Build ID = Version Code = github.run_number`；
2. 日志区间规则（§10.1/§12.1/§15.1）与双文件输出（§26.1）；
3. `docs/chore/ci/test/style/build` 不入日志、同消息去重（§26.4）；
4. 上传顺序：产物 zip → README（release.md）→ version.json（changelog 用 changelog.txt）→ 首页卡片 → 归档清理；
5. tag 构建顺序：Deploy（清理）→ Create Release。

---

# 30. Commit 规范

> 本规范在 `docs/COMMITTING.md` 与 `docs/VERSIONING.md` §30 各存一份**完全相同的副本**：修改任一处必须同步另一处。
> 基于 [约定式提交（Conventional Commits）1.0.0](https://www.conventionalcommits.org/zh-hans/v1.0.0/)，
> 追加本项目约定：**描述一律中文**、**feat/fix 必须面向用户写**。
> Release Log 由 Commit 历史自动生成（VERSIONING §26），写错类型 = 日志分错组或被过滤。

---

## 1. 格式

```text
<type>[可选 scope]: <中文描述>

[可选 正文]

[可选 脚注]
```

规则（前 5 条为约定式提交 1.0.0 原文要求，后 2 条为本项目追加）：

1. 每个提交**必须**以类型字段开头，其后是**可选**的范围字段、**可选**的 `!`，以及
   **必须**的英文半角冒号 + 空格；
2. `type` 使用英文小写（`feat`、`fix`、`docs`……见 §2 全表）；
3. `scope` 可选，圆括号包裹，使用英文短词（如 `fix(weight):`、`feat(water)`）；
4. 描述**必须**是提交的简短总结，紧跟在冒号空格之后；
5. 破坏性变更**必须**标记：类型后加 `!`（`feat!: …`）或脚注 `BREAKING CHANGE: <说明>`；
6. **描述必须使用中文**，一句话，不以句号结尾的长段；
7. **`feat` / `fix` 的描述必须面向最终用户**：写「用户能感知到什么变化」，
   不写实现手段、文件名、内部流程（详见 §4）。

正文（body）在描述后空行分隔，可多段；脚注（footer）在正文后空行分隔，
采用 `token: value` 形式（`Refs: #123`、`BREAKING CHANGE: …`）。
CI 的 Release Log **只读首行**，正文与脚注不会进入日志。

---

## 2. 类型全表与日志分组映射

| Type | 含义（约定式提交 / Angular 约定） | 入日志 | 非 Stable 分组 | Stable 分组 |
| ---- | ---------------------------------- | ------ | -------------- | ----------- |
| `feat` | 新增功能 | ✅ | 新增 | 新增 |
| `fix` | 修复缺陷 | ✅ | 修复 | 修复 |
| `perf` | 性能优化 | ✅ | 变更 | 优化 |
| `refactor` | 重构（不改外部行为） | ✅ | 变更 | 优化 |
| `revert` | 回滚提交 | ✅ | 变更 | 优化 |
| 其他自定义类型 / 无类型裸文本 | — | ✅ | 其他 | 优化 |
| `docs` | 仅文档 | ❌ | — | — |
| `style` | 格式、空白、分号等样式 | ❌ | — | — |
| `test` | 测试用例增删改 | ❌ | — | — |
| `ci` | CI / 工作流配置 | ❌ | — | — |
| `build` | 构建系统、依赖升级 | ❌ | — | — |
| `chore` | 杂务（不改业务代码） | ❌ | — | — |

「不入日志」= 对最终用户没有可讲述的信息，会被 `ci/release-log.sh` 直接过滤；
完整实现见 VERSIONING §26.4。

---

## 3. scope 惯例（本项目常用）

范围用英文小写短词，指代变更所属的功能面：

| Scope | 对应模块 |
| ----- | -------- |
| `analysis` | ROM 分析主流程（下载、解包、取镜像） |
| `rename` / `update` | APK 重命名与版本号更新 |
| `device` | 设备库（phone / pad / fold / flip） |
| `db` | `app_name.json` / `app_version.json` 数据库 |
| `exclude` | 排除名单与产物筛选 |
| `action` | Analysis / Build workflow |
| `ci` / `docs` / `release-log` | 流程、文档、发布脚本（注意：`ci`/`docs` 类型本身不入日志） |

不确定就不写 scope——scope 是可选的，宁缺毋滥。

---

## 4. 描述写作要求（中文 + 面向用户）

面向用户的 Release Log 最佳实践（release-notes.dev / releaseglow / changelog 写作指南 2025–2026 共识）：

1. **为读者写，不为开发者写**：release notes 是给用户的，不是 git log 的复读；
2. **收益优先（benefit-first）**：先说用户得到什么，而不是改了哪个类；
3. **按分组组织**：本规范由 §2 的类型自动分组，写好 type 即可；
4. **避免内部术语**：文件名、类名、重构、管线、CI 这类词不该出现在用户可见的条目里。

因此 `feat` / `fix`（会进入用户可见分组）的描述按下面方式写：

```text
✅ feat: 新增小米 Pad 7 系列机型数据           ← 用户能感知的能力
✅ fix: 跳过分包 APK 避免生成重复文件            ← 用户遇到的现象
✅ feat(device): Flip 机型支持折叠态识别         ← 收益导向
❌ feat: 重构重命名模块为懒加载                  ← 实现细节，用户无感
❌ fix: 修复 main.py 空指针                     ← 内部术语
❌ ci: 日志分组中文化                           ← 应为 docs/ci 类型（不入日志），
                                                 若确属用户可见功能则用 feat 重述
```

`docs` / `ci` / `chore` 等本身不入日志，可以随便写实现细节；
一旦你判断「这个变化值得让用户知道」，就说明它应该用 `feat` / `fix` 并按上面的方式描述。

---

## 5. 正反示例

```text
✅ feat: 新增 Xiaomi 17 系列设备数据
✅ feat(device): 支持 Fold 机型内屏包识别
✅ fix: 修复版本号缺失时文件名出现 None
✅ perf: 批量重命名提速
✅ docs: 补充 OpenList 发布说明
✅ refactor: 重命名流程拆成独立模块             ← refactor 不入日志，可写实现
✅ feat!: 不再产出未签名的更新包

BREAKING CHANGE: 旧版 .apks 需用新流程重新打包

❌ Fix: 修复一个 bug            ← type 必须小写
❌ 修复了闪退                    ← 缺少类型前缀
❌ feat: fix the crash           ← 描述未使用中文
❌ feat：新增机型                ← 冒号必须是英文半角
❌ feat: 改了几个文件            ← 无信息量
```

---

## 6. 与 Release Log、版本号的关系

- **日志**：`ci/release-log.sh` 只取首行 subject，按 §2 映射分组；
  区间内没有任何入日志的提交时，输出兜底条目「修复 - 修复了一些已知问题」
  （见 VERSIONING §26.4）。
- **版本号不由 Commit 推导**：`x.y.z` 由 `VERSION` 文件与 Git Tag 决定，
  `x.y.z-alpha.BUILD_ID` 的后缀恒等于全局 Build ID（见 VERSIONING §3、§5）。
  `feat`→MINOR、`fix`→PATCH 的语义只作团队沟通参考，不驱动自动化版本。

---

## 7. 常用命令

```bash
# 单行提交
git commit -m "feat(device): 新增 Xiaomi Pad 7 Ultra 机型"

# 带 scope 与正文
git commit -m "fix(rename): 跳过分包 APK 避免生成重复文件

android:split 标记的分包与主包同名，旧逻辑会覆盖已重命名的产物；
改名前先按 split 过滤，并保留原始包名便于回溯。"

# 破坏性变更
git commit -m "feat!: 弃用旧版 JSON 备份格式

BREAKING CHANGE: 1.0 之前的备份文件需重新导出后再导入"
```

提交前自查三问：

1. type 对吗？（用户可见 → `feat`/`fix`；纯内部 → `docs`/`ci`/`chore`…）
2. 描述是中文、并且是**用户能读懂**的话吗？
3. 一个提交只讲一件事吗？
