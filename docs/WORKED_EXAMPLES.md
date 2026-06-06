# Non-trivial theorems, proven down to their roots

Every result below is decided by sangaku and reduces, with no trusted oracle, to primitive certificates the
system itself produces and re-checks: Sturm sign sequences (for real-root counts and isolation), Sylvester
resultants (for elimination), sum-of-squares certificates (for positivity), isolating rational intervals and
algebraic-number arithmetic (for the witnesses). "To its roots" is meant literally: the trust chain bottoms out in
exact rational arithmetic on integer-coefficient polynomials.

## 1. A quintic with a real root that no radical can express

`x^5 - x - 1 = 0` has exactly one real root. Sturm's theorem produces the count from the sign changes of the
canonical remainder sequence, and the root is isolated to a rational interval. This is striking because, by the
Abel-Ruffini theorem and a Galois-group computation, this particular quintic is *not solvable by radicals* -- its
real root cannot be written with nested square, cube, and higher roots at all. Yet its existence, its count, and an
arbitrarily tight rational enclosure are all decided exactly. Solvability by radicals and existence as a real
number are different questions, and the second is fully in reach when the first is provably hopeless.

## 2. The irrationality of sqrt 2, with no appeal to a parity argument

`x^2 - 2 = 0` has two real roots (Sturm) and zero rational roots (the rational root theorem: the only candidates
are +-1 and +-2, none of which satisfy it). Two real solutions and no rational ones means both real solutions are
irrational. The classical proof argues by parity of a hypothetical reduced fraction; this proof instead counts
roots over two different fields and compares, and the comparison is carried out in exact integer arithmetic.

## 3. Positivity that is not obvious by inspection

`x^4 - x^2 + 1 > 0` for every real `x`. The polynomial dips -- its value at `x = 1` is `1`, at `x = 0` is `1`, and
it has a local structure that makes "always positive" non-obvious -- but it has no real root and stays strictly
positive, certified by a sum-of-squares decomposition. The certificate is a theorem about *all* real points at
once, which is why it settles a universally quantified statement without sampling.

## 4. The general quadratic, eliminated completely

`exists x. a x^2 + b x + c = 0` over the reals, with the leading coefficient `a` free, is equivalent to

  (a != 0 and b^2 - 4 a c >= 0) or (a = 0 and b != 0) or (a = 0 and c = 0).

This is the textbook-hard example of real quantifier elimination: when `a = 0` the degree drops and the discriminant
stops governing, so the answer genuinely splits on the leading coefficient. sangaku decomposes the three-parameter
space, decides each cell, and -- via prime-implicant cover with don't-cares -- returns exactly this three-branch
minimal formula, proven minimal by branch-and-bound over the prime implicants.

## 5. A system solvable only at an irrational parameter

`exists x. (x - p = 0) and (x^2 - 2 = 0)` is equivalent to `p^2 - 2 = 0`. The two equations share a real root
exactly when `p = +- sqrt 2`. The boundary here is an *irrational* surface in the parameter, and it is sampled at
the exact algebraic number: the section `p^2 - 2 = 0` is recorded as the true locus, the open sectors on either side
as false, all decided by exact arithmetic in the field extension `Q(sqrt 2)`.

## 6. Cheap refutation independent of dimension

`x^2 + 1 < 0` (and `x^2 + 1 = 0`, and `x^4 + x^2 + 1 < 0`, and any conjunction containing one of these) is refuted
in constant work by a non-negativity certificate, with no decomposition built. This matters because a complete
decision is doubly exponential in the number of variables -- a theorem of Davenport and Heintz, not a limitation of
the implementation -- so the only way to stay fast on large unsatisfiable instances is a certificate-based filter
that never has to enumerate cells. The filter is one-directional and sound: it refutes only genuinely empty sets.

---

Each example is reproduced by an entry under `examples/` and pinned by a golden under `tests/`, so the proofs are
not narrated once but re-run on every check, and the certificates underneath them are the same exact-arithmetic
objects every time.
