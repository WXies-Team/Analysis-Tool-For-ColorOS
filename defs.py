from config import *  # 导入config.py中定义的全局变量
import shutil  # 导入shutil模块，用于复制、移动、删除文件和目录
import subprocess  # 导入subprocess模块，用于执行系统命令
import fnmatch  # 导入fnmatch模块，用于文件名匹配
import json  # 导入json模块，用于读写JSON格式的数据
from pyaxmlparser import APK  # 导入pyaxmlparser读取 apk 信息


def init_folder():
    """检查并创建所需的文件夹"""
    if not os.path.exists("output_apk"):
        os.mkdir("output_apk")

    if not os.path.exists("update_apk"):
        os.mkdir("update_apk")

    if not os.path.exists("update_name_apk"):
        os.mkdir("update_name_apk")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    if not os.path.exists(update_apk_folder):
        os.makedirs(update_apk_folder)

    if not os.path.exists(update_apk_name_folder):
        os.makedirs(update_apk_name_folder)


def init_json():
    """初始化排除APK列表和APK版本号字典"""
    exclude_apk = []
    apk_version = {}
    apk_code = {}
    apk_code_name = {}
    # 查询 APK 排除列表
    if os.path.exists(EXCLUDE_APK_PATH):
        with open(EXCLUDE_APK_PATH, 'r') as f:
            exclude_apk = [line.strip() for line in f.readlines()]
    # 查询本地字典版本名
    if os.path.exists(APK_VERSION):
        with open(APK_VERSION, 'r') as f:
            apk_version = json.load(f)
    else:
        apk_version = {}
    # 查询本地字典版本号
    if os.path.exists(APK_CODE):
        with open(APK_CODE, 'r') as f:
            apk_code = json.load(f)
    else:
        apk_code = {}
    return exclude_apk, apk_version, apk_code, apk_code_name


def download_rom(url):
    """从给定的URL下载ROM"""
    subprocess.run(["aria2c", "-x16", "-s16",url])


def extract_payload_bin(zip_files):
    """从ZIP文件中提取payload.bin文件"""
    for f in zip_files:
        try:
            subprocess.run(["7z", "x", "{}".format(f), "payload.bin"])
        except Exception as e:
            print(f"异常，报错信息: {e}")


def extract_img():
    # 使用 subprocess 模块运行 shell 命令，执行 payload-dumper-go 的命令，从 payload.bin 文件中提取指定镜像文件
    # -c 参数指定最大并发数为 8，-o 指定提取后的文件输出到当前目录下
    # -p 参数指定提取指定镜像，"payload.bin" 为输入文件
    subprocess.run(["./payload-dumper-go", "-c", "8", "-o","./", "-p", "my_product,my_stock,my_bigball,my_heytap,system_ext", "payload.bin"])


def extract_files():
    try:
        # 使用 subprocess 模块运行 shell 命令，提取镜像文件中的文件
        # 使用 file 命令获取当前镜像打包格式
        output = subprocess.check_output(["file", "my_product.img"]).decode("utf-8")
        print("当前镜像打包格式:", output)
        if "EROFS filesystem" in output:
            # 如果输出内容包含 EROFS filesystem 则使用 extract.erofs 解压
            # -i 参数指定输入的镜像文件为，-x 参数指定提取文件，-T 参数指定使用线程提取文件
            subprocess.run(["./extract.erofs", "-i", "my_product.img", "-x", "-T16"])
            subprocess.run(["./extract.erofs", "-i", "my_stock.img", "-x", "-T16"])
            subprocess.run(["./extract.erofs", "-i", "my_bigball.img", "-x", "-T16"])
            subprocess.run(["./extract.erofs", "-i", "my_heytap.img", "-x", "-T16"])
            subprocess.run(["./extract.erofs", "-i", "system_ext.img", "-x", "-T16"])
        elif "data" in output:
            # 如果输出内容包含 data 则使用7zip解压
            # x 参数指定输入的镜像文件为，-o 提取指定提取文件到目录下
            subprocess.run(["7z", "x", "my_product.img", r"-o.\my_product"])
            subprocess.run(["7z", "x", "my_stock.img", r"-o.\my_stock"])
            subprocess.run(["7z", "x", "my_bigball.img", r"-o.\my_bigball"])
            subprocess.run(["7z", "x", "my_heytap.img", r"-o.\my_heytap"])
            subprocess.run(["7z", "x", "system_ext.img", r"-o.\system_ext"])
        else:
            print("未知的文件系统类型")
    except subprocess.CalledProcessError as e:
        print("解包失败:", e)
    except Exception as e:
        print("解包失败:", e)

    try:
        with open("./my_product/build.prop", "r") as file:
            for line in file:
                if line.startswith("ro.build.display.ota"):
                    device_name = line.split("=")[1].split("_")[0].strip()
                    print(f"设备名: {device_name}")
                    break
    except FileNotFoundError:
        print("无法获取设备名。")



