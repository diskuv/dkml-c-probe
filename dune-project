(lang dune 2.9)

(name dkml-c-probe)

(version 3.0.0)

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
 (synopsis
  "Cross-compiler friendly ABI and library discovery for OCaml's native C compilers")
 (description
  "dkml-c-probe simplifies the creation of cross-compiling compatible foreign C stub code. It includes two components:\n\nC_abi: Introspects OCaml's native C compiler, including cross-compilers, to determine the ABI those C compilers will generate\nC_conf: Supplies flags to C compilers and OCaml tools that specify the locations of C headers and C libraries")
 (depends
  (ocaml
   (>= 4.12.1))
  (ounit2
   (and
    (>= 2.2.0)
    :with-test))
  (mdx
   (and
    (>= 2.0.0)
    :with-test))
  (dune-configurator
   (and
    (>= 2.9)
    :build))))
