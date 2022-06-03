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

(* [read_file fname] gets the contents of [fname] *)
let read_file header_filename =
  let ch = open_in_bin header_filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

(* [dos2unix s] converts all CRLF sequences in [s] into LF. Assumes [s] is ASCII encoded. *)
let dos2unix s = 
  let slen = String.length s in
  let buf = Buffer.create slen in
  let rec loop i =
    match String.index_from_opt s i '\r' with
    | None  ->
      Buffer.add_substring buf s i (slen - i);
      Buffer.contents buf
    | Some j when j < (slen - 2) && String.unsafe_get s (j + 1) <> '\n' ->
      Buffer.add_substring buf s i (j + 1);
      loop (j + 2)
    | Some j ->
      Buffer.add_substring buf s i (j - i);
      Buffer.add_char buf '\n';
      loop (j + 2)
  in loop 0

(* Prints the file from the first argument in Sys.argv as:

   [[
     let contents = "..."
   ]]

   The file contents will have been trimmed for whitespace, and have all CRLF normalized into LF.
*)
let () =
  let filename = Sys.argv.(1) in
  let basename = Filename.basename filename in
  let file_as_ocaml_string =
    read_file filename |> String.trim |> dos2unix |> String.escaped
  in
  print_string ("let contents = \"" ^ file_as_ocaml_string ^ "\"\n");
  print_string ("let filename = \"" ^ Stdlib.String.escaped basename ^ "\"\n")
