# dkml-c-probe

`dkml-c-probe` simplifies the creation of cross-compiling compatible
[foreign C stub code](https://dune.readthedocs.io/en/latest/foreign-code.html).
It includes two components:

1. **C_abi**: Introspects OCaml's native C compiler, including cross-compilers,
   to determine the ABI those C compilers will generate
2. **C_conf**: Supplies flags to C compilers and OCaml tools that specify the locations
   of C headers and C libraries

Its support for cross-compiling comes from:

- With cross-compilers you will not often be able to run the executables
  that have been generated. `C_abi` never runs executables created by the C compiler.
- When compiling on a host ABI and cross-compiling to multiple target ABIs,
  there must be separate sets of C libraries: one set for the host ABI and
  one set for each target ABI. `C_conf` can locate C headers and C libraries
  that are appropriate for the host ABI and target ABIs.

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

which would mean using the `C_abi`:

<!-- $MDX non-deterministic=command -->
```ocaml
Dkml_c_probe.C_abi.V3.get_abi ()
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
`get_abi ()` would give `Ok Darwin_x86_64` while during the compilation of
the Apple Silicon binaries (Dune's "default_arm64" context) it would give
`Ok Darwin_arm64`.

---

Let's also say you needed to link your code against the foreign C library "gmp".

Your `dune` script would typically look like:

```lisp
(library
 (name my_library)
 (c_library_flags
  :standard
  (:include c_library_flags.sexp))
 (foreign_stubs
  (language c)
  (names my_stubs)
  (flags
   :standard
   (:include c_flags.sexp))))

(rule
 (targets c_flags.sexp c_library_flags.sexp)
 (action
  (run
   ./config/discover.exe
   -context_name
   %{context_name}
   -ccomp_type
   %{ocaml-config:ccomp_type})))
```

In the above `dune` script the responsibility to supply the C
flags (ex. `-I/usr/local/include/gmp`) and C library flags
(ex. `-L/usr/local/lib/gmp -lgmp`) has been delegated
to `./config/discover.exe`.

You would use `C_conf` in the
[Dune Configurator based `config/discover.ml`](https://dune.readthedocs.io/en/stable/dune-libs.html)
to generate these flags:

```lisp
; file: config/dune
(executable
 (name discover)
 (libraries dune-configurator dkml-c-probe))
```

<!-- $MDX file=samples/discover.ml -->
```ocaml
(* file: config/discover.ml *)

module C = Configurator.V1

let () =
  let ctxname = ref "" in
  let ccomp_type = ref "" in
  let args =
    [
      ("-context_name", Arg.Set_string ctxname, "Dune %{context_name} variable");
      ( "-ccomp_type",
        Arg.Set_string ccomp_type,
        "Dune %{ocaml-config:ccomp_type} variable" );
    ]
  in
  C.main ~args ~name:"discover" (fun _c ->
      let cflags, clibraryflags =
        let open Dkml_c_probe.C_conf in
        match load_from_dune_context_name !ctxname with
        | Error msg ->
            failwith ("Failed loading C_conf in Dune Configurator. " ^ msg)
        | Ok conf -> (
            match
              compiler_flags_of_ccomp_type conf ~ccomp_type:!ccomp_type
                ~clibrary:"ffi"
            with
            | Error msg ->
                failwith ("Failed getting compiler flags from C_conf. " ^ msg)
            | Ok (Some fl) -> (C_flags.cc_flags fl, C_flags.link_flags fl)
            | Ok None ->
                (* We can't find the library! You could fall back
                   to pkg-config by using C.Pkg_config, or just have
                   a sane default. *)
                ([], [ "-lgmp" ]))
      in

      C.Flags.write_sexp "c_flags.sexp" cflags;
      C.Flags.write_sexp "c_library_flags.sexp" clibraryflags)
```

## Usage

Install it with:

<!-- $MDX non-deterministic=command -->
```console
$ opam install dkml-c-probe
```

Then either:
* Use the [OCaml Interfaces](#ocaml-interfaces) in your [Dune Configurator](https://dune.readthedocs.io/en/latest/dune-libs.html#configurator-1)
* Use the [C Header](#c-header) in your [foreign C stub code](https://dune.readthedocs.io/en/latest/foreign-code.html)

OCaml API documentation is at https://diskuv.github.io/dkml-c-probe/dkml-c-probe/Dkml_c_probe/index.html

## OCaml Interfaces

### C_abi

```console
$ ocaml samples/show_abi_signature.ml
module V3 = Dkml_c_probe.C_abi.V3
module V3 :
  sig
    type t_os =
        UnknownOS
      | Android
      | DragonFly
      | FreeBSD
      | IOS
      | Linux
      | NetBSD
      | OpenBSD
      | OSX
      | Windows
    type t_abi =
        Unknown_unknown
      | Android_arm32v7a
      | Android_arm64v8a
      | Android_x86
      | Android_x86_64
      | Darwin_arm64
      | Darwin_x86_64
      | DragonFly_x86_64
      | FreeBSD_x86_64
      | Linux_arm32v6
      | Linux_arm32v7
      | Linux_arm64
      | Linux_x86
      | Linux_x86_64
      | NetBSD_x86_64
      | OpenBSD_x86_64
      | Windows_arm32
      | Windows_arm64
      | Windows_x86
      | Windows_x86_64
    val get_os : unit -> (t_os, string) result
    val get_abi : unit -> (t_abi, string) result
    val get_abi_name : unit -> (string, string) result
  end
```

### C_conf

Extensive documentation is available at the
[C_conf documentation page](https://diskuv.github.io/dkml-c-probe/dkml-c-probe/Dkml_c_probe/C_conf/index.html)

Here is a quick peek at `C_conf`:

```console
$ ocaml samples/show_conf_signature.ml
module C_conf = Dkml_c_probe__.C_conf
module C_conf = Dkml_c_probe.C_conf
module C_conf :
  sig
    type t
    type env_getter = string -> string option
    module C_flags : sig ... end
    module Ocamlmklib_flags : sig ... end
    val load : ?getenv:env_getter -> unit -> (t, string) result
    val load_from_dune_context_name :
      ?getenv:env_getter -> string -> (t, string) result
    val load_from_findlib_toolchain :
      ?getenv:env_getter -> string option -> (t, string) result
    val compiler_flags_of_ccomp_type :
      t ->
      ccomp_type:string ->
      clibrary:string -> (C_flags.t option, string) result
    val compiler_flags_msvc :
      t -> clibrary:string -> (C_flags.t option, string) result
    val compiler_flags_gcc :
      t -> clibrary:string -> (C_flags.t option, string) result
    val tool_flags_ocamlmklib :
      t -> clibrary:string -> (Ocamlmklib_flags.t option, string) result
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
#       elif TARGET_CPU_PPC64
#           define DKML_ABI "darwin_ppc64"
#           define DKML_ABI_darwin_ppc64
#       endif /* TARGET_CPU_ARM64, TARGET_CPU_X86_64, TARGET_CPU_PPC64 */
#   elif TARGET_OS_IOS
#       define DKML_OS_NAME "IOS"
#       define DKML_OS_IOS
#       define DKML_ABI "darwin_arm64"
#       define DKML_ABI_darwin_arm64
#   endif /* TARGET_OS_OSX, TARGET_OS_IOS */
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__DragonFly__)
#   if __OpenBSD__
#       define DKML_OS_NAME "OpenBSD"
#       define DKML_OS_OpenBSD
#       if __x86_64__
#           define DKML_ABI "openbsd_x86_64"
#           define DKML_ABI_openbsd_x86_64
#       endif /* __x86_64__ */
#   elif __FreeBSD__
#       define DKML_OS_NAME "FreeBSD"
#       define DKML_OS_FreeBSD
#       if __x86_64__
#           define DKML_ABI "freebsd_x86_64"
#           define DKML_ABI_freebsd_x86_64
#       endif /* __x86_64__ */
#   elif __NetBSD__
#       define DKML_OS_NAME "NetBSD"
#       define DKML_OS_NetBSD
#       if __x86_64__
#           define DKML_ABI "netbsd_x86_64"
#           define DKML_ABI_netbsd_x86_64
#       endif /* __x86_64__ */
#   elif __DragonFly__
#       define DKML_OS_NAME "DragonFly"
#       define DKML_OS_DragonFly
#       if __x86_64__
#           define DKML_ABI "dragonfly_x86_64"
#           define DKML_ABI_dragonfly_x86_64
#       endif /* __x86_64__ */
#   endif /* __OpenBSD__, __FreeBSD__, __NetBSD__, __DragonFly__ */
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
#       elif defined(__ppc64__) || defined(__PPC64__)
#           define DKML_ABI "linux_ppc64"
#           define DKML_ABI_linux_ppc64
#       elif __s390x__
#           define DKML_ABI "linux_s390x"
#           define DKML_ABI_linux_s390x
#       endif /* __aarch64__, __arm__, __x86_64__, __i386__, __ppc64__ || __PPC64__, __s390x__ */
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

#ifndef DKML_OS_NAME
#   define DKML_OS_NAME "UnknownOS"
#   define DKML_OS_UnknownOS
#endif
#ifndef DKML_ABI
#   define DKML_ABI "unknown_unknown"
#   define DKML_ABI_unknown_unknown
#endif

#endif /* DKMLCOMPILERPROBE_H */
```

## Contributions

We are always looking for new ABIs! Each new ABI needs to have its own
maintainer.

If you are interested, head over to **[Your Contributions](CONTRIBUTORS.md)**.

## Status

| Status                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Syntax check](https://github.com/diskuv/dkml-c-probe/actions/workflows/test.yml/badge.svg)](https://github.com/diskuv/dkml-c-probe/actions/workflows/test.yml) |
