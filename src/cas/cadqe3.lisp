; -*- lisp -*-
; src/cas/cadqe3.lisp -- THREE-parameter parametric quantifier elimination: eliminate one quantified variable from a
; formula with three free parameters, returning a quantifier-free condition expressed as sign conditions on the
; projection factors.  This reaches the hard textbook quantifier-elimination example that two-parameter elimination
; (cadqe2.lisp) could not -- the GENERAL quadratic with a free leading coefficient,
;
;   exists x . a x^2 + b x + c = 0   over the reals,
;
; whose answer is NOT simply the discriminant, because when a = 0 the polynomial drops to degree one (or zero) and
; the discriminant condition no longer governs.  The full answer is
;
;   (a != 0  and  b^2 - 4 a c >= 0)   or   (a = 0  and  (b != 0  or  c = 0)),
;
; a quantifier-free formula in the three parameters with a genuine case split on the leading coefficient.
;
; The construction extends cadqe2 from the parameter PLANE to the parameter 3-SPACE.  With the three parameters a
; (outer), b, c and the quantified variable x eliminated, the projection of the family onto (a, b, c) -- including
; the leading coefficient itself, since its vanishing changes the degree -- partitions the 3-space into cells of
; constant truth.  The 3-space is decomposed by an outer-to-inner sweep: project the factors onto a, sample each
; a-cell, and over each a-sample SUBSTITUTE a into the factors, leaving a two-parameter (b, c) family decomposed by
; the planar sweep of cadqe2; each (a, b, c) sample is then decided once by the complete univariate decider
; (realqe), and the eliminated condition is read off the cells that hold as the SIGN VECTOR of the projection
; factors there.
;
; The projection factors for the general quadratic are taken as the leading coefficient and the coefficients of its
; reducta together with the discriminant -- in the canonical case the four polynomials a, b, c, and b^2 - 4 a c,
; whose sign cells stratify (a, b, c)-space exactly into the degree-two non-degenerate stratum, the degree-one
; stratum a = 0, b != 0, and the constant stratum a = b = 0.  The module accepts the family and the explicit factor
; list (the caller supplies the coordinate factors and the discriminant), keeping cadqe3 a faithful sign-cell
; evaluator over a correct projection rather than silently guessing the projection of a non-uniform-degree family.
;
; Output.  cadqe3-elim returns a pair (factors . sign-vectors); cadqe3-formula renders the eliminated condition as a
; readable disjunction of sign conditions on the named factors; cadqe3-holds-at gives the truth at a specific
; (a, b, c).  Soundness is unchanged from cadqe2: every sample is a genuine point and each cell's truth is decided
; exactly by the complete univariate decider (now guarded for the constant/zero polynomial that a degenerate
; parameter point produces).
;
; Public:
;   cadqe3-elim factors quant phi   -> (factors . sign-vectors): the sign-vectors over the supplied (a,b,c) factors
;                                      on which (quant x . phi) holds
;   cadqe3-formula factors quant phi -> a readable disjunction of sign conditions on the factors
;   cadqe3-holds-at quant phi av bv cv -> #t/#f at (a,b,c) = (av,bv,cv)
;
; Verified: for the general quadratic exists x . a x^2 + b x + c = 0 the true sign-cells are exactly the union of
; { a any nonzero sign, disc >= 0 } and { a = 0 with b nonzero } and { a = 0, b = 0, c = 0 }.
;
; Builds on cadqe2.lisp (the planar (b,c) sweep, reused per a-sample), realqe.lisp (the complete univariate decider,
; now constant-poly-guarded), sturm.lisp and poly.lisp.

