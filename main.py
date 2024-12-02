from config import *  # 从config.py模块中导入所有内容
from defs import *  # 从defs.py模块中导入所有内容
import argparse


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="EMRA: A tool to process Android ROM and APK files")

    parser.add_argument('-d', '--download', metavar='URL',
                        help='Download ROM from given URL')
    parser.add_argument('-p', '--extract-payload', action='store_true',
                        help='Extract payload.bin from zip files')
    parser.add_argument('-i', '--img', action='store_true',
                        help='Extract img from payload.bin')
    parser.add_argument('-f', '--files', action='store_true',
                        help='Extract files from img')
    parser.add_argument('-a', '--apk', action='store_true',
                        help='Remove specified APKs')
    parser.add_argument('-n', '--rename', action='store_true',
                        help='Rename APK files')
    parser.add_argument('-u', '--update-version',
                        action='store_true', help='Update APK versions')
    parser.add_argument('-m', '--update-name',
                        action='store_true', help='Update APK names')
    parser.add_argument('-c', '--clean', action='store_true',
                        help='Delete unnecessary files and folders')
    parser.add_argument('-g', '--git_push', action='store_true',
                        help='Upload Datebase to GitHub repository')
    return parser.parse_args()


def main():
    args = parse_arguments()

    init_folder()
    exclude_apk, apk_version, apk_code, apk_code_name = init_json()

    if args.download:
        download_rom(args.download)
    if args.extract_payload:
        extract_payload_bin(zip_files)
    if args.img:
        extract_img()
    if args.files:
        extract_files()
    if args.apk:
        remove_some_apk(exclude_apk)
    if args.rename:
        rename_apk(apk_files)
    if args.update_version:
        update_apk_version(apk_version, apk_code, apk_code_name)
    if args.update_name:
        update_apk_name()
    if args.clean:
        delete_files_and_folders()
    if args.git_push:
        git_push()


if __name__ == "__main__":  # 如果这个脚本文件是被直接运行的
    main()  # 调用main()函数
