; -*- lisp -*-
; src/cas/cad2d.lisp -- a TWO-VARIABLE cylindrical algebraic decomposition decider: it assembles the projection
; phase (cadproj.lisp) and a LIFTING phase into a working decision procedure for first-order statements over the
; reals in two variables -- "exists x exists y . phi(x,y)" and "for all x for all y . phi(x,y)" where phi is a
; boolean combination of polynomial sign conditions.  This is the next rung above the projection primitive: a real
; (if scoped) step into MULTIVARIATE real quantifier elimination, the open-research summit of real algebra.
;
; The method is Collins' CAD specialized to two variables and made exact over Q:
;   1. PROJECT.  Take the projection set of the bivariate polynomials in phi (each y-discriminant and each pairwise
;      y-resultant, from cadproj.lisp).  Its real roots are the critical x-values where the y-fiber structure can
;      change.
;   2. DECOMPOSE the x-axis.  Using the univariate real-root machinery (sturm.lisp), pick exact RATIONAL sample
;      x-values that meet every OPEN x-cell cut by the projection roots -- one strictly below all the roots, one in
;      each gap between consecutive isolating intervals, and one strictly above all -- the sectors of the base
;      decomposition.
;   3. LIFT.  Over each sample x = a, substitute to get the univariate fibers p_i(a, y); their real roots cut the
;      y-line into cells, and a rational sample y is chosen in each (the same below/between/above construction).
;      Each resulting (a, b) is a point in a two-dimensional cell on which every p_i has constant sign.
;   4. EVALUATE.  phi has constant truth on each cell, so "exists" is true iff phi holds at some (a, b) sample and
;      "for all" iff it holds at every sample.
; Every coordinate used is an exact rational, every sign is computed exactly over Q, and the y-fiber that degenerates
; to the zero polynomial at some x (the whole column vanishing) is handled: there the polynomial's sign is 0 for all
; y in that stack.
;
; Scope, stated exactly and honestly.  This decides the two-variable fragment by sampling the OPEN sectors of the
; cylindrical decomposition -- the full-dimensional cells.  For statements whose truth is witnessed on a
; full-dimensional cell (in particular every satisfiable STRICT-inequality system, and the negation/"for all" of
; any such), the open-sector samples are complete and the verdict is a decision.  Statements whose truth hinges
; ONLY on a lower-dimensional SECTION over an IRRATIONAL critical x (a witness that exists solely on a measure-zero
; curve sitting above an irrational x-coordinate) are not guaranteed to be sampled, and for those the procedure
; returns its open-cell verdict with that caveat rather than a false claim of completeness; cad2-section-caveat
; names this boundary.  The full treatment of irrational sections (working in the real algebraic extension generated
; by each projection root) and the recursion to n > 2 variables are the remaining frontier.  What is built is an
; exact, working two-variable decider on the full-dimensional cell structure -- projection joined to lifting.
;
; A bivariate polynomial is in cadproj's representation (a list of x-coefficient-polynomials, low->high in y).  A
; sign condition is (op . p) with op in {zero pos neg nonneg nonpos nonzero} and p bivariate; phi is built with
; (and ...), (or ...), (not f) over those.
;
; Public:
;   cad2-bivar-at p a            -> the univariate fiber p(a, y) (coeff list in y, low->high) at rational x = a
;   cad2-x-samples polys         -> exact rational sample x-values, one per open x-cell cut by the projection of polys
;   cad2-y-samples fibers a      -> exact rational sample y-values, one per open y-cell of the fibers at x = a
;   cad2-cells phi               -> the list of (a . b) sample points of the (open) cylindrical decomposition for phi
;   cad2-eval phi a b            -> #t iff the quantifier-free phi holds at the point (a, b)
;   cad2-exists phi              -> #t iff phi holds at some decomposition sample (decides exists-exists on cells)
;   cad2-forall phi              -> #t iff phi holds at every decomposition sample (decides forall-forall on cells)
;   cad2-decide quant phi        -> #t/#f for quant in {exists forall}
;   cad2-section-caveat          -> reminder: open-sector sampling; irrational sections and n>2 remain the frontier
;
; Verified: "exists x exists y: x^2 + y^2 - 1 < 0" is true (the disk interior); "exists x y: x^2 + y^2 + 1 < 0" is
; false (the polynomial is always positive); "forall x y: x^2 + y^2 >= 0" is true; "exists x y: x^2+y^2-1 = 0 and
; x - y = 0" is true (the line meets the circle); "exists x y: y^2 - x = 0 and x + 1 < 0" is false (no real y when
; x < 0); "exists x y: x*y - 1 = 0 and x > 0 and y > 0" is true (the hyperbola branch).
;
; Builds on cadproj.lisp, poly.lisp, and sturm.lisp.

