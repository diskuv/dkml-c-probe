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
  osname: (string, string) result;
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
    | [ (_, String ("UnknownOS" as x)) ] -> Result.ok x
    | [ (_, String ("Android" as x)) ] -> Result.ok x
    | [ (_, String ("DragonFly" as x)) ] -> Result.ok x
    | [ (_, String ("FreeBSD" as x)) ] -> Result.ok x
    | [ (_, String ("IOS" as x)) ] -> Result.ok x
    | [ (_, String ("Linux" as x)) ] -> Result.ok x
    | [ (_, String ("NetBSD" as x)) ] -> Result.ok x
    | [ (_, String ("OpenBSD" as x)) ] -> Result.ok x
    | [ (_, String ("OSX" as x)) ] -> Result.ok x
    | [ (_, String ("Windows" as x)) ] -> Result.ok x
    | _ ->
        Result.error
          ("Unknown operating system: no detection found in "
         ^ Dkml_compiler_probe_c_header.filename)
  in
  let osname = Result.map String.lowercase_ascii ostypename in

  let abitypename =
    match abi_define with
    | [ (_, String ("unknown_unknown")) ] ->
        (Result.ok "Unknown_unknown")
    | [ (_, String ("android_arm64v8a")) ] ->
        (Result.ok "Android_arm64v8a")
    | [ (_, String ("android_arm32v7a")) ] ->
        (Result.ok "Android_arm32v7a")
    | [ (_, String ("android_x86")) ] ->
        (Result.ok "Android_x86")
    | [ (_, String ("android_x86_64")) ] ->
        (Result.ok "Android_x86_64")
    | [ (_, String ("darwin_arm64")) ] ->
        (Result.ok "Darwin_arm64")
    | [ (_, String ("darwin_x86_64")) ] ->
        (Result.ok "Darwin_x86_64")
    | [ (_, String "darwin_ppc64") ] ->
        (Result.ok "Unknown_unknown")
    | [ (_, String ("linux_arm64")) ] ->
        (Result.ok "Linux_arm64")
    | [ (_, String ("linux_arm32v6")) ] ->
        (Result.ok "Linux_arm32v6")
    | [ (_, String ("linux_arm32v7")) ] ->
        (Result.ok "Linux_arm32v7")
    | [ (_, String ("linux_x86_64")) ] ->
        (Result.ok "Linux_x86_64")
    | [ (_, String ("linux_x86")) ] -> (Result.ok "Linux_x86")
    | [ (_, String "linux_ppc64") ] ->
        (Result.ok "Unknown_unknown")
    | [ (_, String "linux_s390x") ] ->
        (Result.ok "Unknown_unknown")
    | [ (_, String ("windows_x86_64")) ] ->
        (Result.ok "Windows_x86_64")
    | [ (_, String ("windows_x86")) ] ->
        (Result.ok "Windows_x86")
    | [ (_, String ("windows_arm64")) ] ->
        (Result.ok "Windows_arm64")
    | [ (_, String ("windows_arm32")) ] ->
        (Result.ok "Windows_arm32")
    | [ (_, String ("dragonfly_x86_64")) ] ->
        (Result.ok "DragonFly_x86_64")
    | [ (_, String ("freebsd_x86_64")) ] ->
        (Result.ok "FreeBSD_x86_64")
    | [ (_, String ("netbsd_x86_64")) ] ->
        (Result.ok "NetBSD_x86_64")
    | [ (_, String ("openbsd_x86_64")) ] ->
        (Result.ok "OpenBSD_x86_64")
    | _ ->
        let msg =
          "Unknown ABI: no detection found in "
          ^ Dkml_compiler_probe_c_header.filename
        in
        (Result.error msg)
  in
  let abiname = Result.map String.lowercase_ascii abitypename in

  { ostypename; osname; abitypename; abiname }

let result_to_string = function
  | Result.Ok v -> "Result.ok (" ^ v ^ ")"
  | Result.Error e -> "Result.error (\"" ^ String.escaped e ^ "\")"

let result_to_quoted_string = function
  | Result.Ok v -> "Result.ok (\"" ^ v ^ "\")"
  | Result.Error e -> "Result.error (\"" ^ String.escaped e ^ "\")"

let adjust_pre_v2_abi ~abitypename ~abiname =
  match (abitypename, abiname) with
  | Result.Ok "Linux_x86", _ | _, Result.Ok "linux_x86" ->
      let err =
        Result.error
          "linux_x86 ABI is only available in Target_context.V2 or later"
      in
      (err, err)
  | Result.Ok tn, Result.Ok n -> (Result.ok tn, Result.ok n)
  | Result.Error e, _ | _, Result.Error e -> (Result.error e, Result.error e)

