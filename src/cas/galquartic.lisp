; -*- lisp -*-
; src/cas/galquartic.lisp -- the GALOIS GROUP of a quartic, by its resolvent cubic and discriminant.  This is the
; classical decision that completes the story the worked examples tell: the quintic x^5 - x - 1 is unsolvable by
; radicals because its Galois group is the non-solvable S_5, while every quartic IS solvable because each of the five
; possible Galois groups of a quartic -- S_4, A_4, the dihedral D_4, the cyclic C_4, the Klein four-group V_4 -- is
; solvable.  For a quartic the group, and with it the precise structure of the radical solution, is computable
; exactly from two pieces of data, and that computation is what this module performs.
;
; The method (for an irreducible quartic; reducibility is detected first by a rational root and by factoring off a
; rational quadratic).  Depress x^4 + a x^3 + b x^2 + c x + d by x -> x - a/4 to x^4 + p x^2 + q x + r, form the
; RESOLVENT CUBIC y^3 - p y^2 - 4 r y + (4 p r - q^2), count its rational roots m, and test whether the quartic's
; DISCRIMINANT is a perfect rational square.  Then:
;   m = 3  (resolvent splits completely)          -> V_4, the Klein four-group;
;   m = 0  (resolvent irreducible), disc square    -> A_4;
;   m = 0  (resolvent irreducible), disc non-square -> S_4;
;   m = 1  (resolvent has one rational root)        -> C_4 or D_4, the two distinguished by whether the quartic
;                                                      remains irreducible over the field adjoining the square root
;                                                      of the discriminant (D_4) or factors there (C_4).
; The discriminant of a quartic is invariant under depression, so it is computed once from p, q, r.
;
; Scope, kept honest (galq-caveat).  The module reports the group exactly in the cases the resolvent and
; discriminant settle outright -- V_4, A_4, S_4 -- and reports the unresolved C_4-or-D_4 pair when m = 1 (the
; tie-break needs irreducibility testing over a quadratic extension, which this module does not perform).  All five
; groups are solvable, so the SOLVABILITY verdict is unconditional and total for every quartic; only the finer
; C_4-vs-D_4 naming is deferred.  Reducible quartics are reported as such (their group is read off the factors).
;
; Public:
;   galq-group  a b c d   -> the Galois group of x^4 + a x^3 + b x^2 + c x + d (rational a,b,c,d), as a symbol:
;                            V4 / A4 / S4 / C4-or-D4 / reducible
;   galq-solvable? a b c d -> #t always for a quartic (every quartic group is solvable); the certificate that the
;                             radical solution exists
;   galq-resolvent a b c d -> the resolvent cubic (after depressing), as a polynomial low -> high
;   galq-discriminant a b c d -> the discriminant of the quartic (a rational number)
;
; Builds on poly.lisp, the exact rational-root recovery of cadqenx (cadqenx-rat-roots), and sturm.lisp.

(import "cas/poly.lisp")
(import "cas/cadqenx.lisp")
(import "cas/sturm.lisp")

(define (galq-len l) (if (null? l) 0 (+ 1 (galq-len (cdr l)))))

; ----- depress x^4 + a x^3 + b x^2 + c x + d by x -> x - a/4, returning (p q r) of x^4 + p x^2 + q x + r -----
; p = b - 3a^2/8 ; q = c - a b/2 + a^3/8 ; r = d - a c/4 + a^2 b/16 - 3 a^4/256
(define (galq-depress a b c d) (list (galq-p a b) (galq-q a b c) (galq-r a b c d)))
(define (galq-p a b) (- b (/ (* 3 (* a a)) 8)))
(define (galq-q a b c) (+ (- c (/ (* a b) 2)) (/ (* a (* a a)) 8)))
(define (galq-r a b c d) (- (+ (- d (/ (* a c) 4)) (/ (* (* a a) b) 16)) (/ (* 3 (* (* a a) (* a a))) 256)))

; ----- resolvent cubic of the depressed quartic: y^3 - p y^2 - 4 r y + (4 p r - q^2) -----
(define (galq-resolvent a b c d) (galq-resolvent-dep (galq-depress a b c d)))
(define (galq-resolvent-dep pqr) (galq-rc (car pqr) (car (cdr pqr)) (car (cdr (cdr pqr)))))
(define (galq-rc p q r) (list (- (* 4 (* p r)) (* q q)) (- 0 (* 4 r)) (- 0 p) 1))

