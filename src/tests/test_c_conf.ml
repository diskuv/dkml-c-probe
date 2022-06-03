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

open OUnit2
open Dkml_c_probe.C_conf

let getenv = function
  | "CP_GMP_LINK_DEFAULT" ->
      Some "-LZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/lib;-lgmp"
  | "CP_GMP_LINK_DEFAULT_DARWIN_X86_64" ->
      Some "-LZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/lib;-lgmp"
  | "CP_EXPLICIT_EMPTY_LINK_DEFAULT" -> Some ";"
  | "CP_GMP_CC_DEFAULT" ->
      Some "-IZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/include"
  | "CP_GMP_CC_DEFAULT_DARWIN_X86_64" ->
      Some "-IZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/include"
  | "CP_EXPLICIT_EMPTY_CC_DEFAULT" -> Some ";"
  | _ -> None

let test_is_loaded = function Ok _ -> () | Error msg -> assert_failure msg

let invalid_dune_context_name_suite =
  let conf = load_from_dune_context_name ~getenv "invalid_dune_context_name" in
  [
    ( "not is_loaded" >:: fun _ ->
      match conf with
      | Error _ -> ()
      | Ok _ ->
          assert_failure
            "The invalid Dune context name should not have been loaded" );
  ]

let c_includeflags ?(clibrary = "gmp") ?(f = compiler_flags_msvc) conf_res =
  match conf_res with
  | Error msg -> [ "<error> " ^ msg ]
  | Ok conf -> (
      match f conf ~clibrary with
      | Ok None -> [ "<missing library>" ]
      | Ok (Some flags) -> C_flags.cc_flags flags
      | Error msg -> [ "<error> " ^ msg ])

let c_libflags ?(clibrary = "gmp") ~f conf_res =
  match conf_res with
  | Error msg -> [ "<error> " ^ msg ]
  | Ok conf -> (
      match f conf ~clibrary with
      | Ok None -> [ "<missing library>" ]
      | Ok (Some flags) -> C_flags.link_flags flags
      | Error msg -> [ "<error> " ^ msg ])

let ocamlmklib_libflags ?(clibrary = "gmp") ~f conf_res =
  match conf_res with
  | Error msg -> [ "<error> " ^ msg ]
  | Ok conf -> (
      match f conf ~clibrary with
      | Ok None -> [ "<missing library>" ]
      | Ok (Some flags) -> Ocamlmklib_flags.lib_flags flags
      | Error msg -> [ "<error> " ^ msg ])

let printer_list_of_string v =
  Format.asprintf "%a"
    (fun fmt l ->
      let n = List.length l in
      List.iteri
        (fun i s ->
          if i = 0 then Format.fprintf fmt "[";
          if i > 0 then Format.fprintf fmt ",";
          Format.fprintf fmt "%s" s;
          if i = n - 1 then Format.fprintf fmt "]")
        l)
    v

let default_context_suite =
  let conf = load_from_dune_context_name ~getenv "default" in
  [
    ("is_loaded" >:: fun _ -> test_is_loaded conf);
    ( "include_flags" >:: fun _ ->
      assert_equal ~printer:printer_list_of_string
        [ "-IZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/include" ]
        (c_includeflags conf) );
    ( "include_flags for missing lib" >:: fun _ ->
      assert_equal ~printer:printer_list_of_string [ "<missing library>" ]
        (c_includeflags ~clibrary:"missing" conf) );
    ( "include_flags for explicitly empty flags" >:: fun _ ->
      assert_equal ~printer:printer_list_of_string []
        (c_includeflags ~clibrary:"explicit-empty" conf) );
    "ocamlmklib"
    >::: [
           ( "lib_flags" >:: fun _ ->
             assert_equal ~printer:printer_list_of_string
               [
                 "-LZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/lib";
                 "-lgmp";
               ]
               (ocamlmklib_libflags ~f:tool_flags_ocamlmklib conf) );
         ];
    "msvc"
    >::: [
           ( "lib_flags" >:: fun _ ->
             assert_equal ~printer:printer_list_of_string
               [
                 "-LIBPATH:Z:/build/darwin_arm64/vcpkg_installed/arm64-osx/lib";
                 "gmp.lib";
               ]
               (c_libflags ~f:compiler_flags_msvc conf) );
         ];
    "gcc"
    >::: [
           ( "lib_flags" >:: fun _ ->
             assert_equal ~printer:printer_list_of_string
               [
                 "-LZ:/build/darwin_arm64/vcpkg_installed/arm64-osx/lib";
                 "-lgmp";
               ]
               (c_libflags ~f:compiler_flags_gcc conf) );
         ];
  ]

let darwin_x86_64_context_suite =
  let conf = load_from_dune_context_name ~getenv "default.darwin_x86_64" in
  [
    ("is_loaded" >:: fun _ -> test_is_loaded conf);
    ( "include_flags" >:: fun _ ->
      assert_equal ~printer:printer_list_of_string
        [ "-IZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/include" ]
        (c_includeflags conf) );
    "msvc"
    >::: [
           ( "lib_flags" >:: fun _ ->
             assert_equal ~printer:printer_list_of_string
               [
                 "-LIBPATH:Z:/build/darwin_x86_64/vcpkg_installed/x64-osx/lib";
                 "gmp.lib";
               ]
               (c_libflags ~f:compiler_flags_msvc conf) );
         ];
    "gcc"
    >::: [
           ( "lib_flags" >:: fun _ ->
             assert_equal ~printer:printer_list_of_string
               [
                 "-LZ:/build/darwin_x86_64/vcpkg_installed/x64-osx/lib"; "-lgmp";
               ]
               (c_libflags ~f:compiler_flags_gcc conf) );
         ];
  ]

let full_suite =
  "c_conf"
  >::: [
         "invalid_dune_context_name" >::: invalid_dune_context_name_suite;
         "default" >::: default_context_suite;
         "default.darwin_x86_64" >::: darwin_x86_64_context_suite;
       ]

let () = run_test_tt_main full_suite
