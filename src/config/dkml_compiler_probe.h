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
