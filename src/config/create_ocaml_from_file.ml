open Astring

(* [read_file fname] gets the contents of [fname] *)
let read_file header_filename =
  let ch = open_in_bin header_filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

(* [dos2unix s] converts all CRLF sequences in [s] into LF. Assumes [s] is ASCII encoded. *)
let dos2unix s = String.concat ~sep:"\n" @@ String.cuts ~sep:"\r\n" s

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
    read_file filename |> String.trim |> dos2unix |> String.Ascii.escape_string
  in
  print_string ("let contents = \"" ^ file_as_ocaml_string ^ "\"\n");
  print_string ("let filename = \"" ^ Stdlib.String.escaped basename ^ "\"\n")
