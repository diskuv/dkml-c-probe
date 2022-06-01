(lang dune 2.9)
(name dkml-c-probe)
(version 2.0.0)

(using mdx 0.1)

(generate_opam_files true)

(source
 (github diskuv/dkml-c-probe))
(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
(maintainers "opensource+diskuv-ocaml@support.diskuv.com")
(homepage "https://github.com/diskuv/dkml-c-probe#readme")
(bug_reports "https://github.com/diskuv/dkml-c-probe/issues")

(package
 (name dkml-c-probe)
 (synopsis "Cross-compiler friendly characterizations of the OCaml's native C compiler")
 (description "Using the C compiler of ocamlopt -config, which may be a cross-compiler, vends an OCaml module with enumerations of the target operating system and ABI, and a C header that introspects the same at compile time")
 (depends
  (ocaml    (>= 4.12.1))
  (rresult  (>= 0.6.0))
  (astring  (>= 0.8.5))
  (mdx      (and (>= 2.0.0) :with-test))
  (dune-configurator (and (>= 2.9) :build))))
