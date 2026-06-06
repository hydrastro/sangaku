; MULTI-PARAMETER parametric quantifier elimination -- eliminating a quantified variable from a formula with TWO free
; parameters, returning a quantifier-free condition on the parameters (docs/CAS.md).  This is the textbook QE example
; that one-parameter elimination could not reach: exists x . x^2 + b x + c = 0 over the reals, whose answer is the
; discriminant locus b^2 - 4 c >= 0.
;
; With the two parameters (b, c) and the quantified x eliminated, the projection of the family onto (b, c) -- the
; discriminant in x and the resultants in x, via the multivariate resultant -- partitions the parameter PLANE into
; cells of constant truth; the plane is decomposed by the planar projection-and-lift, each cell decided once by the
; complete univariate decider, and the eliminated condition is read off as the SIGN of the projection factors.
(import "cas/cadqe2.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (same? a b) (equal? a b))

(display "Eliminating a quantifier from a two-parameter family, producing a condition on the parameters (b, c).") (newline) (newline)

; x^2 + b x + c as a polynomial in x (last variable) with multivariate coefficients over (b, c)
(define quad (list (list (cons 1 (list 0 1))) (list (cons 1 (list 1 0))) (list (cons 1 (list 0 0)))))

; the single projection factor is the discriminant, computed as -b^2 + 4c (the discriminant up to sign)
(must "the projection factor is the discriminant -b^2 + 4c"
  (same? (car (cadqe2-elim (quote exists) (cons (quote zero) quad))) (quote (((-1 2 0) (4 0 1))))))

; exists x. x^2 + b x + c = 0  ->  discriminant <= 0 in our sign (= b^2 - 4c >= 0): factor sign 0 or -1
(must "exists x. x^2 + b x + c = 0  holds where the discriminant factor is 0 or < 0  (b^2 - 4c >= 0)"
  (same? (cdr (cadqe2-elim (quote exists) (cons (quote zero) quad))) (quote ((0) (-1)))))

; exists x. x^2 + b x + c < 0  ->  two distinct real roots  ->  discriminant > 0  (factor < 0 only)
(must "exists x. x^2 + b x + c < 0  holds where the discriminant is strictly positive  (b^2 - 4c > 0)"
  (same? (cdr (cadqe2-elim (quote exists) (cons (quote neg) quad))) (quote ((-1)))))

; forall x. x^2 + b x + c > 0  ->  no real roots  ->  discriminant < 0  (factor > 0 only)
(must "forall x. x^2 + b x + c > 0  holds where the discriminant is strictly negative  (b^2 - 4c < 0)"
  (same? (cdr (cadqe2-elim (quote forall) (cons (quote pos) quad))) (quote ((1)))))

; a resultant rather than a discriminant: exists x. x = b and x = c  <=>  b = c
(define xmb (list (list (cons -1 (list 1 0))) (list (cons 1 (list 0 0)))))
(define xmc (list (list (cons -1 (list 0 1))) (list (cons 1 (list 0 0)))))
(must "exists x. x = b and x = c  holds where the resultant factor (b - c) is zero  (b = c)"
  (same? (cdr (cadqe2-elim (quote exists) (list (quote and) (cons (quote zero) xmb) (cons (quote zero) xmc)))) (quote ((0)))))

(newline)
(display "Each result is an exact quantifier-free condition on the two parameters, read as sign conditions on the") (newline)
(display "projection factors -- the discriminant locus for the quadratic, the resultant locus for the shared root.") (newline)
(display "Two parameters and one quantified variable is the planar scope; three or more is the general parametric CAD.") (newline)
