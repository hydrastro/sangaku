; -*- lisp -*-
; src/cas/realqe.lisp -- UNIVARIATE REAL QUANTIFIER ELIMINATION: a DECISION PROCEDURE for first-order statements
; over the real numbers in ONE variable, by sign-invariant cell decomposition of the real line (the exact
; one-variable case of Tarski's theorem / cylindrical algebraic decomposition -- a genuine decision procedure, not
; a checker, and the 1-D base of the real-closed-field summit).
;
; A statement here is a quantified boolean combination of polynomial SIGN CONDITIONS on a single variable x, e.g.
; "there exists x with p(x) = 0 and q(x) > 0", or "for all x, p(x) >= 0".  The procedure is the sample-point method:
; the real roots of all polynomials appearing in the formula partition R into finitely many CELLS -- the open
; intervals between consecutive roots, together with the root points themselves -- and on each cell every
; polynomial has constant sign.  So the truth of the quantifier-free matrix is constant on each cell, and a
; quantified statement is decided by evaluating the matrix at ONE sample point per cell: "exists" is true iff the
; matrix holds at some sample, "for all" iff it holds at every sample.  This is exact and complete for the
; univariate fragment.
;
; Sample points are chosen exactly over Q.  Let B be a Cauchy root bound for the product of the (squarefree)
; polynomials.  The OPEN-interval cells are sampled by isolating the real roots to disjoint rational intervals,
; ordering them, and taking a rational strictly below the least root (-B-1), a rational in each gap between
; consecutive isolating intervals, and a rational above the greatest (+B+1) -- every such sample is a non-root
; rational, so all signs are exact and nonzero there.  The ROOT cells are handled by sign-on-the-isolating-interval:
; at a root alpha of some polynomial, alpha's sign for that polynomial is 0, and for every other polynomial the sign
; is its (constant) value on alpha's refined isolating interval (refined until it excludes all other roots); the
; module evaluates these via the interval endpoints, so no irrational value is ever needed.
;
; A sign condition is (op . poly) with op in {zero pos neg nonneg nonpos nonzero}; the matrix is a boolean formula
; over these built with (and ...), (or ...), (not f); a polynomial is a coefficient list low->high over Q.
;
; Public:
;   qe-sample-points polys     -> a list of exact rational sample points hitting every OPEN cell of R cut by the
;                                 real roots of the given polynomials (below, between, and above the roots)
;   qe-eval-cond cond x        -> #t iff the sign condition holds at the rational point x
;   qe-eval-formula f x        -> #t iff the boolean formula f holds at the rational point x
;   qe-exists f polys          -> #t iff the formula f is satisfied at some open-cell sample (exists x . f)
;   qe-forall f polys          -> #t iff f holds at every open-cell sample (for all x . f), the dual of qe-exists
;   qe-decide quant f          -> #t/#f for quant in {exists forall}, collecting the polynomials from f itself
;   qe-polys-of f              -> the list of polynomials occurring in the formula f (the projection set)
;
; Note on scope, kept exact: qe-exists / qe-forall as implemented quantify over the OPEN cells (the generic points
; between roots), which decides every statement whose truth does not hinge on the measure-zero root points -- in
; particular all STRICT-inequality formulas and their boolean combinations, and "for all" of any closed condition
; (since the closure is determined by the open cells).  Equality-witness statements ("exists x with p(x)=0 and ...")
; are decided separately by qe-exists-root, which tests the formula at each real root via sign-on-isolating-interval.
;   qe-exists-root f polys     -> #t iff f holds at some common real root point (the root-cell companion to qe-exists)
;   qe-sat f polys             -> #t iff f holds at some cell at all (open OR root): full existential decision
;
; Verified: "exists x: x^2-1 < 0" is true (the cell (-1,1)); "for all x: x^2+1 > 0" is true; "for all x: x^2-1 >= 0"
; is false (false on (-1,1)); "exists x: x^2-3x+2 = 0 and x-1 = 0" is true (the root x=1); "exists x: x^2+1 = 0" is
; false (no real root); "for all x: x^2 >= 0" is true.
;
; Builds on poly.lisp and sturm.lisp.

(import "cas/poly.lisp")
(import "cas/sturm.lisp")

