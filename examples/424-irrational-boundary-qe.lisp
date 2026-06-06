; IRRATIONAL boundary surfaces in parametric quantifier elimination, the case left open by the rational-section
; sampler cadqenx (docs/CAS.md).  A projection factor's section -- the parameter values where it vanishes -- can be
; an irrational algebraic number, and rational sampling misses it: the boundary cell is absent from the true/false
; partition.  cadqenr samples those sections at the exact ALGEBRAIC numbers.  A section is the real root of a factor
; isolated in a rational interval; the section factor's sign there is zero by definition, the sign of every other
; factor is computed exactly by refining the interval until that factor is sign-constant (the classical
; sign-at-an-algebraic-number computation), and the family is decided exactly at the algebraic point by substituting
; it with algebraic-number arithmetic.
(import "cas/cadqenr.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))
(define (cadr l) (car (cdr l))) (define (caddr l) (car (cdr (cdr l))))
(define (mem x s) (cond ((null? s) #f) ((equal? x (car s)) #t) (else (mem x (cdr s)))))

(display "Capturing irrational boundary cells with exact algebraic section sampling.") (newline) (newline)

; the sign of a polynomial at an irrational algebraic point is computed exactly
(must "sign of (p - 1) at the root sqrt 2 of p^2 - 2 is positive (sqrt 2 > 1)"
  (= (cadqenr-sign-of (list -1 1) (list -2 0 1) 0 2) 1))
(must "sign of (p - 2) at sqrt 2 is negative (sqrt 2 < 2)"
  (= (cadqenr-sign-of (list -2 1) (list -2 0 1) 0 2) -1))
(must "sign of (p^2 - 2) at its own root sqrt 2 is zero"
  (= (cadqenr-sign-of (list -2 0 1) (list -2 0 1) 0 2) 0))
(must "sign of (p^2 - 3) at sqrt 2 is negative (2 - 3 < 0)"
  (= (cadqenr-sign-of (list -3 0 1) (list -2 0 1) 0 2) -1))

; exists x . (x - p = 0) and (x^2 - 2 = 0): the answer is the irrational locus p^2 - 2 = 0 (p = +- sqrt 2)
(define xmp (list (list (cons -1 (list 1))) (list (cons 1 (list 0)))))
(define xx2 (list (list (cons -2 (list 0))) (quote ()) (list (cons 1 (list 0)))))
(define phi2 (list (quote and) (cons (quote zero) xmp) (cons (quote zero) xx2)))
(define fres2 (list (list -2 0) (list 1 2)))
(define tf2 (cadqenr-elim2-1 (list fres2) (quote exists) phi2))
(must "the irrational section p^2 - 2 = 0 is captured and is TRUE (a common real root x = sqrt 2 exists)"
  (mem (list 0) (cadr tf2)))
(must "the open sectors p^2 - 2 > 0 and p^2 - 2 < 0 are FALSE (no common real root)"
  (and (mem (list 1) (caddr tf2)) (mem (list -1) (caddr tf2))))

; exists x . (x - p = 0) and (x^3 - 2 = 0): the answer is the irrational locus p^3 - 2 = 0 (p = cube root of 2)
(define xx3 (list (list (cons -2 (list 0))) (quote ()) (quote ()) (list (cons 1 (list 0)))))
(define phi3 (list (quote and) (cons (quote zero) xmp) (cons (quote zero) xx3)))
(define fres3 (list (list -2 0) (list 1 3)))
(must "the irrational cube-root section p^3 - 2 = 0 is captured and TRUE"
  (mem (list 0) (cadr (cadqenr-elim2-1 (list fres3) (quote exists) phi3))))

(newline)
(display "Sections on an irrational surface -- the discriminant or resultant vanishing at an algebraic number -- are") (newline)
(display "now sampled exactly, their sign vectors computed over the algebraic point and their truth decided by exact") (newline)
(display "algebraic substitution.  Multi-parameter algebraic towers remain the documented boundary (cadqenr-caveat).") (newline)
