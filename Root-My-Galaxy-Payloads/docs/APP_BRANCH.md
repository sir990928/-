# APP Branch

The `app` branch is reserved for the application-side project. Its project
organization, lifecycle, native-library loading arrangement, and logging
layout can follow the APP architecture used by
[BuSung-dev/Root-My-Galaxy](https://github.com/BuSung-dev/Root-My-Galaxy).

That reference is used as an application framework only. Sroot's native
payload, target adaptation, and validation records remain separate and are
not copied from the reference project's exploit path.

The APP branch is not an ADB-shell drop-in. An ordinary APK runs with
different permissions, SELinux context, filesystem access, and process-launch
behavior. These properties must be measured independently.

Public APP work should begin with:

1. a harmless native diagnostic library;
2. device/build fingerprint checks;
3. structured log collection;
4. an explicit user-authorized service boundary;
5. reproducible Gradle and NDK builds.

No operational no-ADB privilege-escalation payload is included in this branch.
