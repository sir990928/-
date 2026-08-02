API ?= 35
TARGET ?= pa3q-S9380ZHU1AYA1

ifndef CLANG
    CLANG := $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android$(API)-clang
endif

ROOT := .
SRC_ORIGINAL := $(ROOT)/src/original
SRC_DEVICE := $(ROOT)/src/device
SRC_APP := $(ROOT)/src/app
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

VARIANT ?= adb

ifeq ($(VARIANT),app)
    VARIANT_CFLAGS := -DAPP_PAYLOAD=1
    SOURCE_CPPFLAGS := $(DEVICE_CPPFLAGS)
    MAIN_SRC := $(SRC_APP)/main.c
    UTIL_SRC := $(SRC_APP)/util.c
    FOPS_SRC := $(SRC_APP)/fops.c
    PIPE_SRC := $(SRC_APP)/pipe.c
    PRELOAD_SRC := $(SRC_APP)/preload.c
    SLIDE_SRC := $(SRC_APP)/slide.c
    PAYLOAD := $(OUT_DIR)/cve-2026-43499-app.so
else
    VARIANT_CFLAGS := -DAPP_PAYLOAD=0
    SOURCE_CPPFLAGS := $(ORIGINAL_CPPFLAGS)
    MAIN_SRC := $(SRC_ORIGINAL)/main.c
    UTIL_SRC := $(SRC_ORIGINAL)/util.c
    FOPS_SRC := $(SRC_ORIGINAL)/fops.c
    PIPE_SRC := $(SRC_ORIGINAL)/pipe.c
    PRELOAD_SRC := $(SRC_ORIGINAL)/preload_minimal.c
    SLIDE_SRC := $(SRC_DEVICE)/slide.c
    PAYLOAD := $(OUT_DIR)/cve-2026-43499
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

HELPER := $(OUT_DIR)/cve-2026-43499-root

.PHONY: all clean

all: $(PAYLOAD) $(HELPER)

$(TARGET_INCLUDE): $(TARGET_DIR)/target.h
	mkdir -p $(@D)
	cp $< $@

$(OBJ_DIR) $(OUT_DIR):
	mkdir -p $@

$(OBJ_DIR)/main.o: $(MAIN_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(SOURCE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/util.o: $(UTIL_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(SOURCE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/fops.o: $(FOPS_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(SOURCE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/pipe.o: $(PIPE_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(SOURCE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/root_compat_globals.o: $(SRC_ORIGINAL)/root_compat_globals.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(ORIGINAL_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/root-umh.o: $(SRC_DEVICE)/root.c $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(DEVICE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/preload.o: $(PRELOAD_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(SOURCE_CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/slide.o: $(SLIDE_SRC) $(TARGET_INCLUDE) | $(OBJ_DIR)
	$(CLANG) $(COMMON_CFLAGS) $(VARIANT_CFLAGS) -fPIC $(if $(filter app,$(VARIANT)),$(DEVICE_CPPFLAGS),$(ORIGINAL_CPPFLAGS)) -c $< -o $@

$(PAYLOAD): $(OBJECTS) | $(OUT_DIR)
	$(CLANG) $(TARGET_FLAGS) -shared -fuse-ld=lld \
		-Wl,--no-undefined -Wl,-z,relro -Wl,-z,now \
		$(OBJECTS) -pthread -ldl -o $@

$(HELPER): $(ROOT)/helper/su_daemon.c | $(OUT_DIR)
	$(CLANG) $(TARGET_FLAGS) -fPIE -pie -O2 -g0 -Wall -Wextra \
		$< -ldl -o $@

clean:
	rm -rf $(BUILD_DIR)
