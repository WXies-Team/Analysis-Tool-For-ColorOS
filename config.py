import os  # 引入OS模块，用于操作文件和目录
import glob  # 引入glob模块，用于搜索文件夹中的文件

# 获取当前脚本文件所在目录的绝对路径
src_dir = os.path.abspath(__file__)

# 在当前脚本文件所在目录下创建一个名为"output_apk"的子目录
dst_dir = os.path.join(src_dir, "output_apk")

# 在当前目录下搜索所有以".zip"为后缀的文件，并返回它们的文件路径
zip_files = glob.glob("*.zip")

# 创建名为"output_apk"的目录（如果它不存在）
output_dir = 'output_apk'

update_apk_folder = "update_apk"

update_apk_name_folder = "update_name_apk"

if not os.path.exists(update_apk_folder):
    os.makedirs(update_apk_folder)

if not os.path.exists(update_apk_name_folder):
    os.makedirs(update_apk_name_folder)

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# 获取名为"output_apk"目录中所有以".apk"为后缀的文件列表
apk_files = [f for f in os.listdir(output_dir) if f.endswith('.apk')]

# 定义了两个字符串常量，分别用于指定排除 APK 的文件路径和 APK 版本号和名称的 JSON 文件路径
EXCLUDE_APK_PATH = 'exclude_apk.txt'
APK_VERSION = 'app_version.json'
APK_CODE = 'app_code.json'
APK_APP_NAME = 'app_name.json'
# 定义一个临时字典，用于存储版本名相同但版本号有所变更的 APK
APK_CODE_NAME = 'app_code_name.json'