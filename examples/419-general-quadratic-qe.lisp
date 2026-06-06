; THREE-parameter parametric quantifier elimination -- the hard textbook QE example, the GENERAL quadratic with a
; free leading coefficient (docs/CAS.md):
;
;   exists x . a x^2 + b x + c = 0   over the reals,
;
; whose answer is NOT simply the discriminant, because when a = 0 the polynomial drops to degree one (or zero) and
; the discriminant condition no longer governs.  The full law is
;
;   (a != 0 and b^2 - 4 a c >= 0)   or   (a = 0 and b != 0)   or   (a = 0 and b = 0 and c = 0),
;
; a quantifier-free formula in the three parameters with a genuine case split on the leading coefficient.  cadqe3
; decomposes the parameter 3-space with the projection factors {a, b, c, b^2 - 4 a c}, decides each cell with the
; complete univariate decider, and returns the sign-vectors over those factors on which the statement holds.
(import "cas/cadqe3.lisp")
(define (must l x) (display "  ") (display l) (display " : ") (display (if x "ok" "FAIL")) (newline) (if x #t (raise (quote fail))))

(display "Eliminating the quantifier from the general quadratic, over the three free coefficients (a, b, c).") (newline) (newline)

; a x^2 + b x + c as a polynomial in x (last variable) with multivariate coefficients over (a, b, c)
(define genq (list (list (cons 1 (list 0 0 1))) (list (cons 1 (list 0 1 0))) (list (cons 1 (list 1 0 0)))))
; the projection factors {a, b, c, b^2 - 4 a c} as (a,b,c)-monomials (coeff e_a e_b e_c)
(define factors (list (list (list 1 1 0 0)) (list (list 1 0 1 0)) (list (list 1 0 0 1)) (list (list 1 0 2 0) (list -4 1 0 1))))

(define result (cadqe3-elim factors (quote exists) (cons (quote zero) genq)))

; the projection factors come back as supplied
(must "the projection factors are a, b, c, and b^2 - 4 a c"
  (equal? (car result) factors))

; every true sign-vector must satisfy the exact target law (a != 0 & disc >= 0) or (a = 0 & (b != 0 or c = 0))
(define (cadr l) (car (cdr l))) (define (caddr l) (car (cdr (cdr l)))) (define (cadddr l) (car (cdr (cdr (cdr l)))))
(define (target sa sb sc sd) (cond ((not (= sa 0)) (>= sd 0)) (else (if (not (= sb 0)) #t (= sc 0)))))
(define (all-match vs) (cond ((null? vs) #t) ((target (car (car vs)) (cadr (car vs)) (caddr (car vs)) (cadddr (car vs))) (all-match (cdr vs))) (else #f)))
(must "every true sign-vector satisfies the general-quadratic law"
  (all-match (cdr result)))

; spot-check membership of representative strata (the sign-vector for that stratum must be present)
(define (present? v vs) (cond ((null? vs) #f) ((equal? v (car vs)) #t) (else (present? v (cdr vs)))))
(must "stratum a>0, disc>0 (two real roots) is in the solution"
  (present? (list 1 1 1 1) (cdr result)))
(must "stratum a=0, b>0 (a linear equation) is in the solution"
  (present? (list 0 1 1 1) (cdr result)))
(must "stratum a=0, b=0, c=0 (the identity 0=0) is in the solution"
  (present? (list 0 0 0 0) (cdr result)))

(newline)
(display "The three strata -- the genuine quadratic (a != 0, discriminant >= 0), the degenerate linear (a = 0,") (newline)
(display "b != 0), and the trivial identity (a = b = c = 0) -- are all recovered, with the leading-coefficient case") (newline)
(display "split that makes this the standard hard example of real quantifier elimination.") (newline)
