### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=GKI Kernel by SM-S93XX
do.devicecheck=1
do.modules=1
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=pa3q
device.name2=pa2q
device.name3=pa1q
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/by-name/boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
split_boot;

flash_boot;
## end boot install


## vendor_dlkm install
if [ -d "$MODULES/vendor_dlkm/lib/modules" ]; then
  ui_print " ";
  ui_print "-> 刷入 vendor_dlkm 模块...";
  copy_separate "$MODULES/vendor_dlkm" "/vendor_dlkm";
  set_perm_recursive 0 0 0755 0644 /vendor_dlkm/lib/modules;
fi;
## end vendor_dlkm install


## system_dlkm install
if [ -d "$MODULES/system_dlkm/lib/modules" ]; then
  ui_print " ";
  ui_print "-> 刷入 system_dlkm 模块...";
  copy_separate "$MODULES/system_dlkm" "/system_dlkm";
  set_perm_recursive 0 0 0755 0644 /system_dlkm/lib/modules;
fi;
## end system_dlkm install
