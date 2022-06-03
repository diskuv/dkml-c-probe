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

type t = {
  envname_suffixes : string list;
      (** suffixes for the environment variables, in precedence order *)
  env_getter : env_getter;
}

and env_getter = string -> string option

let default_env_getter = Sys.getenv_opt

type t_env = { cc_flags : t_cc_flag list; link_flags : t_link_flag list }

and t_link_flag = Libpath of string | Library of string

and t_cc_flag = Includepath of string

module C_flags = struct
  type t = {
    c_cc_flags : string list;
    c_link_flags : string list;
    c_link_flags_pathonly : string list;
    c_link_flags_libonly : string list;
  }

  let cc_flags { c_cc_flags; _ } = c_cc_flags

  let link_flags { c_link_flags; _ } = c_link_flags

  let link_flags_pathonly { c_link_flags_pathonly; _ } = c_link_flags_pathonly

  let link_flags_libonly { c_link_flags_libonly; _ } = c_link_flags_libonly
end

module Ocamlmklib_flags = struct
  type t = { om_lib_flags : string list }

  let lib_flags { om_lib_flags; _ } = om_lib_flags
end

let load_from_findlib_toolchain ?(getenv = default_env_getter) = function
  | None -> Ok { envname_suffixes = [ "DEFAULT" ]; env_getter = getenv }
  | Some toolchain ->
      Ok
        {
          envname_suffixes =
            [
              (* Search for ABI-specific settings first *)
              "DEFAULT_" ^ Probe_common.normalize_into_upper_alnum toolchain;
              "DEFAULT";
            ];
          env_getter = getenv;
        }

let default_dot = "default."

let l_default_dot = String.length default_dot

let load_from_dune_context_name ?(getenv = default_env_getter) ctxname =
  let l = String.length ctxname in
  let create_error () =
    Error
      ("The Dune context name '" ^ ctxname
     ^ "' is not 'default' or 'default.NAME'")
  in
  if l > l_default_dot then
    if String.sub ctxname 0 l_default_dot = default_dot then
      let after_default_dot =
        String.sub ctxname l_default_dot (l - l_default_dot)
      in
      load_from_findlib_toolchain ~getenv (Some after_default_dot)
    else create_error ()
  else if ctxname = "default" then load_from_findlib_toolchain ~getenv None
  else create_error ()

let load ?(getenv = default_env_getter) () =
  let abi_name_res = Lazy.force C_abi.V3.get_abi_name in
  match abi_name_res with
  | Ok abi_name -> load_from_findlib_toolchain ~getenv (Some abi_name)
  | Error msg -> Error msg

let parse_nonempty s =
  String.split_on_char ';' s |> List.filter (fun s -> String.length s > 0)

let parse_short_opt s =
  let l = String.length s in
  if l >= 2 && s.[0] = '-' then Ok (s.[1], String.sub s 2 (l - 2))
  else Error ("The list item '" ^ s ^ "' is not a command line option")

let parse_link_flags s =
  parse_nonempty s
  |> List.fold_left
       (fun acc_res item ->
         match (acc_res, parse_short_opt item) with
         | Error msg, _ | _, Error msg -> Error msg
         | Ok acc, Ok ('L', value) -> Ok (Libpath value :: acc)
         | Ok acc, Ok ('l', value) -> Ok (Library value :: acc)
         | Ok _, Ok (c, _) -> Error ("Invalid option: -" ^ String.make 1 c))
       (Ok [])

let parse_cc_flags s =
  parse_nonempty s
  |> List.fold_left
       (fun acc_res item ->
         match (acc_res, parse_short_opt item) with
         | Error msg, _ | _, Error msg -> Error msg
         | Ok acc, Ok ('I', value) -> Ok (Includepath value :: acc)
         | Ok _, Ok (c, _) -> Error ("Invalid option: -" ^ String.make 1 c))
       (Ok [])

let parse_env_helper ~envname_suffix ~env_getter ~clibrary =
  let envname part =
    "CP_"
    ^ Probe_common.normalize_into_upper_alnum clibrary
    ^ "_" ^ part ^ "_" ^ envname_suffix
  in
  let envvalue part =
    (* Get from the environment. Treat empty = unset. *)
    match env_getter (envname part) with
    | None | Some "" -> None
    | Some v -> Some v
  in
  match (envvalue "CC", envvalue "LINK") with
  | None, None | Some _, None | None, Some _ -> Ok None
  | Some cc_str, Some link_str -> (
      match (parse_cc_flags cc_str, parse_link_flags link_str) with
      | Ok cc_flags, Ok link_flags ->
          Ok
            (Some
               {
                 cc_flags = List.rev cc_flags;
                 link_flags = List.rev link_flags;
               })
      | Error msg, _ | _, Error msg -> Error msg)

let parse_env { envname_suffixes; env_getter } ~clibrary =
  let rec search_in_suffixes = function
    | [] -> Ok None
    | envname_suffix :: remaining_suffixes -> (
        match parse_env_helper ~envname_suffix ~env_getter ~clibrary with
        | Error e -> Error e
        | Ok (Some v) -> Ok (Some v)
        | Ok None -> search_in_suffixes remaining_suffixes)
  in
  search_in_suffixes envname_suffixes

let filter_link_flags_pathonly = function Libpath _ -> true | _ -> false

let filter_link_flags_libonly = function Library _ -> true | _ -> false

let compiler_flags_msvc conf ~clibrary =
  match parse_env conf ~clibrary with
  | Error msg -> Error msg
  | Ok None -> Ok None
  | Ok (Some { cc_flags; link_flags }) ->
      let f_link_flags = function
        | Libpath p -> "-LIBPATH:" ^ p
        | Library l -> l ^ ".lib"
      in
      Ok
        (Some
           {
             C_flags.c_cc_flags =
               List.map (function Includepath p -> "-I" ^ p) cc_flags;
             c_link_flags = List.map f_link_flags link_flags;
             c_link_flags_pathonly =
               List.filter filter_link_flags_pathonly link_flags
               |> List.map f_link_flags;
             c_link_flags_libonly =
               List.filter filter_link_flags_libonly link_flags
               |> List.map f_link_flags;
           })

let compiler_flags_gcc conf ~clibrary =
  match parse_env conf ~clibrary with
  | Error msg -> Error msg
  | Ok None -> Ok None
  | Ok (Some { cc_flags; link_flags }) ->
      let f_link_flags = function
        | Libpath p -> "-L" ^ p
        | Library l -> "-l" ^ l
      in
      Ok
        (Some
           {
             C_flags.c_cc_flags =
               List.map (function Includepath p -> "-I" ^ p) cc_flags;
             c_link_flags = List.map f_link_flags link_flags;
             c_link_flags_pathonly =
               List.filter filter_link_flags_pathonly link_flags
               |> List.map f_link_flags;
             c_link_flags_libonly =
               List.filter filter_link_flags_libonly link_flags
               |> List.map f_link_flags;
           })

let compiler_flags_of_ccomp_type conf ~ccomp_type ~clibrary =
  match ccomp_type with
  | "msvc" -> compiler_flags_msvc conf ~clibrary
  | _ -> compiler_flags_gcc conf ~clibrary

let tool_flags_ocamlmklib conf ~clibrary =
  match parse_env conf ~clibrary with
  | Error msg -> Error msg
  | Ok None -> Ok None
  | Ok (Some { link_flags; _ }) ->
      Ok
        (Some
           {
             Ocamlmklib_flags.om_lib_flags =
               List.map
                 (function Libpath p -> "-L" ^ p | Library l -> "-l" ^ l)
                 link_flags;
           })
