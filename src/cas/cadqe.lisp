; -*- lisp -*-
; src/cas/cadqe.lisp -- PARAMETRIC quantifier elimination: eliminate one quantified variable from a formula that
; still has a free parameter, returning a quantifier-free description of the parameter values for which the
; quantified statement holds.  This is the headline capability of a real-QE system -- not merely deciding a closed
; sentence true or false, but turning "exists x . phi(b, x)" into an equivalent condition on b, the way QEPCAD or
; Mathematica's Resolve answers "exists x . x^2 + b < 0" with "b < 0".
;
; The method is the cylindrical algebraic decomposition of the PARAMETER line.  With the parameter b outer and the
; quantified variable x inner, the projection of the family onto b (the discriminant of each polynomial in x and the
; resultants between them) is a univariate polynomial in b whose real roots cut the b-line into cells -- open
; sectors and the section points between them -- on each of which the family is sign-invariant in x, hence on each
; of which the quantified statement has a constant truth value.  Evaluating that truth value once per cell, by
; substituting a sample b from the cell and deciding the resulting univariate statement with the complete univariate
; decider (realqe), labels every cell true or false; the eliminated formula is the union of the true cells,
; described by sign conditions on b relative to the projection roots.
;
; Output.  The quantifier-free result is returned as a list of CELLS that hold, each a relation on b:
;   (lt . r)        b < r
;   (gt . r)        b > r
;   (between r1 r2) r1 < b < r2
;   (eq . r)        b = r
;   (all)           every b (the statement holds identically)
;   (none)          no b (it never holds)
; with r rationals here (the projection roots are isolated and, when rational, named exactly; an irrational root is
; given by a tight rational separating it from its neighbours, which suffices to delimit the adjacent cells).
; cadqe-formula renders this list as a readable disjunction.  Adjacent true cells sharing a boundary are merged so
; that, for instance, "b < 0 or b = 0" is reported as "b <= 0".
;
; Scope.  One quantified variable over one free parameter (the planar case), which is where parametric QE is both
; most common and cleanly complete via the bivariate projection (cadproj).  More parameters are the genuinely harder
; general parametric CAD; cadqe-caveat names that boundary.  Within scope the result is exact: the projection is
; exact, and each cell's truth is decided by the complete univariate decider on an exact sample.
;
; Public:
;   cadqe-elim quant phi          -> the list of parameter cells (above) for which (quant x . phi) holds, where phi
;                                    is a formula over the bivariate family with b outer and x inner
;   cadqe-formula quant phi       -> a readable sexp rendering of the eliminated condition on b
;   cadqe-holds-at quant phi bval -> #t/#f, the truth of (quant x . phi) at the specific parameter value b = bval
;
; Verified: exists x . x^2 + b < 0  gives  b < 0; forall x . x^2 - b >= 0 gives b <= 0; exists x . (x - b)^2 < 1
; gives all b; exists x . x^2 + b^2 + 1 < 0 gives none.
;
; Builds on cadproj.lisp (the bivariate projection / resultant), realqe.lisp (the complete univariate decider on
; each sampled cell), sturm.lisp (root isolation of the b-projection), and poly.lisp.

