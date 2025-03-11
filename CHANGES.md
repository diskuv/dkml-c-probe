## 3.2.0

* Add osname

## 3.1.0

* Fix bug with eol=CRLF not recognized on macOS .gitattributes
* Allow cross-compile dune build step

## 3.0.0

* Remove unnecessary `rresult`
* Remove `failwith`
* Add `Unknown` to `t_abi` and other sum types
* Avoid [compiler issues](https://github.com/owlbarn/eigen/issues/38) by
  defaulting to `Unknown` in the C header
* Add `C_conf` module
* Add OpenBSD, FreeBSD, NetBSD and DragonFly on x86_64 architectures
* Add CI for cross-compiling on macOS

## 2.0.0

* Add `Linux_x86`.
* Switch from `(t_os, Rresult.msg) result` to `(t_os, string) result` (ditto for `t_abi`).

## 1.0.0

Internal version.
