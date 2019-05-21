# Libraries builder for Unity3D Native Plugin
This repository is a set of build static/shared libraries to use in Unity (Unity3D) native plugin.

# Usage
In bash,

```bash
TARGET=<TARGET_NAME> bash ./build.sh
```

Supported <TARGET_NAME> is following list:

- android
  (which compiles for armv7, arm64, x86)
- android_armv7
- android_arm64
- android_x86
- ios
- macos
- win64
- linux_x86_64
- default
  (which compiles for host machine)


# Contribution
It is personal project but your contribution is welcome.

# License
These build-scripts excluded library-provided-scripts is released under The 2-Clause BSD License.
These library's source code and binary is released under original license each library.

In other words, I think following:

- If your application does not contains our build-scripts, you have to notice library's license only.
- If you redistributes the (modified or not) our build script, you have to notice build-script's license.
