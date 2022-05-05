# dkml-c-probe

Introspects OCaml's native C compiler to determine the ABI used by executables
created by the C compiler. For example, if OCaml's native C compiler were
the following on a Apple Intel x86_64 build machine:

```console
$ ocamlopt -config
...
native_c_compiler: clang -arch x86_64

$ ocamlfind -toolchain darwin_arm64 ocamlopt -config
...
native_c_compiler: clang -arch arm64
```

then the ABI would be reported as `Darwin_x86_64` or `Darwin_arm64`
by dkml-c-probe, depending on which toolchain was used.
