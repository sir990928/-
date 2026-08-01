# Device Adaptation Guide

This guide describes how Sroot records a secondary device adaptation without
mixing target data into the generic research implementation.

## 1. Identify The Exact Build

A target profile must be tied to all of the following:

- product/model identifier;
- region and CSC;
- firmware build string;
- Android release;
- complete build fingerprint;
- boot image provenance;
- kernel source or symbol provenance.

Two phones with the same marketing name are not interchangeable when their
kernel build, vendor configuration, or firmware revision differs.

## 2. Keep Target Data Isolated

Use one directory per exact build, for example:

```text
targets/
  pa3q-S9380ZHU1AYA1/
    README.md
    target-profile.h        # private lab file, not public
    validation-notes.md
```

Generic code should consume a target profile through a single include or
configuration boundary. Avoid copying constants into multiple C files.

The public repository intentionally omits operational target profiles. A
private profile should document the origin and confidence of every value,
including whether it came from symbols, disassembly, runtime observation, or
an independent cross-check.

## 3. Use The Kernel Source Correctly

Samsung open-source kernel packages are useful for structure and configuration
context, but they do not automatically provide the exact runtime addresses
for a shipped build. Record:

- kernel branch and release tag;
- vendor patches used by the shipped firmware;
- configuration differences;
- architecture and page-size assumptions;
- any mismatch between source and boot image.

The boot image and firmware package should remain private unless redistribution
is clearly permitted.

## 4. Validate In Stages

Use separate test records for each stage:

```text
compile/load
  -> information disclosure
  -> address validation
  -> control-flow test
  -> memory primitive test
  -> authorized privileged-service test
```

Record the process UID, SELinux domain, enforcement state, Android version,
and whether the process was launched by ADB, an authorized service, or an APK.
These contexts are not equivalent.

## 5. Build Hygiene

For every successful private build, save:

- source commit IDs;
- target profile hash;
- compiler and NDK versions;
- complete command line;
- output SHA-256 values;
- a redacted log showing the validation result.

Generated object files are disposable. They should be rebuilt from source and
must not be used as a substitute for recording the source revision and build
configuration.

## 6. APP Work

An application wrapper should first be tested with a harmless native
diagnostic library. It should report process context, file access, linker
behavior, and logging results before any privileged integration is attempted.

An ordinary APK cannot assume the permissions, SELinux domain, filesystem
access, or process-launch behavior available to an ADB shell. APP compatibility
must therefore be demonstrated independently and must use an explicitly
authorized service for any privileged operation.

