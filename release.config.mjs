// Analysis-Tool 发版配置（semantic-release），Analysis-Tool-For-ColorOS 由 registry.yaml 的 products: 替换。
// 与客户端配置的差异：产物是 output/*.zip（8 平台工具包），打包由 ci/pack-all.sh 完成。
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
          { type: "feat", section: "✨ 新增", effect: "bump" },
          { type: "fix", section: "🐛 修复", effect: "bump" },
          { type: "perf", section: "⚡ 改进", effect: "bump" },
          { type: "revert", section: "🐛 修复", effect: "bump" },
          { type: "docs", effect: "hidden" },
          { type: "style", effect: "hidden" },
          { type: "chore", effect: "hidden" },
          { type: "ci", effect: "hidden" },
          { type: "build", effect: "hidden" },
          { type: "refactor", effect: "hidden" },
          { type: "test", effect: "hidden" },
        ],
        formatNoteTitle: (context, title) =>
          /^BREAKING(?:[ -]CHANGE)?$/i.test(title) ? "🚨 破坏性变更" : title.toUpperCase(),
      },
    }],
    ["@semantic-release/exec", {
      prepareCmd: "bash ci/prepare-release.sh ${nextRelease.version} '${nextRelease.gitTag}' 'Analysis-Tool-For-ColorOS' <<'SEMANTIC_RELEASE_NOTES'\n${nextRelease.notes}\nSEMANTIC_RELEASE_NOTES",
      publishCmd: "bash ci/publish-openlist.sh ${nextRelease.version} ${branch.name} 'Analysis-Tool-For-ColorOS'",
    }],
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md" }],
    ["@semantic-release/github", { assets: ["output/*.zip"] }],
  ],
};
