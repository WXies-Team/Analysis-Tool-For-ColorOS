#!/usr/bin/env bash
# Analysis-Tool 多平台工具包打包（数据驱动，替代原来 8 组近乎相同的 workflow 步骤）。
# 由 prepare-release-tool.sh 调用：$1=VERSION(四段 X.Y.Z.BUILD) $2=ColorApkExtractor
# 产物名 <PREFIX>-<VERSION>-<platform>.zip（VERSION 已含 BUILD，不再有独立 BUILD_ID 段）
#
# 每个平台: 下载 payload-dumper-go + erofs-tools，解压指定文件到 tools/，7z 打包到 output/。
# 下载用 gh CLI（runner 自带），等价于原 robinraju/release-downloader 的 latest/tag + fileName。
set -Eeuo pipefail
shopt -s inherit_errexit

VERSION=${1:?version required}
PREFIX=${2:?project prefix required}

mkdir -p output

# 平台表: 平台名|dumper 文件 glob|dumper 解压文件名|erofs 文件 glob|erofs tag(空=latest)|erofs 解压文件(空格分隔)
PLATFORMS=(
  "windows-x86_64|payload-dumper-go_*_windows_amd64.tar.gz|payload-dumper-go.exe|erofs-tools-*Cygwin_x86_64*.zip||cygwin1.dll extract.erofs.exe"
  "linux-x86_64|payload-dumper-go_*_linux_amd64.tar.gz|payload-dumper-go|erofs-tools-*Linux_x86_64*.zip||extract.erofs"
  "linux-arm64|payload-dumper-go_*_linux_arm64.tar.gz|payload-dumper-go|erofs-tools-*Linux_aarch64*.zip||extract.erofs"
  "darwin-x86_64|payload-dumper-go_*_darwin_amd64.tar.gz|payload-dumper-go|erofs-utils-*Darwin_x86_64*.zip|v1.8.10-251217|extract.erofs"
  "darwin-arm64|payload-dumper-go_*_darwin_arm64.tar.gz|payload-dumper-go|erofs-utils-*Darwin_aarch64*.zip|v1.8.10-251217|extract.erofs"
  "android-arm64|payload-dumper-go_*_linux_arm64.tar.gz|payload-dumper-go|erofs-tools-*Android_arm64*.zip||extract.erofs"
  "android-x86_64|payload-dumper-go_*_linux_amd64.tar.gz|payload-dumper-go|erofs-tools-*Android_x86_64*.zip||extract.erofs"
  "wsl-x86_64|payload-dumper-go_*_linux_amd64.tar.gz|payload-dumper-go|erofs-tools-*WSL_x86_64*.zip||extract.erofs"
)

pack_one() {
  local platform=$1 dumper_glob=$2 dumper_file=$3 erofs_glob=$4 erofs_tag=$5 erofs_files=$6
  local dir="$PREFIX-$platform"
  rm -rf "$dir"; mkdir -p "$dir/tools"
  cp -r ./repo/* "$dir/"

  local tmp; tmp=$(mktemp -d)
  (
    cd "$tmp"
    gh release download --repo ssut/payload-dumper-go --pattern "$dumper_glob" --clobber
    if [ -n "$erofs_tag" ]; then
      gh release download "$erofs_tag" --repo sekaiacg/erofs-tools --pattern "$erofs_glob" --clobber
    else
      gh release download --repo sekaiacg/erofs-tools --pattern "$erofs_glob" --clobber
    fi
    for f in *; do
      case "$f" in
        *.zip)     unzip -o -j "$f" $erofs_files -d "$OLDPWD/$dir/tools" ;;
        *.tar.gz)  tar -xzf "$f" -C "$OLDPWD/$dir/tools" "$dumper_file" ;;
      esac
    done
  )
  rm -rf "$tmp"

  ( cd "$dir" && 7z a -y "../$PREFIX-$platform.zip" ./* >/dev/null )
  mv "$PREFIX-$platform.zip" "output/$PREFIX-$VERSION-$platform.zip"
  echo "packed: output/$PREFIX-$VERSION-$platform.zip"
}

for spec in "${PLATFORMS[@]}"; do
  IFS='|' read -r platform dumper_glob dumper_file erofs_glob erofs_tag erofs_files <<<"$spec"
  pack_one "$platform" "$dumper_glob" "$dumper_file" "$erofs_glob" "$erofs_tag" "$erofs_files"
done

test -n "$(find output -name "$PREFIX-$VERSION-*.zip" -print -quit)" \
  || { echo "::error::no platform archives produced"; exit 1; }
