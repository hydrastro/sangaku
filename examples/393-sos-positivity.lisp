; A DECISION PROCEDURE for global nonnegativity of a univariate real polynomial -- p(x) >= 0 for ALL real x --
; with an exact sign/sum-of-squares certificate (docs/CAS.md -- Sangaku's first rung of REAL algebraic decision,
; the Positivstellensatz world, reasoning over the ordered field R rather than the algebraic closure).
;
; Exact characterization (univariate, no relaxation gap): p >= 0 everywhere iff its leading coefficient is positive,
; its degree even, and every real root has EVEN multiplicity -- i.e. the product of the odd-multiplicity squarefree
; factors has NO real root, which Sturm's theorem decides exactly over Q. By Hilbert, a nonnegative univariate
; polynomial is a sum of squares, so this is equivalently an SOS certificate; here it is certified by the exact
; root-multiplicity criterion, everything over Q.
(import "cas/sos.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Global nonnegativity of a univariate real polynomial, decided exactly with a certificate.") (newline) (newline)

(display "x^2 >= 0 everywhere (a square; its only real root, 0, has even multiplicity):") (newline)
(display "  decision: ") (display (sos-decide (list 0 0 1))) (newline)
(must "x^2 is nonnegative" (sos-nonneg? (list 0 0 1)))
(must "but not strictly positive (it vanishes at 0)" (if (sos-positive? (list 0 0 1)) #f #t))
(must "the certificate verifies" (sos-verify (list 0 0 1)))

(display "x^2 + 1 > 0 everywhere (no real root at all):") (newline)
(must "x^2 + 1 is strictly positive" (sos-positive? (list 1 0 1)))
(must "x^4 + 1 is strictly positive" (sos-positive? (list 1 0 0 0 1)))

(display "(x-1)^2 (x-2)^2 >= 0 (real roots 1 and 2, each of even multiplicity):") (newline)
(define q (poly-mul (poly-mul (list -1 1) (list -1 1)) (poly-mul (list -2 1) (list -2 1))))
(must "it is nonnegative" (sos-nonneg? q))
(must "the certificate verifies" (sos-verify q))

(display "x^2 - 1 changes sign (real roots +-1 of odd multiplicity), so it is INDEFINITE:") (newline)
(display "  decision: ") (display (sos-decide (list -1 0 1))) (newline)
(must "x^2 - 1 is not nonnegative" (if (sos-nonneg? (list -1 0 1)) #f #t))
(must "it is classified indefinite" (equal? (sos-decide (list -1 0 1)) (quote indefinite)))

(display "x^2 (x - 1): the factor x has even multiplicity but (x-1) is an odd-multiplicity real root:") (newline)
(define r (poly-mul (list 0 0 1) (list -1 1)))
(must "the odd-multiplicity factor is exactly (x - 1)" (equal? (sos-trim (sos-odd-factor r)) (list -1 1)))
(must "so the polynomial is indefinite" (equal? (sos-decide r) (quote indefinite)))

(display "-x^2 - 1 <= 0 everywhere (NONPOSITIVE):") (newline)
(must "-x^2 - 1 is nonpositive" (equal? (sos-decide (list -1 0 -1)) (quote nonpositive)))

(display "honest scope: this is the UNIVARIATE case, where nonnegativity = sum of squares is an iff:") (newline)
(must "the multivariate boundary is named, not hidden" (equal? (sos-multivariate-caveat) (quote univariate-only-multivariate-needs-Positivstellensatz-or-Tarski-QE)))

(newline)
(display "Global nonnegativity over the reals is now a decision with an exact certificate, via the odd-multiplicity") (newline)
(display "factor and Sturm.  This is the univariate Positivstellensatz rung; multivariate real nonnegativity (where") (newline)
(display "nonnegative is strictly weaker than SOS -- Motzkin -- and the decision is Tarski quantifier elimination)") (newline)
(display "remains the frontier ahead.") (newline)
