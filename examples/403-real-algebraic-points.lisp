; REAL ALGEBRAIC POINTS in the plane, and the exact sign of a bivariate rational polynomial at one, by interval
; arithmetic over a refining isolating box (docs/CAS.md -- the primitive the nested tower Q(alpha)(beta) needs, where
; a point's x-coordinate alpha and y-coordinate beta are both algebraic and beta is algebraic OVER Q(alpha); it is
; also exactly what a lifted CAD sample point is, so it is the shared foundation of both remaining frontiers).
;
; A point is the unique common real solution of a defining pair A(x,y)=0, B(x,y)=0, isolated by a rational box.  The
; sign of any bivariate g at the point is computed by evaluating g over the box with interval arithmetic: if the
; resulting rational interval excludes zero, that is the sign; otherwise the box is refined (bisect the wider side,
; keep the half still bracketing the common root) and retried -- terminating whenever g is nonzero at the point.
; Vanishing is decided algebraically: g(alpha,beta)=0 iff alpha is a common root of Res_y(A,g) and Res_y(B,g).  All
; exact rational arithmetic; no floating point, no algebraic-field arithmetic.
(import "cas/algpoint.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "The exact sign of a bivariate polynomial at an algebraic point (alpha, beta), both coordinates irrational.") (newline) (newline)

(display "the point (1/sqrt2, 1/sqrt2): the intersection of the circle x^2 + y^2 = 1 and the line x = y:") (newline)
(define A (list (list -1 0 1) (list) (list 1)))   ; x^2 + y^2 - 1
(define B (list (list 0 1) (list -1)))            ; x - y
(define pt (apt-make A B (/ 6 10) (/ 8 10) (/ 6 10) (/ 8 10)))

(must "x > 0 at the point" (= (apt-sign (list (list 0 1)) pt) 1))
(must "y > 0 at the point" (= (apt-sign (list (list) (list 1)) pt) 1))
(must "x + y - 1 > 0 (it is sqrt(2) - 1, about 0.414)" (= (apt-sign (list (list -1 1) (list 1)) pt) 1))
(must "x - 1 < 0 (since 1/sqrt2 < 1)" (= (apt-sign (list (list -1 1)) pt) -1))
(must "2x - 1 > 0 (since 1/sqrt2 > 1/2)" (= (apt-sign (list (list -1 2)) pt) 1))

(display "the defining curves vanish at the point (sign exactly 0, decided algebraically):") (newline)
(must "x - y = 0 there" (= (apt-sign B pt) 0))
(must "x^2 + y^2 - 1 = 0 there" (= (apt-sign A pt) 0))

(display "products and other algebraic relations are exact too:") (newline)
(must "xy > 0 (it is 1/2)" (= (apt-sign (list (list) (list 0 1)) pt) 1))
(must "2xy - 1 = 0 (since xy = 1/2)" (= (apt-sign (list (list -1) (list 0 2)) pt) 0))

(display "the x-coordinate alone is recoverable as an algebraic number (root of 2x^2 - 1):") (newline)
(must "its minimal polynomial 2x^2 - 1 vanishes at alpha" (= (asec-sign (list -1 0 2) (apt-x-alpha pt)) 0))

(newline)
(display "The sign of a bivariate polynomial at a point with BOTH coordinates algebraic is now exact, by interval") (newline)
(display "refinement over a box with algebraic vanishing decided by resultants.  This is the nested-tower primitive") (newline)
(display "Q(alpha)(beta) -- and precisely what a lifted CAD sample point is -- the shared foundation for completing") (newline)
(display "the two-variable decider on algebraic-witness sections and for carrying samples up the lifting tower.") (newline)