; ----- sign-condition and formula evaluation at a rational point -----
(define (qe-sgn p x) (sign-at p x))
(define (qe-eval-cond cnd x) (qe-test (car cnd) (qe-sgn (cdr cnd) x)))
(define (qe-test op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

(define (qe-eval-formula f x)
  (cond ((equal? (car f) (quote and)) (qe-all (cdr f) x))
        ((equal? (car f) (quote or)) (qe-any (cdr f) x))
        ((equal? (car f) (quote not)) (if (qe-eval-formula (car (cdr f)) x) #f #t))
        (else (qe-eval-cond f x))))               ; a leaf sign condition (op . poly)
(define (qe-all fs x) (cond ((null? fs) #t) ((qe-eval-formula (car fs) x) (qe-all (cdr fs) x)) (else #f)))
(define (qe-any fs x) (cond ((null? fs) #f) ((qe-eval-formula (car fs) x) #t) (else (qe-any (cdr fs) x))))

; ----- collect the polynomials occurring in a formula (the projection set) -----
(define (qe-polys-of f)
  (cond ((equal? (car f) (quote and)) (qe-polys-list (cdr f)))
        ((equal? (car f) (quote or)) (qe-polys-list (cdr f)))
        ((equal? (car f) (quote not)) (qe-polys-of (car (cdr f))))
        (else (list (cdr f)))))                   ; a leaf: its polynomial
(define (qe-polys-list fs) (if (null? fs) (quote ()) (qe-append (qe-polys-of (car fs)) (qe-polys-list (cdr fs)))))
(define (qe-append a b) (if (null? a) b (cons (car a) (qe-append (cdr a) b))))

; ----- the product of the polynomials (its real roots are all the cell breakpoints) -----
(define (qe-product polys) (qe-prod-go polys (list 1)))
(define (qe-prod-go ps acc) (if (null? ps) acc (qe-prod-go (cdr ps) (poly-mul acc (qe-nz (car ps))))))
(define (qe-nz p) (if (qe-allzero? p) (list 1) p))      ; guard: never multiply by the zero poly (empty OR all-zero like (0))
(define (qe-allzero? p) (cond ((null? p) #t) ((= (car p) 0) (qe-allzero? (cdr p))) (else #f)))

; ----- open-cell sample points: below all roots, in each gap between isolating intervals, above all roots -----
(define (qe-sample-points polys) (qe-samples-from (qe-iso-roots polys) (qe-bound polys)))
(define (qe-iso-roots polys) (if (qe-nonconst-prod? polys) (isolate-roots (sqfree-part (qe-clear-denoms (qe-product polys)))) (quote ())))
; clear denominators of a polynomial by multiplying through by the lcm of its coefficient denominators, so the
; integer-coefficient root isolator (sturm) applies; multiplying by a positive constant preserves every root
(define (qe-clear-denoms p) (qe-cd-scale p (qe-cd-lcm p)))
(define (qe-cd-scale p m) (if (null? p) (quote ()) (cons (* (car p) m) (qe-cd-scale (cdr p) m))))
(define (qe-cd-lcm p) (qe-cd-go p 1))
(define (qe-cd-go p acc) (if (null? p) acc (qe-cd-go (cdr p) (qe-cd-l acc (denominator (car p))))))
(define (qe-cd-l a b) (/ (* a b) (qe-cd-g a b)))
(define (qe-cd-g a b) (if (= b 0) a (qe-cd-g b (remainder a b))))
(define (qe-bound polys) (if (qe-nonconst-prod? polys) (+ (cauchy-bound (sqfree-part (qe-clear-denoms (qe-product polys)))) 1) 1))
; the product is non-constant iff it has degree >= 1; a constant (or zero) product means every atom is constant in
; x, so there are no roots to isolate and one sample point (0) suffices -- guard the root machinery, which would
; otherwise divide by a vanishing leading coefficient in sqfree-part / cauchy-bound
(define (qe-nonconst-prod? polys) (> (qe-pdeg (qe-product polys)) 0))
(define (qe-pdeg p) (- (qe-plen (qe-ptrim p)) 1))
(define (qe-plen l) (if (null? l) 0 (+ 1 (qe-plen (cdr l)))))
(define (qe-ptrim p) (qe-ptr p (qe-plen p)))
(define (qe-ptr p k) (cond ((= k 0) (quote ())) ((= (qe-pnth p (- k 1)) 0) (qe-ptr p (- k 1))) (else (qe-ptake p k))))
(define (qe-pnth l k) (if (= k 0) (car l) (qe-pnth (cdr l) (- k 1))))
(define (qe-ptake l k) (qe-ptk l k 0))
(define (qe-ptk l k i) (if (= i k) (quote ()) (cons (car l) (qe-ptk (cdr l) k (+ i 1)))))
; isolate-roots gives ordered disjoint intervals (lo . hi as a 2-list). Build samples: -B, midpoints of the gaps
; (right end of one interval to left end of the next), and +B. A point inside no interval is a non-root.
(define (qe-samples-from ivs B)
  (if (null? ivs)
      (list 0)                                    ; no real roots: one cell, sample anywhere (0)
      (cons (- (- 0 B) 0) (qe-gap-samples ivs B))))
(define (qe-gap-samples ivs B)
  (cond ((null? (cdr ivs)) (list (+ B 0)))        ; after the last interval
        (else (cons (qe-mid (qe-hi (car ivs)) (qe-lo (car (cdr ivs)))) (qe-gap-samples (cdr ivs) B)))))
(define (qe-lo iv) (car iv))
(define (qe-hi iv) (car (cdr iv)))
(define (qe-mid a b) (/ (+ a b) 2))

; ----- existential / universal over the OPEN cells -----
(define (qe-exists f polys) (qe-any-pt f (qe-sample-points polys)))
(define (qe-forall f polys) (qe-all-pt f (qe-sample-points polys)))
(define (qe-any-pt f xs) (cond ((null? xs) #f) ((qe-eval-formula f (car xs)) #t) (else (qe-any-pt f (cdr xs)))))
(define (qe-all-pt f xs) (cond ((null? xs) #t) ((qe-eval-formula f (car xs)) (qe-all-pt f (cdr xs))) (else #f)))

; ----- existential over the ROOT cells: test the formula at each real root via sign-on-isolating-interval -----
; At a root alpha (isolated to (lo,hi) excluding all other roots of the product), each polynomial's sign at alpha is
; its sign on (lo,hi) for a non-vanishing poly, and 0 for a poly that has alpha as a root. We evaluate by: a poly q
; is zero at alpha iff alpha is a root of gcd(q, product-derivative-structure)... simpler and exact: q(alpha)=0 iff
; the isolating interval of the PRODUCT at alpha is also an isolating interval where q changes sign (q has a root in
; it). Since the interval isolates a single root of the product, q vanishes there iff q shares that root, detected by
; sign(q,lo) and sign(q,hi) differing OR q being zero at an endpoint-free test. We use the robust test: q(alpha)=0
; iff num-real-roots(gcd(q, prod)) accounts for it -- but to stay simple we test each root interval against each q
; by sign change.
(define (qe-roots polys) (qe-iso-roots polys))
(define (qe-exists-root f polys) (qe-any-root f (qe-roots polys) polys))
(define (qe-any-root f ivs polys) (cond ((null? ivs) #f) ((qe-eval-at-root f (car ivs) polys) #t) (else (qe-any-root f (cdr ivs) polys))))
; evaluate the formula at the root isolated by interval iv: a condition (op . q) holds at the root if, classifying
; q's sign at the root as 0 (q vanishes there) or its constant sign on iv otherwise.
(define (qe-eval-at-root f iv polys)
  (cond ((equal? (car f) (quote and)) (qe-all-root (cdr f) iv polys))
        ((equal? (car f) (quote or)) (qe-any-root-f (cdr f) iv polys))
        ((equal? (car f) (quote not)) (if (qe-eval-at-root (car (cdr f)) iv polys) #f #t))
        (else (qe-test (car f) (qe-sign-at-root (cdr f) iv)))))
(define (qe-all-root fs iv polys) (cond ((null? fs) #t) ((qe-eval-at-root (car fs) iv polys) (qe-all-root (cdr fs) iv polys)) (else #f)))
(define (qe-any-root-f fs iv polys) (cond ((null? fs) #f) ((qe-eval-at-root (car fs) iv polys) #t) (else (qe-any-root-f (cdr fs) iv polys))))
; sign of q at the root isolated in iv=(lo,hi): if q vanishes at that root treat as 0; else q's constant sign on the
; interval (= sign at lo, a non-root rational).  Vanishing must be detected via the SQUARE-FREE part of q, because an
; even-multiplicity root of q (e.g. x^2 at x=0) does not change the sign of q itself across the interval, yet q does
; vanish there; the square-free part has only simple roots and changes sign reliably.
(define (qe-sign-at-root q iv)
  (cond ((qe-allzero? q) 0)                              ; the zero polynomial is identically 0
        ((qe-const-poly? q) (qe-sgn0 (qe-const-val q)))  ; a nonzero constant has that constant's sign everywhere
        ((qe-vanishes? q iv) 0)
        (else (qe-sgn q (qe-lo iv)))))
(define (qe-const-poly? q) (< (qe-pdeg q) 1))            ; degree 0 (or the trimmed-empty zero poly)
(define (qe-const-val q) (if (null? q) 0 (car q)))
(define (qe-sgn0 v) (cond ((> v 0) 1) ((< v 0) -1) (else 0)))
(define (qe-vanishes? q iv) (qe-le0 (* (qe-sgn (sqfree-part q) (qe-lo iv)) (qe-sgn (sqfree-part q) (qe-hi iv)))))
(define (qe-le0 n) (if (< n 0) #t (= n 0)))

; ----- full existential: some cell (open or root) satisfies f -----
(define (qe-sat f polys) (if (qe-exists f polys) #t (qe-exists-root f polys)))

; ----- top-level decide -----
(define (qe-decide quant f)
  (cond ((equal? quant (quote exists)) (qe-sat f (qe-polys-of f)))
        ((equal? quant (quote forall)) (if (qe-forall f (qe-polys-of f)) (qe-forall-roots f (qe-polys-of f)) #f))
        (else #f)))
(define (qe-forall-roots f polys) (qe-all-root-cells f (qe-roots polys) polys))
(define (qe-all-root-cells f ivs polys) (cond ((null? ivs) #t) ((qe-eval-at-root f (car ivs) polys) (qe-all-root-cells f (cdr ivs) polys)) (else #f)))
