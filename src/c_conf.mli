(******************************************************************************)
(*  Copyright 2022 Diskuv, Inc.                                               *)
(*                                                                            *)
(*  Licensed under the Apache License, Version 2.0 (the "License");           *)
(*  you may not use this file except in compliance with the License.          *)
(*  You may obtain a copy of the License at                                   *)
(*                                                                            *)
(*      http://www.apache.org/licenses/LICENSE-2.0                            *)
(*                                                                            *)
(*  Unless required by applicable law or agreed to in writing, software       *)
(*  distributed under the License is distributed on an "AS IS" BASIS,         *)
(*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  *)
(*  See the License for the specific language governing permissions and       *)
(*  limitations under the License.                                            *)
(******************************************************************************)

(** Cross-compiler friendly configuration of C headers and libraries.

    {1 Problem}

    Let's take the C library "gmp" (GNU Multiprecision Bignum Library) as an
    example. Many OCaml libraries depend on it through the "conf-gmp" Opam package.
    However almost all "conf-*" packages use the system's package manager
    to install the C library or use "pkg-config" to locate the C library. So if
    the system were a Linux x86_64 system and the cross-compiling toolchain is for
    Android ARM64, the Android ARM64 executables should never be linked to the system
    Linux x86_64 C library "gmp".

    {1 Solution}

    A solution is to let the consumer define and link to pre-existing cross-compiled
    libraries.

    During cross-compilation each distinct toolchain would need its own
    external C libraries and perhaps C headers. This module lets the
    developer specify the locations of these libraries and headers by
    setting environment variables.

    The environment variables follow the grammar:

    {v
    variableName:
      'CP_' clibrary '_' type '_DEFAULT' ('_' toolchain)?
      ;
    clibrary:
      [A-ZA-Z0-9_]+
      ;
    toolchain:
      [A-ZA-Z0-9_]+
      ;
    type:
      'CP' | 'LINK'
      ;

    (*  Semicolons separate list items in a variable *)
    variableValue:
      listItem (';' listItem)*
      ;
    (*  Any 7-bit ASCII printable character are valid. Spaces are significant,
        and there are no space characters. *)
    listItem:
      ([\x20-\x7E] - ';')*
      ;
    v}

    Both ["<clibrary>"] and ["<toolchain>"] must be uppercased and sanitized with underscores.

    For example, the following environment variables can be set for the C library "gmp":

    {v
    CP_GMP_CC_DEFAULT                 = -IZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/include
    CP_GMP_CC_DEFAULT_DARWIN_X86_64   = -IZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/include
    CP_GMP_LINK_DEFAULT               = -LZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/lib;-lgmp
    CP_GMP_LINK_DEFAULT_DARWIN_X86_64 = -LZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/lib;-lgmp
    v}

    Semantically each environment variable is equivalent to an optional list of items. In particular:

    - An undefined environment variable and an empty environment variable are equivalent
      to an absent list (ie. [None])
    - Any empty list item is skipped. So you can use [";"] to mean [Some []]

    For CC type variables, each list item is a command line option:

    - ["-I<path>"] adds an include directory. The path should have forward slashes, even on Windows.

    For LINK type variables, each list item is a command line option:

    - ["-L<path>"] adds a library directory. The path should have forward slashes, even on Windows.
    - ["-l<library>"] adds a named library.

    There are no spaces between the command line option (ex. ["-L"]) and the option value.

    As a library author you can use this module to convert these CC and LINK variables
    into the paricular convention used by your OCaml tool or C compiler. For example, using
    the {!compiler_flags_msvc} in the ["darwin_x86_64"] toolchain will give you:

    {[
       let link_flags = ["-LIBPATH:Z:/build/darwin_x86_64/vcpkg_installed/x64-osx/lib"; "gmp.lib"]
       let cc_flags = ["-IZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/include"]
    ]}

    while using the {!tool_flags_ocamlmklib} in the same toolchain will give you:

    {[
       let link_flags = ["-LZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/lib"; "-lgmp"]
    ]}

    {1 Prerequisites}

    The consumer of your library will need:

    - cross-compiled toolchains named according to {!C_abi}'s ["get_abi_name"].
    - pre-existing cross-compiled libraries. The cross-compiled libraries are
      available from many sources:
      {ul
      {- development environments like Android Studio}
      {- C package managers like vcpkg and Conan}
      {- "sysroot" images}
      {- direct downloads from architecture specific package repositories}
      }
    - set environment variables that reference the pre-existing cross-compiled
      libraries. For an Opam switch you can use
      {{:https://opam.ocaml.org/doc/man/opam-option.html} opam option setenv+="CP_xxx=yyy"};
      the docs for setenv are at https://opam.ocaml.org/doc/Manual.html#opamfield-setenv

    {1 Integrations}

    When you are using the {{:https://dune.readthedocs.io/en/stable/dune-libs.html} Dune Configurator}
    you should:

    + Use the {!load_from_dune_context_name} constructor by supplying the Dune
      variable ["%{context_name}"]
    + Use {!compiler_flags_of_ccomp_type} to get the compiler flags by
      supplying the Dune variable ["%{ocaml-config:ccomp_type}"].

    Dune variables are described in the
    {{:https://dune.readthedocs.io/en/stable/concepts.html#variables-1} General Concepts of the Dune Docs}.
*)

(** {1 Module Documentation} *)

type t

type env_getter = string -> string option

(** Flags for C compilers *)
module C_flags : sig
  type t

  val cc_flags : t -> string list
  (** All C compiler flags, including the equivalents of -I *)

  val link_flags : t -> string list
  (** All C linker flags, including the equivalents of both -L and -l *)

  val link_flags_pathonly : t -> string list
  (** The C linker flags which are the equivalents of -L *)

  val link_flags_libonly : t -> string list
  (** The C linker flags whare are the equivalents of -l *)
end

(** Flags for ocamlmklib *)
module Ocamlmklib_flags : sig
  type t

  val lib_flags : t -> string list
  (** ocamlmklib flags including both -L and -l *)
end

val load : ?getenv:env_getter -> unit -> (t, string) result
(** [load ?getenv ()] creates C configuration from the current {!C_abi}.

    If there is an error getting the C configuration then the result
    it [Error "some error message"].

    Otherwise, the result is the C configuration [conf]. *)

val load_from_dune_context_name :
  ?getenv:env_getter -> string -> (t, string) result
(** [load_from_dune_context_name ?getenv ctxname] creates C configuration from the
    Dune variable ["%{context_name}"] that has been captured in [ctxname].

    Examples of ["%{context_name}"] are:

    - ["default"]
    - ["default.darwin_arm64"] *)

val load_from_findlib_toolchain :
  ?getenv:env_getter -> string option -> (t, string) result
(** [load_from_findlib_toolchain ?getenv toolchain_opt] creates C configuration from
    the optional findlib toolchain [toolchain_opt].

    Examples of [toolchain] are:

    - [None]
    - [Some "darwin_arm64"] *)

val compiler_flags_of_ccomp_type :
  t -> ccomp_type:string -> clibrary:string -> (C_flags.t option, string) result
(** [compiler_flags_of_ccomp_type conf ~ccomp_type ~clibrary] gets the compiler flags
    of the compiler identified by ["ocamlc -config"]'s [ccomp_type]
    from the C configuration [conf].

    If there is no C configuration for [clibrary], the result is [Ok None]. *)

val compiler_flags_msvc :
  t -> clibrary:string -> (C_flags.t option, string) result
(** [compiler_flags_msvc conf ~clibrary] gets the compiler flags
    for the MSVC compiler from the C configuration [conf].

    If there is no C configuration for [clibrary], the result is [Ok None]. *)

val compiler_flags_gcc :
  t -> clibrary:string -> (C_flags.t option, string) result
(** [compiler_flags_gcc conf ~clibrary] gets the compiler flags
    for the GCC compiler from the C configuration [conf].

    If there is no C configuration for [clibrary], the result is [Ok None]. *)

val tool_flags_ocamlmklib :
  t -> clibrary:string -> (Ocamlmklib_flags.t option, string) result
(** [tool_flags_ocamlmklib conf ~clibrary] gets the ocamlmklib flags
    from the C configuration [conf].

    If there is no C configuration for [clibrary], the result is [Ok None]. *)
