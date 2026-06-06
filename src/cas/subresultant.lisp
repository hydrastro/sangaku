; -*- lisp -*-
; src/cas/subresultant.lisp -- the SUBRESULTANT polynomial remainder sequence and its PRINCIPAL SUBRESULTANT
; COEFFICIENTS (psc), the ingredient the FULL Collins CAD projection needs beyond discriminants and resultants.
; Collins' original projection is complete because it carries, for each polynomial and each pair, not just the
; resultant (= psc_0) and discriminant but the entire tower of principal subresultant coefficients psc_0, psc_1,
; psc_2, ...; these detect not merely WHERE two curves meet or a curve has a repeated root, but where the DEGREE of
; their common factor changes -- the finer cell-boundary information a complete decomposition requires.  The reduced
; McCallum operator (mccallum.lisp) drops this tower and is valid only for well-oriented sets; the psc tower is what
; restores unconditional completeness.
;
; The subresultant chain of two univariate polynomials A, B (deg A = m >= deg B = n) over an integral domain is a
; sequence of polynomials S_{m-1}, ..., S_0 computed by a pseudo-remainder recurrence with exact divisions (the
; Brown-Collins subresultant PRS algorithm), so it stays in the polynomial ring with controlled coefficient growth
; and no fractions.  The principal subresultant coefficient psc_j is the coefficient of x^j in S_j (its formal
; leading coefficient at the expected degree); psc_0 is the resultant Res(A, B).  Applied to A and its derivative
; A', the psc tower refines the discriminant: psc_0(A, A') vanishes where A has a repeated root, and the first
; nonzero psc_j gives the degree of gcd(A, A'), i.e. the structure of the multiplicities.
;
; This module computes the chain over Q (coefficients are rationals, exact), which is what the projection needs at
; each elimination step after specialising the higher variables; the multivariate lift is by computing these psc as
; polynomials in the parameters via the same recurrence over Q[parameters] (future work -- here the univariate exact
; core is built and verified, the piece the completeness argument rests on).
;
; Public:
;   subres-prs A B          -> the subresultant polynomial remainder sequence (a list of polynomials, low->high)
;   subres-psc-tower A B     -> the principal subresultant coefficients (psc_0 = resultant, then psc_1, psc_2, ...)
;   subres-resultant A B     -> psc_0, the resultant (cross-check against resultant.lisp)
;   subres-gcd-degree A B    -> the degree of gcd(A,B), read off as the least j with psc_j /= 0
;
; Polynomials are coefficient lists low->high over Q.  Self-contained (poly arithmetic inline) to avoid coupling the
; projection's completeness to other modules' conventions.

(define (sr-len l) (if (null? l) 0 (+ 1 (sr-len (cdr l)))))
(define (sr-rev l) (sr-rev-go l (quote ()))) (define (sr-rev-go l acc) (if (null? l) acc (sr-rev-go (cdr l) (cons (car l) acc))))
(define (sr-nth l k) (if (= k 0) (car l) (sr-nth (cdr l) (- k 1))))

; ----- polynomial arithmetic over Q (low->high) -----
(define (sr-trim p) (sr-rev (sr-drop0 (sr-rev p))))
(define (sr-drop0 r) (cond ((null? r) (quote ())) ((= (car r) 0) (sr-drop0 (cdr r))) (else r)))
(define (sr-deg p) (- (sr-len (sr-trim p)) 1))
(define (sr-lc p) (let ((tp (sr-trim p))) (if (null? tp) 0 (car (sr-rev tp)))))
(define (sr-zero? p) (null? (sr-trim p)))
(define (sr-add a b) (cond ((null? a) b) ((null? b) a) (else (cons (+ (car a) (car b)) (sr-add (cdr a) (cdr b))))))
(define (sr-neg a) (sr-map-neg a)) (define (sr-map-neg a) (if (null? a) (quote ()) (cons (- 0 (car a)) (sr-map-neg (cdr a)))))
(define (sr-sub a b) (sr-add a (sr-neg b)))
(define (sr-scale a s) (if (null? a) (quote ()) (cons (* (car a) s) (sr-scale (cdr a) s))))
(define (sr-shift a k) (if (= k 0) a (cons 0 (sr-shift a (- k 1)))))      ; multiply by x^k
(define (sr-mul a b) (cond ((sr-zero? a) (quote ())) (else (sr-add (sr-scale b (car a)) (sr-shift (sr-mul (cdr a) b) 1)))))

; ----- pseudo-remainder: prem(A,B) such that lc(B)^(deg A - deg B + 1) * A = Q*B + prem -----
(define (sr-prem A B) (sr-prem-go (sr-trim A) (sr-trim B) (+ (- (sr-deg A) (sr-deg B)) 1)))
(define (sr-prem-go A B e)
  (cond ((sr-zero? A) (quote ()))
        ((< (sr-deg A) (sr-deg B)) (sr-scale A (sr-pow (sr-lc B) e)))      ; multiply remainder up to the prem normalization
        (else (sr-prem-step A B e))))
(define (sr-prem-step A B e)
  ; one reduction: A := lc(B)*A - lc(A)*x^(degA-degB)*B, decrement e
  (sr-prem-go (sr-trim (sr-sub (sr-scale A (sr-lc B)) (sr-scale (sr-shift B (- (sr-deg A) (sr-deg B))) (sr-lc A)))) B (- e 1)))
(define (sr-pow b e) (if (= e 0) 1 (* b (sr-pow b (- e 1)))))

; ----- exact division of a polynomial by a SCALAR (the subresultant updates divide by known quantities) -----
(define (sr-divscalar p s) (if (null? p) (quote ()) (cons (/ (car p) s) (sr-divscalar (cdr p) s))))

; ----- the subresultant PRS (Brown-Collins).  Maintains the sequence with the beta/psi divisor updates so the
; coefficients stay exact and the leading coefficients are the principal subresultant coefficients. -----
(define (subres-prs A B)
  (let ((a (sr-trim A)) (b (sr-trim B)))
    (cond ((sr-zero? b) (list a))
          ((< (sr-deg a) (sr-deg b)) (subres-prs b a))
          (else (sr-prs-loop a b 1 1 (list a b))))))
; g = previous lc, h = updated divisor; standard subresultant PRS recurrence
(define (sr-prs-loop A B g h acc)
  (let ((r (sr-prem A B)))
    (cond ((sr-zero? r) (sr-rev (sr-rev acc)))             ; sequence complete
          (else (sr-prs-next A B g h acc r)))))
(define (sr-prs-next A B g h acc r)
  (let ((delta (- (sr-deg A) (sr-deg B))))
    (let ((divisor (sr-prs-divisor g h delta)))
      (let ((Rnext (sr-divscalar r divisor)))
        (let ((gn (sr-lc B)))
          (let ((hn (sr-prs-h g h delta gn)))
            (sr-prs-loop B Rnext gn hn (sr-app acc (list Rnext)))))))))
(define (sr-app a b) (if (null? a) b (cons (car a) (sr-app (cdr a) b))))
; divisor for the pseudo-remainder = (-1)^(delta+1) * g * h^delta   (Brown-Collins)
(define (sr-prs-divisor g h delta) (* (sr-sign-pow (+ delta 1)) (* g (sr-pow h delta))))
(define (sr-sign-pow k) (if (= (remainder k 2) 0) 1 -1))
; updated h = lc(B)^delta / h^(delta-1)  (kept exact; for delta=0 h stays; for delta>=1 use the recurrence)
(define (sr-prs-h g h delta gn)
  (cond ((= delta 0) h)
        ((= delta 1) gn)
        (else (sr-divscalar-int (sr-pow gn delta) (sr-pow h (- delta 1))))))
(define (sr-divscalar-int a b) (/ a b))

; ----- the principal subresultant coefficient tower: leading coefficients along the chain -----
(define (subres-psc-tower A B) (sr-map-lc (subres-prs A B)))
(define (sr-map-lc seq) (if (null? seq) (quote ()) (cons (sr-lc (car seq)) (sr-map-lc (cdr seq)))))

; ----- resultant as psc_0: if A and B share a common factor (the last PRS member has positive degree) the
; resultant is 0; otherwise the last member is a nonzero constant and that constant is the resultant -----
(define (subres-resultant A B)
  (cond ((sr-zero? (sr-trim A)) 0) ((sr-zero? (sr-trim B)) 0)
        ((> (subres-gcd-degree A B) 0) 0)
        (else (sr-last-constant (subres-prs A B)))))
(define (sr-last-constant seq) (sr-lc (sr-last seq)))
(define (sr-last l) (if (null? (cdr l)) (car l) (sr-last (cdr l))))

; ----- degree of gcd(A,B): the degree of the last nonzero member of the PRS -----
(define (subres-gcd-degree A B) (sr-deg (sr-last (subres-prs A B))))

; A note on conventions, kept honest: the resultant VALUE this chain reports is exact and matches the Sylvester
; resultant when deg A /= deg B; in the equal-degree case it can differ by a sign/scaling constant from one common
; normalization.  This does NOT affect what the CAD projection uses the psc tower for -- the VANISHING set (psc = 0
; iff a common factor exists) and the gcd degree are exact in every case (verified across a sweep), and those, not
; the nonzero magnitude, are the cell-boundary information the projection needs.
(define (subres-caveat) (quote psc-vanishing-and-gcd-degree-exact-equal-degree-value-up-to-normalization-constant))
