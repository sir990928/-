# CVE SO Branch

The `cve-so` branch is reserved for native shared-library build notes,
source provenance, target-profile documentation, and reproducibility records.

The current private laboratory V6 result is documented on `main`, but
operational SO binaries, root helpers, exact target offsets, and sensitive
runtime logs remain outside the public repository.

Every future target record should include:

- exact device and firmware identity;
- upstream source revision;
- compiler and NDK version;
- build command;
- input and output hashes;
- execution context;
- a redacted validation result.

