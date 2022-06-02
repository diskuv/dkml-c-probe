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
  "dos2unix"
  >::: [
         ("pass_empty" >:: fun _ -> assert_equal "" (dos2unix ""));
         ("pass_lf" >:: fun _ -> assert_equal "\n" (dos2unix "\n"));
         ("shrink_crlf" >:: fun _ -> assert_equal "\n" (dos2unix "\r\n"));
         ("pass_cr" >:: fun _ -> assert_equal "\r" (dos2unix "\r"));
         ("pass_lf_lf" >:: fun _ -> assert_equal "\n\n" (dos2unix "\n\n"));
         ( "shrink_crlf_crlf" >:: fun _ ->
           assert_equal "\n\n" (dos2unix "\r\n\r\n") );
         ( "pass_textlf_textlf" >:: fun _ ->
           assert_equal "hi\nthere\n" (dos2unix "hi\nthere\n") );
         ( "shrink_textcrlf_textcrlf" >:: fun _ ->
           assert_equal "hi\nthere\n" (dos2unix "hi\r\nthere\r\n") );
       ]

let () = run_test_tt_main suite