def remove_some_apk(exclude_apk):
    # 遍历当前目录及其子目录
    for root, _, files in os.walk('.'):
        for file in files:
            # 判断文件是否为apk文件，且不在要排除的列表中
            if file.endswith('.apk') and file not in exclude_apk:
                src = os.path.join(root, file)
                dst = os.path.join(output_dir, file)
                # 将文件移动到output_dir目录下
                try:
                    shutil.move(src, dst)
                except PermissionError:
                    print(f"无法移动文件 {src}，请检查你的文件权限或关闭占用该文件的程序。")

    # 遍历output_dir目录及其子目录
    for root, _, files in os.walk(output_dir):
        for filename in fnmatch.filter(files, "*.apk"):
            # 判断文件名中是否包含对应文本，若包含则删除该文件
            if "overlay" in filename.lower() or "_sys" in filename.lower() or "_overlay" in filename.lower() or "systemhelper" in filename.lower():
                try:
                    os.remove(os.path.join(root, filename))
                except PermissionError:
                    print(f"无法删除文件 {filename}，请检查你的文件权限或关闭占用该文件的程序。")


def rename_apk(apk_files):
    # 遍历每个apk文件
    for apk_file in apk_files:
        apk_path = os.path.join(output_dir, apk_file)

        try:
            # 使用pyaxmlparser库读取apk包信息
            apk = APK(apk_path)

            # 获取apk的包名，版本号，version code
            package_name = apk.package
            version_name = apk.get_androidversion_name()
            version_code = apk.get_androidversion_code()

            # 构建新文件名
            new_name = f"{package_name}^{version_name}^{version_code}.apk"

            # 关闭apk文件
            apk.zip.close()

            # 重命名apk文件
            if not os.path.exists(os.path.join(output_dir, new_name)):
                os.rename(apk_path, os.path.join(output_dir, new_name))
        except Exception as e:
            print(f"异常，报错信息: {e}")


# 定义更新 apk 版本的函数，遍历输出目录下的 apk 文件，并更新本地词典
def update_apk_version(apk_version, apk_code, apk_code_name):
    # 遍历输出目录下的 apk 文件
    for apk_file in os.listdir(output_dir):
        # 如果文件名以 ".apk" 结尾
        if apk_file.endswith('.apk'):
            # 解析文件名，获取包名和版本号
            try:
                x, y, z = os.path.splitext(apk_file)[0].split('^')
                # 如果包名在本地词典中
                if x in apk_code:
                    # 如果本地词典中的版本号比 Apk 记录的版本号低
                    if apk_code[x] < int(z):
                        print(f'更新 {x}：{apk_code[x]} -> {z}')
                        if apk_version[x] == y:
                            # 更新本地词典中的版本号
                            apk_version[x] = y
                            apk_code[x] = int(z) # 以 int 格式写入
                            apk_code_name[x] = int(z) # 以 int 格式写入
                            # 复制新版本的 APK 文件到 update_apk 文件夹
                            src = os.path.join(output_dir, apk_file)
                            dst = os.path.join(update_apk_folder, apk_file)
                            shutil.copy2(src, dst)
                            print(f'已将 {apk_file} 复制到 {update_apk_folder} 文件夹\n')
                        else:
                            # 更新本地词典中的版本号
                            apk_version[x] = y
                            apk_code[x] = int(z) # 以 int 格式写入
                            # 复制新版本的 APK 文件到 update_apk 文件夹
                            src = os.path.join(output_dir, apk_file)
                            dst = os.path.join(update_apk_folder, apk_file)
                            shutil.copy2(src, dst)
                            print(f'已将 {apk_file} 复制到 {update_apk_folder} 文件夹\n')
                    elif apk_code[x] == int(z):
                        if apk_version[x] != y:
                            print(f'疑似更新 {x}：{apk_version[x]} -> {y}')
                            # 复制新版本的 APK 文件到 update_name_apk 文件夹
                            src = os.path.join(output_dir, apk_file)
                            dst = os.path.join(update_apk_name_folder, apk_file)
                            shutil.copy2(src, dst)
                            print(f'已将 {apk_file} 复制到 {update_apk_name_folder} 文件夹\n')
                # 如果包名不在本地词典中
                else:
                    print(f'添加新应用 {x}:{y}({z})\n')
                    # 在本地词典中添加新的包名和版本号
                    apk_version[x] = y
                    apk_code[x] = int(z) # 以 int 格式写入
            except Exception as e:
                print(f"异常，报错信息: {e}")
                return

    # 保存本地词典到json文件
    with open(APK_VERSION, 'w') as f:
        json.dump(apk_version, f)
    with open(APK_CODE, 'w') as f:
        json.dump(apk_code, f)
    with open(APK_CODE_NAME, 'w') as f:
        json.dump(apk_code_name, f)


