# Your Contributions

Diskuv Probe accepts Pull Requests (PRs)!

Before you start writing a PR, please be aware of three things:
1. The project code is under the Apache v2.0 license. People *will* be able
   to use your contributions for commercial code!
2. We only accept PRs that have signed the [Developer Certificate of Origin (DCO)](https://developercertificate.org/)
   license. You sign by including a `Signed-off-by` line
   with an email address that matches the commit author. For example, your
   commit message could look like:

   ```
   This is my commit message

   Signed-off-by: Random J Developer <random@developer.example.org>   
   ```
   
   or you can just use `git commit -s -m 'This is my commit message'`.
3. Especially if this is your first PR, it is helpful to open an issue first
   so your upcoming contribution idea can be sanity tested.

If you would like to add a new ABI, you will need to:

* Add the ABI introspection test to the C header at [src/config/dkml_compiler_probe.h](src/config/dkml_compiler_probe.h).
* Create a new versioned module (ex. `module V123`) of the ABI enumeration in
  [src/config/discover.ml](src/config/discover.ml). See how `module V2` extends `module V1` in a backwards-compatible way.
* Update the `(version xxx)` in [dune-project](dune-project)

Before submitting your PR make sure you have:
1. Run `dune build`
2. Run `dune build @runtest @runmarkdown --auto-promote`
