(* file: config/discover.ml *)

module C = Configurator.V1

let () =
  let ctxname = ref "" in
  let ccomp_type = ref "" in
  let args =
    [
      ("-context_name", Arg.Set_string ctxname, "Dune %{context_name} variable");
      ( "-ccomp_type",
        Arg.Set_string ccomp_type,
        "Dune %{ocaml-config:ccomp_type} variable" );
    ]
  in
  C.main ~args ~name:"discover" (fun _c ->
      let cflags, clibraryflags =
        let open Dkml_c_probe.C_conf in
        match load_from_dune_context_name !ctxname with
        | Error msg ->
            failwith ("Failed loading C_conf in Dune Configurator. " ^ msg)
        | Ok conf -> (
            match
              compiler_flags_of_ccomp_type conf ~ccomp_type:!ccomp_type
                ~clibrary:"ffi"
            with
            | Error msg ->
                failwith ("Failed getting compiler flags from C_conf. " ^ msg)
            | Ok (Some fl) -> (C_flags.cc_flags fl, C_flags.link_flags fl)
            | Ok None ->
                (* We can't find the library! You could fall back
                   to pkg-config by using C.Pkg_config, or just have
                   a sane default. *)
                ([], [ "-lgmp" ]))
      in

      C.Flags.write_sexp "c_flags.sexp" cflags;
      C.Flags.write_sexp "c_library_flags.sexp" clibraryflags)
