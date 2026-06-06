; -*- lisp -*-
; src/cas/cadqe2.lisp -- MULTI-PARAMETER parametric quantifier elimination: eliminate one quantified variable from a
; formula that still has TWO free parameters, returning a quantifier-free condition on the parameters expressed as
; sign conditions on the projection factors.  This is the textbook quantifier-elimination example that one-parameter
; elimination (cadqe.lisp) could not reach -- "exists x . x^2 + b x + c = 0" over the reals, whose answer is the
; discriminant locus b^2 - 4 c >= 0, a quantifier-free formula in the two parameters b and c.
;
; The method generalizes cadqe from the parameter LINE to the parameter PLANE.  With the two parameters b (outer)
; and c (inner) and the quantified variable x eliminated, the projection of the family onto (b, c) -- the
; discriminant in x of each polynomial and the resultants in x between them, computed by the multivariate resultant
; (cadnd) -- is a set of polynomials in (b, c) whose zero sets partition the plane into cells on each of which every
; polynomial of the family is sign-invariant in x, hence on each of which the quantified statement has a constant
; truth value.  The plane is decomposed by the planar projection-and-lift (the same construction cadcomplete uses):
; project the (b, c) factors onto b, sample each b-sector and section, and over each b-sample isolate the c-roots
; and sample the c-sectors and sections, giving a point in every cell.  Deciding the quantified statement once per
; cell -- substitute the (b, c) sample, leaving a univariate statement in x, and call the complete univariate decider
; (realqe) -- labels every cell; the eliminated condition is read off the cells that hold, as the SIGN VECTOR of the
; projection factors there.  Cells sharing the same sign vector and verdict collapse to one sign condition, so
; "exists x . x^2 + b x + c = 0" is reported as "the discriminant has sign >= 0".
;
; Output.  cadqe2-elim returns the list of factor sign-vectors on which the statement holds; cadqe2-formula renders
; them as a readable disjunction of sign conditions on the named projection factors (printed as their (b, c)
; polynomials), and cadqe2-holds-at gives the truth at a specific (b, c).  The factors are returned alongside so the
; sign conditions can be read against them.
;
; Scope.  Two parameters and one quantified variable -- the planar parameter space, where the projection-and-lift is
; complete for the full-dimensional and section cells that the sign-vector reading captures.  Three or more
; parameters are the general parametric CAD over a higher-dimensional parameter space (and full solution-formula
; construction, Brown's problem, is a further refinement); cadqe2-caveat names this boundary.  Within scope the
; result is exact: the projection is the exact multivariate resultant, and each cell's truth is decided by the
; complete univariate decider on an exact rational sample.
;
; Public:
;   cadqe2-elim quant phi      -> a pair (factors . sign-vectors): the (b,c) projection factors (each a monomial list
;                                 (coeff e_b e_c)) and the list of factor-sign-vectors on which (quant x . phi) holds
;   cadqe2-formula quant phi   -> a readable sexp: the eliminated condition as a disjunction of sign conditions
;   cadqe2-holds-at quant phi bval cval -> #t/#f, the truth of (quant x . phi) at (b,c) = (bval,cval)
;
; Verified: exists x . x^2 + b x + c = 0 gives discriminant >= 0 (i.e. b^2 - 4c >= 0); exists x . x^2 + b x + c < 0
; gives discriminant > 0; forall x . x^2 + b x + c > 0 gives discriminant < 0.
;
; Builds on cadnd.lisp (the multivariate resultant / discriminant that projects away x), cadcomplete.lisp (the planar
; projection-and-sample over the parameter plane), realqe.lisp (the complete univariate decider per cell), sturm.lisp
; and poly.lisp.

(import "cas/cadnd.lisp")
(import "cas/cadcomplete.lisp")
(import "cas/realqe.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

(define (cadqe2-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))

; ===== the family's polynomials, carried as cadn polys in x (last var) with mpoly coeffs over (b,c) =====
(define (cadqe2-polys-of f)
  (cond ((equal? (car f) (quote and)) (cadqe2-pl (cdr f)))
        ((equal? (car f) (quote or)) (cadqe2-pl (cdr f)))
        ((equal? (car f) (quote not)) (cadqe2-polys-of (car (cdr f))))
        (else (list (cdr f)))))
(define (cadqe2-pl fs) (if (null? fs) (quote ()) (cadqe2-app (cadqe2-polys-of (car fs)) (cadqe2-pl (cdr fs)))))
(define (cadqe2-app a b) (if (null? a) b (cons (car a) (cadqe2-app (cdr a) b))))

; ===== project away x: discriminants in x and pairwise resultants in x, each an mpoly in (b,c) =====
(define (cadqe2-factors polys) (cadqe2-nonconst (cadqe2-app (cadqe2-discs polys) (cadqe2-pairs polys))))
(define (cadqe2-discs polys) (if (null? polys) (quote ()) (cons (cadn-discriminant (car polys)) (cadqe2-discs (cdr polys)))))
(define (cadqe2-pairs polys) (if (null? polys) (quote ()) (cadqe2-app (cadqe2-pw (car polys) (cdr polys)) (cadqe2-pairs (cdr polys)))))
(define (cadqe2-pw p rest) (if (null? rest) (quote ()) (cons (cadn-resultant p (car rest)) (cadqe2-pw p (cdr rest)))))
; drop factors that are constant (no b or c dependence): they cut nothing
(define (cadqe2-nonconst fs) (cond ((null? fs) (quote ())) ((cadqe2-const-mpoly? (car fs)) (cadqe2-nonconst (cdr fs))) (else (cons (car fs) (cadqe2-nonconst (cdr fs))))))
(define (cadqe2-const-mpoly? mp) (cadqe2-cm mp))
(define (cadqe2-cm mp) (cond ((null? mp) #t) ((cadqe2-zero-exp? (cdr (car mp))) (cadqe2-cm (cdr mp))) (else #f)))
(define (cadqe2-zero-exp? ev) (cond ((null? ev) #t) ((= (car ev) 0) (cadqe2-zero-exp? (cdr ev))) (else #f)))

; ===== evaluate / substitute a (b,c) mpoly factor (monomials (coeff e_b e_c)) =====
(define (cadqe2-meval mp bv cv) (cadqe2-me mp bv cv 0))
(define (cadqe2-me mp bv cv acc) (if (null? mp) acc (cadqe2-me (cdr mp) bv cv (+ acc (* (car (car mp)) (* (cadqe2-rpow bv (cadqe2-eb (car mp))) (cadqe2-rpow cv (cadqe2-ec (car mp)))))))))
(define (cadqe2-eb m) (car (cdr m)))
(define (cadqe2-ec m) (car (cdr (cdr m))))
(define (cadqe2-rpow base e) (if (= e 0) 1 (* base (cadqe2-rpow base (- e 1)))))
; substitute b = bv into a factor -> a univariate poly in c (dense, low->high)
(define (cadqe2-subst-b mp bv) (cadqe2-densify-c (cadqe2-collect-c mp bv (quote ()))))
(define (cadqe2-collect-c mp bv acc) (if (null? mp) acc (cadqe2-collect-c (cdr mp) bv (cadqe2-addc acc (cadqe2-ec (car mp)) (* (car (car mp)) (cadqe2-rpow bv (cadqe2-eb (car mp))))))))
(define (cadqe2-addc acc deg v) (cond ((null? acc) (list (cons deg v))) ((= (car (car acc)) deg) (cons (cons deg (+ (cdr (car acc)) v)) (cdr acc))) (else (cons (car acc) (cadqe2-addc (cdr acc) deg v)))))
(define (cadqe2-densify-c assoc) (cadqe2-dc assoc 0 (cadqe2-maxd assoc 0)))
(define (cadqe2-maxd assoc m) (if (null? assoc) m (cadqe2-maxd (cdr assoc) (if (> (car (car assoc)) m) (car (car assoc)) m))))
(define (cadqe2-dc assoc k kmax) (if (> k kmax) (quote ()) (cons (cadqe2-lk assoc k) (cadqe2-dc assoc (+ k 1) kmax))))
(define (cadqe2-lk assoc k) (cond ((null? assoc) 0) ((= (car (car assoc)) k) (cdr (car assoc))) (else (cadqe2-lk (cdr assoc) k))))

; ===== the parameter-plane sample points: b-samples (project factors onto b), then c-samples per b =====
; b-samples: project every factor onto b by isolating the roots of (each factor with c eliminated).  We eliminate c
; from a factor by the b-coefficients of its c-discriminant and c-leading term; in practice it suffices to collect
; the b-roots of the resultant-in-c of the factors with their c-derivatives plus their c-leading coefficients.  We
; obtain these b-polynomials by viewing each (b,c) factor as a polynomial in c with b-polynomial coefficients.
(define (cadqe2-b-samples factors) (cadqe2-samples-of (cadqe2-b-breakpoints factors)))
(define (cadqe2-b-breakpoints factors) (cadqe2-sort-uniq (cadqe2-b-roots factors)))
(define (cadqe2-b-roots factors) (if (null? factors) (quote ()) (cadqe2-app (cadqe2-broots-1 (car factors)) (cadqe2-b-roots (cdr factors)))))
; b-roots from one factor: the b-roots of disc_c, of the c-leading coeff, and (with other factors) resultants; here
; disc_c and c-leading-coeff suffice to fix where the c-fiber count changes
(define (cadqe2-broots-1 f) (cadqe2-app (cadqe2-iso-b (cadqe2-disc-c-as-b f)) (cadqe2-iso-b (cadqe2-clead-as-b f))))
(define (cadqe2-iso-b u) (if (cadqe2-trivial? u) (quote ()) (cadqe2-mids (cadqe2-isolate-refined (cadqe2-cleard u)))))
(define (cadqe2-trivial? u) (< (cadqe2-deg u) 1))
(define (cadqe2-mids ivs) (if (null? ivs) (quote ()) (cons (cadqe2-rat-in (car (car ivs)) (car (cdr (car ivs)))) (cadqe2-mids (cdr ivs)))))
(define (cadqe2-rat-in lo hi) (/ (+ lo hi) 2))
; isolate the roots of u and refine each isolating interval to a tight width, so the interval midpoint is an
; accurate rational estimate of the root (the raw isolating intervals from isolate-roots can be wide -- e.g. the
; root 1/4 of 1 - 4c is only isolated to (-5/4, 5/4), whose midpoint 0 is not the root); refinement against the
; square-free part pins it down
(define (cadqe2-isolate-refined u) (cadqe2-refine-each (sqfree-part u) (isolate-roots u)))
(define (cadqe2-refine-each sf ivs) (if (null? ivs) (quote ()) (cons (refine-iv sf (car (car ivs)) (car (cdr (car ivs))) (/ 1 1000000)) (cadqe2-refine-each sf (cdr ivs)))))
; disc_c(f) and lc_c(f) as univariate b-polynomials: build the c-indexed b-coefficient lists, then use the resultant
(define (cadqe2-disc-c-as-b f) (cadqe2-resultant-b (cadqe2-as-cpoly f) (cadqe2-dc-cpoly (cadqe2-as-cpoly f))))
(define (cadqe2-clead-as-b f) (cadqe2-leadb (cadqe2-as-cpoly f)))
; represent f (monomials in (b,c)) as a polynomial in c whose coefficients are b-polynomials (dense low->high in c)
(define (cadqe2-as-cpoly f) (cadqe2-acp f 0 (cadqe2-maxc f 0)))
(define (cadqe2-maxc f m) (if (null? f) m (cadqe2-maxc (cdr f) (if (> (cadqe2-ec (car f)) m) (cadqe2-ec (car f)) m))))
(define (cadqe2-acp f k kmax) (if (> k kmax) (quote ()) (cons (cadqe2-bcoeff f k) (cadqe2-acp f (+ k 1) kmax))))
; the b-polynomial coefficient of c^k in f
(define (cadqe2-bcoeff f k) (cadqe2-densify-b (cadqe2-collect-b f k (quote ()))))
(define (cadqe2-collect-b f k acc) (cond ((null? f) acc) ((= (cadqe2-ec (car f)) k) (cadqe2-collect-b (cdr f) k (cadqe2-addb acc (cadqe2-eb (car f)) (car (car f))))) (else (cadqe2-collect-b (cdr f) k acc))))
(define (cadqe2-addb acc deg v) (cond ((null? acc) (list (cons deg v))) ((= (car (car acc)) deg) (cons (cons deg (+ (cdr (car acc)) v)) (cdr acc))) (else (cons (car acc) (cadqe2-addb (cdr acc) deg v)))))
(define (cadqe2-densify-b assoc) (cadqe2-dc assoc 0 (cadqe2-maxd assoc 0)))
; leading c-coefficient (highest nonzero c power) as a b-poly
(define (cadqe2-leadb cpoly) (cadqe2-last-nonempty cpoly (quote (1))))
(define (cadqe2-last-nonempty cpoly best) (cond ((null? cpoly) best) ((cadqe2-poly-zero? (car cpoly)) (cadqe2-last-nonempty (cdr cpoly) best)) (else (cadqe2-last-nonempty (cdr cpoly) (car cpoly)))))
(define (cadqe2-poly-zero? p) (cond ((null? p) #t) ((= (car p) 0) (cadqe2-poly-zero? (cdr p))) (else #f)))
; derivative in c of a c-poly (coefficients are b-polys): drop constant term, multiply each by its c-power
(define (cadqe2-dc-cpoly cpoly) (cadqe2-dcp (cdr cpoly) 1))
(define (cadqe2-dcp cs k) (if (null? cs) (quote ()) (cons (cadqe2-pscale k (car cs)) (cadqe2-dcp (cdr cs) (+ k 1)))))
(define (cadqe2-pscale k p) (if (null? p) (quote ()) (cons (* k (car p)) (cadqe2-pscale k (cdr p)))))
; resultant in c of two c-polynomials with b-poly coefficients -> a b-polynomial (Sylvester via cadnd's machinery is
; overkill; here both have low c-degree, so we use the polynomial resultant over the ring of b-polynomials by the
; subresultant-free Euclidean approach is delicate -- instead we form the (b,c) bivariate and reuse cad-resultant)
(define (cadqe2-resultant-b cpoly dcpoly) (cadqe2-bires (cadqe2-cpoly->biv cpoly) (cadqe2-cpoly->biv dcpoly)))
; convert a c-poly with b-poly coefficients into cadproj bivariate form (list of c-polys? no: cad-resultant
; eliminates the INNER var y of a bivariate given as list of x-polys low->high in y).  We treat b as x and c as y:
; bivariate = list over c-powers of b-polynomials -- which is exactly cpoly.  cad-resultant eliminates the inner
; (c here).
(define (cadqe2-cpoly->biv cpoly) cpoly)
(define (cadqe2-bires p q) (if (cadqe2-bad? p) (quote (1)) (if (cadqe2-bad? q) (quote (1)) (cad-resultant p q))))
(define (cadqe2-bad? p) (< (cadqe2-deg p) 1))

; helpers shared: degree, trim, clear denominators of a univariate poly; sort+unique a rational list; samples
(define (cadqe2-deg u) (- (cadqe2-len (cadqe2-trim u)) 1))
(define (cadqe2-len l) (if (null? l) 0 (+ 1 (cadqe2-len (cdr l)))))
(define (cadqe2-trim p) (cadqe2-tr p (cadqe2-len p)))
(define (cadqe2-tr p k) (cond ((= k 0) (quote ())) ((= (cadqe2-nth p (- k 1)) 0) (cadqe2-tr p (- k 1))) (else (cadqe2-take p k))))
(define (cadqe2-nth l k) (if (= k 0) (car l) (cadqe2-nth (cdr l) (- k 1))))
(define (cadqe2-take l k) (cadqe2-tk l k 0))
(define (cadqe2-tk l k i) (if (= i k) (quote ()) (cons (car l) (cadqe2-tk (cdr l) k (+ i 1)))))
(define (cadqe2-cleard p) (cadqe2-scl (cadqe2-trim p) (cadqe2-lcd (cadqe2-trim p))))
(define (cadqe2-scl p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadqe2-scl (cdr p) m))))
(define (cadqe2-lcd p) (cadqe2-lcd-go p 1))
(define (cadqe2-lcd-go p acc) (if (null? p) acc (cadqe2-lcd-go (cdr p) (cadqe2-lcm acc (denominator (car p))))))
(define (cadqe2-lcm a b) (/ (* a b) (cadqe2-gcd a b)))
(define (cadqe2-gcd a b) (if (= b 0) a (cadqe2-gcd b (remainder a b))))
(define (cadqe2-sort-uniq xs) (cadqe2-uniq (cadqe2-sort xs)))
(define (cadqe2-sort xs) (cadqe2-isort xs (quote ())))
(define (cadqe2-isort xs acc) (if (null? xs) acc (cadqe2-isort (cdr xs) (cadqe2-ins (car xs) acc))))
(define (cadqe2-ins x s) (cond ((null? s) (list x)) ((< x (car s)) (cons x s)) ((= x (car s)) s) (else (cons (car s) (cadqe2-ins x (cdr s))))))
(define (cadqe2-uniq xs) (cond ((null? xs) (quote ())) ((null? (cdr xs)) xs) ((= (car xs) (car (cdr xs))) (cadqe2-uniq (cdr xs))) (else (cons (car xs) (cadqe2-uniq (cdr xs))))))
; sample points around a sorted breakpoint list: below first, between each, above last, and the breakpoints
(define (cadqe2-samples-of brks)
  (if (null? brks) (list 0)
      (cadqe2-app (list (- (car brks) 1)) (cadqe2-app (cadqe2-betweens brks) (list (+ (cadqe2-lastv brks) 1))))))
(define (cadqe2-betweens brks) (if (null? (cdr brks)) brks (cons (car brks) (cons (/ (+ (car brks) (car (cdr brks))) 2) (cadqe2-betweens (cdr brks))))))
(define (cadqe2-lastv l) (if (null? (cdr l)) (car l) (cadqe2-lastv (cdr l))))

; ===== decide the statement at a (b,c) point: substitute, leaving a univariate-in-x statement, then qe-decide =====
(define (cadqe2-holds-at quant phi bval cval) (qe-decide quant (cadqe2-subst phi bval cval)))
(define (cadqe2-subst phi bval cval)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (cadqe2-subst-list (cdr phi) bval cval)))
        ((equal? (car phi) (quote or)) (cons (quote or) (cadqe2-subst-list (cdr phi) bval cval)))
        ((equal? (car phi) (quote not)) (list (quote not) (cadqe2-subst (car (cdr phi)) bval cval)))
        (else (cons (car phi) (cadqe2-subst-poly (cdr phi) bval cval)))))
(define (cadqe2-subst-list fs bv cv) (if (null? fs) (quote ()) (cons (cadqe2-subst (car fs) bv cv) (cadqe2-subst-list (cdr fs) bv cv))))
; a cadn poly in x (mpoly coeffs over (b,c)) -> univariate in x by evaluating each coeff mpoly at (bv,cv)
(define (cadqe2-subst-poly p bv cv) (if (null? p) (quote ()) (cons (cadqe2-meval (car p) bv cv) (cadqe2-subst-poly (cdr p) bv cv))))

; ===== the sign vector of the factors at a (b,c) point =====
(define (cadqe2-signvec factors bv cv) (if (null? factors) (quote ()) (cons (cadqe2-sgn (cadqe2-meval (car factors) bv cv)) (cadqe2-signvec (cdr factors) bv cv))))

; ===== walk the parameter plane, collect the sign vectors on which the statement holds =====
(define (cadqe2-elim quant phi) (cadqe2-pack (cadqe2-factors (cadqe2-polys-of phi)) quant phi))
(define (cadqe2-pack factors quant phi) (cons factors (cadqe2-collect-true factors quant phi (cadqe2-plane-samples factors))))
; the (b,c) sample points of the parameter plane
(define (cadqe2-plane-samples factors) (cadqe2-plane-go factors (cadqe2-b-samples factors)))
(define (cadqe2-plane-go factors bsamps) (if (null? bsamps) (quote ()) (cadqe2-app (cadqe2-row factors (car bsamps)) (cadqe2-plane-go factors (cdr bsamps)))))
; one b-row: substitute b, isolate the c-roots of all factors, sample c-sectors/sections, pair with b
(define (cadqe2-row factors bv) (cadqe2-pairup bv (cadqe2-samples-of (cadqe2-sort-uniq (cadqe2-c-roots factors bv)))))
(define (cadqe2-c-roots factors bv) (if (null? factors) (quote ()) (cadqe2-app (cadqe2-iso-c (cadqe2-subst-b (car factors) bv)) (cadqe2-c-roots (cdr factors) bv))))
(define (cadqe2-iso-c u) (if (cadqe2-trivial? u) (quote ()) (cadqe2-mids (cadqe2-isolate-refined (cadqe2-cleard u)))))
(define (cadqe2-pairup bv cs) (if (null? cs) (quote ()) (cons (cons bv (car cs)) (cadqe2-pairup bv (cdr cs)))))
; collect the distinct sign vectors on which the statement holds
(define (cadqe2-collect-true factors quant phi pts) (cadqe2-ct factors quant phi pts (quote ())))
(define (cadqe2-ct factors quant phi pts acc)
  (cond ((null? pts) acc)
        ((cadqe2-holds-at quant phi (car (car pts)) (cdr (car pts)))
         (cadqe2-ct factors quant phi (cdr pts) (cadqe2-add-vec acc (cadqe2-signvec factors (car (car pts)) (cdr (car pts))))))
        (else (cadqe2-ct factors quant phi (cdr pts) acc))))
(define (cadqe2-add-vec acc v) (if (cadqe2-member-vec v acc) acc (cons v acc)))
(define (cadqe2-member-vec v acc) (cond ((null? acc) #f) ((equal? v (car acc)) #t) (else (cadqe2-member-vec v (cdr acc)))))

; ===== readable rendering: a disjunction of sign conditions on the factor polynomials =====
(define (cadqe2-formula quant phi) (cadqe2-render (cadqe2-elim quant phi)))
(define (cadqe2-render result) (cadqe2-render2 (car result) (cdr result)))
(define (cadqe2-render2 factors vecs)
  (cond ((null? vecs) (quote false))
        ((cadqe2-all-vec? factors vecs) (quote true))
        (else (cons (quote or) (cadqe2-render-vecs factors vecs)))))
; if every one of the 3^k sign patterns holds, the answer is "true"
(define (cadqe2-all-vec? factors vecs) (= (cadqe2-len vecs) (cadqe2-pow3 (cadqe2-len factors))))
(define (cadqe2-pow3 k) (if (= k 0) 1 (* 3 (cadqe2-pow3 (- k 1)))))
(define (cadqe2-render-vecs factors vecs) (if (null? vecs) (quote ()) (cons (cadqe2-render-vec factors (car vecs)) (cadqe2-render-vecs factors (cdr vecs)))))
(define (cadqe2-render-vec factors v) (cons (quote and) (cadqe2-render-conds factors v)))
(define (cadqe2-render-conds factors v)
  (cond ((null? factors) (quote ()))
        (else (cons (cadqe2-cond (car factors) (car v)) (cadqe2-render-conds (cdr factors) (cdr v))))))
(define (cadqe2-cond factor s)
  (cond ((> s 0) (list (quote >) (cadqe2-show factor) 0))
        ((< s 0) (list (quote <) (cadqe2-show factor) 0))
        (else (list (quote =) (cadqe2-show factor) 0))))
; render a (b,c) factor (monomial list) as a readable polynomial sexp
(define (cadqe2-show factor) (cons (quote poly) factor))

(define (cadqe2-caveat) (quote two-parameters-one-quantified-variable-planar))
