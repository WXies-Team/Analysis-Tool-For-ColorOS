# Analysis Tool For ColorOS

> 从 ColorOS ROM 提取、解包和重命名 APK，解压即用的跨平台工具

[![build](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS/actions/workflows/analysis.yml/badge.svg)](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS/actions/workflows/analysis.yml) [![release](https://img.shields.io/github/v/release/WXies-Team/Analysis-Tool-For-ColorOS)](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS/releases)

一个处理 ColorOS ROM 的命令行工具：把 ROM 里的镜像解包，取出并整理系统 APK——改包名、改版本号、改文件名，按需清理。

## 它能做什么

给它一个 ROM 下载链接或一个本地 ZIP，它会走完整条链路：下载 ROM → 取出 `payload.bin` → 解出指定镜像 → 提取文件 → 整理 APK（删除、重命名、更新版本与名称）→ 清理多余文件，最后还能打印包信息。

```bash
python main.py [-h] [-d URL] [-p] [-i] [-f] [-a] [-n] [-u] [-m] [-c] [-o]
```

```bash
    -h, --help            显示帮助并退出
    -d URL, --download URL
                          从指定 URL 下载 ROM
    -p, --extract-payload
                          从 zip 中提取 payload.bin
    -i, --img             从 payload.bin 中提取指定镜像
    -f, --files           从镜像中提取文件
    -a, --apk             删除指定的 APK
    -n, --rename          重命名 APK 文件
    -u, --update-version  更新 APK 版本
    -m, --update-name     更新 APK 名称
    -c, --clean           删除不需要的文件和文件夹
    -o, --get-info        获取包信息
```

按提示选择要执行的操作即可。

## 下载哪个版本

两通道托管在自建 OpenList，各通道独立保留历史版本：

| 版本 | 适合 | 下载 |
| --- | --- | --- |
| 📁 正式版 Stable | 日常使用，稳定优先（推荐） | [stable/](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/stable/) · [GitHub Releases](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS/releases) |
| 📁 测试版 Beta | 想先试新功能、帮忙挑毛病 | [beta/](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/beta/) |

- 每个版本目录都附有这次更新了什么（CI 自动生成的更新说明）
- 压缩包已自带 `tools/` 依赖（payload-dumper-go、extract.erofs），解压即用
- 下载中心首页：[https://storage.horatio.cn/Analysis-Tool-For-ColorOS](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/)

## 自己运行

需要 Python 3.x、aria2c、7zip，并安装依赖：

```bash
pip install -r requirements.txt
python main.py --help
```

姊妹项目：
- [Analysis Tool For ColorOS](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS)
- [Analysis Tool For HyperOS](https://github.com/WXies-Team/Analysis-Tool-For-HyperOS)
- [Analysis Tool For OriginOS](https://github.com/WXies-Team/Analysis-Tool-For-OriginOS)
