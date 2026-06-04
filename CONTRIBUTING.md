# Contributing to Sangaku

Sangaku is a proof-carrying computer algebra system in Lisp, running on the
[Lizard](https://github.com/hydrastro/lizard) interpreter. The guiding discipline is that **every
positive result carries a machine-checkable certificate**, and a contribution is good when a
reviewer can run it and watch the certificate check out.

## Building and testing

Sangaku has nothing to compile — it is interpreted Lisp. "Building" means running the suite against
the interpreter.

```sh
nix develop                  # Lizard on PATH, helper env set
bash scripts/test.sh         # golden tests + example suite
bash scripts/run-examples.sh # examples only (quicker)
scripts/sangaku FILE.lisp    # run one file with the library on the path
```

Without Nix, set `LIZARD` to a Lizard binary (or put `lizard` on `PATH`) and run the same scripts.

## How a module is structured

Library code lives in `src/cas/`. A module is imported by the path it presents to the engine, e.g.
`(import "cas/poly.lisp")`; the [prelude](src/prelude.lisp) puts `src/` on the module search path so
those imports resolve. Each module opens with a header comment stating what it does, the
mathematics it relies on, its public functions, and what it verifies, followed by its imports and
definitions.

A few interpreter conventions worth knowing (Lizard specifics):

- `if` takes exactly three arguments; use `cond` for multi-way branches.
- `max` and `min` are binary.
- Prefer top-level prefixed helper functions over internal `define`s and deeply nested `let`s.
- Polynomials are coefficient lists, low-to-high: `(1 0 2)` is `1 + 2x²`.
- A bare top-level expression is echoed by the interpreter — bind throwaway values with `define`
  (as the prelude does) so they do not corrupt golden output.

## The per-feature workflow

1. **Verify the mathematics first**, by hand or in a scratch file, on concrete inputs. The strongest
   validation is two independent methods agreeing.
2. **Check for name collisions** before adding a module: grep `src/` for the module name and your
   function prefix.
3. **Write the module** in `src/cas/` with a full header and a unique prefix.
4. **Test every case, including the honest-failure controls** — a sound function returns a definite
   "don't know" (e.g. `not-integral`, `independent`, `no-real-form`) rather than a guess; test those
   paths too.
5. **Add an example** in `examples/NNN-name.lisp` that demonstrates and checks the feature, guarding
   each assertion so a failure raises.
6. **Add a golden test** `tests/cas_name.lisp` whose stdout is recorded in `tests/cas_name.expected`
   (generate once, then re-run and diff to confirm determinism).
7. **Re-run `scripts/test.sh`** and expect zero regressions.
8. **Document** the capability in `docs/CAS.md`, and update `docs/LIMITATIONS.md` if the scope of
   what works changed.

## Certificates and honest scope

Preserve the central discipline: the arbiter must be independent of the method. Do not add a code
path that returns an uncertified positive result, and do not weaken an honest "don't know" into a
guess. When you reach a genuine open problem, name it precisely in the docs and the roadmap rather
than papering over it. This is what makes the system trustworthy and is non-negotiable.

## Generating a golden

```sh
# produce the expected output, then confirm it is reproducible
cat src/prelude.lisp tests/cas_NAME.lisp | "$LIZARD" > tests/cas_NAME.expected
cat src/prelude.lisp tests/cas_NAME.lisp | "$LIZARD" | diff - tests/cas_NAME.expected && echo deterministic
```

## Submitting

Keep changes additive where possible, each with the example and golden that prove the behavior. A
good change is one a reviewer can verify by running `scripts/test.sh` and reading the new example.
