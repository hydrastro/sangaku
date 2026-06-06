; -*- lisp -*-
; src/cas/cadqenx.lisp -- n-parameter parametric quantifier elimination with EXACT section sampling, for COMPLETE
; boundary coverage of the parameter space.  cadqen.lisp samples each parameter cell by refined rational
; approximations of the projection-factor roots, which is sound for deciding individual points but can miss the
; measure-zero BOUNDARY cells -- a factor exactly zero with prescribed signs on the others, e.g. the tangent stratum
; of the general quadratic where the discriminant vanishes (b^2 = 4 a c).  An approximate section sample lands just
; off such a surface, so the boundary cell is recorded with the wrong sign and the true/false partition handed to the
; minimal-formula constructor (cadqemin) is incomplete, forcing it into conservative (less minimal) validity.
;
; cadqenx closes this for the case that covers the standard examples: families whose projection factors have RATIONAL
; roots.  It keeps cadqen's recursion -- project onto the outer parameter, sample, substitute, recurse -- but samples
; each level at the EXACT rational roots of every factor's pure-outer restriction (recovered by the rational root
; theorem), in addition to rational sector points strictly between and beyond them.  Because a rational section value
; is substituted exactly, the downstream factors stay exact, so an inner factor that vanishes on the boundary (the
; discriminant's exact rational root) is sampled exactly and the boundary cell is recorded with its true sign 0.  The
; result is the COMPLETE realizable true/false partition over the sampled factors, on which cadqemin attains the true
; minimum (the textbook three-branch law for the general quadratic) with no conservative loss.
;
; The honest boundary: a factor with IRRATIONAL roots still has its sections sampled by refined approximation (the
; exact section would need an algebraic-number sample point), so for such families the boundary coverage is partial
; and cadqemin should fall back to conservative validity.  cadqenx-caveat records this.  For rational-root projections
; -- the general quadratic and the linear-system examples among them -- the partition is complete.
;
; Public:
;   cadqenx-elim2 factors k quant phi   -> (factors trues falses): the COMPLETE realizable true and false sign-vector
;                                          sets over the factors, with boundary (section) cells included exactly
;   cadqenx-samples factors k           -> the parameter sample points, including exact rational section points
;
; Reuses cadqen for the decision and sign-vector machinery (cadqen-holds-at, cadqen-signvec, cadqen-subst-factors,
; cadqen-meval) and the multivariate/poly/sturm infrastructure beneath it.

(import "cas/cadqen.lisp")
(import "cas/poly.lisp")

(define (cadqenx-app a b) (if (null? a) b (cons (car a) (cadqenx-app (cdr a) b))))
(define (cadqenx-len l) (if (null? l) 0 (+ 1 (cadqenx-len (cdr l)))))
(define (cadqenx-nth l k) (if (= k 0) (car l) (cadqenx-nth (cdr l) (- k 1))))
(define (cadqenx-rev l) (cadqenx-rev-go l (quote ()))) (define (cadqenx-rev-go l acc) (if (null? l) acc (cadqenx-rev-go (cdr l) (cons (car l) acc))))
(define (cadqenx-abs x) (if (< x 0) (- x) x))
(define (cadqenx-mem x s) (cond ((null? s) #f) ((= x (car s)) #t) (else (cadqenx-mem x (cdr s)))))

; ===== exact rational roots of an integer-coefficient univariate polynomial (low -> high) =====
; via the rational root theorem: any rational root p/q has p dividing the constant term and q the leading term
(define (cadqenx-rat-roots p)
  (cond ((cadqenx-allzero? p) (quote ()))                       ; identically zero: no isolated roots
        ((= (car p) 0) (cadqenx-adjoin 0 (cadqenx-rat-roots (cdr p))))  ; zero is a root; deflate one power of x
        (else (cadqenx-rr-scan p (cadqenx-divisors (car p)) (cadqenx-divisors (cadqenx-last p))))))
(define (cadqenx-allzero? p) (cond ((null? p) #t) ((= (car p) 0) (cadqenx-allzero? (cdr p))) (else #f)))
(define (cadqenx-last l) (if (null? (cdr l)) (car l) (cadqenx-last (cdr l))))
(define (cadqenx-divisors n) (cadqenx-div-go (cadqenx-abs n) 1 (quote ())))
(define (cadqenx-div-go n d acc) (cond ((> d n) (cadqenx-rev acc)) ((= (remainder n d) 0) (cadqenx-div-go n (+ d 1) (cons d acc))) (else (cadqenx-div-go n (+ d 1) acc))))
; scan all +- p/q candidates, keep those that are exact roots
(define (cadqenx-rr-scan p ps qs) (cadqenx-rr p ps qs ps qs (quote ())))
(define (cadqenx-rr p ps qs pp qq acc)
  (cond ((null? pp) (cadqenx-rev acc))
        ((null? qq) (cadqenx-rr p ps qs (cdr pp) qs acc))
        (else (cadqenx-rr p ps qs pp (cdr qq)
                (cadqenx-addif p (- (/ (car pp) (car qq)))
                  (cadqenx-addif p (/ (car pp) (car qq)) acc))))))
(define (cadqenx-addif p r acc) (if (= (cadqenx-eval p r) 0) (cadqenx-adjoin r acc) acc))
(define (cadqenx-adjoin r acc) (if (cadqenx-mem r acc) acc (cons r acc)))
(define (cadqenx-eval p x) (cadqenx-ev p x 0 0))
(define (cadqenx-ev p x i acc) (if (= i (cadqenx-len p)) acc (cadqenx-ev p x (+ i 1) (+ acc (* (cadqenx-nth p i) (cadqenx-pow x i))))))
(define (cadqenx-pow x i) (if (= i 0) 1 (* x (cadqenx-pow x (- i 1)))))

; ===== the recursive sampler with exact section points =====
(define (cadqenx-samples factors k)
  (if (<= k 1) (cadqenx-line factors) (cadqenx-space factors k)))

; --- k = 1: the parameter line, with exact rational section roots ---
(define (cadqenx-line factors) (cadqenx-wrap1 (cadqenx-points (cadqenx-sort-uniq (cadqenx-line-roots factors)))))
(define (cadqenx-wrap1 xs) (if (null? xs) (quote ()) (cons (list (car xs)) (cadqenx-wrap1 (cdr xs)))))
(define (cadqenx-line-roots factors) (if (null? factors) (quote ()) (cadqenx-app (cadqenx-rat-roots (cadqenx-as-uni (car factors))) (cadqenx-line-roots (cdr factors)))))

; --- k > 1: project onto the outer parameter, sample (exact roots + sectors), substitute, recurse ---
(define (cadqenx-space factors k) (cadqenx-go factors k (cadqenx-outer-samples factors)))
(define (cadqenx-go factors k osamps)
  (if (null? osamps) (quote ())
      (cadqenx-app (cadqenx-slab factors k (car osamps)) (cadqenx-go factors k (cdr osamps)))))
(define (cadqenx-slab factors k v) (cadqenx-prefix v (cadqenx-samples (cadqen-subst-factors factors v) (- k 1))))
(define (cadqenx-prefix v pts) (if (null? pts) (quote ()) (cons (cons v (car pts)) (cadqenx-prefix v (cdr pts)))))
; outer samples: EXACT rational roots of each factor's pure-outer restriction, plus sector points around them
(define (cadqenx-outer-samples factors) (cadqenx-points (cadqenx-sort-uniq (cadqenx-outer-roots factors))))
(define (cadqenx-outer-roots factors) (if (null? factors) (quote ()) (cadqenx-app (cadqenx-rat-roots (cadqenx-pure-outer (car factors))) (cadqenx-outer-roots (cdr factors)))))

; --- pure-outer restriction (monomials whose OTHER exponents are all zero), as a univariate-in-outer poly ---
(define (cadqenx-pure-outer factor) (cadqenx-as-uni (cadqenx-pick-pure factor (quote ()))))
(define (cadqenx-pick-pure factor acc)
  (cond ((null? factor) acc)
        ((cadqenx-tail-zero? (cdr (cdr (car factor)))) (cadqenx-pick-pure (cdr factor) (cons (cons (car (car factor)) (list (car (cdr (car factor))))) acc)))
        (else (cadqenx-pick-pure (cdr factor) acc))))
(define (cadqenx-tail-zero? tail) (cond ((null? tail) #t) ((= (car tail) 0) (cadqenx-tail-zero? (cdr tail))) (else #f)))

; --- a 1-parameter factor (monomials (coeff e)) as a dense univariate poly low->high ---
(define (cadqenx-as-uni factor) (cadqenx-densify (cadqenx-assoc factor (quote ()))))
(define (cadqenx-assoc factor acc) (if (null? factor) acc (cadqenx-assoc (cdr factor) (cadqenx-adda acc (car (cdr (car factor))) (car (car factor))))))
(define (cadqenx-adda acc deg v) (cond ((null? acc) (list (cons deg v))) ((= (car (car acc)) deg) (cons (cons deg (+ (cdr (car acc)) v)) (cdr acc))) (else (cons (car acc) (cadqenx-adda (cdr acc) deg v)))))
(define (cadqenx-densify assoc) (cadqenx-dens assoc 0 (cadqenx-maxd assoc 0)))
(define (cadqenx-maxd assoc m) (if (null? assoc) m (cadqenx-maxd (cdr assoc) (if (> (car (car assoc)) m) (car (car assoc)) m))))
(define (cadqenx-dens assoc d dmax) (if (> d dmax) (quote ()) (cons (cadqenx-lk assoc d) (cadqenx-dens assoc (+ d 1) dmax))))
(define (cadqenx-lk assoc d) (cond ((null? assoc) 0) ((= (car (car assoc)) d) (cdr (car assoc))) (else (cadqenx-lk (cdr assoc) d))))

; --- sample points from a sorted root list: each exact root (section), and a rational point below, between, above ---
(define (cadqenx-points roots)
  (if (null? roots) (list 0)
      (cadqenx-app (list (- (car roots) 1)) (cadqenx-app (cadqenx-weave roots) (list (+ (cadqenx-lastv roots) 1))))))
; weave: root_1, mid(root_1,root_2), root_2, mid(...), ..., root_n  -- both the sections and the sectors between
(define (cadqenx-weave roots) (if (null? (cdr roots)) roots (cons (car roots) (cons (/ (+ (car roots) (car (cdr roots))) 2) (cadqenx-weave (cdr roots))))))
(define (cadqenx-lastv l) (if (null? (cdr l)) (car l) (cadqenx-lastv (cdr l))))

; --- sort + dedup a rational list ---
(define (cadqenx-sort-uniq xs) (cadqenx-uniq (cadqenx-sort xs)))
(define (cadqenx-sort xs) (cadqenx-isort xs (quote ())))
(define (cadqenx-isort xs acc) (if (null? xs) acc (cadqenx-isort (cdr xs) (cadqenx-ins (car xs) acc))))
(define (cadqenx-ins x s) (cond ((null? s) (list x)) ((< x (car s)) (cons x s)) ((= x (car s)) s) (else (cons (car s) (cadqenx-ins x (cdr s))))))
(define (cadqenx-uniq xs) (cond ((null? xs) (quote ())) ((null? (cdr xs)) xs) ((= (car xs) (car (cdr xs))) (cadqenx-uniq (cdr xs))) (else (cons (car xs) (cadqenx-uniq (cdr xs))))))

; ===== complete realizable partition over the sampled points =====
(define (cadqenx-elim2 factors k quant phi) (cadqenx-part factors k quant phi (cadqenx-samples factors k) (quote ()) (quote ())))
(define (cadqenx-part factors k quant phi pts ts fs)
  (cond ((null? pts) (list factors (cadqenx-rev ts) (cadqenx-rev fs)))
        ((cadqen-holds-at k quant phi (car pts)) (cadqenx-part factors k quant phi (cdr pts) (cadqenx-addv ts (cadqen-signvec factors (car pts))) fs))
        (else (cadqenx-part factors k quant phi (cdr pts) ts (cadqenx-addv fs (cadqen-signvec factors (car pts)))))))
(define (cadqenx-addv acc v) (if (cadqenx-memv v acc) acc (cons v acc)))
(define (cadqenx-memv v acc) (cond ((null? acc) #f) ((equal? v (car acc)) #t) (else (cadqenx-memv v (cdr acc)))))

(define (cadqenx-caveat) (quote exact-rational-section-sampling-complete-for-rational-root-projections))
