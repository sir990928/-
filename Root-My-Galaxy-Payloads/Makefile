API ?= 35
TARGET ?= pa3q-S9380ZHU1AYA1

# 设置CLANG编译器，优先使用环境变量，否则使用TARGET_CC
ifndef CLANG
    CLANG := $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android$(API)-clang
endif

ROOT := .
SRC_ORIGINAL := $(ROOT)/src/original
SRC_DEVICE := $(ROOT)/src/device
TARGET_DIR := $(ROOT)/target/$(TARGET)
INCLUDE_DIR := $(ROOT)/include
TARGET_INCLUDE := $(INCLUDE_DIR)/targets/$(TARGET)/target.h
BUILD_DIR := $(ROOT)/build/$(TARGET)
OBJ_DIR := $(BUILD_DIR)/obj
OUT_DIR := $(BUILD_DIR)


TARGET_FLAGS := --target=aarch64-linux-android$(API)
COMMON_CFLAGS := $(TARGET_FLAGS) -O2 -g0 -Wall -Wextra -Wno-unused-parameter
ORIGINAL_CPPFLAGS := -I$(SRC_ORIGINAL) -I$(INCLUDE_DIR) -I$(TARGET_DIR) -DTARGET_CONFIG_H=\"target.h\"
DEVICE_CPPFLAGS := -I$(SRC_DEVICE) -I$(INCLUDE_DIR) -I$(TARGET_DIR)

# 默认构建变体
VARIANT ?= adb

ifeq ($(VARIANT),app)
    VARIANT_CFLAGS := -DAPP_PAYLOAD=1
    PRELOAD_SRC := $(SRC_ORIGINAL)/preload.c
    SLIDE_SRC := $(SRC_ORIGINAL)/slide_app.c
    OUT_SUFFIX := -app
else
    VARIANT_CFLAGS := -DAPP_PAYLOAD=0
    PRELOAD_SRC := $(SRC_ORIGINAL)/preload_minimal.c
    SLIDE_SRC := $(SRC_DEVICE)/slide.c
    OUT_SUFFIX := -adb
endif

OBJECTS := \
	$(OBJ_DIR)/main.o \
	$(OBJ_DIR)/util.o \
	$(OBJ_DIR)/fops.o \
	$(OBJ_DIR)/pipe.o \
	$(OBJ_DIR)/root_compat_globals.o \
	$(OBJ_DIR)/root-umh.o \
	$(OBJ_DIR)/preload.o \
	$(OBJ_DIR)/slide.o

PAYLOAD := $(OUT_DIR)/cve-2026-43499-root$(OUT_SUFFIX).so
HELPER := $(OUT_DIR)/cve-2026-43499-root

.PHONY: all clean hashes debug

all: $(PAYLOAD) $(HELPER)

# 调试目标，显示变量值
debug:
	@echo "API = $(API)"
	@echo "TARGET = $(TARGET)"
	@echo "VARIANT = $(VARIANT)"
	@echo "CLANG = $(CLANG)"

$(TARGET_INCLUDE): $(TARGET_DIR)/target.h
	mkdir -p $(@D)
	cp $< $@

$(OBJ_DIR) $(OUT_DIR):
	mkdir -p $@

$(OBJ_DIR)/main.o: $(SRC_ORIGINAL)/main.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/util.o: $(SRC_ORIGINAL)/util.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/fops.o: $(SRC_ORIGINAL)/fops.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/pipe.o: $(SRC_ORIGINAL)/pipe.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/root_compat_globals.o: $(SRC_ORIGINAL)/root_compat_globals.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/root-umh.o: $(SRC_DEVICE)/root.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(DEVICE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/preload.o: $(PRELOAD_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/slide.o: $(SLIDE_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(PAYLOAD): $(OBJECTS) | $(OUT_DIR)
	$(CLANG) $(TARGET_FLAGS) -shared -fuse-ld=lld \
		-Wl,--no-undefined -Wl,-z,relro -Wl,-z,now \
		$(OBJECTS) -pthread -ldl -o $@

$(HELPER): $(ROOT)/helper/su_daemon.c | $(OUT_DIR)
	$(CLANG) $(TARGET_FLAGS) -fPIE -pie -O2 -g0 -Wall -Wextra \
		$< -ldl -o $@

hashes: all
	sha256sum $(PAYLOAD) $(HELPER) $(TARGET_DIR)/target.h

clean:
	rm -rf $(BUILD_DIR)
