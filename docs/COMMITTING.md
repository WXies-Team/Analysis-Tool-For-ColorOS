# Commit 规范

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
