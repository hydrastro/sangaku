# Sangaku

A **proof-carrying computer algebra system**, written in Lisp.

In a *sangaku* (算額), a mathematician inscribes a theorem on a wooden tablet and hangs it at a
shrine — a result offered in public, for anyone to check. This system is built in that spirit:
**every positive result it produces carries a machine-checkable certificate.** An integral comes
with a differentiation check; an ideal membership with a reduction modulo a Gröbner basis; a
solution tuple with an exact evaluation to zero; a non-elementarity claim with a finite proof.
Where a problem is genuinely open, Sangaku says so precisely rather than guessing.

Sangaku is the computer-algebra library; it runs on the
[**Lizard**](https://github.com/hydrastro/lizard) interpreter and its trusted dependent-type
kernel. Sangaku itself is pure Lisp — about 21,000 lines across 239 modules — with no compiled
component of its own.

## What it can do

- **Integration with proof.** Symbolic integration in the Risch tradition: rational and
  transcendental towers (exp/log), the algebraic case (integrals over `Q(x)[y]`), elliptic and
  hyperelliptic integrals, and decision procedures that prove an integral *non-elementary* when it
  is. Definite integrals are returned as theorems (`∫₀¹x² dx = 1/3`, with an FTC proof record), and
  classically hard values like the Dirichlet/sinc integral `∫₀^∞ sin(x)/x dx = π/2` are proved by
  the parameter-integral method with each lemma certified.
- **Algebraic geometry & number theory.** Gröbner bases (Buchberger and an F4-style linear-algebra
  core), integral closure of function fields (finite, nodal, and ramified places), Puiseux
  expansions, Jacobian group laws and torsion decisions, genus computations, and polynomial Pell /
  continued-fraction unit finding with an unconditional aperiodicity certificate.
- **A lightweight axiom mode.** State a set of axioms once, then ask whether any statement is
  *proven*, *disproven*, or *independent* — a sound three-valued front end over a Horn-clause
  engine, with contradictory axiom sets flagged rather than hidden.

Every capability above is exercised by a runnable example in [`examples/`](examples/) and pinned by
a golden test in [`tests/`](tests/).

## Quick start

Sangaku runs on the Lizard interpreter. The easiest path is Nix, which fetches Lizard for you:

```sh
nix develop          # drops you in a shell with Lizard available
sangaku-run examples/388-definite-integral-theorems.lisp
bash scripts/test.sh # run the golden + example suite
```

Or, with a Lizard binary already on your `PATH` (or pointed to by `$LIZARD`):

```sh
scripts/sangaku examples/389-sinc-dirichlet-theorem.lisp
bash scripts/test.sh
```

A Sangaku program is just Lisp that imports from the library:

```lisp
(import "cas/defint.lisp")
(display (dint-prove (list 0 0 1) 0 1)) (newline)
;; => (theorem (definite-integral (0 0 1) 0 1) = 1/3
;;      (by FTC (antiderivative (0 0 0 1/3)) (certificate F-prime=f #t)))
```

The launcher feeds the [prelude](src/prelude.lisp) (which puts the library on the import path)
and your file to Lizard together, so `(import "cas/...")` resolves with no further setup.

## Layout

```
src/            the Sangaku library
  cas/          239 modules: integration, Gröbner, function fields, ...
  logic.lisp    the Horn-clause engine (used by the axiom mode)
  prelude.lisp  registers the library on the module search path
examples/       243 runnable, self-checking examples
tests/          golden tests (cas_*.lisp + cas_*.expected), byte-for-byte
docs/           design notes and the capability/roadmap writeups
scripts/        sangaku (launcher), test.sh, run-examples.sh
flake.nix       Nix build/dev shell; fetches the Lizard interpreter
```

## How the certificates work

The guiding discipline is that the **arbiter is independent of the method**. Sangaku may use an
elaborate algorithm to *find* an antiderivative, but the claim "this is an antiderivative" is
discharged by differentiating the answer and checking equality — a computation that does not trust
the integrator. Likewise an ideal-membership claim is checked by reduction, a solution by
substitution, a span by re-reduction, and a non-elementarity result by exhibiting a closed
continued-fraction cycle. The strongest checks are two independent computations agreeing (a genus
from Riemann–Hurwitz against a genus from a closed formula, a Pell verdict against a bounded
search). Results that cannot be certified are reported as honest "don't know" verdicts, never as
guesses.

## Relationship to Lizard

[Lizard](https://github.com/hydrastro/lizard) is the interpreter, runtime, and trusted kernel;
Sangaku is the mathematics built on top. The two are developed separately: Sangaku pins Lizard as a
flake input, and the test suite runs Sangaku against that interpreter. If you change the library,
`scripts/test.sh` re-checks every certificate against the engine.

## License

Not yet selected — see [`LICENSE`](LICENSE). Until a license is chosen, no usage rights are granted
beyond reading.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). In short: verify the mathematics first, give every new
capability an example and a golden test, keep the certificate-and-honest-scope discipline, and run
`scripts/test.sh` before submitting.
