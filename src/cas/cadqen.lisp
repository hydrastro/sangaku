; -*- lisp -*-
; src/cas/cadqen.lisp -- GENERAL n-parameter parametric quantifier elimination: eliminate one quantified variable
; from a formula with any number of free parameters, returning a quantifier-free condition expressed as sign
; conditions on the projection factors.  This is the uniform generalization of the parameter LINE (cadqe), PLANE
; (cadqe2), and 3-SPACE (cadqe3) to a parameter space of arbitrary dimension k: the eliminated statement has a
; constant truth value on each cell of the cylindrical algebraic decomposition of the k-dimensional parameter space
; induced by the projection of the family, and the answer is the union of the cells on which it holds, read off as
; the sign vector of the projection factors there.
;
; Representation.  A parameter polynomial (a projection factor, or a coefficient of the eliminated family) is a list
; of MONOMIALS, each (coeff e_1 e_2 ... e_k), giving the coefficient and the exponent of each of the k parameters in
; order p_1 (outer), ..., p_k (inner).  The eliminated family is carried as a polynomial in the quantified variable x
; (its last variable) whose coefficients are such k-parameter monomial lists -- the cadnd multivariate
; representation.  The caller supplies BOTH the family and the explicit projection-factor list, because a
; non-uniform-degree family (a free leading coefficient, as in the general quadratic) needs the coefficient
; polynomials included among the factors; cadqen is then a faithful sign-cell evaluator over a correct projection.
;
; The recursive sweep.  cadqen-samples decomposes the k-dimensional parameter space into a finite set of sample
; points, one per cell, by recursion on k:
;   k = 1: the parameter LINE.  Isolate the real roots of every factor (refining each isolating interval to a tight
;     width so its midpoint is an accurate rational root estimate), and take a rational sample below all roots,
;     between consecutive roots, above all roots, and at each root -- the standard one-dimensional cell samples.
;   k > 1: project every factor onto the outer parameter p_1 (the p_1-roots where the lower-dimensional fibre
;     structure changes -- captured by the roots of each factor's pure-p_1 restriction, together with p_1 = 0 where a
;     factor's degree in the remaining variables can drop), sample each p_1-cell, and over each p_1 sample SUBSTITUTE
;     p_1 into every factor -- peeling the first exponent and lowering the parameter count by one -- then recurse on
;     the resulting (k-1)-parameter factors, prefixing the p_1 value to each lower-dimensional sample.
; Each sample point is decided once by the complete univariate decider (realqe): substitute the parameter point into
; the family, leaving a univariate statement in x, and decide it.  The eliminated condition is the set of sign
; vectors -- the sign of each original factor at the point -- over the points that hold.
;
; Soundness.  Every sample is a genuine real parameter point, and the univariate decider is complete and (since the
; rational-coefficient fix) exact on the substituted statement, so a sign vector is recorded as true only for a real
; satisfiable cell.  Completeness of the sweep rests on the supplied factor list being a valid projection of the
; family; for the standard families (the general quadratic and the linear-system examples) it captures every cell,
; matching cadqe2 and cadqe3 where they overlap.  cadqen-caveat records the boundary: the projection is supplied
; rather than computed for fully general non-uniform-degree input, and the cost is the inherent doubly-exponential
; cost of CAD in the parameter dimension (Davenport-Heintz).
;
; Public:
;   cadqen-elim factors k quant phi   -> (factors . sign-vectors): the sign-vectors over the k-parameter factors on
;                                        which (quant x . phi) holds
;   cadqen-formula factors k quant phi -> a readable disjunction of sign conditions on the factors
;   cadqen-holds-at k quant phi pt    -> #t/#f at the parameter point pt (a list of k rationals)
;
; Verified: the general quadratic (k = 3) reproduces cadqe3; the two-linear-equations example
; exists x . a x = b and c x = d (k = 4) yields the resultant locus b c - a d = 0 on the nondegenerate stratum.
;
; Builds on cadnd.lisp (the multivariate resultant, for the caller to form factors), realqe.lisp (the complete,
; rational-coefficient-robust univariate decider per cell), sturm.lisp (root isolation and interval refinement), and
; poly.lisp.

(import "cas/cadnd.lisp")
(import "cas/realqe.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

(define (cadqen-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))
(define (cadqen-app a b) (if (null? a) b (cons (car a) (cadqen-app (cdr a) b))))
(define (cadqen-len l) (if (null? l) 0 (+ 1 (cadqen-len (cdr l)))))
(define (cadqen-rpow base e) (if (= e 0) 1 (* base (cadqen-rpow base (- e 1)))))
(define (cadqen-nth l k) (if (= k 0) (car l) (cadqen-nth (cdr l) (- k 1))))

; ===== monomial operations over a k-length exponent vector =====
; a monomial is (coeff e_1 ... e_k); coeff is (car m), the exponent of parameter i (0-indexed) is (nth (cdr m) i)
(define (cadqen-coeff m) (car m))
(define (cadqen-exps m) (cdr m))
; evaluate a factor (monomial list) at a full parameter point pt (list of k values)
(define (cadqen-meval factor pt) (cadqen-me factor pt 0))
(define (cadqen-me factor pt acc) (if (null? factor) acc (cadqen-me (cdr factor) pt (+ acc (cadqen-mono-val (car factor) pt)))))
(define (cadqen-mono-val m pt) (* (cadqen-coeff m) (cadqen-prod-pow (cadqen-exps m) pt)))
(define (cadqen-prod-pow exps pt) (if (null? exps) 1 (* (cadqen-rpow (car pt) (car exps)) (cadqen-prod-pow (cdr exps) (cdr pt)))))
; substitute the OUTER parameter p_1 = v into a factor, peeling the first exponent: each monomial
; (coeff e_1 e_2 ... e_k) becomes (coeff*v^e_1 e_2 ... e_k), then like exponent-tails are combined
(define (cadqen-subst-outer factor v) (cadqen-combine (cadqen-peel factor v)))
(define (cadqen-peel factor v) (if (null? factor) (quote ()) (cons (cons (* (cadqen-coeff (car factor)) (cadqen-rpow v (car (cadqen-exps (car factor))))) (cdr (cadqen-exps (car factor)))) (cadqen-peel (cdr factor) v))))
; combine monomials with identical exponent tails (summing coefficients), dropping zero coefficients
(define (cadqen-combine mons) (cadqen-drop0 (cadqen-comb mons (quote ()))))
(define (cadqen-comb mons acc) (if (null? mons) acc (cadqen-comb (cdr mons) (cadqen-ins-mono (car mons) acc))))
(define (cadqen-ins-mono m acc)
  (cond ((null? acc) (list m))
        ((equal? (cdr m) (cdr (car acc))) (cons (cons (+ (cadqen-coeff m) (cadqen-coeff (car acc))) (cdr m)) (cdr acc)))
        (else (cons (car acc) (cadqen-ins-mono m (cdr acc))))))
(define (cadqen-drop0 mons) (cond ((null? mons) (quote ())) ((= (cadqen-coeff (car mons)) 0) (cadqen-drop0 (cdr mons))) (else (cons (car mons) (cadqen-drop0 (cdr mons))))))

; ===== the recursive parameter-space sampler =====
; cadqen-samples : factor-list, k (number of params) -> list of parameter points (each a list of k rationals)
(define (cadqen-samples factors k)
  (if (<= k 1)
      (cadqen-line-points factors)
      (cadqen-space-points factors k)))

; ---- k = 1: the parameter line ----
; sample below/between/above the roots of all factors, plus the roots; each point is a 1-list
(define (cadqen-line-points factors) (cadqen-wrap1 (cadqen-samples-of (cadqen-sort-uniq (cadqen-line-roots factors)))))
(define (cadqen-wrap1 xs) (if (null? xs) (quote ()) (cons (list (car xs)) (cadqen-wrap1 (cdr xs)))))
(define (cadqen-line-roots factors) (if (null? factors) (quote ()) (cadqen-app (cadqen-roots-of-uni (cadqen-as-uni (car factors))) (cadqen-line-roots (cdr factors)))))
; a 1-parameter factor (monomials (coeff e_1)) as a dense univariate poly low->high
(define (cadqen-as-uni factor) (cadqen-densify (cadqen-to-assoc factor (quote ()))))
(define (cadqen-to-assoc factor acc) (if (null? factor) acc (cadqen-to-assoc (cdr factor) (cadqen-adda acc (car (cadqen-exps (car factor))) (cadqen-coeff (car factor))))))
(define (cadqen-adda acc deg v) (cond ((null? acc) (list (cons deg v))) ((= (car (car acc)) deg) (cons (cons deg (+ (cdr (car acc)) v)) (cdr acc))) (else (cons (car acc) (cadqen-adda (cdr acc) deg v)))))
(define (cadqen-densify assoc) (cadqen-dens assoc 0 (cadqen-maxd assoc 0)))
(define (cadqen-maxd assoc m) (if (null? assoc) m (cadqen-maxd (cdr assoc) (if (> (car (car assoc)) m) (car (car assoc)) m))))
(define (cadqen-dens assoc d dmax) (if (> d dmax) (quote ()) (cons (cadqen-lk assoc d) (cadqen-dens assoc (+ d 1) dmax))))
(define (cadqen-lk assoc d) (cond ((null? assoc) 0) ((= (car (car assoc)) d) (cdr (car assoc))) (else (cadqen-lk (cdr assoc) d))))
(define (cadqen-roots-of-uni u) (if (cadqen-trivial? u) (quote ()) (cadqen-mids (cadqen-isolate-refined (cadqen-cleard u)))))

; ---- k > 1: project onto the outer parameter, sample it, substitute, recurse ----
(define (cadqen-space-points factors k) (cadqen-space-go factors k (cadqen-outer-samples factors)))
(define (cadqen-space-go factors k osamps)
  (if (null? osamps) (quote ())
      (cadqen-app (cadqen-slab factors k (car osamps)) (cadqen-space-go factors k (cdr osamps)))))
; one outer-slab: substitute p_1 = v into all factors, recurse on the (k-1)-param subproblem, prefix v
(define (cadqen-slab factors k v) (cadqen-prefix v (cadqen-samples (cadqen-subst-factors factors v) (- k 1))))
(define (cadqen-subst-factors factors v) (if (null? factors) (quote ()) (cons (cadqen-subst-outer (car factors) v) (cadqen-subst-factors (cdr factors) v))))
(define (cadqen-prefix v pts) (if (null? pts) (quote ()) (cons (cons v (car pts)) (cadqen-prefix v (cdr pts)))))
; outer-parameter samples: roots of each factor's pure-p_1 restriction, plus p_1 = 0 where a factor depends on p_1
(define (cadqen-outer-samples factors) (cadqen-samples-of (cadqen-sort-uniq (cadqen-outer-roots factors))))
(define (cadqen-outer-roots factors) (if (null? factors) (quote ()) (cadqen-app (cadqen-outer-roots-1 (car factors)) (cadqen-outer-roots (cdr factors)))))
(define (cadqen-outer-roots-1 factor) (cadqen-app (cadqen-roots-of-uni (cadqen-pure-outer factor)) (cadqen-zero-if-dep factor)))
; the pure-p_1 restriction: monomials whose OTHER exponents are all zero, as a univariate-in-p_1 factor
(define (cadqen-pure-outer factor) (cadqen-pick-pure factor (quote ())))
(define (cadqen-pick-pure factor acc) (cond ((null? factor) acc) ((cadqen-tail-zero? (cdr (cadqen-exps (car factor)))) (cadqen-pick-pure (cdr factor) (cons (cons (cadqen-coeff (car factor)) (list (car (cadqen-exps (car factor))))) acc))) (else (cadqen-pick-pure (cdr factor) acc))))
(define (cadqen-tail-zero? tail) (cond ((null? tail) #t) ((= (car tail) 0) (cadqen-tail-zero? (cdr tail))) (else #f)))
(define (cadqen-zero-if-dep factor) (if (cadqen-dep-outer? factor) (list 0) (quote ())))
(define (cadqen-dep-outer? factor) (cond ((null? factor) #f) ((> (car (cadqen-exps (car factor))) 0) #t) (else (cadqen-dep-outer? (cdr factor)))))

; ===== decide the statement at a parameter point; sign vector of the original factors there =====
(define (cadqen-holds-at k quant phi pt) (qe-decide quant (cadqen-subst-phi phi pt)))
(define (cadqen-subst-phi phi pt)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (cadqen-subst-list (cdr phi) pt)))
        ((equal? (car phi) (quote or)) (cons (quote or) (cadqen-subst-list (cdr phi) pt)))
        ((equal? (car phi) (quote not)) (list (quote not) (cadqen-subst-phi (car (cdr phi)) pt)))
        (else (cons (car phi) (cadqen-subst-fpoly (cdr phi) pt)))))
(define (cadqen-subst-list fs pt) (if (null? fs) (quote ()) (cons (cadqen-subst-phi (car fs) pt) (cadqen-subst-list (cdr fs) pt))))
; the family is a poly in x (last var) with k-parameter mpoly coefficients; evaluate each coefficient at pt
(define (cadqen-subst-fpoly fam pt) (if (null? fam) (quote ()) (cons (cadqen-meval (car fam) pt) (cadqen-subst-fpoly (cdr fam) pt))))
(define (cadqen-signvec factors pt) (if (null? factors) (quote ()) (cons (cadqen-sgn (cadqen-meval (car factors) pt)) (cadqen-signvec (cdr factors) pt))))

; ===== assemble: the sign vectors on which the statement holds =====
(define (cadqen-elim factors k quant phi) (cons factors (cadqen-collect factors k quant phi (cadqen-samples factors k))))
; like cadqen-elim, but returns (factors trues falses): both the realizable TRUE sign-vectors and the realizable
; FALSE ones, partitioning every sample point by the decision -- the don't-care-aware input a minimal-cover
; constructor (cadqemin) needs, since unrealizable sign patterns appear in neither set and are free
(define (cadqen-elim2 factors k quant phi) (cadqen-partition factors k quant phi (cadqen-samples factors k) (quote ()) (quote ())))
(define (cadqen-partition factors k quant phi pts ts fs)
  (cond ((null? pts) (list factors (cadqen-rev2 ts) (cadqen-rev2 fs)))
        ((cadqen-holds-at k quant phi (car pts))
         (cadqen-partition factors k quant phi (cdr pts) (cadqen-addvec ts (cadqen-signvec factors (car pts))) fs))
        (else
         (cadqen-partition factors k quant phi (cdr pts) ts (cadqen-addvec fs (cadqen-signvec factors (car pts)))))))
(define (cadqen-rev2 l) (cadqen-r2 l (quote ())))
(define (cadqen-r2 l acc) (if (null? l) acc (cadqen-r2 (cdr l) (cons (car l) acc))))
(define (cadqen-collect factors k quant phi pts) (cadqen-ct factors k quant phi pts (quote ())))
(define (cadqen-ct factors k quant phi pts acc)
  (cond ((null? pts) acc)
        ((cadqen-holds-at k quant phi (car pts)) (cadqen-ct factors k quant phi (cdr pts) (cadqen-addvec acc (cadqen-signvec factors (car pts)))))
        (else (cadqen-ct factors k quant phi (cdr pts) acc))))
(define (cadqen-addvec acc v) (if (cadqen-memv v acc) acc (cons v acc)))
(define (cadqen-memv v acc) (cond ((null? acc) #f) ((equal? v (car acc)) #t) (else (cadqen-memv v (cdr acc)))))

; ===== shared numeric helpers =====
(define (cadqen-trivial? u) (< (cadqen-deg u) 1))
(define (cadqen-deg u) (- (cadqen-len (cadqen-trim u)) 1))
(define (cadqen-trim p) (cadqen-tr p (cadqen-len p)))
(define (cadqen-tr p kk) (cond ((= kk 0) (quote ())) ((= (cadqen-nth p (- kk 1)) 0) (cadqen-tr p (- kk 1))) (else (cadqen-take p kk))))
(define (cadqen-take l kk) (cadqen-tk l kk 0))
(define (cadqen-tk l kk i) (if (= i kk) (quote ()) (cons (car l) (cadqen-tk (cdr l) kk (+ i 1)))))
(define (cadqen-cleard p) (cadqen-scl (cadqen-trim p) (cadqen-lcd (cadqen-trim p))))
(define (cadqen-scl p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadqen-scl (cdr p) m))))
(define (cadqen-lcd p) (cadqen-lcd-go p 1))
(define (cadqen-lcd-go p acc) (if (null? p) acc (cadqen-lcd-go (cdr p) (cadqen-lcm acc (denominator (car p))))))
(define (cadqen-lcm a b) (/ (* a b) (cadqen-gcd a b)))
(define (cadqen-gcd a b) (if (= b 0) a (cadqen-gcd b (remainder a b))))
(define (cadqen-isolate-refined u) (cadqen-refine-each (sqfree-part u) (isolate-roots u)))
(define (cadqen-refine-each sf ivs) (if (null? ivs) (quote ()) (cons (refine-iv sf (car (car ivs)) (car (cdr (car ivs))) (/ 1 1000000)) (cadqen-refine-each sf (cdr ivs)))))
(define (cadqen-mids ivs) (if (null? ivs) (quote ()) (cons (/ (+ (car (car ivs)) (car (cdr (car ivs)))) 2) (cadqen-mids (cdr ivs)))))
(define (cadqen-sort-uniq xs) (cadqen-uniq (cadqen-sort xs)))
(define (cadqen-sort xs) (cadqen-isort xs (quote ())))
(define (cadqen-isort xs acc) (if (null? xs) acc (cadqen-isort (cdr xs) (cadqen-ins (car xs) acc))))
(define (cadqen-ins x s) (cond ((null? s) (list x)) ((< x (car s)) (cons x s)) ((= x (car s)) s) (else (cons (car s) (cadqen-ins x (cdr s))))))
(define (cadqen-uniq xs) (cond ((null? xs) (quote ())) ((null? (cdr xs)) xs) ((= (car xs) (car (cdr xs))) (cadqen-uniq (cdr xs))) (else (cons (car xs) (cadqen-uniq (cdr xs))))))
(define (cadqen-samples-of brks)
  (if (null? brks) (list 0)
      (cadqen-app (list (- (car brks) 1)) (cadqen-app (cadqen-betweens brks) (list (+ (cadqen-lastv brks) 1))))))
(define (cadqen-betweens brks) (if (null? (cdr brks)) brks (cons (car brks) (cons (/ (+ (car brks) (car (cdr brks))) 2) (cadqen-betweens (cdr brks))))))
(define (cadqen-lastv l) (if (null? (cdr l)) (car l) (cadqen-lastv (cdr l))))

; ===== readable rendering =====
(define (cadqen-formula factors k quant phi) (cadqen-render factors (cdr (cadqen-elim factors k quant phi))))
(define (cadqen-render factors vecs)
  (cond ((null? vecs) (quote false))
        ((= (cadqen-len vecs) (cadqen-pow3 (cadqen-len factors))) (quote true))
        (else (cons (quote or) (cadqen-render-vecs factors vecs)))))
(define (cadqen-pow3 k) (if (= k 0) 1 (* 3 (cadqen-pow3 (- k 1)))))
(define (cadqen-render-vecs factors vecs) (if (null? vecs) (quote ()) (cons (cadqen-render-vec factors (car vecs)) (cadqen-render-vecs factors (cdr vecs)))))
(define (cadqen-render-vec factors v) (cons (quote and) (cadqen-render-conds factors v)))
(define (cadqen-render-conds factors v) (cond ((null? factors) (quote ())) (else (cons (cadqen-cond (car factors) (car v)) (cadqen-render-conds (cdr factors) (cdr v))))))
(define (cadqen-cond factor s)
  (cond ((> s 0) (list (quote >) (cons (quote poly) factor) 0))
        ((< s 0) (list (quote <) (cons (quote poly) factor) 0))
        (else (list (quote =) (cons (quote poly) factor) 0))))

(define (cadqen-caveat) (quote general-parameter-dimension-explicit-projection-doubly-exponential))
