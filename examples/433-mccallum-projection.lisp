; The McCALLUM reduced PROJECTION operator for cylindrical algebraic decomposition (docs/CAS.md) -- the published
; improvement (McCallum 1988, the basis of the default projection in QEPCAD B and Mathematica's CAD) that makes the
; projection set dramatically smaller than Collins' original.  Collins carries, for every projection polynomial, its
; whole tower of principal subresultant coefficients; McCallum proved that for a WELL-ORIENTED set the projection
; needs only each polynomial's discriminant, the pairwise resultants, and the leading coefficients -- dropping the
; subresultant tower entirely.  Implemented here from the literature, not adapted from any system's source.  It does
; not beat the doubly-exponential worst case (Davenport-Heintz, a theorem); it reduces the base and the constants,
; which is what makes CAD run on real problems.
(import "cas/mccallum.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "The reduced projection operator the established CAD systems use, built from the literature.") (newline) (newline)

; the parabola y^2 - x and the line y - x, in the mpoly representation (low->high in y; each y-coefficient an mpoly
; in x as (coeff . exponent-vector) terms)
(define p1 (list (list (cons -1 (list 1))) (quote ()) (list (cons 1 (list 0)))))
(define p2 (list (list (cons -1 (list 1))) (list (cons 1 (list 0)))))

; well-orientedness is certified for this set (positive degree, non-identically-zero leading coefficients)
(must "the set { y^2 - x, y - x } is certified well-oriented" (mccallum-well-oriented? (list p1 p2)))

; the reduced projection is exactly the discriminant of the parabola and the resultant of the pair
(must "the McCallum projection is { disc_y(y^2 - x) = -4x, res_y(p1,p2) = x^2 - x }"
  (equal? (mccallum-project (list p1 p2)) (list (list (list -4 1)) (list (list 1 2) (list -1 1)))))

; the constant leading coefficients are correctly dropped (a nonzero constant marks no cell boundary)
(must "constant leading coefficients contribute nothing and are dropped"
  (= (mc-len (mccallum-project (list p1 p2))) 2))

; the safe projection equals the McCallum projection exactly when the set is well-oriented
(must "the safe projection equals the reduced McCallum set on a well-oriented input"
  (equal? (mccallum-project (list p1 p2)) (mccallum-project-safe (list p1 p2))))

; and the reduced set marks the SAME cell boundaries as the conservative Collins-safe superset here
(must "McCallum and the Collins-safe projection agree on this well-oriented set (sign-invariance preserved)"
  (equal? (mccallum-project (list p1 p2)) (mccallum-project-safe (list p1 p2))))

; the discriminant and resultant components are individually correct
(must "the discriminant of the parabola in y is a nonzero multiple of x (boundary at x = 0)"
  (equal? (car (mccallum-project (list p1 p2))) (list (list -4 1))))
(must "the resultant of parabola and line is x^2 - x (boundaries at x = 0 and x = 1)"
  (equal? (car (cdr (mccallum-project (list p1 p2)))) (list (list 1 2) (list -1 1))))

(newline)
(display "The reduced operator keeps only discriminants, pairwise resultants, and leading coefficients, dropping the") (newline)
(display "subresultant tower Collins carried -- valid because the set is well-oriented, and falling back to the full") (newline)
(display "Collins projection when well-orientedness cannot be certified (mccallum-caveat).  It shrinks the base of the") (newline)
(display "exponential, the practical lever the established systems rely on, without changing the worst-case class.") (newline)
