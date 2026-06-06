# From a computed result down to the axioms

Sangaku is a proof-*carrying* system: each result comes with a certificate whose verification is finite and
mechanical. This note follows three results all the way down -- from the answer Sangaku prints, through the
certificate it emits, to the theorems those certificates instantiate, to the axioms those theorems rest on. The
point is not that Sangaku emits a formal derivation in ZFC (it does not -- that is what a foundational proof
assistant is for, and the bridge in `certlean.lisp` is the first step toward handing the obligation to one). The
point is that the chain is real and unbroken: nothing in it appeals to authority, and every link is either a
finite computation Sangaku performs or a named theorem with a known proof.

A caution on scale, kept honest throughout: "down to the axioms" describes the *logical dependency* of each link,
not a formal object Sangaku produces. The deepest link Sangaku actually checks is the certificate; the descent from
the certificate's governing theorem to the axioms is mathematics, cited here, not machine-checked here.

## Chain 1 — an existence statement: there is a real x with x squared equal to 2

**Sangaku prints:** `exists x. x^2 - 2 = 0` is true; the root is isolated in the rational interval `(1, 2)`.

**The certificate** is a Sturm sign count. Sangaku forms the Sturm chain of `x^2 - 2`, evaluates the sign sequence
at `1` and at `2`, and finds the count of sign changes drops by one across the interval: the polynomial is negative
at `1` (value `-1`) and positive at `2` (value `2`). That is the whole certificate -- two sign sequences and a
subtraction, all in exact integer arithmetic.

**The theorem the certificate instantiates** is Sturm's theorem: the number of distinct real roots of a squarefree
polynomial in an interval equals the difference in sign-change counts of its Sturm chain at the endpoints. A sign at
one endpoint negative and at the other positive, with one net sign change, is a single real root strictly between.