(import "cas/cadqe2.lisp")
(import "cas/realqe.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

(define (cadqe3-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))
(define (cadqe3-cadr l) (car (cdr l)))
(define (cadqe3-caddr l) (car (cdr (cdr l))))
(define (cadqe3-cadddr l) (car (cdr (cdr (cdr l)))))
(define (cadqe3-app a b) (if (null? a) b (cons (car a) (cadqe3-app (cdr a) b))))
(define (cadqe3-rpow base e) (if (= e 0) 1 (* base (cadqe3-rpow base (- e 1)))))

; ===== evaluate / substitute an (a,b,c) factor (monomials (coeff e_a e_b e_c)) =====
(define (cadqe3-meval mp av bv cv) (cadqe3-me mp av bv cv 0))
(define (cadqe3-me mp av bv cv acc)
  (if (null? mp) acc
      (cadqe3-me (cdr mp) av bv cv (+ acc (* (car (car mp)) (* (cadqe3-rpow av (cadqe3-cadr (car mp))) (* (cadqe3-rpow bv (cadqe3-caddr (car mp))) (cadqe3-rpow cv (cadqe3-cadddr (car mp))))))))))
; substitute a = av into a factor -> a (b,c) factor (monomials (coeff e_b e_c)), collapsing by (e_b,e_c)
(define (cadqe3-subst-a mp av) (cadqe3-sa mp av (quote ())))
(define (cadqe3-sa mp av acc)
  (if (null? mp) acc
      (cadqe3-sa (cdr mp) av (cadqe3-addbc acc (cadqe3-caddr (car mp)) (cadqe3-cadddr (car mp)) (* (car (car mp)) (cadqe3-rpow av (cadqe3-cadr (car mp))))))))
(define (cadqe3-addbc acc eb ec v)
  (cond ((null? acc) (list (list v eb ec)))
        ((and (= (cadqe3-cadr (car acc)) eb) (= (cadqe3-caddr (car acc)) ec)) (cons (list (+ (car (car acc)) v) eb ec) (cdr acc)))
        (else (cons (car acc) (cadqe3-addbc (cdr acc) eb ec v)))))

; ===== the a-axis sample points: a-breakpoints from projecting the factors onto a, then sectors+sections =====
; project a factor onto a: the a-roots where its (b,c)-content can change come from its own a-structure; for the
; sign-cell sweep it suffices to collect the a-roots of each factor restricted along b=c=0 (its pure-a part) plus the
; a-roots of its leading (b,c) coefficient; in the canonical cases the only breakpoint is a = 0 (the degree drop),
; which this captures, and additional breakpoints (if a factor genuinely bends in a) are picked up from the pure-a
; restriction's roots
(define (cadqe3-a-samples factors) (cadqe3-samples-of (cadqe3-sort-uniq (cadqe3-a-roots factors))))
(define (cadqe3-a-roots factors) (if (null? factors) (quote ()) (cadqe3-app (cadqe3-aroots-1 (car factors)) (cadqe3-a-roots (cdr factors)))))
; a-roots of one factor: roots (in a) of its restriction to b=c=0 (the pure-a univariate), and of the a-polynomial
; obtained by setting b=c=0 in each (b,c)-coefficient is the same; we also add a=0 itself whenever the factor depends
; on a, since that is where the degree of the original family can drop
(define (cadqe3-aroots-1 f) (cadqe3-app (cadqe3-iso-a (cadqe3-pure-a f)) (cadqe3-azero-if-depends f)))
(define (cadqe3-pure-a f) (cadqe3-densify-a (cadqe3-collect-pure-a f (quote ()))))
(define (cadqe3-collect-pure-a f acc)
  (cond ((null? f) acc)
        ((and (= (cadqe3-caddr (car f)) 0) (= (cadqe3-cadddr (car f)) 0))     ; e_b = 0 and e_c = 0: a pure-a term
         (cadqe3-collect-pure-a (cdr f) (cadqe3-adda acc (cadqe3-cadr (car f)) (car (car f)))))
        (else (cadqe3-collect-pure-a (cdr f) acc))))
(define (cadqe3-adda acc deg v) (cond ((null? acc) (list (cons deg v))) ((= (car (car acc)) deg) (cons (cons deg (+ (cdr (car acc)) v)) (cdr acc))) (else (cons (car acc) (cadqe3-adda (cdr acc) deg v)))))
(define (cadqe3-densify-a assoc) (cadqe3-da assoc 0 (cadqe3-maxd assoc 0)))
(define (cadqe3-maxd assoc m) (if (null? assoc) m (cadqe3-maxd (cdr assoc) (if (> (car (car assoc)) m) (car (car assoc)) m))))
(define (cadqe3-da assoc k kmax) (if (> k kmax) (quote ()) (cons (cadqe3-lk assoc k) (cadqe3-da assoc (+ k 1) kmax))))
(define (cadqe3-lk assoc k) (cond ((null? assoc) 0) ((= (car (car assoc)) k) (cdr (car assoc))) (else (cadqe3-lk (cdr assoc) k))))
(define (cadqe3-iso-a u) (if (cadqe3-trivial? u) (quote ()) (cadqe3-mids (isolate-roots (cadqe3-cleard u)))))
(define (cadqe3-azero-if-depends f) (if (cadqe3-depends-a? f) (list 0) (quote ())))
(define (cadqe3-depends-a? f) (cond ((null? f) #f) ((> (cadqe3-cadr (car f)) 0) #t) (else (cadqe3-depends-a? (cdr f)))))

; ===== walk a-space, reduce to (b,c) per a-sample via cadqe2's planar sweep, collect sign-vectors =====
(define (cadqe3-elim factors quant phi) (cons factors (cadqe3-collect factors quant phi (cadqe3-space-samples factors))))
; the (a,b,c) sample points: for each a-sample, substitute a into the factors and run the planar (b,c) sweep
(define (cadqe3-space-samples factors) (cadqe3-space-go factors (cadqe3-a-samples factors)))
(define (cadqe3-space-go factors asamps)
  (if (null? asamps) (quote ())
      (cadqe3-app (cadqe3-slab factors (car asamps)) (cadqe3-space-go factors (cdr asamps)))))
; one a-slab: substitute a into every factor -> (b,c) factors, get the planar (b,c) samples, prefix each with a
(define (cadqe3-slab factors av) (cadqe3-prefix av (cadqe2-plane-samples (cadqe3-subst-factors factors av))))
(define (cadqe3-subst-factors factors av) (if (null? factors) (quote ()) (cons (cadqe3-subst-a (car factors) av) (cadqe3-subst-factors (cdr factors) av))))
(define (cadqe3-prefix av bcs) (if (null? bcs) (quote ()) (cons (cons av (car bcs)) (cadqe3-prefix av (cdr bcs)))))

; collect the distinct sign-vectors (over the ORIGINAL (a,b,c) factors) on which the statement holds
(define (cadqe3-collect factors quant phi pts) (cadqe3-ct factors quant phi pts (quote ())))
(define (cadqe3-ct factors quant phi pts acc)
  (cond ((null? pts) acc)
        ((cadqe3-holds-at quant phi (car (car pts)) (car (cdr (car pts))) (cdr (cdr (car pts))))
         (cadqe3-ct factors quant phi (cdr pts) (cadqe3-addvec acc (cadqe3-signvec factors (car (car pts)) (car (cdr (car pts))) (cdr (cdr (car pts)))))))
        (else (cadqe3-ct factors quant phi (cdr pts) acc))))
(define (cadqe3-addvec acc v) (if (cadqe3-memv v acc) acc (cons v acc)))
(define (cadqe3-memv v acc) (cond ((null? acc) #f) ((equal? v (car acc)) #t) (else (cadqe3-memv v (cdr acc)))))
(define (cadqe3-signvec factors av bv cv) (if (null? factors) (quote ()) (cons (cadqe3-sgn (cadqe3-meval (car factors) av bv cv)) (cadqe3-signvec (cdr factors) av bv cv))))

; ===== decide the statement at an (a,b,c) point: substitute, leaving a univariate-in-x statement, then qe-decide ====
(define (cadqe3-holds-at quant phi av bv cv) (qe-decide quant (cadqe3-subst phi av bv cv)))
(define (cadqe3-subst phi av bv cv)
  (cond ((equal? (car phi) (quote and)) (cons (quote and) (cadqe3-subst-list (cdr phi) av bv cv)))
        ((equal? (car phi) (quote or)) (cons (quote or) (cadqe3-subst-list (cdr phi) av bv cv)))
        ((equal? (car phi) (quote not)) (list (quote not) (cadqe3-subst (car (cdr phi)) av bv cv)))
        (else (cons (car phi) (cadqe3-subst-poly (cdr phi) av bv cv)))))
(define (cadqe3-subst-list fs av bv cv) (if (null? fs) (quote ()) (cons (cadqe3-subst (car fs) av bv cv) (cadqe3-subst-list (cdr fs) av bv cv))))
; a cadn poly in x (mpoly coeffs over (a,b,c)) -> univariate in x by evaluating each coeff mpoly at (av,bv,cv)
(define (cadqe3-subst-poly p av bv cv) (if (null? p) (quote ()) (cons (cadqe3-meval (car p) av bv cv) (cadqe3-subst-poly (cdr p) av bv cv))))

; ===== shared numeric helpers (degree, trim, clear denominators, sort/uniq, samples) =====
(define (cadqe3-trivial? u) (< (cadqe3-deg u) 1))
(define (cadqe3-deg u) (- (cadqe3-len (cadqe3-trim u)) 1))
(define (cadqe3-len l) (if (null? l) 0 (+ 1 (cadqe3-len (cdr l)))))
(define (cadqe3-trim p) (cadqe3-tr p (cadqe3-len p)))
(define (cadqe3-tr p k) (cond ((= k 0) (quote ())) ((= (cadqe3-nth p (- k 1)) 0) (cadqe3-tr p (- k 1))) (else (cadqe3-take p k))))
(define (cadqe3-nth l k) (if (= k 0) (car l) (cadqe3-nth (cdr l) (- k 1))))
(define (cadqe3-take l k) (cadqe3-tk l k 0))
(define (cadqe3-tk l k i) (if (= i k) (quote ()) (cons (car l) (cadqe3-tk (cdr l) k (+ i 1)))))
(define (cadqe3-cleard p) (cadqe3-scl (cadqe3-trim p) (cadqe3-lcd (cadqe3-trim p))))
(define (cadqe3-scl p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadqe3-scl (cdr p) m))))
(define (cadqe3-lcd p) (cadqe3-lcd-go p 1))
(define (cadqe3-lcd-go p acc) (if (null? p) acc (cadqe3-lcd-go (cdr p) (cadqe3-lcm acc (denominator (car p))))))
(define (cadqe3-lcm a b) (/ (* a b) (cadqe3-gcd a b)))
(define (cadqe3-gcd a b) (if (= b 0) a (cadqe3-gcd b (remainder a b))))
(define (cadqe3-mids ivs) (if (null? ivs) (quote ()) (cons (/ (+ (car (car ivs)) (car (cdr (car ivs)))) 2) (cadqe3-mids (cdr ivs)))))
(define (cadqe3-sort-uniq xs) (cadqe3-uniq (cadqe3-sort xs)))
(define (cadqe3-sort xs) (cadqe3-isort xs (quote ())))
(define (cadqe3-isort xs acc) (if (null? xs) acc (cadqe3-isort (cdr xs) (cadqe3-ins (car xs) acc))))
(define (cadqe3-ins x s) (cond ((null? s) (list x)) ((< x (car s)) (cons x s)) ((= x (car s)) s) (else (cons (car s) (cadqe3-ins x (cdr s))))))
(define (cadqe3-uniq xs) (cond ((null? xs) (quote ())) ((null? (cdr xs)) xs) ((= (car xs) (car (cdr xs))) (cadqe3-uniq (cdr xs))) (else (cons (car xs) (cadqe3-uniq (cdr xs))))))
(define (cadqe3-samples-of brks)
  (if (null? brks) (list 0)
      (cadqe3-app (list (- (car brks) 1)) (cadqe3-app (cadqe3-betweens brks) (list (+ (cadqe3-lastv brks) 1))))))
(define (cadqe3-betweens brks) (if (null? (cdr brks)) brks (cons (car brks) (cons (/ (+ (car brks) (car (cdr brks))) 2) (cadqe3-betweens (cdr brks))))))
(define (cadqe3-lastv l) (if (null? (cdr l)) (car l) (cadqe3-lastv (cdr l))))

; ===== readable rendering: a disjunction of sign conditions on the (a,b,c) factor polynomials =====
(define (cadqe3-formula factors quant phi) (cadqe3-render factors (cdr (cadqe3-elim factors quant phi))))
(define (cadqe3-render factors vecs)
  (cond ((null? vecs) (quote false))
        ((= (cadqe3-len vecs) (cadqe3-pow3 (cadqe3-len factors))) (quote true))
        (else (cons (quote or) (cadqe3-render-vecs factors vecs)))))
(define (cadqe3-pow3 k) (if (= k 0) 1 (* 3 (cadqe3-pow3 (- k 1)))))
(define (cadqe3-render-vecs factors vecs) (if (null? vecs) (quote ()) (cons (cadqe3-render-vec factors (car vecs)) (cadqe3-render-vecs factors (cdr vecs)))))
(define (cadqe3-render-vec factors v) (cons (quote and) (cadqe3-render-conds factors v)))
(define (cadqe3-render-conds factors v)
  (cond ((null? factors) (quote ()))
        (else (cons (cadqe3-cond (car factors) (car v)) (cadqe3-render-conds (cdr factors) (cdr v))))))
(define (cadqe3-cond factor s)
  (cond ((> s 0) (list (quote >) (cons (quote poly) factor) 0))
        ((< s 0) (list (quote <) (cons (quote poly) factor) 0))
        (else (list (quote =) (cons (quote poly) factor) 0))))

(define (cadqe3-caveat) (quote three-parameters-one-quantified-variable-explicit-projection))
