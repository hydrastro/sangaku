; Exact evaluation of a formula on the SECTION over an IRRATIONAL critical x -- closing the boundary that the
; two-variable CAD named last (docs/CAS.md -- together with the full-dimensional-cell decision this completes the
; two-variable decider; witnesses living only on a section over an algebraic x are now found).
;
; At a critical x = alpha (a root of a projection polynomial, possibly irrational), the fibers p_i(alpha, y) have
; coefficients in Q(alpha).  The exact move: the sign of p_i(alpha, b) at a RATIONAL b equals asec-sign(p_i(x, b),
; alpha), because substituting the rational y = b leaves a polynomial in x with rational coefficients whose sign at
; the algebraic number alpha is computed exactly by the real-algebraic-number primitive -- no irrational arithmetic.
; Equality witnesses (two curves meeting over alpha) are detected by their y-resultant vanishing at alpha.
(import "cas/cadsection.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Deciding sign conditions on the section over an irrational critical x, exactly over Q.") (newline) (newline)

(define circle (list (list -1 0 1) (list) (list 1)))   ; x^2 + y^2 - 1
(define linexy (list (list 0 1) (list -1)))            ; x - y
(define alpha (asec-make (list -1 0 2) 0 1))           ; 1/sqrt(2), the root of 2x^2 - 1 in (0, 1)

(display "the circle x^2 + y^2 = 1 and the line x = y meet over the irrational x = 1/sqrt(2):") (newline)
(must "their y-resultant 2x^2 - 1 vanishes at 1/sqrt(2)" (csec-pair-meets? circle linexy alpha))

(display "exact signs of x^2 + y^2 - 1 at points on the section over 1/sqrt(2) (where alpha^2 = 1/2):") (newline)
(must "at (1/sqrt2, 0): 1/2 - 1 < 0, inside the disk" (= (csec-sign-on-section circle alpha 0) -1))
(must "at (1/sqrt2, 1): 1/2 + 1 - 1 > 0" (= (csec-sign-on-section circle alpha 1) 1))
(must "the strict condition x^2+y^2-1 < 0 holds at (1/sqrt2, 0)" (csec-eval-strict (cons (quote neg) circle) alpha 0))

(display "the line x - y at (1/sqrt2, 0) is positive (alpha - 0 = alpha > 0):") (newline)
(must "sign(x - y) at (1/sqrt2, 0) is +1" (= (csec-sign-on-section linexy alpha 0) 1))

(display "conjunctions of strict conditions are decided on the irrational section:") (newline)
(define xpos (list (list 0 1)))   ; the polynomial x, as a bivariate
(must "x > 0 AND x^2+y^2-1 < 0 holds at (1/sqrt2, 0)"
  (csec-eval-strict (list (quote and) (cons (quote pos) xpos) (cons (quote neg) circle)) alpha 0))

(newline)
(display "The section over an irrational critical x is now decided exactly: strict conditions through the signs of") (newline)
(display "rational-y substitutions at the algebraic alpha, and equality witnesses through resultant vanishing.  The") (newline)
(display "two-variable decider's previously-missed irrational-section witnesses are recovered.  The fully nested case") (newline)
(display "-- an algebraic y-root over an algebraic alpha, the tower Q(alpha)(beta) -- is the deep frontier ahead.") (newline)
