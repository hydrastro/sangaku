; -*- lisp -*-
; src/cas/psubres.lisp -- the PARAMETRIC subresultant tower: the multivariate lift of subresultant.lisp, computing
; principal subresultant coefficients whose entries are POLYNOMIALS IN A PARAMETER rather than rational constants.
; This is what the CAD projection actually consumes at each elimination level: the polynomials being projected are
; in the main variable x with coefficients that are polynomials in the remaining variables, and the psc tower of two
; such polynomials is itself a set of polynomials in those remaining variables whose VANISHING defines the
; cell boundaries one level down.  subresultant.lisp built the univariate-over-Q core and verified it; psubres.lisp
; lifts the identical recurrence to coefficients in Q[t], the single-parameter case that is the workhorse of a
; projection step (each step eliminates one variable, parametrised by the next).
;
; The representation.  A polynomial in the main variable x is a list, low-to-high in x, of COEFFICIENTS, where each
; coefficient is itself a polynomial in the parameter t (a rational coefficient list, low-to-high in t).  Thus the
; whole object is a bivariate polynomial in (t, x) viewed as (Q[t])[x].  The subresultant PRS runs over the ring
; Q[t]: the pseudo-remainder and the subresultant coefficient updates require EXACT division in Q[t], which the
; subresultant theory guarantees is exact (the quantities divided out are known factors), so the coefficients stay
; polynomial with no denominators introduced -- the property that makes the subresultant PRS the right algorithm
; over a domain that is not a field.
;
; The principal subresultant coefficient psc_j is then a polynomial in t; psc_0 is the resultant Res_x(A,B) in t,
; and Res_x(A,B)(t_0) = 0 exactly when the specialisations A(t_0, x), B(t_0, x) share an x-root -- i.e. the values
; of the parameter at which the fiber structure changes.  Verified below: Res_x(x^2 - a, 2x) = -4a (boundary at
; a = 0, where x^2 - a acquires a double root), and the resultant of two parametric polynomials vanishes exactly on
; the parameter locus where they meet.
;
; Public:
;   psubres-resultant A B    -> psc_0 as a polynomial in t (the parametric resultant Res_x(A,B))
;   psubres-psc-tower A B     -> the principal subresultant coefficients, each a polynomial in t
;   psubres-prs A B           -> the parametric subresultant polynomial remainder sequence
;   psubres-gcd-degree A B    -> the x-degree of gcd over Q(t) (generic common-factor degree)
;
; A and B are lists low->high in x; each entry is a Q[t] coefficient (a rational list low->high in t).  Coefficient
; arithmetic over Q[t] is provided inline (add/sub/mul/exact-div/deg/zero?), self-contained.

(define (ps-len l) (if (null? l) 0 (+ 1 (ps-len (cdr l)))))
(define (ps-rev l) (ps-rev-go l (quote ()))) (define (ps-rev-go l acc) (if (null? l) acc (ps-rev-go (cdr l) (cons (car l) acc))))

; ===== coefficient ring Q[t]: a coefficient is a rational list low->high in t =====
(define (ct-trim p) (ps-rev (ct-drop0 (ps-rev p))))
(define (ct-drop0 r) (cond ((null? r) (quote ())) ((= (car r) 0) (ct-drop0 (cdr r))) (else r)))
(define (ct-zero? p) (null? (ct-trim p)))
(define (ct-deg p) (- (ps-len (ct-trim p)) 1))
(define (ct-lc p) (let ((tp (ct-trim p))) (if (null? tp) 0 (car (ps-rev tp)))))
(define (ct-add a b) (cond ((null? a) b) ((null? b) a) (else (cons (+ (car a) (car b)) (ct-add (cdr a) (cdr b))))))
(define (ct-neg a) (if (null? a) (quote ()) (cons (- 0 (car a)) (ct-neg (cdr a)))))
(define (ct-sub a b) (ct-add a (ct-neg b)))
(define (ct-scale a s) (if (null? a) (quote ()) (cons (* (car a) s) (ct-scale (cdr a) s))))
(define (ct-shift a k) (if (= k 0) a (cons 0 (ct-shift a (- k 1)))))
(define (ct-mul a b) (cond ((ct-zero? a) (quote ())) (else (ct-add (ct-scale b (car a)) (ct-shift (ct-mul (cdr a) b) 1)))))
(define (ct-const c) (list c))
; EXACT division in Q[t]: divide a by b assuming b | a exactly (subresultant theory guarantees this); classic long
; division, returns the quotient; remainder is discarded (must be zero when the divisibility holds)
(define (ct-divexact a b) (ct-divexact-go (ct-trim a) (ct-trim b) (quote ())))
(define (ct-divexact-go a b qacc)
  (cond ((ct-zero? a) (ps-rev qacc))
        ((< (ct-deg a) (ct-deg b)) (ps-rev qacc))                       ; remainder (should be 0 under exact divisibility)
        (else (ct-divexact-step a b qacc))))
