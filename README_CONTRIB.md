# Sangaku contribution: cas/dynsys.lisp — dynamical-systems primitives

Drop these into the Sangaku source tree (same paths). Adds exact, certificate-
backed dynamical-systems analysis built on cas/groebner.lisp (multivariate
polynomials) and cas/linalg.lisp (exact eigenvalues):

  src/cas/dynsys.lisp                  the module
  tests/cas_dynsys.lisp + .expected    golden test (byte-for-byte, verified deterministic)
  examples/392-dynamical-systems.lisp  runnable, self-checking example

## What it adds (none of these existed in src/ before)
- mpoly-deriv p i        partial derivative of a multivariate polynomial
- vf-jacobian F nv       Jacobian of a polynomial vector field (matrix of mpolys)
- jacobian-at F nv pt    that Jacobian at a rational point -> rational matrix
- equilibrium? / equilibrium-eigenvalues / -charpoly / ->string / -trace / -det
- vf-divergence / divergence-at      phase-volume contraction (trace field)
- mpoly-gradient / mpoly-deriv2 / mpoly-hessian / hessian-at

## Verified
On Lorenz (sigma=10, rho=28, beta=8/3): Jacobian at the origin is exactly
[[-10,10,0],[28,-1,0],[0,0,-8/3]]; the eigenvalues are -8/3 and
(-11 +/- sqrt 1201)/2; the divergence is the constant -41/3 (dissipative).
All exact — the eigenvalues are the exact roots of the characteristic
polynomial via cas/linalg.lisp.

## Run
  scripts/sangaku examples/392-dynamical-systems.lisp
  # golden: cat src/prelude.lisp tests/cas_dynsys.lisp | lizard  (matches .expected)

Follows the repo conventions: golden pair in tests/, numbered example in
examples/, certificate-and-exactness discipline (no floating point).
