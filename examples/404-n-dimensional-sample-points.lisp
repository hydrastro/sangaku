; n-DIMENSIONAL ALGEBRAIC SAMPLE POINTS: a point in R^n all of whose coordinates are real algebraic numbers, given
; by a rational isolating BOX, with the exact sign of any n-variate rational polynomial at it (docs/CAS.md -- the
; device the LIFTING phase of cylindrical algebraic decomposition carries up the projection tower; a CAD sample
; point in R^n is exactly such an algebraic point, and the n-box lets us evaluate signs without constructing the
; algebraic tower Q(alpha_1)...(alpha_n) symbolically).
;
; The tower is FINITE: a problem in n variables projects through exactly n-1 levels, and lifting climbs the same
; n-1 levels, so a sample is an n-box -- nothing recurses without bound.  Signs come from interval arithmetic over
; the box (nested Horner), refining the widest coordinate until the sign separates from zero; a genuine zero is
; recognized through the defining system.  All exact rational arithmetic.
(import "cas/nbox.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cn c n) (if (= n 0) c (list (cn c (- n 1)))))   ; the constant c as an n-variate nested polynomial

(display "A point in R^3 with an irrational coordinate, signs evaluated exactly over a refining box.") (newline) (newline)

(display "the point (1/2, 1/2, 1/sqrt2) on the unit sphere x^2 + y^2 + z^2 = 1 (since 1/4 + 1/4 + 1/2 = 1):") (newline)
(define xm (list (cn (/ -1 2) 2) (cn 1 2)))                       ; x - 1/2
(define ym (list (list (cn (/ -1 2) 1) (cn 1 1))))               ; y - 1/2
(define sph (list (list (list -1 0 1) (list) (list 1)) (cn 0 2) (cn 1 2)))   ; x^2 + y^2 + z^2 - 1
(define box (list (cons (/ 4 10) (/ 6 10)) (cons (/ 4 10) (/ 6 10)) (cons (/ 6 10) (/ 8 10))))
(define pt (nbox-make (list xm ym sph) box))

(must "the sphere vanishes at the point" (= (nbox-sign sph pt) 0))
(must "z > 0 there (z = 1/sqrt2)" (= (nbox-sign (list (list (list 0 1))) pt) 1))
(must "2z^2 - 1 = 0 there (z^2 = 1/2)" (= (nbox-sign (list (list (list -1 0 2))) pt) 0))
(must "x - z < 0 there (1/2 < 1/sqrt2)" (= (nbox-sign (list (list (list 0 -1)) (cn 1 2)) pt) -1))
(must "x - y = 0 there (x = y = 1/2)" (= (nbox-sign (list (list (list) (list -1)) (cn 1 2)) pt) 0))

(newline)
(display "An algebraic point in n-space, with exact n-variate signs, is now a first-class object -- represented by") (newline)
(display "a refining rational box, needing no symbolic algebraic-tower arithmetic.  This is precisely what a lifted") (newline)
(display "CAD sample point is, the same code for every dimension; the projection tower (built earlier) descends, and") (newline)
(display "this ascends.  Wiring the two into a full n-variable lifting -- climbing the finite n-1 levels -- is the") (newline)
(display "remaining frontier, and its sample-point foundation is now in place.") (newline)
