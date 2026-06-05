; UNIVARIATE REAL QUANTIFIER ELIMINATION: a DECISION PROCEDURE for first-order statements over the reals in one
; variable -- "exists x . phi(x)" and "for all x . phi(x)" where phi is a boolean combination of polynomial sign
; conditions -- by sign-invariant cell decomposition of the real line (docs/CAS.md -- the exact one-variable case of
; Tarski's theorem / CAD, a genuine decision procedure rather than a certificate checker).
;
; The real roots of all polynomials in the statement cut R into finitely many cells (open intervals between
; consecutive roots, plus the root points), and every polynomial has constant sign on each cell.  So the truth of
; phi is constant per cell, and a quantified statement is decided by evaluating phi at one sample point per cell:
; "exists" iff phi holds at some sample, "for all" iff at every sample.  Sample points are exact rationals (below,
; between, and above the isolated roots); root points are handled by sign-on-the-isolating-interval, so no irrational
; value is ever needed.  A sign condition is (op . poly), op in {zero pos neg nonneg nonpos nonzero}; formulas are
; (and ...), (or ...), (not f) over those.
(import "cas/realqe.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Univariate real quantifier elimination: decide 'exists x . phi' and 'for all x . phi' exactly.") (newline) (newline)

(display "there exists a real x with x^2 - 1 < 0 -- true, on the interval (-1, 1):") (newline)
(must "exists x: x^2 - 1 < 0" (qe-decide (quote exists) (cons (quote neg) (list -1 0 1))))

(display "for all real x, x^2 + 1 > 0 -- true (the polynomial never vanishes):") (newline)
(must "forall x: x^2 + 1 > 0" (qe-decide (quote forall) (cons (quote pos) (list 1 0 1))))
(must "forall x: x^4 + 1 > 0" (qe-decide (quote forall) (cons (quote pos) (list 1 0 0 0 1))))

(display "for all real x, x^2 - 1 >= 0 -- FALSE (it is negative on (-1, 1)):") (newline)
(must "forall x: x^2 - 1 >= 0 is false" (if (qe-decide (quote forall) (cons (quote nonneg) (list -1 0 1))) #f #t))

(display "for all real x, x^2 >= 0 -- true:") (newline)
(must "forall x: x^2 >= 0" (qe-decide (quote forall) (cons (quote nonneg) (list 0 0 1))))

(display "there exists a real x with x^2 + 1 = 0 -- FALSE (no real root):") (newline)
(must "exists x: x^2 + 1 = 0 is false" (if (qe-decide (quote exists) (cons (quote zero) (list 1 0 1))) #f #t))

(display "there exists x with x^2 - 3x + 2 = 0 AND x - 1 = 0 -- true (the common root x = 1):") (newline)
(define common (list (quote and) (cons (quote zero) (list 2 -3 1)) (cons (quote zero) (list -1 1))))
(must "exists x: x^2-3x+2 = 0 and x-1 = 0" (qe-decide (quote exists) common))

(display "the sign at a root matters -- x - 2 = 0 AND x^2 - 3x + 2 > 0 is FALSE (the quadratic vanishes at 2):") (newline)
(define atroot2 (list (quote and) (cons (quote zero) (list -2 1)) (cons (quote pos) (list 2 -3 1))))
(must "exists x: x-2 = 0 and x^2-3x+2 > 0 is false" (if (qe-decide (quote exists) atroot2) #f #t))

(display "but x - 3 = 0 AND x^2 - 3x + 2 > 0 is true (the quadratic is 2 at x = 3):") (newline)
(define atroot3 (list (quote and) (cons (quote zero) (list -3 1)) (cons (quote pos) (list 2 -3 1))))
(must "exists x: x-3 = 0 and x^2-3x+2 > 0" (qe-decide (quote exists) atroot3))

(newline)
(display "Statements over the reals in one variable are now DECIDED exactly by sign-invariant cell decomposition --") (newline)
(display "the one-dimensional case of real quantifier elimination.  The multivariate case (cylindrical algebraic") (newline)
(display "decomposition, with projection and lifting over many variables) is the frontier ahead; this is its base.") (newline)
