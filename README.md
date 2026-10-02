# Analysis Tool For ColorOS

用于提取、修改和重命名 ColorOS 中的 APK 文件的 Python 脚本。它可以帮助开发者和用户轻松地获取 APK 文件及比对更新，并根据需要对其进行定制。

## 功能

- 从 ROM 下载链接下载 ROM
- 从 ZIP 文件中提取 payload.bin
- 从 payload.bin 文件中提取指定镜像文件
- 提取镜像
- 删除指定的 APK
- 重命名 APK 文件
- 更新 APK 版本
- 更新 APK 文件名
- 删除多余文件
- 获取包信息

## ⬇️ 下载

三通道托管在自建 OpenList，各通道独立保留最新版本：

| 通道 | 适合谁 | 下载 |
| --- | --- | --- |
| 📁 **内测版 Alpha** | 想第一时间尝鲜（每次 push 自动构建） | [alpha/](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/alpha/) |
| 📁 公测版 Beta | 想体验候选功能、帮忙挑毛病 | [beta/](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/beta/) · [GitHub Releases](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS/releases) |
| 📁 **正式版 Stable** | 日常使用，稳定优先（推荐） | [stable/](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/stable/) · [GitHub Releases](https://github.com/WXies-Team/Analysis-Tool-For-ColorOS/releases) |

- 每个版本目录都附有这次更新了什么（CI 自动生成的更新说明）
- 压缩包内已自带 `tools/` 依赖（payload-dumper-go、extract.erofs），解压即用
- 下载中心首页：[storage.horatio.cn/Analysis-Tool-For-ColorOS](https://storage.horatio.cn/Analysis-Tool-For-ColorOS/)

## 如何使用

1. 在上面的表格里挑一个通道，下载对应平台的 zip；
   
2. 确保已安装 Python 3.x, aria2c, 7zip 并安装依赖库：

   ```
   pip install -r requirements.txt
   ```

3. 运行脚本：

   ```
   python main.py [-h] [-d URL] [-p] [-i] [-f] [-a] [-n] [-u] [-m] [-c] [-O]
   ```

按照提示选择相应的操作。

```bash
    -h, --help            显示此帮助消息并退出
    -d URL, --download URL
                          从指定 URL 下载 ROM
    -p, --extract-payload
                          从 zip 文件中提取 payload.bin
    -i, --img             从 payload.bin 中提取指定镜像
    -f, --files           从镜像中提取文件
    -a, --apk             删除指定的 APK
    -n, --rename          重命名 APK 文件
    -u, --update-version  更新 APK 版本
    -m, --update-name     更新 APK 名称
    -c, --clean           删除不需要的文件和文件夹
    -o, --get-info        获取包信息
```