**Down to the axioms.** Sturm's theorem for the *existence* of the crossing is, at bottom, the intermediate value
theorem: a continuous function negative at `1` and positive at `2` takes the value `0` somewhere between. The
intermediate value theorem is not true of the rationals -- `x^2 - 2` skips across `0` there with no rational root --
and holds for the reals precisely because of the **completeness (least-upper-bound) axiom** of the ordered field of
real numbers. The reals, in turn, are constructed in ZFC (as Dedekind cuts of rationals, or equivalence classes of
Cauchy sequences -- objects ZFC's axioms of pairing, union, power set, and infinity supply), and the
least-upper-bound property is a *theorem* about that construction. So the chain is: sign count (computed) ->
Sturm's theorem -> intermediate value theorem -> completeness of the reals -> the real-number construction in ZFC.
The contrast with Chain 2 is the lesson: that `x^2 - 2` has *no rational root* needs only the rational root
theorem and divisibility -- elementary, no completeness -- while its having a *real* root is exactly where the
completeness axiom enters.

## Chain 2 — a universal inequality: x to the fourth minus x squared plus one is always positive

**Sangaku prints:** `x^4 - x^2 + 1 > 0` for every real `x`.

**The certificate** is a sum-of-squares / sign certificate. Sangaku extracts the squarefree odd-multiplicity part
of the polynomial, counts its real roots (zero, by a Sturm computation), and checks the leading coefficient is
positive. A nonnegative polynomial with no sign-changing real root and positive leading coefficient is positive
everywhere; the explicit witness, when an exact rational one exists, is the identity `x^4 - x^2 + 1 =
(x^2 - 1/2)^2 + 3/4`, two manifestly nonnegative pieces summing to the polynomial.

**The theorem the certificate instantiates** is the real-univariate Positivstellensatz fact: a univariate real
polynomial is nonnegative on the whole line if and only if it is a sum of two squares of real polynomials. The
explicit decomposition is a *proof* of nonnegativity that needs no analysis at all -- only that a square is
nonnegative and a sum of nonnegatives is nonnegative.

**Down to the axioms.** "A square is nonnegative" and "a sum of nonnegatives is nonnegative" are theorems of the
theory of **ordered fields** -- the order axioms (a product of like-sign elements is positive; the sum of
positives is positive). No completeness is needed here: this is why the sum-of-squares certificate is so much
cheaper and more elementary than the existence certificate of Chain 1. The ordered-field axioms hold of the reals
as constructed in ZFC. So: the SOS identity (a polynomial identity, checkable by expansion) -> nonnegativity of
squares in an ordered field -> the order axioms -> the reals in ZFC. The `ring`-checked Lean lemma the bridge emits
for the quadratic cases is exactly this chain made machine-checkable in a foundational system: `nlinarith` closes
the goal from the square hints by normalizing a polynomial identity, an operation whose correctness is the
commutative-ring axioms.

## Chain 3 — an integral: the integral of 2x is x squared

**Sangaku prints:** an antiderivative of `2x` is `x^2`.

**The certificate** is a derivative judgment, not a re-integration. Sangaku's trusted kernel has a relation
`Der F f` ("`f` is the derivative of `F`"), with the differentiation rules as its constructors (`diff-cert.lisp`).
The integral result `F = x^2` is certified by exhibiting `Der (x^2) (2x)` -- a derivation built from the power rule
and the constant-multiple rule -- because, by the definition of antiderivative, "`F` is an antiderivative of `f`"
*is* `Der F f`. Integration thus introduces no new trust: it reuses the derivative judgment
(`integral-cert.lisp`).

**The theorem the certificate instantiates** is the Fundamental Theorem of Calculus, used backwards: to certify an
antiderivative one need not compute an integral, only verify a derivative, and `D(x^2) = 2x` is checked by the rules
the kernel already trusts.

**Down to the axioms.** The differentiation rules are theorems about limits of difference quotients; limits are
defined by the epsilon-delta condition on the ordered field of reals; their existence and uniqueness for the
functions in question rest again on the **completeness axiom**. And the definite-integral side of the Fundamental
Theorem rests on the existence of the Riemann (or Lebesgue) integral, an existence theorem that is once more a
consequence of completeness. So: the derivative judgment (a finite derivation in the kernel) -> the differentiation
rules -> limits -> completeness of the reals -> the reals in ZFC.

## What is and is not claimed

Each result above is decided by Sangaku and carries a certificate Sangaku itself re-checks in exact arithmetic. The
descent from each certificate's governing theorem (Sturm, the univariate Positivstellensatz, the Fundamental
Theorem) down through the order and completeness axioms to the ZFC construction of the reals is standard
mathematics, laid out here so the dependency is explicit -- it is *not* a formal derivation Sangaku emits. The
honest frontier is precisely the bridge: for the sum-of-squares chain, the certificate is already exported as a
Lean lemma a foundational kernel checks (`docs/sangaku_certificates.lean`), so that one chain is mechanically
verified down to the commutative-ring axioms inside Lean. The existence chain (Chain 1) is also exported: a sign-change bracket
is rendered as a Lean lemma proving the root exists by the intermediate value theorem
(`certlean-lean-exists`, in `docs/sangaku_certificates.lean`).  And -- the decisive step toward the goal of a CAS
whose statements prove in lizard's own type theory -- two of the three chains are now checked NOT by an external
assistant but by LIZARD'S OWN dependent-type kernel (`certkernel.lisp`, via the kernel primitive kernel-check):
the order chain (a sum-of-squares nonnegativity, through the order axioms stated as kernel constructors) and the
derivative chain (Chain 3's `Der` judgment, from diff-cert, whose proof term the kernel type-checks directly).  So
the Fundamental Theorem chain is now machine-checked inside lizard, not merely exportable.  What remains is breadth
of fragment: the kernel proofs cover the sum-of-squares nonnegativity fragment and the elementary derivatives, not
yet every statement Sangaku can decide -- extending that fragment (general nonnegativity, the existence judgment as
a kernel proof rather than only a Lean export, the decision procedures) is the path to the full goal.
