#!/usr/bin/env python3
import os
import struct
import sys

def transplant_avb_smart(official_img, custom_img, output_img):
    print("[*] 正在解析镜像并进行智能移植...")
    
    # 1. 提取官方 VBMeta 签名块
    with open(official_img, 'rb') as f_off:
        f_off.seek(0, os.SEEK_END)
        part_size = f_off.tell()
        
        f_off.seek(part_size - 64)
        footer = f_off.read(64)
        magic, major, minor, orig_size, vbmeta_offset, vbmeta_size = struct.unpack('>4sLLQQQ', footer[:36])
        
        if magic != b'AVBf':
            print("[-] 错误：官方镜像不包含 AVB 尾部！")
            sys.exit(1)
            
        f_off.seek(vbmeta_offset)
        off_vbmeta_blob = f_off.read(vbmeta_size)
        print(f"[+] 提取官方签名块成功 (大小: {vbmeta_size} 字节)")

    # 2. 智能剥离自定义镜像的填充和旧签名
    with open(custom_img, 'rb') as f_cust:
        f_cust.seek(0, os.SEEK_END)
        cust_size = f_cust.tell()
        
        f_cust.seek(cust_size - 64)
        cust_footer = f_cust.read(64)
        magic, _, _, _, cust_vbmeta_offset, _ = struct.unpack('>4sLLQQQ', cust_footer[:36])
        
        f_cust.seek(0)
        if magic == b'AVBf':
            # 如果包含我们编译时加的测试签名，将其剥离，只取真实 Payload
            pure_cust_data = f_cust.read(cust_vbmeta_offset)
            print(f"[+] 成功剥离测试签名，OrangeFox 真实体积: {len(pure_cust_data)} 字节")
        else:
            pure_cust_data = f_cust.read()
            print(f"[+] 未发现测试签名，OrangeFox 真实体积: {len(pure_cust_data)} 字节")

    # 检查真实体积是否超限
    if len(pure_cust_data) + len(off_vbmeta_blob) + 64 > part_size:
        print("[-] 错误：你编译的 OrangeFox 实在太大了，100MB 的分区装不下！请在 BoardConfig 里精简组件。")
        sys.exit(1)

    # 3. 动态重构 AVB 尾部指针并组装
    new_vbmeta_offset = len(pure_cust_data)
    # 打包新的 64 字节 Footer
    new_footer = struct.pack('>4sLLQQQ', b'AVBf', major, minor, new_vbmeta_offset, new_vbmeta_offset, vbmeta_size)
    new_footer += b'\0' * 28  # 填充剩下的保留位

    with open(output_img, 'wb') as f_out:
        f_out.write(pure_cust_data)       # 写入真正的 OrangeFox 内容
        f_out.write(off_vbmeta_blob)      # 紧贴着写入官方签名块
        
        current_pos = f_out.tell()
        f_out.write(b'\0' * (part_size - 64 - current_pos)) # 用 0 填充满剩余的空白
        
        f_out.write(new_footer)           # 在最后 64 字节打上新的指针
        
    print(f"[+] AVB移植成功，新镜像已生成：{output_img}")

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("用法: python transplanting_vbmeta.py <原厂recovery.img> <被修补的镜像> <修补后的文件>")
        sys.exit(1)
    transplant_avb_smart(sys.argv[1], sys.argv[2], sys.argv[3])