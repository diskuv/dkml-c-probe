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
open Probe_common

let suite =
  "normalize_into_upper_alnum"
  >::: [
         ( "pass_empty" >:: fun _ ->
           assert_equal "" (normalize_into_upper_alnum "") );
         ( "underscore_lf" >:: fun _ ->
           assert_equal "_" (normalize_into_upper_alnum "\n") );
         ( "underscore_crlf" >:: fun _ ->
           assert_equal "__" (normalize_into_upper_alnum "\r\n") );
         ( "upcase_lower" >:: fun _ ->
           assert_equal "ABC" (normalize_into_upper_alnum "abc") );
         ( "pass_digits" >:: fun _ ->
           assert_equal "3489765" (normalize_into_upper_alnum "3489765") );
         ( "underscore_non_alnum" >:: fun _ ->
           assert_equal "____" (normalize_into_upper_alnum "@#%^") );
         ( "upcase_underscore_phrase" >:: fun _ ->
           assert_equal "HELLO__WORLD_"
             (normalize_into_upper_alnum "Hello, World!") );
       ]

let () = run_test_tt_main suite
