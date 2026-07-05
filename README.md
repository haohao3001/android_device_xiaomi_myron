# OrangeFox Recovery — Xiaomi myron (POCO F8 Ultra / Redmi K90 Pro Max)

## 设备信息

| 项目 | 规格 |
|------|------|
| 处理器 | Snapdragon 8 Elite Gen 5（SM8850 / sun） |
| CPU | Oryon（8 核） |
| 内存 | 12/16 GB |
| 存储 | 256/512 GB UFS 4.0 |
| 屏幕 | 1200×2608，120Hz OLED |
| 内核 | GKI 6.12（Android 16） |
| 分区架构 | Virtual A/B + 独立 recovery 分区 |
| 加密方式 | FBE（aes-256-xts + wrappedkey_v0） |
| KeyMint | TEE（vendor.keymint-qti）+ Strongbox（Thales JavaCard via se_omapi） |
| 振动马达 | PMIC HV haptics (qcom-hv-haptics revision 5) |

---

## 构建
### 初始化构建环境
```bash
git clone https://github.com/OrangeFox16/sync.git
cd sync
./orangefox_sync.sh --branch 16.0 --path ~/fox_16.0 #同步源码，这一步需要在googlesource下载大约80G的源码(This may take a very *long* time)
cd fox_16.0
git clone https://github.com/haohao3001/android_device_xiaomi_myron.git device/xiaomi/myron
```
### Build
```bash
source build/envsetup.sh
git -C $ANDROID_BUILD_TOP/bootable/recovery apply $ANDROID_BUILD_TOP/device/xiaomi/myron/0000-Add-haptics.patch #需要震动的就应用该patch
lunch twrp_myron-bp2a-eng
mka recoveryimage
```
如需使用github actions构建，请自行寻找脚本


## 支持的特性
- [X] 显示
- [X] 触屏 
- [X] 震动
- [X] 解密Data
- [X] 刷入卡刷包
- [X] 备份
- [X] KernelSU, KernelSU Next & SukiSU Ultra 安装
- [X] MTP
- [X] ADB/FastbootD
- [X] 手电筒

## 不支持的特性
- [ ] WLAN(为什么Recovery需要WLAN支持?)(遥遥无期)

## 注意
对于假回锁用户，自行构建的OrangeFox不能直接刷入recovery分区(Release里的是处理好的)，需要使用仓库下的“transplanting_vbmeta.py”脚本把原厂recovery的avb信息移植过去后再刷入  
```bash
python transplanting_vbmeta.py <原厂recovery.img> <被修补的镜像> <修补后的文件>
```
---
1.1.0及其之前的版本配置文件保存在/persisit中，1.2.0之后改为了保存到/data/recovery(避免污染persisit分区)
使用下面的命令可删除保存在persist中的OrangeFox配置文件
```bash
rm -r /mnt/vendor/persist/Fox
rm /mnt/vendor/persist/.foxs
rm /mnt/vendor/persist/.fsec
```

## Maintainer
haohao3001 - 维护者  
基于[hackpupg001-a11y的设备树](https://github.com/hackpupg001-a11y/android_device_xiaomi_myron)二次开发  
recovery/root下的大部分二进制文件参考自 變換風雲@coolapk 的TWRP
