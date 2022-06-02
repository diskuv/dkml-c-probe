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

open Configurator.V1
open Flags

type t_abi =
  | Android_arm64v8a
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

type osinfo = {
  ostypename : (string, string) result;
  abitypename : (string, string) result;
  abiname : (string, string) result;
}

let get_osinfo t =
  let header =
    let file = "discover_osinfo.h" in
    let fd = open_out file in
    output_string fd Dkml_compiler_probe_c_header.contents;
    close_out fd;
    file
  in
  let os_define =
    C_define.import t ~c_flags:[ "-I"; Sys.getcwd () ] ~includes:[ header ]
      [ ("DKML_OS_NAME", String) ]
  in
  let abi_define =
    C_define.import t ~c_flags:[ "-I"; Sys.getcwd () ] ~includes:[ header ]
      [ ("DKML_ABI", String) ]
  in

  let ostypename =
    match os_define with
    | [ (_, String ("Android" as x)) ] -> Result.ok x
    | [ (_, String ("IOS" as x)) ] -> Result.ok x
    | [ (_, String ("Linux" as x)) ] -> Result.ok x
    | [ (_, String ("OSX" as x)) ] -> Result.ok x
    | [ (_, String ("Windows" as x)) ] -> Result.ok x
    | _ ->
        failwith
          ("Unknown operating system: no detection found in "
         ^ Dkml_compiler_probe_c_header.filename)
  in

  let abitypename, abiname =
    match abi_define with
    | [ (_, String ("android_arm64v8a" as x)) ] ->
        (Result.ok "Android_arm64v8a", Result.ok x)
    | [ (_, String ("android_arm32v7a" as x)) ] ->
        (Result.ok "Android_arm32v7a", Result.ok x)
    | [ (_, String ("android_x86" as x)) ] ->
        (Result.ok "Android_x86", Result.ok x)
    | [ (_, String ("android_x86_64" as x)) ] ->
        (Result.ok "Android_x86_64", Result.ok x)
    | [ (_, String ("darwin_arm64" as x)) ] ->
        (Result.ok "Darwin_arm64", Result.ok x)
    | [ (_, String ("darwin_x86_64" as x)) ] ->
        (Result.ok "Darwin_x86_64", Result.ok x)
    | [ (_, String "darwin_ppc64") ] ->
        ( Result.error "Darwin_ppc64 is unsupported",
          Result.error "darwin_ppc64 is unsupported" )
    | [ (_, String ("linux_arm64" as x)) ] ->
        (Result.ok "Linux_arm64", Result.ok x)
    | [ (_, String ("linux_arm32v6" as x)) ] ->
        (Result.ok "Linux_arm32v6", Result.ok x)
    | [ (_, String ("linux_arm32v7" as x)) ] ->
        (Result.ok "Linux_arm32v7", Result.ok x)
    | [ (_, String ("linux_x86_64" as x)) ] ->
        (Result.ok "Linux_x86_64", Result.ok x)
    | [ (_, String ("linux_x86" as x)) ] -> (Result.ok "Linux_x86", Result.ok x)
    | [ (_, String "linux_ppc64") ] ->
        ( Result.error "Linux_ppc64 is unsupported",
          Result.error "linux_ppc64 is unsupported" )
    | [ (_, String "linux_s390x") ] ->
        ( Result.error "Linux_s390x is unsupported",
          Result.error "linux_s390x is unsupported" )
    | [ (_, String ("windows_x86_64" as x)) ] ->
        (Result.ok "Windows_x86_64", Result.ok x)
    | [ (_, String ("windows_x86" as x)) ] ->
        (Result.ok "Windows_x86", Result.ok x)
    | [ (_, String ("windows_arm64" as x)) ] ->
        (Result.ok "Windows_arm64", Result.ok x)
    | [ (_, String ("windows_arm32" as x)) ] ->
        (Result.ok "Windows_arm32", Result.ok x)
    | _ ->
        failwith
          ("Unknown platform: no detection found in "
         ^ Dkml_compiler_probe_c_header.filename)
  in

  { ostypename; abitypename; abiname }

let () =
  main ~name:"discover" (fun t ->
      let { ostypename; abitypename; abiname } = get_osinfo t in
      let result_to_string = function
        | Result.Ok v -> "Result.ok (" ^ v ^ ")"
        | Result.Error e -> "Result.error (\"" ^ String.escaped e ^ "\")"
      in
      let v1result_to_string r =
        match (r, abiname) with
        | _, Result.Ok "linux_x86" ->
            "Result.error (\"linux_x86 platform is only available in \
             Target_context.V2 or later\")"
        | Result.Ok v, _ -> result_to_string (Result.ok v)
        | Result.Error e, _ -> result_to_string (Result.error e)
      in
      let quote_string s = "\"" ^ s ^ "\"" in
      let to_lazy s = "lazy (" ^ s ^ ")" in

      write_lines "c_abi.ml"
        [
          (* As you expand the list of platforms and OSes make new versions! Make sure the new platforms and OS give back Result.error in older versions. *)
          {|(** New applications should use the {!V3} module instead. *)|};
          {|module V1 = struct|};
          {|  type t_os = Android | IOS | Linux | OSX | Windows|};
          {|  type t_abi =
              | Android_arm64v8a
              | Android_arm32v7a
              | Android_x86
              | Android_x86_64
              | Darwin_arm64
              | Darwin_x86_64
              | Linux_arm64
              | Linux_arm32v6
              | Linux_arm32v7
              | Linux_x86_64
              | Windows_x86_64
              | Windows_x86
              | Windows_arm64
              | Windows_arm32
          |};
          {|  let get_os : (t_os, string) result Lazy.t = |}
          ^ (v1result_to_string ostypename |> to_lazy);
          {|  let get_abi : (t_abi, string) result Lazy.t = |}
          ^ (v1result_to_string abitypename |> to_lazy);
          {|  let get_abi_name : (string, string) result Lazy.t = |}
          ^ (Result.map quote_string abiname |> v1result_to_string |> to_lazy);
          {|end (* module V1 *) |};
          {||};
          (* V2 *)
          {|(** New applications should use the {!V3} module instead. *)|};
          {|module V2 = struct|};
          {|  type t_os = Android | IOS | Linux | OSX | Windows|};
          {|  type t_abi =
              | Android_arm64v8a
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
          |};
          {|  let get_os : (t_os, string) result Lazy.t = |}
          ^ (result_to_string ostypename |> to_lazy);
          {|  let get_abi : (t_abi, string) result Lazy.t = |}
          ^ (result_to_string abitypename |> to_lazy);
          {|  let get_abi_name : (string, string) result Lazy.t = |}
          ^ (Result.map quote_string abiname |> result_to_string |> to_lazy);
          {|end (* module V2 *) |};
          {||};
          (* V3 *)
          {|(** Enumerations of the operating system and the ABI, typically from an introspection of OCaml's native C compiler. *)|};
          {|module V3 = struct|};
          {|  type t_os = Android | IOS | Linux | OSX | Windows|};
          {|  type t_abi =
              | Android_arm64v8a
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
          |};
          {|  let get_os : (t_os, string) result Lazy.t = |}
          ^ (result_to_string ostypename |> to_lazy);
          {|  let get_abi : (t_abi, string) result Lazy.t = |}
          ^ (result_to_string abitypename |> to_lazy);
          {|  let get_abi_name : (string, string) result Lazy.t = |}
          ^ (Result.map quote_string abiname |> result_to_string |> to_lazy);
          {|end (* module V3 *) |};
        ])
