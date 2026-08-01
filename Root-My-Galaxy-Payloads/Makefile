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
BUILD_DIR := $(ROOT)/build/v6
OBJ_DIR := $(BUILD_DIR)/obj
OUT_DIR := $(BUILD_DIR)/artifact

TARGET_FLAGS := --target=aarch64-linux-android$(API)
COMMON_CFLAGS := $(TARGET_FLAGS) -O2 -g0 -Wall -Wextra -Wno-unused-parameter
ORIGINAL_CPPFLAGS := -I$(SRC_ORIGINAL) -I$(INCLUDE_DIR) -I$(TARGET_DIR) -DTARGET_CONFIG_H=\"target.h\"
DEVICE_CPPFLAGS := -I$(SRC_DEVICE) -I$(INCLUDE_DIR) -I$(TARGET_DIR)

ORIGINAL_OBJECTS := \
	$(OBJ_DIR)/main.o \
	$(OBJ_DIR)/util.o \
	$(OBJ_DIR)/fops.o \
	$(OBJ_DIR)/pipe.o \
	$(OBJ_DIR)/preload_minimal.o \
	$(OBJ_DIR)/root_compat_globals.o

DEVICE_OBJECTS := \
	$(OBJ_DIR)/root-umh.o \
	$(OBJ_DIR)/slide-tracefs.o

PAYLOAD := $(OUT_DIR)/cve-2026-43499-root-original-zhu-tracefs-v6.so
HELPER := $(OUT_DIR)/cve-2026-43499-root

.PHONY: all clean hashes debug

all: $(PAYLOAD) $(HELPER)

# 调试目标，显示变量值
debug:
	@echo "API = $(API)"
	@echo "TARGET = $(TARGET)"
	@echo "ANDROID_NDK_HOME = $(ANDROID_NDK_HOME)"
	@echo "CLANG = $(CLANG)"
	@echo "TARGET_FLAGS = $(TARGET_FLAGS)"

$(TARGET_INCLUDE): $(TARGET_DIR)/target.h
	mkdir -p $(@D)
	cp $< $@

$(OBJ_DIR) $(OUT_DIR):
	mkdir -p $@

$(OBJ_DIR)/%.o: $(SRC_ORIGINAL)/%.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/root-umh.o: $(SRC_DEVICE)/root.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) -fPIC $(DEVICE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/slide-tracefs.o: $(SRC_DEVICE)/slide.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) -fPIC $(DEVICE_CPPFLAGS) -c $< -o $@

$(PAYLOAD): $(ORIGINAL_OBJECTS) $(DEVICE_OBJECTS) | $(OUT_DIR)
	$(CLANG) $(TARGET_FLAGS) -shared -fuse-ld=lld \
		-Wl,--no-undefined -Wl,-z,relro -Wl,-z,now \
		$(ORIGINAL_OBJECTS) $(DEVICE_OBJECTS) -pthread -ldl -o $@

$(HELPER): $(ROOT)/helper/su_daemon.c | $(OUT_DIR)
	$(CLANG) $(TARGET_FLAGS) -fPIE -pie -O2 -g0 -Wall -Wextra \
		$< -ldl -o $@

hashes: all
	sha256sum $(PAYLOAD) $(HELPER) $(TARGET_DIR)/target.h

clean:
	rm -rf $(BUILD_DIR)
