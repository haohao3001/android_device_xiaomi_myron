#
# Copyright (C) 2026 The OrangeFox Recovery Project
# Device : Xiaomi POCO F8 Ultra / Redmi K90 Pro Max (myron)
# SoC    : Snapdragon 8 Elite Gen 5 (SM8850 / sun)
# Branch : OrangeFox 14.1
#
# Confirmed from:
#   fastboot getvar all  (partition sizes, slots, logical flags)
#   adb shell getprop    (platform, board, first_api_level=35, fbe params)
#   adb shell /proc/cmdline + /proc/bootconfig
#   adb shell /odm vintf manifests (keymint v3, weaver, vibrator fqname)
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/myron

# ─────────────────────────────────────────────────────────
# Build rules
# ─────────────────────────────────────────────────────────
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN
BUILD_BROKEN_PLUGIN_VALIDATION := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# ─────────────────────────────────────────────────────────
# Architecture — Oryon CPU (Snapdragon 8 Elite Gen 5)
# Confirmed: cpu-abi=arm64-v8a (fastboot), ro.product.cpu.abi=arm64-v8a (getprop)
# ─────────────────────────────────────────────────────────
TARGET_ARCH             := arm64
TARGET_ARCH_VARIANT     := armv8-a
TARGET_CPU_ABI          := arm64-v8a
TARGET_CPU_ABI2         :=
TARGET_CPU_VARIANT      := generic
TARGET_CPU_VARIANT_RUNTIME := oryon

ENABLE_CPUSETS    := true
ENABLE_SCHEDBOOST := true

# ─────────────────────────────────────────────────────────
# Platform
# Confirmed: ro.board.platform=xiaomi_sm8750, ro.product.board=sun (getprop)
# ─────────────────────────────────────────────────────────
PRODUCT_PLATFORM      := canoe
TARGET_BOOTLOADER_BOARD_NAME := canoe
TARGET_NO_BOOTLOADER  := true
TARGET_USES_UEFI      := true

TARGET_BOARD_PLATFORM := canoe
TARGET_BOARD_PLATFORM_GPU := qcom-adreno840
QCOM_BOARD_PLATFORMS  += canoe

# ─────────────────────────────────────────────────────────
# Kernel — prebuilt GKI 6.12, boot header v4, vendor_boot style
# Confirmed:
#   ro.boot.hardware.cpu.pagesize=4096 (getprop)
#   kernel lives in vendor_boot (kernel_size=0 in boot.img)
#   ro.bootimage.build.version.sdk=36 → BOARD_BOOT_HEADER_VERSION=4
# ─────────────────────────────────────────────────────────
TARGET_KERNEL_ARCH        := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME   := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE     := 4096
TARGET_KERNEL_CLANG_COMPILE := true
TARGET_PREBUILT_KERNEL    := $(DEVICE_PATH)/prebuilt/kernel
BOARD_MKBOOTIMG_ARGS      += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS      += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_RAMDISK_USE_LZ4     := true

# Kernel lives in vendor_boot — do NOT embed in recovery.img
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
# Empty cmdline — all params via bootconfig (confirmed /proc/cmdline vs /proc/bootconfig)
BOARD_KERNEL_CMDLINE :=

# ─────────────────────────────────────────────────────────
# A/B — dedicated recovery partition
#
# PROOF (fastboot getvar all):
#   partition-size:recovery_a = 0x6400000 (104857600 = 100MB)
#   has-slot:recovery = yes
#   is-logical:recovery_a = no  → raw partition, NOT in super
#   BOARD_USES_RECOVERY_AS_BOOT = false
#
# AB_OTA_PARTITIONS confirmed from:
#   ro.product.ab_ota_partitions (getprop stock ROM):
#   boot,dtbo,init_boot,odm,product,system,system_dlkm,
#   system_ext,vbmeta,vbmeta_system,vendor,vendor_boot,vendor_dlkm
# ─────────────────────────────────────────────────────────
AB_OTA_UPDATER   := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

BOARD_USES_RECOVERY_AS_BOOT             := false
BOARD_RECOVERY_NEEDS_BOOTLOADER_CONTROL := true

# ─────────────────────────────────────────────────────────
# Verified Boot (AVB)
# Confirmed:
#   ro.boot.verifiedbootstate=orange (unlocked, getprop)
#   ro.boot.vbmeta.avb_version=1.3
#   secure=no (fastboot getvar)
#   → Use NONE algorithm (unsigned build, no key needed)
# ─────────────────────────────────────────────────────────
BOARD_AVB_ENABLE                           := true
BOARD_AVB_RECOVERY_KEY_PATH                := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM               := SHA256_RSA4096
BOARD_AVB_ALGORITHM                        := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX          := 0
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 0

# ─────────────────────────────────────────────────────────
# Partition sizes — ALL confirmed from fastboot getvar all
#   recovery_a  : 0x6400000  = 104857600  (100MB) ← FIXED (was 100663296)
#   boot_a      : 0x6000000  = 100663296  (96MB)
#   vendor_boot : 0x6000000  = 100663296  (96MB)
#   init_boot_a : 0x800000   = 8388608    (8MB)
#   super       : 0x360000000= 14495514624 (13.5GB)
# ─────────────────────────────────────────────────────────
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
BOARD_BOOTIMAGE_PARTITION_SIZE         := 100663296
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE   := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE  := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE     := 104857600

