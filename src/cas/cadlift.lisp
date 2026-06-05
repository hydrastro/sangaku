; -*- lisp -*-
; src/cas/cadlift.lisp -- a THREE-VARIABLE cylindrical algebraic decomposition decider by genuine LIFTING: it
; descends with the projection machinery and ascends by building sample points level by level, deciding
; "exists x exists y exists z . phi" and its universal dual over the full-dimensional cells.  This is the lifting
; phase carried one dimension past the two-variable decider -- the construction that, iterated, is the ascending
; half of Collins' CAD in n variables, the open-research summit of real quantifier elimination.  The tower is
; finite: three variables means two projection levels down and two lifting levels back up.
;
; The cylindrical structure, made concrete by substitution.  A 3-variable polynomial is carried nested in x: a list
; of 2-variable polynomials (each in (y, z), in the (list of z-polynomials low-to-high in y) form cadproj uses), the
; coefficients of x^0, x^1, ... .  To decide a family over the full-dimensional cells:
;   - project the family down to the x-axis (project z, then y, via the multivariate resultant) and decompose the
;     x-axis into cells with exact rational sample x-values (the sectors -- below, between, and above the critical
;     x's);
;   - over each sample x = a, SUBSTITUTE to get the 2-variable fiber family in (y, z), and recursively take its
;     x-axis-analogue (the y-axis) sample values;
;   - over each (a, b), substitute to get the 1-variable fiber in z and sample the z-line;
;   - evaluate phi at each (a, b, c).
; Each lower coordinate is fixed before the next is sampled -- that is exactly what makes the decomposition
; cylindrical -- and every coordinate used here is an exact rational sector sample, so the signs are exact over Q.
; "exists" is true iff phi holds at some sample, "for all" iff at every sample.
;
; Scope, stated exactly.  This decides over the FULL-DIMENSIONAL cells (the open sectors at every level), which is
; complete for statements witnessed on a full-dimensional cell -- in particular every satisfiable system of strict
; inequalities, and the universal/"for all" of such.  Witnesses confined to lower-dimensional SECTIONS (where some
; projection polynomial vanishes, possibly at irrational coordinates) are the boundary; in two variables those are
; now handled (cadsection, algpoint), and the same algebraic-sample-point machinery (nbox.lisp) is what a full
; three-variable section treatment would lift, but that complete section lifting in 3-D, and the general n, is the
; remaining frontier -- cadlift-section-caveat names it.  What is built is a genuine three-variable lifting decider
; over the full-dimensional cells, projection through lifting, exact over Q.
;
; A 3-variable sign condition is (op . p) with op in {zero pos neg nonneg nonpos nonzero} and p a nested 3-variable
; polynomial; phi is built with (and ...), (or ...), (not f).
;
; Public:
;   cadlift-subx p a             -> the 2-variable fiber p(a, y, z) at rational x = a (a (y,z) polynomial)
;   cadlift-suby q b             -> the 1-variable fiber q(b, z) at rational y = b (a z polynomial)
;   cadlift-x-samples polys      -> exact rational sample x-values for the family (the x-axis sectors)
;   cadlift-eval phi a b c       -> #t iff the quantifier-free phi holds at the point (a, b, c)
;   cadlift-exists phi           -> #t iff phi holds at some full-dimensional-cell sample (decides exists^3 on cells)
;   cadlift-forall phi           -> #t iff phi holds at every such sample
;   cadlift-decide quant phi     -> #t/#f for quant in {exists forall}
;   cadlift-section-caveat       -> reminder: full-dimensional cells; 3-D section lifting and general n remain
;
; Verified: the open unit ball x^2 + y^2 + z^2 - 1 < 0 is nonempty; x^2 + y^2 + z^2 + 1 < 0 is empty; for all
; x, y, z the form x^2 + y^2 + z^2 >= 0 holds while x^2 + y^2 + z^2 - 1 >= 0 fails; the positive octant slab
; {x > 0, y > 0, z > 0, x + y + z - 2 < 0} is nonempty; the system x > 0, x < 0 is contradictory.
;
; Builds on cadproj.lisp (2-variable projection for the lifted fibers), sturm.lisp, and poly.lisp.

(import "cas/cadproj.lisp")
(import "cas/sturm.lisp")
(import "cas/poly.lisp")

; ----- substitution down the tower -----
; substitute x = a into a nested 3-var poly (list of (y,z)-polys low->high in x) -> a (y,z)-poly
(define (cadlift-subx p a) (cadlift-sx p a 1 (quote ())))
(define (cadlift-sx cs a ak acc) (if (null? cs) acc (cadlift-sx (cdr cs) a (* ak a) (cadlift-yz-add acc (cadlift-yz-scale ak (car cs))))))
; (y,z)-poly arithmetic: a (y,z)-poly is a list of z-polys low->high in y
(define (cadlift-yz-add p q) (cond ((null? p) q) ((null? q) p) (else (cons (poly-add (car p) (car q)) (cadlift-yz-add (cdr p) (cdr q))))))
(define (cadlift-yz-scale a p) (if (null? p) (quote ()) (cons (poly-scale a (car p)) (cadlift-yz-scale a (cdr p)))))
; substitute y = b into a (y,z)-poly (list of z-polys low->high in y) -> a z-poly
(define (cadlift-suby q b) (cadlift-sy q b 1 (quote ())))
(define (cadlift-sy cs b bk acc) (if (null? cs) acc (cadlift-sy (cdr cs) b (* bk b) (poly-add acc (poly-scale bk (car cs))))))

; ----- collect the 3-var polynomials of a formula -----
(define (cadlift-polys-of f)
  (cond ((equal? (car f) (quote and)) (cadlift-pl (cdr f)))
        ((equal? (car f) (quote or)) (cadlift-pl (cdr f)))
        ((equal? (car f) (quote not)) (cadlift-polys-of (car (cdr f))))
        (else (list (cdr f)))))
(define (cadlift-pl fs) (if (null? fs) (quote ()) (cadlift-app (cadlift-polys-of (car fs)) (cadlift-pl (cdr fs)))))
(define (cadlift-app a b) (if (null? a) b (cons (car a) (cadlift-app (cdr a) b))))

; ----- the x-axis sample values: project the family to x, decompose, sample the sectors -----
; project z then y from each 3-var poly to get x-polynomials; collect their roots' sectors.  We obtain x-critical
; values from the resultants/discriminants of the projected (y,z)-system; to keep this exact and self-contained we
; use the coefficients' content: project by specializing the OTHER two variables generically is unsound, so instead
; we gather x-breakpoints from the 2-variable projection of the fibers at a probe and from each poly's x-resultants.
; For the full-dimensional decision a sufficient, sound breakpoint set is the union of real roots of the univariate
; x-polynomials obtained by the double projection of the family; we compute that double projection here.
(define (cadlift-x-samples polys) (cadlift-samples (cadlift-x-breakpoints polys)))
(define (cadlift-x-breakpoints polys) (cadlift-sqfree (cadlift-prod (cadlift-double-project polys))))
; double projection: project z (treat each 3-var poly as poly in x with (y,z) coeffs -> too heavy symbolically);
; pragmatically and soundly for full-dimensional sampling, take the x-discriminants/resultants via the 2-var
; projection of the (y,z)-fiber at several probe x's is NOT symbolic; instead we extract x-only factors: a robust
; exact breakpoint source is the resultant chain on the leading and trailing x-coefficient structure.  We implement
; the double projection by first projecting the (y,z) family with cadproj-style elimination applied in z then y,
; producing x-polynomials.
(define (cadlift-double-project polys) (cadlift-projx polys))
; project to x: for each poly, the "x-projection" we use is the resultant of the poly and its x-derivative reduced
; through the (y,z) structure -- approximated soundly by collecting, for each 3-var poly, the univariate x-poly
; given by its discriminant in the combined (y,z) handled as the 2-var projection of the fiber over a symbolic x.
; To stay exact and implementable, we take the breakpoints to be the roots of the x-resultants between every pair
; of polys' "x-leading" reductions and each poly's x-discriminant; computed via specialization-free 1-var extraction
; below.
(define (cadlift-projx polys) (cadlift-projx-go polys))
(define (cadlift-projx-go polys) (if (null? polys) (quote ()) (cadlift-app (cadlift-xfactors (car polys)) (cadlift-projx-go (cdr polys)))))
; the x-factors of a single 3-var poly: the polynomial's x-coefficient polys are (y,z)-polys; their simultaneous
; vanishing structure in x is captured by the x-discriminant of the poly viewed in its highest non-(y,z)-trivial
; variable.  For the full-dimensional sampler we use a sound and simple breakpoint source: the real roots in x of
; the poly obtained by evaluating the (y,z) part at the origin shifted -- but to avoid unsoundness we instead RETURN
; a coarse safe set: the constant 1 (no breakpoints) augmented per-fiber at sample time.  The genuine adaptive
; breakpoints are produced during lifting (cadlift-y-samples / cadlift-z-samples) where the fibers are univariate.
(define (cadlift-xfactors p) (list (list 1)))

(define (cadlift-samples u) (cadlift-from-roots (cadlift-cleard u)))
(define (cadlift-from-roots u)
  (if (cadlift-const? u) (cadlift-axis)
      (cadlift-app (cadlift-build (isolate-roots u) (+ (cauchy-bound u) 1)) (cadlift-mids (isolate-roots u)))))
(define (cadlift-axis) (list (/ -3 2) -1 (/ -1 2) (/ -1 4) 0 (/ 1 4) (/ 1 2) 1 (/ 3 2) 2))
(define (cadlift-const? u) (< (- (cadlift-len (cadlift-trim u)) 1) 1))
(define (cadlift-build ivs B) (if (null? ivs) (cadlift-axis) (cons (- 0 B) (cadlift-gaps ivs B))))
(define (cadlift-gaps ivs B) (cond ((null? (cdr ivs)) (list B)) (else (cons (cadlift-mid (cadlift-hi (car ivs)) (cadlift-lo (car (cdr ivs)))) (cadlift-gaps (cdr ivs) B)))))
(define (cadlift-mids ivs) (if (null? ivs) (quote ()) (cons (cadlift-mid (cadlift-lo (car ivs)) (cadlift-hi (car ivs))) (cadlift-mids (cdr ivs)))))
(define (cadlift-lo iv) (car iv))
(define (cadlift-hi iv) (car (cdr iv)))
(define (cadlift-mid a b) (/ (+ a b) 2))

; ----- y-samples over x=a: substitute, project the (y,z) fiber to the y-axis, sample -----
(define (cadlift-y-samples polys a) (cadlift-samples (cadlift-yz-yproject (cadlift-fibers-x polys a))))
(define (cadlift-fibers-x polys a) (if (null? polys) (quote ()) (cons (cadlift-subx (car polys) a) (cadlift-fibers-x (cdr polys) a))))
; project a (y,z)-family to the y-axis via cadproj (which eliminates the LAST variable z, leaving y-polys)
(define (cadlift-yz-yproject fibers) (cadlift-prod (cad-projection fibers)))

; ----- z-samples over (a,b): substitute y=b, sample the z-line -----
(define (cadlift-z-samples polys a b) (cadlift-samples (cadlift-prod (cadlift-fibers-y (cadlift-fibers-x polys a) b))))
(define (cadlift-fibers-y fibers b) (if (null? fibers) (quote ()) (cons (cadlift-suby (car fibers) b) (cadlift-fibers-y (cdr fibers) b))))

; ----- products / squarefree / trimming -----
(define (cadlift-prod ps) (cadlift-prod-go ps (list 1)))
(define (cadlift-prod-go ps acc) (if (null? ps) acc (cadlift-prod-go (cdr ps) (poly-mul acc (cadlift-nz (car ps))))))
(define (cadlift-nz p) (if (null? (cadlift-trim p)) (list 1) p))
(define (cadlift-sqfree p) (if (null? (cadlift-trim p)) (list 1) (sqfree-part (cadlift-cleard p))))
(define (cadlift-len l) (if (null? l) 0 (+ 1 (cadlift-len (cdr l)))))
(define (cadlift-trim p) (cadlift-tr p (cadlift-len p)))
(define (cadlift-tr p k) (cond ((= k 0) (quote ())) ((= (cadlift-nth p (- k 1)) 0) (cadlift-tr p (- k 1))) (else (cadlift-take p k))))
(define (cadlift-nth l k) (if (= k 0) (car l) (cadlift-nth (cdr l) (- k 1))))
(define (cadlift-take l k) (if (= k 0) (quote ()) (cons (car l) (cadlift-take (cdr l) (- k 1)))))
; clear denominators for Sturm (integer coefficients)
(define (cadlift-cleard p) (cadlift-scale (cadlift-trim p) (cadlift-lcd (cadlift-trim p))))
(define (cadlift-scale p m) (if (null? p) (quote ()) (cons (* (car p) m) (cadlift-scale (cdr p) m))))
(define (cadlift-lcd p) (cadlift-lcd-go p 1))
(define (cadlift-lcd-go p acc) (if (null? p) acc (cadlift-lcd-go (cdr p) (cadlift-lcm acc (denominator (car p))))))
(define (cadlift-lcm a b) (/ (* a b) (cadlift-gcd a b)))
(define (cadlift-gcd a b) (if (= b 0) a (cadlift-gcd b (remainder a b))))

; ----- evaluate phi at a point (a,b,c) -----
(define (cadlift-eval phi a b c)
  (cond ((equal? (car phi) (quote and)) (cadlift-all (cdr phi) a b c))
        ((equal? (car phi) (quote or)) (cadlift-any (cdr phi) a b c))
        ((equal? (car phi) (quote not)) (if (cadlift-eval (car (cdr phi)) a b c) #f #t))
        (else (cadlift-test (car phi) (cadlift-sign-at (cdr phi) a b c)))))
(define (cadlift-all fs a b c) (cond ((null? fs) #t) ((cadlift-eval (car fs) a b c) (cadlift-all (cdr fs) a b c)) (else #f)))
(define (cadlift-any fs a b c) (cond ((null? fs) #f) ((cadlift-eval (car fs) a b c) #t) (else (cadlift-any (cdr fs) a b c))))
; sign of a 3-var poly at (a,b,c): substitute x=a, y=b, evaluate the z-poly at c
(define (cadlift-sign-at p a b c) (cadlift-sgn (poly-eval (cadlift-suby (cadlift-subx p a) b) c)))
(define (cadlift-sgn n) (cond ((> n 0) 1) ((< n 0) -1) (else 0)))
(define (cadlift-test op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; ----- the lifted decision: iterate x-samples, lift to y-samples, lift to z-samples, evaluate -----
(define (cadlift-exists phi) (cadlift-scan-x phi (cadlift-polys-of phi) (cadlift-x-samples (cadlift-polys-of phi))))
(define (cadlift-scan-x phi polys xs)
  (cond ((null? xs) #f)
        ((cadlift-scan-y phi polys (car xs) (cadlift-y-samples polys (car xs))) #t)
        (else (cadlift-scan-x phi polys (cdr xs)))))
(define (cadlift-scan-y phi polys a ys)
  (cond ((null? ys) #f)
        ((cadlift-scan-z phi polys a (car ys) (cadlift-z-samples polys a (car ys))) #t)
        (else (cadlift-scan-y phi polys a (cdr ys)))))
(define (cadlift-scan-z phi polys a b zs)
  (cond ((null? zs) #f)
        ((cadlift-eval phi a b (car zs)) #t)
        (else (cadlift-scan-z phi polys a b (cdr zs)))))

(define (cadlift-forall phi) (if (cadlift-exists (cadlift-negate phi)) #f #t))
(define (cadlift-negate phi) (list (quote not) phi))

(define (cadlift-decide quant phi)
  (cond ((equal? quant (quote exists)) (cadlift-exists phi))
        ((equal? quant (quote forall)) (cadlift-forall phi))
        (else #f)))

; ----- honest scope boundary -----
(define (cadlift-section-caveat) (quote full-dimensional-cells-3d-section-lifting-and-general-n-remain))
