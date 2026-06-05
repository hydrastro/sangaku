; REAL ALGEBRAIC NUMBERS by isolating interval, and the exact SIGN of a rational polynomial at one (docs/CAS.md --
; the primitive that closes the irrational-section gap of the two-variable CAD and that the n-variable recursion
; needs to carry algebraic sample coordinates).
;
; A real algebraic number alpha is (defining-poly, lo, hi): a polynomial in Q[x] that alpha is a root of, plus a
; rational isolating interval (lo, hi) containing alpha and no other real root.  The sign of any q in Q[x] at alpha
; is computed exactly with rational arithmetic only: q(alpha) = 0 iff gcd(q, defp) has its root in the interval;
; otherwise the interval is bisected (keeping alpha bracketed) until q is sign-definite on it, and that sign is
; sign(q(alpha)).  No floating point, no symbolic field -- just Sturm-style refinement.
(import "cas/algnum2.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "The exact sign of a polynomial at an irrational algebraic number, by interval refinement over Q.") (newline) (newline)

(display "alpha = sqrt(2), the root of x^2 - 2 in the interval (1, 2):") (newline)
(define s2 (asec-make (list -2 0 1) 1 2))
(must "sqrt(2) - 1 > 0" (= (asec-sign (list -1 1) s2) 1))
(must "1 - sqrt(2) < 0" (= (asec-sign (list 1 -1) s2) -1))
(must "3 - 2*sqrt(2) > 0 (it is about 0.17)" (= (asec-sign (list 3 -2) s2) 1))
(must "sqrt(2) - 2 < 0" (= (asec-sign (list -2 1) s2) -1))
(must "the defining polynomial x^2 - 2 vanishes at sqrt(2)" (= (asec-sign (list -2 0 1) s2) 0))
(must "x^2 - 3 < 0 at sqrt(2) (since 2 < 3)" (= (asec-sign (list -3 0 1) s2) -1))
(must "x^2 - 1 > 0 at sqrt(2) (since 2 > 1)" (= (asec-sign (list -1 0 1) s2) 1))

(display "alpha = the golden ratio phi, the root of x^2 - x - 1 in (1, 2) (about 1.618):") (newline)
(define phi (asec-make (list -1 -1 1) 1 2))
(must "phi - 1 > 0" (= (asec-sign (list -1 1) phi) 1))
(must "2 - phi > 0" (= (asec-sign (list 2 -1) phi) 1))
(must "x^2 - x - 1 vanishes at phi" (= (asec-sign (list -1 -1 1) phi) 0))
(must "phi^2 - 2 > 0 (phi^2 = phi + 1 is about 2.618)" (= (asec-sign (list -2 0 1) phi) 1))

(display "a rational 'algebraic number' (root of x - 3) is handled too:") (newline)
(define three (asec-make (list -3 1) 2 4))
(must "x - 5 < 0 at 3" (= (asec-sign (list -5 1) three) -1))
(must "it is recognized as rational" (asec-rational? three))

(newline)
(display "The sign of a rational polynomial at a real algebraic number is now exact, using only interval") (newline)
(display "refinement over Q.  This is the key that lets the two-variable CAD evaluate a section over an IRRATIONAL") (newline)
(display "critical x -- the boundary named last rung -- and that a many-variable decomposition needs to carry") (newline)
(display "algebraic sample coordinates from one projection level to the next.") (newline)