BOARD_HAS_LARGE_FILESYSTEM         := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_USERIMAGES_USE_EXT4         := true
TARGET_USERIMAGES_USE_F2FS         := true

# ─────────────────────────────────────────────────────────
# Dynamic partitions (super)
# Confirmed from fastboot getvar (is-logical=yes):
#   system, system_ext, product, vendor, vendor_dlkm, odm,
#   system_dlkm, mi_ext, neo_inject
#
# OFox R12.1 accepts max 7 partition names in PARTITION_LIST.
# system_dlkm MUST be included (is-logical=yes, in AB_OTA).
# mi_ext is Xiaomi-only, NOT in AB_OTA → excluded from list.
# neo_inject has no _b slot → not managed by OFox.
# ─────────────────────────────────────────────────────────
BOARD_SUPER_PARTITION_SIZE := 14495514624
BOARD_SUPER_PARTITION_GROUPS := xiaomi_dynamic_partitions
BOARD_XIAOMI_DYNAMIC_PARTITIONS_SIZE := 14491320320
BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm \
    system_dlkm

# Filesystem types
TARGET_COPY_OUT_VENDOR     := vendor
BOARD_USES_VENDOR_DLKMIMAGE := true
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

# ODM — explicitly declared (matches SM8850 reference pattern)
# SINGLE SOURCE: recovery/root/odm/ only. Top-level odm/ removed.
TARGET_COPY_OUT_ODM             := odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs

# EROFS for all logical partitions (confirmed from recovery.fstab)
# TARGET_COPY_OUT_ODM above takes precedence; foreach re-sets to same value.
BOARD_PARTITION_LIST := $(call to-upper, $(BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs))
$(foreach p, $(BOARD_PARTITION_LIST), $(eval TARGET_COPY_OUT_$(p) := $(call to-lower,$(p))))

# ─────────────────────────────────────────────────────────
# Crypto / FBE
# Confirmed from getprop:
#   fbe.contents=aes-256-xts
#   fbe.filenames=aes-256-cts:v2+inlinecrypt_optimized+wrappedkey_v0
#   metadata.contents=aes-256-xts
#   metadata.filenames=wrappedkey_v0
#   prepdecrypt.setpatch=true
# Confirmed from odm vintf: keymint v3 (strongbox NXP JavaCard)
#   weaver-service runs from /odm/bin/hw/android.hardware.weaver-service
# ─────────────────────────────────────────────────────────
BOARD_USES_METADATA_PARTITION    := true
BOARD_USES_QCOM_FBE_DECRYPTION   := true
TW_INCLUDE_CRYPTO                := true
TW_INCLUDE_CRYPTO_FBE            := true
TW_INCLUDE_FBE_METADATA_DECRYPT  := true

# KeyMint AIDL — v4 QTI TEE + v3 ODM strongbox (NXP/Thales JavaCard)
TW_CRYPTO_USE_VENDOR_KEYMINT      := true
TW_KEYMINT_CLIENT_CONNECT_TIMEOUT := 4000
TW_USE_FSCRYPT_POLICY            := 2

# Security patch bypass (anti-rollback workaround)
# Confirmed: version-os=99.87.36 (fastboot), ro.build.version.release=99.87.36 (getprop)
PLATFORM_VERSION             := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH      := 2099-12-31
VENDOR_SECURITY_PATCH        := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH          := $(PLATFORM_SECURITY_PATCH)

# ─────────────────────────────────────────────────────────
# Recovery
# ─────────────────────────────────────────────────────────
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_RECOVERY_FSTAB        := $(DEVICE_PATH)/recovery.fstab
TW_INCLUDE_FASTBOOTD         := true
TW_SKIP_ADDITIONAL_FSTAB     := true
TARGET_SYSTEM_PROP           += $(DEVICE_PATH)/system.prop

# ─────────────────────────────────────────────────────────
# Display
# Confirmed:
#   ro.boot.panel_build_id=Pc0, panel_cell_id=AL7557J01UB961 (getprop)
#   Resolution 1200x2608 (from variant-script.sh in TWRP ramdisk)
#   y_offset=111, h_offset=-111 confirmed from bootconfig
#   TW_BRIGHTNESS_PATH confirmed from /sys/class/backlight/panel0-backlight
#   TW_MAX_BRIGHTNESS=4094 (standard for Xiaomi OLED)
# ─────────────────────────────────────────────────────────
TARGET_USES_VULKAN       := true
TW_THEME                 := portrait_hdpi
TW_FRAMERATE             := 120
TW_BRIGHTNESS_PATH       := "/sys/class/backlight/panel0-backlight/brightness"
TW_DEFAULT_BRIGHTNESS    := 1200
TW_MAX_BRIGHTNESS        := 4094
TW_NO_SCREEN_BLANK  := true
TW_SCREEN_BLANK_ON_BOOT  := true
TARGET_SCREEN_WIDTH      := 1200
TARGET_SCREEN_HEIGHT     := 2608
TW_STATUS_ICONS_ALIGN    := center



