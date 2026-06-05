; The GENERAL REGULAR CHAIN: exact sign and vanishing of a polynomial at a point cut out by a triangular system
; whose defining polynomials may couple ALL lower coordinates at once (docs/CAS.md -- the last structural generality
; past cadtower, which decided only the SIMPLE chain where each f_i relates consecutive coordinates; here f_i may
; depend on x_i and several earlier coordinates simultaneously, the form a regular chain / triangular decomposition
; actually takes, for instance z = x + y depending on two earlier coordinates).
;
; VANISHING is decided by reducing the target polynomial down the chain with the MULTIVARIATE resultant (cadnd's
; Sylvester determinant over the mpoly coefficient ring): eliminate the top variable between its defining polynomial
; and the target, regroup the resulting mpoly for the next variable down, and continue to a univariate polynomial in
; the base, tested at the base algebraic number.  The NONZERO sign is read by interval arithmetic over a box refined
; TOP-DOWN -- the base tightened first, then each coordinate's interval bisected and the half kept on which its
; defining polynomial, evaluated over the now-tighter lower intervals, still straddles zero; coupled fibers isolate
; because the lower coordinates are tightened first.  All exact rational arithmetic.
(import "cas/cadrc.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "A point cut out by a COUPLED chain: x = sqrt(2), y = 2^(1/4), z = x + y (z depends on BOTH x and y).") (newline) (newline)

; chain (top-down higher levels): f3 = z - x - y, f2 = y^2 - x; base f1 = x^2 - 2.
; cadnd nested form: a polynomial in its top variable with mpoly (coeff . exponent-vector) coefficients in the lower.
(define f3 (list (list (cons -1 (list 1 0)) (cons -1 (list 0 1))) (list (cons 1 (list 0 0)))))   ; z - x - y
(define f2 (list (list (cons -1 (list 1))) (list) (list (cons 1 (list 0)))))                      ; y^2 - x
(define chain (list f3 f2))
(define base (list -2 0 1))                                                                        ; x^2 - 2, root in (1,2)
(define levels (list (list f2 1 (/ 3 2)) (list f3 2 3)))                                            ; isolating intervals for y, z

(display "the defining relations vanish, decided by reducing down the chain with the multivariate resultant:") (newline)
(must "z - x - y = 0 at the point" (cadrc-vanishes? f3 chain base 1 2))
; 2(z - x - y) also vanishes
(must "2(z - x - y) = 0 at the point"
  (cadrc-vanishes? (list (list (cons -2 (list 1 0)) (cons -2 (list 0 1))) (list (cons 2 (list 0 0)))) chain base 1 2))

(display "a polynomial that vanishes only because of the COUPLING reduces to zero too:") (newline)
; (z - x)^2 - x = y^2 - x = 0 (since z - x = y and y^2 = x)
(must "(z - x)^2 - x = 0 (it equals y^2 - x)"
  (cadrc-vanishes? (list (list (cons 1 (list 2 0)) (cons -1 (list 1 0))) (list (cons -2 (list 1 0))) (list (cons 1 (list 0 0)))) chain base 1 2))

(display "and non-vanishing coordinates have exact signs, by the top-down refining box:") (newline)
(define gz (list (list) (list (cons 1 (list 0 0)))))                                  ; z
(define gz2 (list (list (cons -2 (list 0 0))) (list (cons 1 (list 0 0)))))            ; z - 2
(define gz3 (list (list (cons -3 (list 0 0))) (list (cons 1 (list 0 0)))))            ; z - 3
(must "z > 0 (z = sqrt(2) + 2^(1/4) is about 2.60)" (= (cadrc-sign gz chain base 1 2 levels) 1))
(must "z - 2 > 0 (2.60 > 2)" (= (cadrc-sign gz2 chain base 1 2 levels) 1))
(must "z - 3 < 0 (2.60 < 3)" (= (cadrc-sign gz3 chain base 1 2 levels) -1))
(must "z - x - y = 0 (sign zero on the defining relation)" (= (cadrc-sign f3 chain base 1 2 levels) 0))

(newline)
(display "The general regular chain -- defining polynomials coupling all lower coordinates at once -- now has exact") (newline)
(display "vanishing (by the multivariate-resultant reduction down the chain) and exact nonzero sign (by the top-down") (newline)
(display "refining box over coupled fibers).  This is the algebraic core a complete real-quantifier-elimination engine") (newline)
(display "spends its heaviest effort on, the last structural generality of the cylindrical-decomposition climb.") (newline)
