// Analysis-Tool 发版配置（semantic-release），Analysis-Tool-For-ColorOS 由 registry.yaml 的 products: 替换。
// 与客户端配置的差异：产物是 output/*.zip（8 平台工具包），打包由 ci/pack-all.sh 完成。
// 去掉 Conventional Commits 的 scope 前缀（如 **ui:** / **ci:**），应用内日志只要纯描述。
// 基于 conventional-changelog-conventionalcommits@9.3.1 的 commitPartial，去掉 `{{#if scope}}` 块。
const noScopeCommitPartial = `* {{#if subject}}
  {{~subject}}
{{~else}}
  {{~header}}
{{~/if}}

{{~!-- commit link --}}{{~#if hash}} {{#if @root.linkReferences~}}
  ([{{shortHash}}]({{commitUrlFormat}}))
{{~else}}
  {{~shortHash}}
{{~/if}}{{~/if}}

{{~#if references~}}
  , closes
  {{~#each references}} {{#if @root.linkReferences~}}
    [{{#if this.owner}}{{~this.owner}}/{{~/if}}{{~this.repository}}{{this.prefix}}{{this.issue}}]({{issueUrlFormat}})
  {{~else}}
    {{~this.owner}}/{{~this.repository}}{{this.prefix}}{{this.issue}}
  {{~/if}}{{/each}}
{{~/if}}

`
export default {
  // 三通道齐全（semantic-release 原生支持 alpha/beta prerelease 分支）
  branches: ["main", { name: "beta", prerelease: true }, { name: "alpha", prerelease: true }],
  tagFormat: "${version}",
  plugins: [
    ["@semantic-release/commit-analyzer", { preset: "conventionalcommits" }],
    ["@semantic-release/release-notes-generator", {
      preset: "conventionalcommits",
      presetConfig: {
        types: [
          { type: "feat", section: "✨ 新增" },
          // scope 为 ci 的 fix 必须放在通用 fix 之前，否则通用条目先匹配导致隐藏失效
          { type: "fix", scope: "ci", hidden: true },
          { type: "fix", section: "🐛 修复" },
          { type: "perf", section: "⚡ 改进" },
          { type: "revert", section: "🐛 修复" },
          { type: "docs", hidden: true },
          { type: "style", hidden: true },
          { type: "chore", hidden: true },
          { type: "ci", hidden: true },
          { type: "build", hidden: true },
          { type: "refactor", hidden: true },
          { type: "test", hidden: true },
        ],
        formatNoteTitle: (context, title) =>
          /^BREAKING(?:[ -]CHANGE)?$/i.test(title) ? "🚨 破坏性变更" : title.toUpperCase(),
      },
      writerOpts: { commitPartial: noScopeCommitPartial },
    }],
    ["@semantic-release/exec", {
      prepareCmd: "bash ci/prepare-release.sh ${nextRelease.version} '${nextRelease.gitTag}' 'Analysis-Tool-For-ColorOS' <<'SEMANTIC_RELEASE_NOTES'\n${nextRelease.notes}\nSEMANTIC_RELEASE_NOTES",
      publishCmd: "bash ci/publish-openlist.sh ${nextRelease.version} ${branch.name} 'Analysis-Tool-For-ColorOS'",
    }],
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md" }],
    ["@semantic-release/github", { assets: ["output/*.zip"] }],
  ],
};