# ─────────────────────────────────────────────────────────
# Storage
# Confirmed: RECOVERY_SDCARD_ON_DATA — sdcard mounts from /data/media
# (ro.boot.dynamic_partitions=true, f2fs data partition)
# ─────────────────────────────────────────────────────────
RECOVERY_SDCARD_ON_DATA   := true
TARGET_USES_MKE2FS        := true
TW_ENABLE_FS_COMPRESSION  := true
TW_INCLUDE_FUSE_EXFAT     := true
TW_INCLUDE_FUSE_NTFS      := true
TW_INCLUDE_NTFS_3G        := false
TW_NO_EXFAT_FUSE          := true

# ─────────────────────────────────────────────────────────
# Tools
# ─────────────────────────────────────────────────────────
TW_INCLUDE_7ZA          := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPDUMP       := true
TW_INCLUDE_LPTOOLS      := true
TW_INCLUDE_REPACKTOOLS  := true
TW_INCLUDE_RESETPROP    := true
TW_USE_TOOLBOX          := true
TW_ENABLE_ALL_PARTITION_TOOLS := true
TW_USE_DMCTL            := true
# TW_USE_QCOM_HAPTICS_VIBRATOR := true  ← disabled: vibratorfeature service not running in recovery → blocks UI 5s per touch
TW_USE_BATTERY_SYSFS_STATS    := true
# myron: mca_business_battery driver exposes battery ở path platform-specific
# Confirmed từ logcat AVC audit: soc:mca_business_battery/power_supply/battery/capacity
# Path ngắn /sys/class/power_supply/battery là symlink kernel tạo tự động → OK
TW_POWER_SUPPLY_BATTERY_PATH  := "/sys/class/power_supply/battery"
TW_DEFAULT_TIMEZONE           := "Asia/Shanghai"

# ─────────────────────────────────────────────────────────
# Debug
# ─────────────────────────────────────────────────────────
TARGET_USES_LOGD         := true
TWRP_INCLUDE_LOGCAT      := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd strace
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace

# ─────────────────────────────────────────────────────────
# Vendor modules (kernel modules for touch / audio / ADSP)
# Touch: focaltech_touch_3683.ko (FTS IC — confirmed from odm ramdisk)
# Audio: ADSP modules required for keymint/weaver init chain
# ─────────────────────────────────────────────────────────
TW_LOAD_VENDOR_MODULES := "focaltech_touch_3683.ko xiaomi_touch.ko adsp_loader_dlkm.ko q6_dlkm.ko q6_pdr_dlkm.ko q6_notifier_dlkm.ko snd_event_dlkm.ko gpr_dlkm.ko spf_core_dlkm.ko rproc_qcom_common.ko qcom_q6v5.ko qcom_q6v5_pas.ko qcom_sysmon.ko qcom-hv-haptics.ko swr_haptics_dlkm.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_PREBUILT_MODULES_AT_FIRST  := true

# ─────────────────────────────────────────────────────────
# Vibrator (cs40l26 haptics)
# Confirmed from odm vintf manifest:
#   vendor.xiaomi.hardware.vibratorfeature.service.xml
#   fqname: IVibrator/vibratorfeature
# Confirmed from getprop:
#   ro.odm.mm.vibrator.sys_path=/sys/class/qcom-haptics
#   ro.odm.mm.vibrator.device_type=agm
#   ro.odm.mm.vibrator.resonant_frequency=170
# ─────────────────────────────────────────────────────────
# Haptics AIDL — libs pulled from /system/lib64/ (android.hardware.vibrator-V1-ndk.so + libxml2.so)
# placed in recovery/root/odm/lib64/ + LD_LIBRARY_PATH updated in service RC

#TW_SUPPORT_INPUT_AIDL_HAPTICS                      := true



TW_NO_LEGACY_PROPS          := true
# Tăng wait time: mca_business_battery driver cần ~1.7s để probe (dmesg)
# 8 giây đủ margin kể cả khi ADSP boot chậm
TW_BATTERY_SYSFS_WAIT_SECONDS := 8

# ─────────────────────────────────────────────────────────
# Misc
# ─────────────────────────────────────────────────────────
TW_EXTRA_LANGUAGES    := true
TW_DEFAULT_LANGUAGE   := zh_CN
# Blacklist non-touch input devices to prevent OFox polling ghost events
# qcom-hv-haptics: FF-only device, no touch events, causes poll stall
# uinput-xiaomi:   virtual key device, not a real touchscreen
TW_INPUT_BLACKLIST    := "hbtp_vm:qcom-hv-haptics:uinput-xiaomi"
TW_EXCLUDE_APEX       := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_HAS_EDL_MODE       := false
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone45/temp"
TW_BACKUP_EXCLUSIONS  := /data/fonts
TW_DEVICE_VERSION     := REDMI_K90_Pro_Max

#解密Data
TW_INCLUDE_OMAPI := true

#MTP支持
TW_HAS_MTP := true