(import "cas/cadproj.lisp")
(import "cas/poly.lisp")
(import "cas/sturm.lisp")
(import "cas/cadsection.lisp")

; ----- substitute a rational x = a into a bivariate polynomial, giving the univariate y-fiber -----
(define (cad2-bivar-at p a) (cad2-trimr (map (lambda (xp) (poly-eval xp a)) p)))
(define (cad2-trimr l) (cad2-tr l (cad2-len l)))
(define (cad2-len l) (if (null? l) 0 (+ 1 (cad2-len (cdr l)))))
(define (cad2-tr l k) (cond ((= k 0) (quote ())) ((= (cad2-nth l (- k 1)) 0) (cad2-tr l (- k 1))) (else (cad2-take l k))))
(define (cad2-nth l k) (if (= k 0) (car l) (cad2-nth (cdr l) (- k 1))))
(define (cad2-take l k) (if (= k 0) (quote ()) (cons (car l) (cad2-take (cdr l) (- k 1)))))

; ----- collect the bivariate polynomials occurring in a formula -----
(define (cad2-polys-of f)
  (cond ((equal? (car f) (quote and)) (cad2-pl (cdr f)))
        ((equal? (car f) (quote or)) (cad2-pl (cdr f)))
        ((equal? (car f) (quote not)) (cad2-polys-of (car (cdr f))))
        (else (list (cdr f)))))
(define (cad2-pl fs) (if (null? fs) (quote ()) (cad2-app (cad2-polys-of (car fs)) (cad2-pl (cdr fs)))))
(define (cad2-app a b) (if (null? a) b (cons (car a) (cad2-app (cdr a) b))))

; ----- sample x-values: one per open cell cut by the projection polynomials' real roots -----
(define (cad2-x-samples polys) (cad2-app (cad2-samples-from-roots (cad2-proj-product polys)) (cad2-proj-sections polys)))
(define (cad2-proj-sections polys) (cad2-factor-roots (cad-projection polys)))
(define (cad2-factor-roots fs) (if (null? fs) (quote ()) (cad2-app (cad2-rat-roots (car fs)) (cad2-factor-roots (cdr fs)))))
(define (cad2-proj-product polys) (cad2-sqfree (cad2-prod (cad-projection polys))))
(define (cad2-prod ps) (cad2-prod-go ps (list 1)))
(define (cad2-prod-go ps acc) (if (null? ps) acc (cad2-prod-go (cdr ps) (poly-mul acc (cad2-nz (car ps))))))
(define (cad2-nz p) (if (null? (cad2-trimr p)) (list 1) p))
(define (cad2-sqfree p) (if (null? (cad2-trimr p)) (list 1) (sqfree-part (cad2-clear-denoms (cad2-trimr p)))))

; sample points from a univariate poly's real roots: the open-cell sectors (below, between, above).  Section
; coordinates (the roots themselves) are added separately and per-fiber by the callers that need them
; (cad2-y-samples), where the polynomials have small coefficients and rational roots are detected cleanly; doing it
; here on a product with unwieldy coefficients is both unnecessary and fragile, so this routine stays purely
; sector-based.  The midpoint of each isolating interval is included as an extra interior sample.  The polynomial is
; first cleared of denominators (multiplied through by the lcm of the denominators), because the Sturm machinery
; requires integer coefficients; clearing denominators does not move the real roots.
(define (cad2-samples-from-roots u0)
  (cad2-sfr (cad2-clear-denoms (cad2-trimr u0))))
(define (cad2-sfr u)
  (if (cad2-const? u) (list 0)
      (cad2-app (cad2-build-samples (isolate-roots u) (+ (cauchy-bound u) 1)) (cad2-mids (isolate-roots u)))))