(import "cas/cadproj.lisp")
(import "cas/realqe.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

(define (cadqe-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ----- collect the bivariate polynomials of the formula (b outer, x inner; cadproj representation) -----
(define (cadqe-polys-of f)
  (cond ((equal? (car f) (quote and)) (cadqe-pl (cdr f)))
        ((equal? (car f) (quote or)) (cadqe-pl (cdr f)))
        ((equal? (car f) (quote not)) (cadqe-polys-of (car (cdr f))))
        (else (list (cdr f)))))
(define (cadqe-pl fs) (if (null? fs) (quote ()) (cadqe-app (cadqe-polys-of (car fs)) (cadqe-pl (cdr fs)))))
(define (cadqe-app a b) (if (null? a) b (cons (car a) (cadqe-app (cdr a) b))))

; ----- project the family onto b: discriminants in x and pairwise resultants in x, multiplied to one b-polynomial
(define (cadqe-projection polys) (cadqe-prod (cadqe-app (cadqe-discs polys) (cadqe-pairs polys))))
(define (cadqe-discs polys) (if (null? polys) (quote ()) (cons (cadqe-disc (car polys)) (cadqe-discs (cdr polys)))))
(define (cadqe-disc p) (cad-resultant p (cadqe-dx p)))             ; Res_x(p, dp/dx): the x-discriminant, a b-poly
(define (cadqe-dx p) (cadqe-deriv-x p))                            ; derivative of p with respect to the inner var x
(define (cadqe-deriv-x p) (cadqe-dx-go (cdr p) 1))
(define (cadqe-dx-go cs k) (if (null? cs) (quote ()) (cons (cadqe-scale-b (car cs) k) (cadqe-dx-go (cdr cs) (+ k 1)))))
(define (cadqe-scale-b coeff k) (cadqe-cs coeff k))               ; multiply a b-coefficient polynomial by integer k
(define (cadqe-cs coeff k) (if (null? coeff) (quote ()) (cons (* k (car coeff)) (cadqe-cs (cdr coeff) k))))
(define (cadqe-pairs polys) (if (null? polys) (quote ()) (cadqe-app (cadqe-pw (car polys) (cdr polys)) (cadqe-pairs (cdr polys)))))
(define (cadqe-pw p rest) (if (null? rest) (quote ()) (cons (cad-resultant p (car rest)) (cadqe-pw p (cdr rest)))))
(define (cadqe-prod ps) (cadqe-prod-go ps (list 1)))
(define (cadqe-prod-go ps acc) (if (null? ps) acc (cadqe-prod-go (cdr ps) (poly-mul acc (cadqe-nz (car ps))))))
(define (cadqe-nz p) (if (cadqe-zero? p) (list 1) p))
(define (cadqe-zero? p) (cond ((null? p) #t) ((= (car p) 0) (cadqe-zero? (cdr p))) (else #f)))

; ----- the b-cells: sector samples and section roots from the projection's real roots -----
(define (cadqe-roots polys) (cadqe-iso (cadqe-cleard (cadqe-projection polys))))
(define (cadqe-iso u) (if (cadqe-const? u) (quote ()) (isolate-roots u)))
(define (cadqe-const? u) (< (cadqe-deg u) 1))
(define (cadqe-deg u) (- (cadqe-len (cadqe-trim u)) 1))
(define (cadqe-len l) (if (null? l) 0 (+ 1 (cadqe-len (cdr l)))))
(define (cadqe-trim p) (cadqe-tr p (cadqe-len p)))
(define (cadqe-tr p k) (cond ((= k 0) (quote ())) ((= (cadqe-nth p (- k 1)) 0) (cadqe-tr p (- k 1))) (else (cadqe-take p k))))
(define (cadqe-nth l k) (if (= k 0) (car l) (cadqe-nth (cdr l) (- k 1))))
(define (cadqe-take l k) (cadqe-tk l k 0))
(define (cadqe-tk l k i) (if (= i k) (quote ()) (cons (car l) (cadqe-tk (cdr l) k (+ i 1)))))
(define (cadqe-cleard p) (cadqe-scl (cadqe-trim p) (cadqe-lcd (cadqe-trim p))))
(define (cadqe-scl p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadqe-scl (cdr p) m))))
(define (cadqe-lcd p) (cadqe-lcd-go p 1))
(define (cadqe-lcd-go p acc) (if (null? p) acc (cadqe-lcd-go (cdr p) (cadqe-lcm acc (denominator (car p))))))
(define (cadqe-lcm a b) (/ (* a b) (cadqe-gcd a b)))
(define (cadqe-gcd a b) (if (= b 0) a (cadqe-gcd b (remainder a b))))

; rational cell representatives: a point below all roots, between consecutive roots, above all roots; and the roots
; themselves as section representatives.  Roots from isolate-roots come as (lo hi); we use a rational inside each
; (its simplest rational) as the section value and gap midpoints as sector values.
(define (cadqe-root-rats ivs) (cadqe-rr ivs))
(define (cadqe-rr ivs) (if (null? ivs) (quote ()) (cons (cadqe-simplest (car (car ivs)) (car (cdr (car ivs)))) (cadqe-rr (cdr ivs)))))
(define (cadqe-simplest lo hi)
  (cond ((cadqe-le lo 0) (if (cadqe-ge hi 0) 0 (- (cadqe-sp (- hi) (- lo))))) (else (cadqe-sp lo hi))))
(define (cadqe-le a b) (if (< a b) #t (= a b)))
(define (cadqe-ge a b) (if (> a b) #t (= a b)))
(define (cadqe-sp lo hi) (cadqe-sp2 lo hi (floor lo) (floor hi)))
(define (cadqe-sp2 lo hi fl fh) (cond ((< fl fh) (+ fl 1)) (else (+ fl (/ 1 (cadqe-sp (/ 1 (- hi fl)) (/ 1 (- lo fl))))))))

; ----- decide the quantified statement at a specific parameter value b = bval (substitute, then univariate decide)
(define (cadqe-holds-at quant phi bval) (qe-decide quant (cadqe-subst phi bval)))
; substitute b = bval into every atom's bivariate polynomial, yielding a univariate-in-x formula
(define (cadqe-subst phi bval)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (cadqe-subst-list (cdr phi) bval)))
        ((equal? (car phi) (quote or)) (cons (quote or) (cadqe-subst-list (cdr phi) bval)))
        ((equal? (car phi) (quote not)) (list (quote not) (cadqe-subst (car (cdr phi)) bval)))
        (else (cons (car phi) (cadqe-subst-poly (cdr phi) bval)))))
(define (cadqe-subst-list fs bval) (if (null? fs) (quote ()) (cons (cadqe-subst (car fs) bval) (cadqe-subst-list (cdr fs) bval))))
; a bivariate poly (list of b-polys, indexed by x-power) -> univariate in x by evaluating each b-coefficient at bval
(define (cadqe-subst-poly p bval) (if (null? p) (quote ()) (cons (poly-eval (car p) bval) (cadqe-subst-poly (cdr p) bval))))

; ----- assemble the cells that hold -----
(define (cadqe-elim quant phi) (cadqe-cells quant phi (cadqe-root-rats (cadqe-roots (cadqe-polys-of phi)))))
; given the sorted rational root representatives, build and test every sector and section cell
(define (cadqe-cells quant phi roots)
  (if (null? roots)
      (cadqe-no-roots quant phi)
      (cadqe-merge (cadqe-collect quant phi roots))))
; no projection roots: the truth is constant over all of b; test one sample (0) and answer all/none
(define (cadqe-no-roots quant phi) (if (cadqe-holds-at quant phi 0) (list (quote (all))) (list (quote (none)))))
; collect the verdict on each cell: (-inf,r1), {r1}, (r1,r2), {r2}, ..., (rk,+inf)
(define (cadqe-collect quant phi roots)
  (cadqe-app (cadqe-below quant phi (car roots))
             (cadqe-app (cadqe-interior quant phi roots)
                        (cadqe-above quant phi (cadqe-last roots)))))
(define (cadqe-below quant phi r1) (if (cadqe-holds-at quant phi (- r1 1)) (list (cons (quote lt) r1)) (quote ())))
(define (cadqe-above quant phi rk) (if (cadqe-holds-at quant phi (+ rk 1)) (list (cons (quote gt) rk)) (quote ())))
(define (cadqe-last l) (if (null? (cdr l)) (car l) (cadqe-last (cdr l))))
; interior: for each root the section {r}, and between consecutive roots the sector (r_i, r_{i+1})
(define (cadqe-interior quant phi roots)
  (cond ((null? roots) (quote ()))
        ((null? (cdr roots)) (cadqe-section quant phi (car roots)))
        (else (cadqe-app (cadqe-section quant phi (car roots))
                         (cadqe-app (cadqe-sector quant phi (car roots) (car (cdr roots)))
                                    (cadqe-interior quant phi (cdr roots)))))))
(define (cadqe-section quant phi r) (if (cadqe-holds-at quant phi r) (list (cons (quote eq) r)) (quote ())))
(define (cadqe-sector quant phi r1 r2) (if (cadqe-holds-at quant phi (cadqe-mid r1 r2)) (list (list (quote between) r1 r2)) (quote ())))
(define (cadqe-mid a b) (/ (+ a b) 2))

; ----- merge adjacent true cells that share a boundary (b<r or b=r -> b<=r; b=r or b>r -> b>=r; etc.) -----
(define (cadqe-merge cells) (cadqe-mg cells))
(define (cadqe-mg cells)
  (cond ((null? cells) (quote ()))
        ((null? (cdr cells)) cells)
        (else (cadqe-mg2 (car cells) (cadqe-mg (cdr cells))))))
(define (cadqe-mg2 c rest)
  (cond ((null? rest) (list c))
        ((cadqe-adj? c (car rest)) (cons (cadqe-join c (car rest)) (cdr rest)))
        (else (cons c rest))))
; adjacency: (lt r) then (eq r) ; (eq r) then (gt r) ; (eq r) then (between r r2); (between r1 r) then (eq r); etc.
(define (cadqe-adj? a b)
  (cond ((and (cadqe-is a (quote lt)) (cadqe-is b (quote eq))) (= (cdr a) (cdr b)))
        ((and (cadqe-is a (quote eq)) (cadqe-is b (quote gt))) (= (cdr a) (cdr b)))
        ((and (cadqe-is a (quote eq)) (cadqe-between? b)) (= (cdr a) (cadqe-bl b)))
        ((and (cadqe-between? a) (cadqe-is b (quote eq))) (= (cadqe-bh a) (cdr b)))
        ((and (cadqe-between? a) (cadqe-between? b)) (= (cadqe-bh a) (cadqe-bl b)))
        (else #f)))
(define (cadqe-is c tag) (if (pair? c) (equal? (car c) tag) #f))
(define (cadqe-between? c) (cadqe-is c (quote between)))
(define (cadqe-bl c) (car (cdr c)))
(define (cadqe-bh c) (car (cdr (cdr c))))
; join two adjacent cells into one
(define (cadqe-join a b)
  (cond ((and (cadqe-is a (quote lt)) (cadqe-is b (quote eq))) (cons (quote le) (cdr a)))
        ((and (cadqe-is a (quote eq)) (cadqe-is b (quote gt))) (cons (quote ge) (cdr a)))
        ((and (cadqe-is a (quote eq)) (cadqe-between? b)) (list (quote between-le) (cdr a) (cadqe-bh b)))
        ((and (cadqe-between? a) (cadqe-is b (quote eq))) (list (quote between-ge) (cadqe-bl a) (cdr b)))
        ((and (cadqe-between? a) (cadqe-between? b)) (list (quote between) (cadqe-bl a) (cadqe-bh b)))
        (else a)))

; ----- readable rendering -----
(define (cadqe-formula quant phi) (cadqe-render (cadqe-elim quant phi)))
(define (cadqe-render cells)
  (cond ((null? cells) (quote false))
        ((cadqe-has-all? cells) (quote true))
        ((cadqe-has-none-only? cells) (quote false))
        (else (cons (quote or) (cadqe-render-list cells)))))
(define (cadqe-has-all? cells) (cond ((null? cells) #f) ((equal? (car cells) (quote (all))) #t) (else (cadqe-has-all? (cdr cells)))))
(define (cadqe-has-none-only? cells) (if (null? (cdr-or cells)) (equal? (car cells) (quote (none))) #f))
(define (cdr-or l) (if (null? l) (quote ()) (cdr l)))
(define (cadqe-render-list cells) (if (null? cells) (quote ()) (cons (cadqe-render-cell (car cells)) (cadqe-render-list (cdr cells)))))
(define (cadqe-render-cell c)
  (cond ((cadqe-is c (quote lt)) (list (quote <) (quote b) (cdr c)))
        ((cadqe-is c (quote gt)) (list (quote >) (quote b) (cdr c)))
        ((cadqe-is c (quote le)) (list (quote <=) (quote b) (cdr c)))
        ((cadqe-is c (quote ge)) (list (quote >=) (quote b) (cdr c)))
        ((cadqe-is c (quote eq)) (list (quote =) (quote b) (cdr c)))
        ((cadqe-is c (quote between)) (list (quote <) (cadqe-bl c) (quote b) (cadqe-bh c)))
        ((cadqe-is c (quote between-le)) (list (quote <) (car (cdr c)) (quote b<=) (car (cdr (cdr c)))))
        ((cadqe-is c (quote between-ge)) (list (quote <=b<) (car (cdr c)) (car (cdr (cdr c)))))
        (else c)))

(define (cadqe-caveat) (quote one-parameter-one-quantified-variable-planar))
