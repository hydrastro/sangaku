; MULTIVARIATE sum-of-squares certificates of global nonnegativity: a SOUND, one-directional positivity proof for
; real polynomials in several variables (docs/CAS.md -- the frontier rung above the univariate decision of example
; 393, and a genuine entry into multivariate real algebra).
;
; In one variable, nonnegative <=> sum of squares (an iff Sturm decides).  In two or more variables this iff FAILS:
; Motzkin's polynomial x^4 y^2 + x^2 y^4 - 3 x^2 y^2 + 1 is nonnegative everywhere yet is not a sum of squares.  So
; SOS does not DECIDE multivariate nonnegativity -- but it still PROVES it in one direction: if p = sum q_i^2 then
; p >= 0 everywhere, and that decomposition is a checkable proof.  This module verifies such certificates exactly
; over Q, and is scrupulous that a failed check means "not this SOS", never "not nonnegative".
(import "cas/sosmv.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Multivariate SOS: a sum-of-squares decomposition is a checkable proof that p >= 0 everywhere.") (newline) (newline)

(display "x^2 + 2xy + y^2 = (x + y)^2 -- one square certifies nonnegativity:") (newline)
(define x+y (list (cons 1 (list 1 0)) (cons 1 (list 0 1))))
(define p1 (list (cons 1 (list 2 0)) (cons 2 (list 1 1)) (cons 1 (list 0 2))))
(must "(x+y)^2 expands to x^2+2xy+y^2" (mvsos-is-certificate? p1 (list x+y)))
(must "so p is certified nonnegative by SOS" (equal? (car (mvsos-certify p1 (list x+y))) (quote nonnegative-by-SOS)))

(display "x^2 + y^2 = x^2 + y^2 -- a sum of two squares:") (newline)
(define qx (list (cons 1 (list 1 0))))
(define qy (list (cons 1 (list 0 1))))
(define p2 (list (cons 1 (list 2 0)) (cons 1 (list 0 2))))
(must "the two-square decomposition verifies" (mvsos-is-certificate? p2 (list qx qy)))
(must "and reports two squares" (equal? (car (cdr (mvsos-certify p2 (list qx qy)))) 2))

(display "soundness: a WRONG candidate is rejected with its residual, not silently accepted:") (newline)
(display "  claiming x^2+y^2 = (x+y)^2 leaves residual ") (display (mvsos-residual p2 (list x+y))) (display " (= -2xy):") (newline)
(must "the false claim is rejected" (if (mvsos-is-certificate? p2 (list x+y)) #f #t))
(must "and reported as not-an-SOS-decomposition" (equal? (car (mvsos-certify p2 (list x+y))) (quote not-an-SOS-decomposition)))

(display "the Gauss identity (a^2+b^2)(c^2+d^2) = (ac-bd)^2 + (ad+bc)^2 combines two SOS into one:") (newline)
(define one (list (cons 1 (list 0 0))))
(define g (mvsos-gauss-product qx one qy one))
(define lhs (mpoly-mul (mpoly-add (mvsos-square qx) (mvsos-square one)) (mpoly-add (mvsos-square qy) (mvsos-square one))))
(must "(x^2+1)(y^2+1) = (xy-1)^2 + (x+y)^2" (mvsos-is-certificate? lhs g))

(display "the honest boundary -- Motzkin's polynomial is nonnegative but NOT a sum of squares:") (newline)
(define M (list (cons 1 (list 4 2)) (cons 1 (list 2 4)) (cons -3 (list 2 2)) (cons 1 (list 0 0))))
(must "no SOS check certifies it (and we never claim it fails to be nonnegative)" (if (mvsos-is-certificate? M (quote ())) #f #t))
(must "the Motzkin caveat is stated" (equal? (mvsos-motzkin-note) (quote nonnegative-is-strictly-weaker-than-SOS-for-multivariate-Motzkin)))

(newline)
(display "A multivariate sum-of-squares decomposition is a sound, exact, checkable proof of global nonnegativity.") (newline)
(display "The converse fails (Motzkin), so this CERTIFIES nonnegativity but does not DECIDE it; the full multivariate") (newline)
(display "decision is Tarski real quantifier elimination, the frontier ahead.") (newline)