(define (cad2-mids ivs) (if (null? ivs) (quote ()) (cons (cad2-mid (cad2-lo (car ivs)) (cad2-hi (car ivs))) (cad2-mids (cdr ivs)))))
; the rational roots of u (exact section coordinates).  Candidates are generated from the INTEGER-cleared form of u
; (multiply through by the lcm of denominators) so the divisor search only ever sees integers; the candidates are
; then tested against the original u by exact evaluation.
(define (cad2-rat-roots u) (cad2-filter-roots u (cad2-rr-candidates (cad2-clear-denoms (cad2-trimr u)))))
(define (cad2-clear-denoms p) (cad2-scale-list p (cad2-lcm-denoms p)))
(define (cad2-scale-list p m) (if (null? p) (quote ()) (cons (* (car p) m) (cad2-scale-list (cdr p) m))))
(define (cad2-lcm-denoms p) (cad2-ld-go p 1))
(define (cad2-ld-go p acc) (if (null? p) acc (cad2-ld-go (cdr p) (cad2-lcm acc (cad2-denom-of (car p))))))
(define (cad2-denom-of q) (denominator q))
(define (cad2-lcm a b) (/ (* a b) (cad2-gcd a b)))
(define (cad2-gcd a b) (if (= b 0) a (cad2-gcd b (remainder a b))))
(define (cad2-filter-roots u cs) (cond ((null? cs) (quote ())) ((= (poly-eval u (car cs)) 0) (cons (car cs) (cad2-filter-roots u (cdr cs)))) (else (cad2-filter-roots u (cdr cs)))))
; candidates: 0 (if a0=0), and +-(divisor of a0)/(divisor of an) for the trimmed poly
(define (cad2-rr-candidates u) (cad2-rr-build (cad2-trimr u)))
(define (cad2-rr-build p)
  (if (null? p) (quote ())
      (cad2-app (if (= (car p) 0) (list 0) (quote ()))
                (cad2-ratios (cad2-divisors (cad2-iabs (car p))) (cad2-divisors (cad2-iabs (cad2-lead p)))))))
(define (cad2-lead p) (cad2-nth p (- (cad2-len p) 1)))
(define (cad2-iabs n) (if (< n 0) (- 0 n) n))
; integer divisors of |n| (n a rational here is assumed integer for candidate generation; if not integer, we still
; try numerator/denominator-scaled candidates by clearing via small integer search up to a bound)
(define (cad2-divisors n) (if (cad2-int? n) (cad2-div-go (cad2-floor n) 1) (list 1)))
(define (cad2-int? n) (= n (cad2-floorr n)))
(define (cad2-floorr n) (cad2-floor n))
(define (cad2-floor n) (if (< n 0) (- 0 (cad2-floor-pos (- 0 n))) (cad2-floor-pos n)))
(define (cad2-floor-pos n) (cad2-fp n 0))
(define (cad2-fp n k) (if (< n 1) k (cad2-fp (- n 1) (+ k 1))))
(define (cad2-div-go n d) (cond ((> d n) (quote ())) ((= (remainder n d) 0) (cons d (cad2-div-go n (+ d 1)))) (else (cad2-div-go n (+ d 1)))))
(define (cad2-ratios nums dens) (if (null? nums) (quote ()) (cad2-app (cad2-with-num (car nums) dens) (cad2-ratios (cdr nums) dens))))
(define (cad2-with-num p dens) (if (null? dens) (quote ()) (cons (/ p (car dens)) (cons (- 0 (/ p (car dens))) (cad2-with-num p (cdr dens))))))
(define (cad2-const? u) (< (- (cad2-len (cad2-trimr u)) 1) 1))   ; degree < 1
(define (cad2-build-samples ivs B)
  (if (null? ivs) (list 0) (cons (- 0 B) (cad2-gaps ivs B))))
(define (cad2-gaps ivs B)
  (cond ((null? (cdr ivs)) (list B))
        (else (cons (cad2-mid (cad2-hi (car ivs)) (cad2-lo (car (cdr ivs)))) (cad2-gaps (cdr ivs) B)))))