let adjust_pre_v3_os ~ostypename ~osname =
  match ostypename, osname with
  | Result.Ok "UnknownOS", _ ->
      let e = "'UnknownOS' OS is only available in Target_context.V3 or later" in
      Result.Error e, Result.Error e
  | Result.Ok "OpenBSD", _ ->
      let e = "'OpenBSD' OS is only available in Target_context.V3 or later" in
      Result.Error e, Result.Error e
  | Result.Ok "FreeBSD", _ ->
      let e = "'FreeBSD' OS is only available in Target_context.V3 or later" in
      Result.Error e, Result.Error e
  | Result.Ok "NetBSD", _ ->
      let e =  "'NetBSD' OS is only available in Target_context.V3 or later" in
      Result.Error e, Result.Error e
  | Result.Ok "DragonFly", _ ->
      let e = "'DragonFly' OS is only available in Target_context.V3 or later" in
      Result.Error e, Result.Error e
  | Result.Ok tn, Result.Ok n -> (Result.ok tn, Result.ok n)
  | Result.Error e, _ | _, Result.Error e -> (Result.error e, Result.error e)

let adjust_pre_v3_abi ~abitypename ~abiname =
  match (abitypename, abiname) with
  | Result.Ok "Unknown_unknown", _ | _, Result.Ok "unknown_unknown" ->
      let err =
        Result.error
          "'Unknown_unknown' ABI is only available in Target_context.V3 or \
           later"
      in
      (err, err)
  | Result.Ok "OpenBSD_x86_64", _ | _, Result.Ok "openbsd_x86_64" ->
      let err =
        Result.error
          "'OpenBSD_x86_64' ABI is only available in Target_context.V3 or later"
      in
      (err, err)
  | Result.Ok "FreeBSD_x86_64", _ | _, Result.Ok "freebsd_x86_64" ->
      let err =
        Result.error
          "'FreeBSD_x86_64' ABI is only available in Target_context.V3 or later"
      in
      (err, err)
  | Result.Ok "NetBSD_x86_64", _ | _, Result.Ok "netbsd_x86_64" ->
      let err =
        Result.error
          "'NetBSD_x86_64' ABI is only available in Target_context.V3 or later"
      in
      (err, err)
  | Result.Ok "DragonFly_x86_64", _ | _, Result.Ok "dragonfly_x86_64" ->
      let err =
        Result.error
          "'DragonFly_x86_64' ABI is only available in Target_context.V3 or \
           later"
      in
      (err, err)
  | Result.Ok tn, Result.Ok n -> (Result.ok tn, Result.ok n)
  | Result.Error e, _ | _, Result.Error e -> (Result.error e, Result.error e)

let () =
  main ~name:"discover" (fun t ->
      let { ostypename; osname; abitypename; abiname } = get_osinfo t in
      let to_unit_fun s = "fun () -> " ^ s in

      let finish_module ~v ~ostypename ~osname ~abitypename ~abiname =
        [
          {|  let get_os : unit -> (t_os, string) result = |}
          ^ (result_to_string ostypename |> to_unit_fun);
          {|  let get_os_name : unit -> (string, string) result = |}
          ^ (result_to_quoted_string osname |> to_unit_fun);
          {|  let get_abi : unit -> (t_abi, string) result = |}
          ^ (result_to_string abitypename |> to_unit_fun);
          {|  let get_abi_name : unit -> (string, string) result = |}
          ^ (result_to_quoted_string abiname |> to_unit_fun);
          {|end (* module |} ^ v ^ {| *) |};
          {||};
        ]
      in

      (* As you expand the list of platforms and OSes make new versions! Make sure the new ABIs
         and OS give back Result.error in older versions. *)
      let lines = [] in

      (* V1 *)
      let lines =
        let abitypename, abiname = adjust_pre_v2_abi ~abitypename ~abiname in
        let abitypename, abiname = adjust_pre_v3_abi ~abitypename ~abiname in
        let ostypename, osname = adjust_pre_v3_os ~ostypename ~osname in
        lines
        @ [
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
          ]
        @ finish_module ~v:"V1" ~ostypename ~osname ~abitypename ~abiname
      in

      (* V2 *)
      let lines =
        let abitypename, abiname = adjust_pre_v3_abi ~abitypename ~abiname in
        let ostypename, osname = adjust_pre_v3_os ~ostypename ~osname in
        lines
        @ [
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
          ]
        @ finish_module ~v:"V2" ~ostypename ~osname ~abitypename ~abiname
      in

      (* V3.

         We did not introduce `t_os = Unknown | ...` and `t_abi = `Unknown | ...` because
         dealing with the same type constructor name is hard (and confusing) in OCaml.
         Instead we introduced `UnknownOS` and `Unknown_unknown`.

         Also for parsing the ABI 'unknown_unknown' follows the ABI pattern of having at
         least two terms separated by an underscore.
      *)
      let lines =
        lines
        @ [
            {|(** Enumerations of the operating system and the ABI, typically from an introspection of OCaml's native C compiler. *)|};
            {|module V3 = struct|};
            {|  type t_os =
              | UnknownOS
              | Android
              | DragonFly
              | FreeBSD
              | IOS
              | Linux
              | NetBSD
              | OpenBSD
              | OSX
              | Windows
              |};
            {|  type t_abi =
              | Unknown_unknown
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
              |};
          ]
        @ finish_module ~v:"V3" ~ostypename ~osname ~abitypename ~abiname
      in

      write_lines "c_abi.ml" lines)