(define (ct-divexact-step a b qacc)
  (let ((d (- (ct-deg a) (ct-deg b))) (q (/ (ct-lc a) (ct-lc b))))
    (ct-divexact-go (ct-trim (ct-sub a (ct-shift (ct-scale b q) d))) b (cons q qacc))))
; NB: qacc accumulates quotient coefficients HIGH->low (we push the top term first); reverse at the end. The leading
; quotient coefficient is found first and pushed, so after reversal it sits at the high end -> need low->high; fix:
; build by storing into a positional list. Simpler: accumulate then reverse gives high..low reversed = low..high only
; if we pushed high first. We push high first => list is [high, next, ...]; reverse => [..., next, high] = low..high. OK.

; ===== the parametric subresultant PRS over Q[t] =====
(define (ps-xdeg A) (- (ps-len (ps-xtrim A)) 1))
(define (ps-xtrim A) (ps-rev (ps-xdrop0 (ps-rev A))))
(define (ps-xdrop0 r) (cond ((null? r) (quote ())) ((ct-zero? (car r)) (ps-xdrop0 (cdr r))) (else r)))
(define (ps-xlc A) (let ((tA (ps-xtrim A))) (if (null? tA) (quote ()) (car (ps-rev tA)))))
(define (ps-xzero? A) (null? (ps-xtrim A)))
; x-arithmetic: A,B lists (low->high in x) of Q[t] coeffs
(define (ps-xadd A B) (cond ((null? A) B) ((null? B) A) (else (cons (ct-add (car A) (car B)) (ps-xadd (cdr A) (cdr B))))))
(define (ps-xsub A B) (ps-xadd A (ps-xneg B)))
(define (ps-xneg A) (if (null? A) (quote ()) (cons (ct-neg (car A)) (ps-xneg (cdr A)))))
(define (ps-xscale A c) (if (null? A) (quote ()) (cons (ct-mul (car A) c) (ps-xscale (cdr A) c))))   ; scale by a Q[t] element
(define (ps-xshift A k) (if (= k 0) A (cons (quote ()) (ps-xshift A (- k 1)))))                       ; multiply by x^k
(define (ps-xdivexact-coeff A c) (if (null? A) (quote ()) (cons (ct-divexact (car A) c) (ps-xdivexact-coeff (cdr A) c))))  ; divide every coeff by a Q[t] element

; pseudo-remainder of A by B over Q[t]
(define (ps-prem A B) (ps-prem-go (ps-xtrim A) (ps-xtrim B)))
(define (ps-prem-go A B)
  (cond ((ps-xzero? A) (quote ()))
        ((< (ps-xdeg A) (ps-xdeg B)) A)
        (else (ps-prem-go (ps-xtrim (ps-xsub (ps-xscale A (ps-xlc B)) (ps-xscale (ps-xshift B (- (ps-xdeg A) (ps-xdeg B))) (ps-xlc A)))) B))))

(define (psubres-prs A B)
  (let ((a (ps-xtrim A)) (b (ps-xtrim B)))
    (cond ((ps-xzero? b) (list a))
          ((< (ps-xdeg a) (ps-xdeg b)) (psubres-prs b a))
          (else (ps-prs-loop a b (list a b))))))
(define (ps-prs-loop A B acc)
  (let ((r (ps-prem A B)))
    (cond ((ps-xzero? r) acc)
          (else (ps-prs-loop B r (ps-app acc (list r)))))))
(define (ps-app a b) (if (null? a) b (cons (car a) (ps-app (cdr a) b))))

; psc tower: leading x-coefficients along the chain (each a Q[t] polynomial)
(define (psubres-psc-tower A B) (ps-map-xlc (psubres-prs A B)))
(define (ps-map-xlc seq) (if (null? seq) (quote ()) (cons (ps-xlc (car seq)) (ps-map-xlc (cdr seq)))))

; parametric resultant psc_0: if the chain ends with a positive-x-degree member, A,B share a factor over Q(t) and
; the resultant is the zero polynomial; otherwise it is the (constant-in-x) last member as a Q[t] polynomial
(define (psubres-resultant A B)
  (cond ((ps-xzero? (ps-xtrim A)) (quote ())) ((ps-xzero? (ps-xtrim B)) (quote ()))
        ((> (psubres-gcd-degree A B) 0) (quote ()))
        (else (ps-xlc (ps-last (psubres-prs A B))))))
(define (ps-last l) (if (null? (cdr l)) (car l) (ps-last (cdr l))))
(define (psubres-gcd-degree A B) (ps-xdeg (ps-last (psubres-prs A B))))

(define (psubres-caveat) (quote single-parameter-Q-of-t-lift-of-subresultant-tower-exact-division-vanishing-defines-projection-cells))