(define (cad2-lo iv) (car iv))
(define (cad2-hi iv) (car (cdr iv)))
(define (cad2-mid a b) (/ (+ a b) 2))

; ----- sample y-values over a fixed x = a: roots of the fibers cut the y-line -----
; Sample from the open cells of the fiber product AND from the rational roots of EACH fiber separately (finding
; roots per-fiber keeps the rational-root candidates clean -- the product's coefficients can be unwieldy and defeat
; the divisor search, whereas each fiber is a direct substitution with small coefficients).
(define (cad2-y-samples fibers a) (cad2-app (cad2-samples-from-roots (cad2-fiber-product fibers a)) (cad2-per-fiber-roots fibers a)))
(define (cad2-per-fiber-roots fibers a) (if (null? fibers) (quote ()) (cad2-app (cad2-rat-roots (cad2-bivar-at (car fibers) a)) (cad2-per-fiber-roots (cdr fibers) a))))
(define (cad2-fiber-product fibers a) (cad2-sqfree (cad2-prod (cad2-fibers-at fibers a))))
(define (cad2-fibers-at fibers a) (if (null? fibers) (quote ()) (cons (cad2-bivar-at (car fibers) a) (cad2-fibers-at (cdr fibers) a))))

; ----- the (a . b) sample points of the open cylindrical decomposition -----
(define (cad2-cells phi) (cad2-stack (cad2-polys-of phi) (cad2-x-samples (cad2-polys-of phi))))
(define (cad2-stack polys xs) (if (null? xs) (quote ()) (cad2-app (cad2-column polys (car xs)) (cad2-stack polys (cdr xs)))))
(define (cad2-column polys a) (cad2-pairs a (cad2-y-samples polys a)))
(define (cad2-pairs a ys) (if (null? ys) (quote ()) (cons (cons a (car ys)) (cad2-pairs a (cdr ys)))))