; ----- discriminant of x^4 + p x^2 + q x + r (depression-invariant) -----
; 16 p^4 r - 4 p^3 q^2 - 128 p^2 r^2 + 144 p q^2 r - 27 q^4 + 256 r^3
(define (galq-discriminant a b c d) (galq-disc-dep (galq-depress a b c d)))
(define (galq-disc-dep pqr) (galq-disc (car pqr) (car (cdr pqr)) (car (cdr (cdr pqr)))))
(define (galq-disc p q r)
  (+ (- (+ (- (- (* 16 (* (galq-pow p 4) r)) (* 4 (* (galq-pow p 3) (* q q))))
              (* 128 (* (* p p) (* r r))))
           (* 144 (* p (* (* q q) r))))
        (* 27 (galq-pow q 4)))
     (* 256 (galq-pow r 3))))
(define (galq-pow x n) (if (= n 0) 1 (* x (galq-pow x (- n 1)))))

; ----- perfect-rational-square test -----
(define (galq-square? x) (and (galq-int-square? (numerator x)) (galq-int-square? (denominator x))))
(define (galq-int-square? n) (if (< n 0) #f (= (* (galq-isqrt n) (galq-isqrt n)) n)))
(define (galq-isqrt n) (galq-isqrt-go n 0)) (define (galq-isqrt-go n k) (if (> (* k k) n) (- k 1) (galq-isqrt-go n (+ k 1))))

; ----- reducibility: a rational root, or a rational quadratic factor -----
; an irreducible quartic is needed for the group naming; reducibility short-circuits to the 'reducible report.  A
; quartic that splits into two rational quadratics is detected by searching for an integer monic quadratic factor
; x^2 + s x + t dividing it (the factor's integer coefficients are bounded in size by the quartic's coefficients,
; so a bounded scan is a sound reducibility test for the integer-coefficient quartics handled here)
(define (galq-reducible? a b c d)
  (cond ((galq-any-root? (cadqenx-rat-roots (list d c b a 1))) #t)
        (else (galq-has-quad-factor? (list d c b a 1)))))
(define (galq-any-root? roots) (cond ((null? roots) #f) (else #t)))
(define (galq-has-quad-factor? quartic) (galq-scan-s quartic (galq-bound quartic)))
(define (galq-bound quartic) (+ 1 (galq-maxabs quartic)))
(define (galq-maxabs p) (galq-maxabs-go p 0))
(define (galq-maxabs-go p m) (if (null? p) m (galq-maxabs-go (cdr p) (galq-max m (galq-abs (car p))))))
(define (galq-abs x) (if (< x 0) (- x) x))
(define (galq-max a b) (if (> a b) a b))
(define (galq-scan-s quartic bnd) (galq-ss quartic (- 0 bnd) (- 0 bnd) bnd))
(define (galq-ss quartic s t bnd)
  (cond ((> s bnd) #f)
        ((> t bnd) (galq-ss quartic (+ s 1) (- 0 bnd) bnd))
        ((galq-divides? quartic s t) #t)
        (else (galq-ss quartic s (+ t 1) bnd))))
(define (galq-divides? quartic s t) (galq-zero? (car (cdr (poly-divmod quartic (list t s 1))))))
(define (galq-zero? p) (cond ((null? p) #t) ((= (car p) 0) (galq-zero? (cdr p))) (else #f)))

; ----- the Galois group -----
(define (galq-group a b c d)
  (cond ((galq-reducible? a b c d) (quote reducible))
        (else (galq-classify (galq-num-rat-roots (galq-resolvent a b c d)) (galq-discriminant a b c d)))))
(define (galq-num-rat-roots cubic) (galq-len (cadqenx-rat-roots cubic)))
(define (galq-classify m disc)
  (cond ((>= m 3) (quote V4))
        ((= m 0) (if (galq-square? disc) (quote A4) (quote S4)))
        (else (quote C4-or-D4))))                ; m = 1: C4 or D4, tie-break deferred (galq-caveat)

; ----- solvability: every quartic group is solvable, so the radical solution always exists -----
(define (galq-solvable? a b c d) #t)

(define (galq-caveat) (quote quartic-group-exact-except-C4-vs-D4-tiebreak-which-needs-extension-irreducibility))
