# dkml-c-probe

Introspects OCaml's native C compiler to determine the ABI used by executables
created by the C compiler. Designed to be used to simplify [Dune Configurator](https://dune.readthedocs.io/en/latest/dune-libs.html#configurator-1)
code or [foreign C stub code](https://dune.readthedocs.io/en/latest/foreign-code.html).
Since `dkml-c-probe` never runs executables created by the C compiler,
`dkml-c-probe` is safe to use with cross-compilers.

For example, let's say you had an Apple Intel x86_64 build machine with
a OCaml ocamlfind cross-compiler toolchain for Apple Silicon. *This will
be available soon from Opam: https://github.com/diskuv/dkml-compiler/blob/main/dkml-base-compiler.opam*

OCaml will report:

<!-- $MDX non-deterministic=command -->
```console
$ ocamlopt -config
...
native_c_compiler: clang -arch x86_64

$ ocamlfind -toolchain darwin_arm64 ocamlopt -config
...
native_c_compiler: clang -arch arm64
```

which would mean:

<!-- $MDX non-deterministic=command -->
```ocaml
Lazy.force (Dkml_c_probe.C_abi.V2.get_platform ())
```

would result in `Ok Darwin_x86_64` or `Ok Darwin_arm64`, depending on which
ocamlfind toolchain was used.

[Dune Cross Compilation](https://dune.readthedocs.io/en/latest/cross-compilation.html)
combined with [Opam Monorepo](https://github.com/ocamllabs/opam-monorepo#opam-monorepo)
makes this simpler. On the same example machine you could do:

<!-- $MDX non-deterministic=command -->
```console
$ dune build -x darwin_arm64
```

and it would compile both Apple Intel and Apple Silicon binaries. During the
compilation of the Apple Intel binaries (Dune's "default" context) the
`get_platform ()` would give `Ok Darwin_x86_64` while during the compilation of
the Apple Silicon binaries (Dune's "default_arm64" context) it would give
`Ok Darwin_arm64`.

## Usage

Install it with:

<!-- $MDX non-deterministic=command -->
```console
$ opam install dkml-c-probe
```

Then either:
* Use the [OCaml Signature](#ocaml-signature) in your [Dune Configurator](https://dune.readthedocs.io/en/latest/dune-libs.html#configurator-1)
* Use the [C Header](#c-header) in your [foreign C stub code](https://dune.readthedocs.io/en/latest/foreign-code.html)

## OCaml Signature

OCaml API documentation is at http://diskuv.github.io/dkml-c-probe/

```console
$ ocaml show_signature.ml
module V2 = Dkml_c_probe.C_abi.V2
module V2 :
  sig
    type ostype = Android | IOS | Linux | OSX | Windows
    type platformtype =
        Android_arm64v8a
      | Android_arm32v7a
      | Android_x86
      | Android_x86_64
      | Darwin_arm64
      | Darwin_x86_64
      | Linux_arm64
      | Linux_arm32v6
      | Linux_arm32v7
      | Linux_x86_64
      | Linux_x86
      | Windows_x86_64
      | Windows_x86
      | Windows_arm64
      | Windows_arm32
    val get_os : (ostype, Rresult.R.msg) Result.t Lazy.t
    val get_platform : (platformtype, Rresult.R.msg) Result.t Lazy.t
    val get_platform_name : (string, Rresult.R.msg) Result.t Lazy.t
  end
```

## C Header

The header file will be available as the following expressions:
- `%{dkml-c-probe:lib}%/dkml_compiler_probe.h` if you are in an `.opam` file
- `%{lib:dkml-c-probe:dkml_compiler_probe.h}` if you are in a `dune` file

<!-- $MDX file=dkml_compiler_probe.h -->
```c
/******************************************************************************/
/*  Copyright 2021 Diskuv, Inc.                                               */
/*                                                                            */
/*  Licensed under the Apache License, Version 2.0 (the "License");           */
/*  you may not use this file except in compliance with the License.          */
/*  You may obtain a copy of the License at                                   */
/*                                                                            */
/*      http://www.apache.org/licenses/LICENSE-2.0                            */
/*                                                                            */
/*  Unless required by applicable law or agreed to in writing, software       */
/*  distributed under the License is distributed on an "AS IS" BASIS,         */
/*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  */
/*  See the License for the specific language governing permissions and       */
/*  limitations under the License.                                            */
/******************************************************************************/

/*
  For Apple see https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary
  For Windows see https://docs.microsoft.com/en-us/cpp/preprocessor/predefined-macros?view=msvc-160
  For Android see https://developer.android.com/ndk/guides/cpu-features
  For Linux see https://sourceforge.net/p/predef/wiki/Architectures/
 */
#ifndef DKMLCOMPILERPROBE_H
#define DKMLCOMPILERPROBE_H

#if __APPLE__
#   include <TargetConditionals.h>
#   if TARGET_OS_OSX
#       define DKML_OS_NAME "OSX"
#       define DKML_OS_OSX
#       if TARGET_CPU_ARM64
#           define DKML_ABI "darwin_arm64"
#           define DKML_ABI_darwin_arm64
#       elif TARGET_CPU_X86_64
#           define DKML_ABI "darwin_x86_64"
#           define DKML_ABI_darwin_x86_64
#       endif /* TARGET_CPU_ARM64, TARGET_CPU_X86_64 */
#   elif TARGET_OS_IOS
#       define DKML_OS_NAME "IOS"
#       define DKML_OS_IOS
#       define DKML_ABI "darwin_arm64"
#       define DKML_ABI_darwin_arm64
#   endif /* TARGET_OS_OSX, TARGET_OS_IOS */
#elif __linux__
#   if __ANDROID__
#       define DKML_OS_NAME "Android"
#       define DKML_OS_Android
#       if __arm__
#           define DKML_ABI "android_arm32v7a"
#           define DKML_ABI_android_arm32v7a
#       elif __aarch64__
#           define DKML_ABI "android_arm64v8a"
#           define DKML_ABI_android_arm64v8a
#       elif __i386__
#           define DKML_ABI "android_x86"
#           define DKML_ABI_android_x86
#       elif __x86_64__
#           define DKML_ABI "android_x86_64"
#           define DKML_ABI_android_x86_64
#       endif /* __arm__, __aarch64__, __i386__, __x86_64__ */
#   else
#       define DKML_OS_NAME "Linux"
#       define DKML_OS_Linux
#       if __aarch64__
#           define DKML_ABI "linux_arm64"
#           define DKML_ABI_linux_arm64
#       elif __arm__
#           if defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_6J__) || defined(__ARM_ARCH_6K__) || defined(__ARM_ARCH_6Z__) || defined(__ARM_ARCH_6ZK__) || defined(__ARM_ARCH_6T2__)
#               define DKML_ABI "linux_arm32v6"
#               define DKML_ABI_linux_arm32v6
#           elif defined(__ARM_ARCH_7__) || defined(__ARM_ARCH_7A__) || defined(__ARM_ARCH_7R__) || defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7S__)
#               define DKML_ABI "linux_arm32v7"
#               define DKML_ABI_linux_arm32v7
#           endif /* __ARM_ARCH_6__ || ...,  __ARM_ARCH_7__ || ... */
#       elif __x86_64__
#           define DKML_ABI "linux_x86_64"
#           define DKML_ABI_linux_x86_64
#       elif __i386__
#           define DKML_ABI "linux_x86"
#           define DKML_ABI_linux_x86
#       endif /* __aarch64__, __arm__, __x86_64__, __i386__ */
#   endif /* __ANDROID__ */
#elif _WIN32
#   define DKML_OS_NAME "Windows"
#   define DKML_OS_Windows
#   if _M_ARM64
#       define DKML_ABI "windows_arm64"
#       define DKML_ABI_windows_arm64
#   elif _M_ARM
#       define DKML_ABI "windows_arm32"
#       define DKML_ABI_windows_arm32
#   elif _WIN64
#       define DKML_ABI "windows_x86_64"
#       define DKML_ABI_windows_x86_64
#   elif _M_IX86
#       define DKML_ABI "windows_x86"
#       define DKML_ABI_windows_x86
#   endif /* _M_ARM64, _M_ARM, _WIN64, _M_IX86 */
#endif

#endif /* DKMLCOMPILERPROBE_H */
```

## Contributions

Head over to **[Your Contributions](CONTRIBUTORS.md)**.