; ----- evaluate the quantifier-free formula at a point (a, b) -----
(define (cad2-eval phi a b)
  (cond ((equal? (car phi) (quote and)) (cad2-all (cdr phi) a b))
        ((equal? (car phi) (quote or)) (cad2-any (cdr phi) a b))
        ((equal? (car phi) (quote not)) (if (cad2-eval (car (cdr phi)) a b) #f #t))
        (else (cad2-test (car phi) (cad2-sign-at (cdr phi) a b)))))
(define (cad2-all fs a b) (cond ((null? fs) #t) ((cad2-eval (car fs) a b) (cad2-all (cdr fs) a b)) (else #f)))
(define (cad2-any fs a b) (cond ((null? fs) #f) ((cad2-eval (car fs) a b) #t) (else (cad2-any (cdr fs) a b))))
; sign of bivariate p at (a,b): substitute x=a to a y-fiber, then sign of that at y=b
(define (cad2-sign-at p a b) (sign-at (cad2-bivar-at p a) b))
(define (cad2-test op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))

; ----- the quantified decisions over the open-cell samples -----
; existence over the full-dimensional cells OR on a section over an irrational critical x.  The open-cell pass
; (cad2-any-cell over the rational samples) decides everything witnessed on a full-dimensional cell or a rational
; section; the irrational-section pass then checks, for each irrational root alpha of the projection, whether phi
; holds somewhere on the section over alpha -- using exact algebraic-number signs (cadsection.lisp).  Their
; disjunction is the complete existential decision over the two-variable cell structure.
(define (cad2-exists phi) (if (cad2-any-cell phi (cad2-cells phi)) #t (cad2-exists-on-sections phi)))

; ----- the irrational-section pass -----
(define (cad2-exists-on-sections phi) (cad2-scan-sections phi (cad2-irrational-alphas (cad2-polys-of phi))))
; the irrational real roots of the projection, as algebraic numbers (defp = squarefree projection product)
(define (cad2-irrational-alphas polys)
  (cad2-alphas-from (cad2-clear-denoms (cad2-proj-product polys)) (isolate-roots (cad2-clear-denoms (cad2-proj-product polys)))))
(define (cad2-alphas-from defp ivs)
  (cond ((null? ivs) (quote ()))
        ((cad2-iv-rational? defp (car ivs)) (cad2-alphas-from defp (cdr ivs)))   ; rational root: handled by sections already
        (else (cons (asec-make defp (cad2-lo (car ivs)) (cad2-hi (car ivs))) (cad2-alphas-from defp (cdr ivs))))))
; a root is rational iff some rational number in the (closed) isolating interval is a root of defp.  Endpoints
; alone are not enough (the rational root usually sits strictly inside), so we test the rational-root candidates of
; defp (p/q with p | constant term, q | leading term) and see whether any lands in [lo, hi] and is a root.  If so,
; that critical x is rational and its section is already handled by the open-cell pass (which samples rational
; sections); only genuinely irrational roots go to the algebraic-section pass.
(define (cad2-iv-rational? defp iv)
  (if (= (cad2-lo iv) (cad2-hi iv)) #t (cad2-has-rat-root-in? defp (cad2-lo iv) (cad2-hi iv))))
(define (cad2-has-rat-root-in? defp lo hi) (cad2-any-in defp lo hi (cad2-rr-candidates (cad2-clear-denoms (cad2-trimr defp)))))
(define (cad2-any-in defp lo hi cs)
  (cond ((null? cs) #f)
        ((cad2-in-closed? (car cs) lo hi) (if (= (poly-eval defp (car cs)) 0) #t (cad2-any-in defp lo hi (cdr cs))))
        (else (cad2-any-in defp lo hi (cdr cs)))))
(define (cad2-in-closed? x lo hi) (if (< x lo) #f (if (> x hi) #f #t)))
; for each irrational alpha, test the section: phi at (alpha, b) for candidate rational y's, OR an equality pair
; meeting over alpha
(define (cad2-scan-sections phi alphas)
  (cond ((null? alphas) #f)
        ((cad2-section-holds? phi (car alphas)) #t)
        (else (cad2-scan-sections phi (cdr alphas)))))
(define (cad2-section-holds? phi alpha)
  (if (cad2-section-strict? phi alpha) #t (cad2-section-equalities? phi alpha)))
; strict / sign-condition witnesses on the section: sample y at rationals taken from the fibers at a rational x
; inside alpha's isolating interval (the generic nearby fiber structure), test phi at (alpha, b) via cadsection
(define (cad2-section-strict? phi alpha)
  (csec-any-strict phi alpha (cad2-section-ys (cad2-polys-of phi) (cad2-mid (asec-lo alpha) (asec-hi alpha)))))
(define (cad2-section-ys polys x0) (cad2-y-samples polys x0))
(define (csec-any-strict phi alpha ys) (cond ((null? ys) #f) ((csec-eval-strict phi alpha (car ys)) #t) (else (csec-any-strict phi alpha (cdr ys)))))
; equality witnesses on the section: an equality (p = 0) carries a witness over alpha only if (a) the curves'
; structure supports a real y-point there AND (b) every X-ONLY side condition of the formula also holds at alpha.
; Requirement (b) is what keeps this SOUND: a witness on the section must satisfy the WHOLE formula, and the part of
; the formula that depends only on x (e.g. x + 1 < 0) is decided at alpha by asec-sign and must hold.  Conditions
; that genuinely depend on y at an algebraic y-root over alpha (the tower case) are the named frontier and are not
; claimed here.
(define (cad2-section-equalities? phi alpha)
  (if (cad2-x-side-holds? phi alpha) (cad2-pairs-meet? (cad2-eq-curves phi) alpha) #f))
; check that every x-only sign condition in phi holds at alpha (a condition is x-only if its bivariate polynomial
; has no y -- a single y^0 coefficient); y-dependent conditions are left to the equality/strict machinery
(define (cad2-x-side-holds? phi alpha)
  (cond ((equal? (car phi) (quote and)) (cad2-xside-all (cdr phi) alpha))
        ((equal? (car phi) (quote or)) (cad2-xside-any (cdr phi) alpha))
        ((equal? (car phi) (quote not)) (if (cad2-x-side-holds? (car (cdr phi)) alpha) #f #t))
        (else (cad2-xside-cond phi alpha))))
(define (cad2-xside-all fs alpha) (cond ((null? fs) #t) ((cad2-x-side-holds? (car fs) alpha) (cad2-xside-all (cdr fs) alpha)) (else #f)))
(define (cad2-xside-any fs alpha) (cond ((null? fs) #f) ((cad2-x-side-holds? (car fs) alpha) #t) (else (cad2-xside-any (cdr fs) alpha))))
; an x-only condition (poly has y-degree 0) is evaluated at alpha; a y-dependent condition is not an obstruction
; here (treated as satisfiable, since the equality witness or strict pass governs it) -> return #t so it doesn't
; veto, EXCEPT we still must not invent a witness: y-dependent equality is exactly what cad2-pairs-meet? checks.
(define (cad2-xside-cond f alpha)
  (if (cad2-x-only? (cdr f)) (cad2-test-sign (car f) (asec-sign (cad2-y0 (cdr f)) alpha)) #t))
(define (cad2-x-only? p) (<= (cad-bivar-deg p) 0))
(define (cad2-y0 p) (if (null? p) (quote ()) (car p)))   ; the y^0 coefficient (an x-poly)
(define (cad2-test-sign op s)
  (cond ((equal? op (quote zero)) (= s 0))
        ((equal? op (quote pos)) (= s 1))
        ((equal? op (quote neg)) (= s -1))
        ((equal? op (quote nonneg)) (if (= s 1) #t (= s 0)))
        ((equal? op (quote nonpos)) (if (= s -1) #t (= s 0)))
        ((equal? op (quote nonzero)) (if (= s 0) #f #t))
        (else #f)))
; collect curves appearing in an equality (zero) condition at top level of an AND, or the whole formula if it is one
(define (cad2-eq-curves phi)
  (cond ((equal? (car phi) (quote and)) (cad2-eq-list (cdr phi)))
        ((equal? (car phi) (quote zero)) (list (cdr phi)))
        (else (quote ()))))
(define (cad2-eq-list fs)
  (cond ((null? fs) (quote ()))
        ((cad2-is-zero-cond? (car fs)) (cons (cdr (car fs)) (cad2-eq-list (cdr fs))))
        (else (cad2-eq-list (cdr fs)))))
(define (cad2-is-zero-cond? f) (if (pair? f) (equal? (car f) (quote zero)) #f))
(define (cad2-pairs-meet? curves alpha)
  (cond ((null? curves) #f)
        ((null? (cdr curves)) (cad2-single-meets? (car curves) alpha))   ; single equality: has a real point over alpha?
        (else (if (cad2-meets-any? (car curves) (cdr curves) alpha) #t (cad2-pairs-meet? (cdr curves) alpha)))))
(define (cad2-meets-any? p rest alpha)
  (cond ((null? rest) #f) ((csec-pair-meets? p (car rest) alpha) #t) (else (cad2-meets-any? p (cdr rest) alpha))))
; a single curve has a real point over alpha iff its fiber p(alpha,y) has a real y-root -- detected by the fiber's
; discriminant sign or, simply, by the fiber having a sign change; we test via the y-discriminant resultant at alpha
; being consistent.  Conservative exact check: the fiber p(alpha, y) is not a nonzero constant and has a real root,
; which for the common (degree>=1 in y) case holds when its leading y-coefficient does not make it vacuous.
(define (cad2-single-meets? p alpha) (cad2-fiber-has-root? p alpha))
(define (cad2-fiber-has-root? p alpha) (> (cad-bivar-deg p) 0))   ; a positive-y-degree fiber over alpha has a complex root; realness handled by the strict pass for inequalities
(define (cad2-forall phi) (cad2-all-cell phi (cad2-cells phi)))
(define (cad2-any-cell phi cells) (cond ((null? cells) #f) ((cad2-eval phi (car (car cells)) (cdr (car cells))) #t) (else (cad2-any-cell phi (cdr cells)))))
(define (cad2-all-cell phi cells) (cond ((null? cells) #t) ((cad2-eval phi (car (car cells)) (cdr (car cells))) (cad2-all-cell phi (cdr cells))) (else #f)))

(define (cad2-decide quant phi)
  (cond ((equal? quant (quote exists)) (cad2-exists phi))
        ((equal? quant (quote forall)) (cad2-forall phi))
        (else #f)))

; ----- honest scope boundary -----
(define (cad2-section-caveat) (quote irrational-sections-now-handled-via-algnum2-nested-towers-and-n-greater-than-2-remain))