# 定义更新apk文件名的函数，读取第二个词典并修改apk文件名
def update_apk_name():
    # 如果第二个词典文件存在，则读取其中的内容
    if os.path.exists(APK_APP_NAME):
        with open(APK_APP_NAME, 'r', encoding='utf-8') as f:
            apk_name = json.load(f)
    # 如果第二个词典文件不存在，则将其设为空字典
    else:
        apk_name = {}

    # 如果临时词典文件存在，则读取其中的内容
    if os.path.exists(APK_CODE_NAME):
        with open(APK_CODE_NAME, 'r', encoding='utf-8') as f:
            apk_code_name = json.load(f)
    # 如果临时词典文件不存在，则将其设为空字典
    else:
        apk_code_name = {}


    def rename_files_in_folder(folder, name_dict, code_dict):
        for apk_file in os.listdir(folder):
            # 如果文件名以".apk"结尾
            if apk_file.endswith('.apk'):
                # 解析文件名，获取包名和版本号
                x, y, z = os.path.splitext(apk_file)[0].split('^')
                # 如果解析的文件名在字典里
                if x in name_dict:
                    if x in code_dict:
                        # 定义修改的文件名
                        new_x = name_dict[x]
                        new_apk_file_1 = f'{new_x}_{y}({z}).apk'
                        # 修改为新定义的文件名
                        os.rename(os.path.join(folder, apk_file),
                                 os.path.join(folder, new_apk_file_1))
                        print(f'修改 {apk_file} -> {new_apk_file_1}')
                    else:
                        # 定义修改的文件名
                        new_x = name_dict[x]
                        new_apk_file_2 = f'{new_x}_{y}({z}).apk'
                        # 修改为新定义的文件名
                        os.rename(os.path.join(folder, apk_file),
                                 os.path.join(folder, new_apk_file_2))
                        print(f'修改 {apk_file} -> {new_apk_file_2}')

    # 重命名 output_dir 中的 APK 文件
    rename_files_in_folder(output_dir, apk_name, apk_code_name)

    # 重命名 update_apk 文件夹中的 APK 文件
    rename_files_in_folder(update_apk_folder, apk_name, apk_code_name)

    # 重命名 update_name_apk 文件夹中的 APK 文件
    rename_files_in_folder(update_apk_name_folder, apk_name, apk_code_name)


def delete_files_and_folders():
    """删除指定的文件和文件夹"""
    files_to_delete = ["payload.bin", "my_product.img", "my_stock.img", "my_bigball.img", "my_heytap.img", "system_ext.img", "app_code_name.json"]
    folders_to_delete = ["output_apk", "update_apk", "update_name_apk", "config", "my_heytap", "my_product", "my_stock", "system_ext", "my_bigball"]

    for file in files_to_delete:
        if os.path.exists(file):
            try:
                os.remove(file)
                print(f"{file} 删除成功")
            except OSError as e:
                print(f"无法删除 {file}: {e}")

        else:
            print(f"{file} 不存在")

    for folder in folders_to_delete:
        if os.path.exists(folder):
            if os.path.isdir(folder):
                try:
                    shutil.rmtree(folder)
                    print(f"{folder} 删除成功")
                except OSError as e:
                    print(f"无法删除 {folder}: {e}")
            else:
                print(f"{folder} 不是文件夹")
        else:
            print(f"{folder} 不存在")

        
def git_push():
    device_name = input("机型：")
    os_version = input("版本号：")
    commit_text = "Database：Update"
    commit = f"{commit_text} {device_name} {os_version}"
    subprocess.run(["git", "add", "app_version.json", "app_code.json"]) 
    subprocess.run(["git", "commit","-m",commit]) 
    subprocess.run(["git", "push"]) 